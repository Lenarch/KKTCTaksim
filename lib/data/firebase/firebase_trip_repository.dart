import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';
import 'package:kktc_taksim/models/trip.dart';

/// Yolculuklar Firestore'da `users/{uid}/trips/{tripId}` altında; herkes yalnızca kendi
/// yolculuklarını görür (bkz. firestore.rules). Belge kimliği yolculuğun kimliğidir.
class FirebaseTripRepository implements TripRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseTripRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _trips(String uid) =>
      _firestore.collection('users').doc(uid).collection('trips');

  CollectionReference<Map<String, dynamic>> get _myTrips {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan yolculuk kaydedilemez');
    return _trips(user.uid);
  }

  /// Firestore kimliği sunucuya gitmeden, yerelde üretilir.
  @override
  String newId() => _firestore.collection('users').doc().id;

  @override
  Stream<List<Trip>> watch(TripStatus status) {
    // Kullanıcı çıkış yapıp başka numarayla girerse liste de onunkine geçer.
    return switchMap(_auth.authStateChanges(), (User? user) {
      if (user == null) return Stream.value(const <Trip>[]);
      // Yalnızca durum filtresi; sıralama burada yapılıyor (bileşik dizin gerekmesin).
      return _trips(user.uid).where('status', isEqualTo: status.name).snapshots().map((snapshot) {
        final trips = snapshot.docs.map(tripFromDocument).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return status == TripStatus.upcoming ? trips : trips.reversed.toList();
      });
    });
  }

  @override
  Future<void> add(Trip trip) => _myTrips.doc(trip.id).set(tripToDocument(trip));

  @override
  Future<void> deleteAll() async {
    final trips = await _myTrips.get();
    for (final doc in trips.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> cancel(String id) => _myTrips.doc(id).update({
        'status': TripStatus.cancelled.name,
        'price': 0,
      });
}

/// Belgede kimlik tekrar tutulmaz; belge kimliğinin kendisidir.
Map<String, dynamic> tripToDocument(Trip trip) => trip.toJson()..remove('id');

Trip tripFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) => Trip.fromJson({...doc.data()!, 'id': doc.id});
