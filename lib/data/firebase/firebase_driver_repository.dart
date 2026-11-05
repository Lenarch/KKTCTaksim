import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/data/firebase/firebase_live_share_repository.dart';
import 'package:kktc_taksim/data/firebase/firebase_shared_ride_repository.dart' show retryWhilePermissionDenied;
import 'package:kktc_taksim/data/firebase/ride_documents.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/services/trusted_clock.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Şoför tarafı: `drivers/{uid}` ve `rides/{rideId}` (bkz. firestore.rules).
class FirebaseDriverRepository implements DriverRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseDriverRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _drivers => _firestore.collection('drivers');
  CollectionReference<Map<String, dynamic>> get _rides => _firestore.collection('rides');

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan şoför işlemi yapılamaz');
    return user;
  }

  static const List<String> _activeStatuses = ['driverAssigned', 'driverArrived', 'inProgress'];

  @override
  Stream<DriverProfile?> watchProfile() => switchMap(_auth.authStateChanges(), (User? user) {
        if (user == null) return Stream.value(null);
        return _drivers.doc(user.uid).snapshots().map((doc) {
          final data = doc.data();
          if (data == null) return null;
          return DriverProfile(
            name: data['name'] as String,
            plate: data['plate'] as String,
            car: data['car'] as String,
            carColor: CarColor.values.byName(data['carColor'] as String),
            online: data['online'] as bool? ?? false,
            approved: data['approved'] as bool? ?? false,
          );
        });
      });

  @override
  Future<void> register(DriverProfile profile) {
    final user = _user;
    return _drivers.doc(user.uid).set({
      'name': profile.name.trim(),
      'plate': profile.plate.trim().toUpperCase(),
      'car': profile.car.trim(),
      'carColor': profile.carColor.name,
      'phone': user.phoneNumber,
      'online': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setOnline(bool online, LatLng? position) async {
    if (online && position == null) throw const DriverException(DriverError.noLocation);
    final ref = _drivers.doc(_user.uid);
    final doc = await ref.get();
    if (!doc.exists) throw const DriverException(DriverError.notRegistered);
    if (online && doc.data()?['approved'] != true) throw const DriverException(DriverError.notApproved);
    await ref.update({
      'online': online,
      if (position != null) 'position': pointToJson(position),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updatePosition(LatLng position) => _drivers.doc(_user.uid).update({
        'position': pointToJson(position),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  // Çevrimiçi olunca dinleme, `online: true` sunucuya ulaşmadan başlayabiliyor; kurallar o an şoförü
  // çevrimdışı görüp dinlemeyi kapatıyordu (çağrılar uygulama yeniden açılana kadar gelmiyordu).
  Stream<List<RideOffer>> watchOpenRequests(LatLng? near) => retryWhilePermissionDenied(() => _rides
      .where('status', isEqualTo: RideStatus.searching.name)
      .snapshots()
      .map((snapshot) {
        // Yolcu arama sırasında uygulamayı kapatırsa çağrı `searching`'de kalır; yolcunun zaman aşımı
        // dolmuş çağrılar gösterilmez.
        final cutoff = TrustedClock.instance.now.subtract(AppDurations.driverSearchTimeout);
        final offers = snapshot.docs
            .where((doc) => !isRequestExpired(doc.data()['createdAt'], cutoff))
            // Şoför kendi çağrısını alamaz (kurallar da reddeder); listede gösterme.
            .where((doc) => doc.data()['passengerId'] != _auth.currentUser?.uid)
            .map(rideOfferFromDocument)
            .toList();
        if (near != null) {
          offers.sort((a, b) =>
              distanceMeters(near, a.pickup.position).compareTo(distanceMeters(near, b.pickup.position)));
        }
        return offers;
      }));

  @override
  Stream<RideOffer?> watchActiveRide() => switchMap(_auth.authStateChanges(), (User? user) {
        if (user == null) return Stream.value(null);
        return _rides
            .where('driverId', isEqualTo: user.uid)
            .where('status', whereIn: _activeStatuses)
            .snapshots()
            .map((snapshot) => snapshot.docs.isEmpty ? null : rideOfferFromDocument(snapshot.docs.first));
      });

  @override
  Future<void> accept(RideOffer offer, LatLng position) async {
    final user = _user;
    final driverDoc = await _drivers.doc(user.uid).get();
    final data = driverDoc.data();
    if (data == null) throw const DriverException(DriverError.notRegistered);
    final profile = DriverProfile(
      name: data['name'] as String,
      plate: data['plate'] as String,
      car: data['car'] as String,
      carColor: CarColor.values.byName(data['carColor'] as String),
    );
    final ref = _rides.doc(offer.id);
    // İki şoför aynı anda kabul ederse transaction birini yeniden dener; o "alınmış" görür.
    final taken = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.data()!['status'] != RideStatus.searching.name) return true;
      transaction.update(ref, {
        'status': RideStatus.driverAssigned.name,
        'driverId': user.uid,
        'driver': driverSnapshot(profile, user.phoneNumber ?? ''),
        'driverPosition': pointToJson(position),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return false;
    });
    if (taken) throw const DriverException(DriverError.rideTaken);
  }

  @override
  Future<void> updateRidePosition(String rideId, LatLng position) => _rides.doc(rideId).update({
        'driverPosition': pointToJson(position),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> advance(String rideId, RideStatus next, LatLng? position) => _rides.doc(rideId).update({
        'status': next.name,
        if (position != null) 'driverPosition': pointToJson(position),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> cancelRide(String rideId) => _rides.doc(rideId).update({
        'status': RideStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
