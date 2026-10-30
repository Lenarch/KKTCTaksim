import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

/// Paylaşımlı gruplar Firestore'da `sharedRides/{rideId}` altında; giriş yapan herkes görür,
/// üyeliğe yalnızca kendini ekleyip çıkarabilir (bkz. firestore.rules).
class FirebaseSharedRideRepository implements SharedRideRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseSharedRideRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rides => _firestore.collection('sharedRides');

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan paylaşımlı yolculuk değiştirilemez');
    return user.uid;
  }

  @override
  Stream<List<SharedRide>> watchActive() {
    // Kurallar giriş yapmayanın okumasına izin vermez; çıkışta liste boşalır.
    return switchMap(_auth.authStateChanges(), (User? user) {
      if (user == null) return Stream.value(const <SharedRide>[]);
      final now = DateTime.now().millisecondsSinceEpoch;
      return _rides.where('departure', isGreaterThan: now).orderBy('departure').snapshots().map((snapshot) {
        // Akış açık kaldıkça kalkışı geçen gruplar da düşsün.
        final current = DateTime.now();
        return snapshot.docs.map(sharedRideFromDocument).where((r) => r.departure.isAfter(current)).toList();
      });
    });
  }

  @override
  Future<void> create(SharedRide ride) {
    final ref = _rides.doc();
    return ref.set(sharedRideToDocument(ride.copyWith(id: ref.id, memberIds: [_userId])));
  }

  @override
  Future<void> join(String rideId) async {
    final userId = _userId;
    final ref = _rides.doc(rideId);
    // Hata transaction'ın dışında fırlatılır; web'de içeride fırlatılan hata sarmalanabiliyor.
    // Aynı anda iki kişi son koltuğa katılırsa Firestore birini yeniden dener, o da `full` alır.
    final error = await _firestore.runTransaction<SharedRideError?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return SharedRideError.notFound;
      final ride = sharedRideFromDocument(snapshot);
      try {
        final members = membersAfterJoin(ride, userId);
        if (!identical(members, ride.memberIds)) transaction.update(ref, {'memberIds': members});
        return null;
      } on SharedRideException catch (e) {
        return e.error;
      }
    });
    if (error != null) throw SharedRideException(error);
  }

  @override
  Future<void> leave(String rideId) async {
    final userId = _userId;
    final ref = _rides.doc(rideId);
    final error = await _firestore.runTransaction<SharedRideError?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return SharedRideError.notFound;
      final ride = sharedRideFromDocument(snapshot);
      if (!ride.hasMember(userId)) return null;
      final members = membersAfterLeave(ride, userId);
      if (members.isEmpty) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, {'memberIds': members});
      }
      return null;
    });
    if (error != null) throw SharedRideException(error);
  }
}

/// Belgede kimlik tekrar tutulmaz; belge kimliğinin kendisidir.
Map<String, dynamic> sharedRideToDocument(SharedRide ride) => ride.toJson()..remove('id');

SharedRide sharedRideFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) =>
    SharedRide.fromJson({...doc.data()!, 'id': doc.id});
