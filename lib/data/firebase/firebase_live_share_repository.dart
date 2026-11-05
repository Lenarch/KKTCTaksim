import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/data/repositories/live_share_repository.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/services/trusted_clock.dart';

/// Canlı paylaşımlar Firestore'da `liveShares/{shareId}` altında. Kimlik tahmin edilemez;
/// takip sayfası belgeyi bu kimlikle, giriş yapmadan okur (bkz. firestore.rules).
class FirebaseLiveShareRepository implements LiveShareRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseLiveShareRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shares => _firestore.collection('liveShares');

  @override
  Future<String> start(LiveShareInfo info, LatLng position) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan konum paylaşılamaz');
    final ref = _shares.doc();
    await ref.set({
      'ownerId': user.uid,
      'from': info.from,
      'to': info.to,
      'destination': pointToJson(info.destination),
      'driverName': info.driverName,
      'plate': info.plate,
      'car': info.car,
      'status': 'active',
      'position': pointToJson(position),
      'updatedAt': FieldValue.serverTimestamp(),
      // Kurallar bitişi sunucu saatiyle denetler.
      'expiresAt': TrustedClock.instance.now.add(LiveShareRepository.maxDuration).millisecondsSinceEpoch,
    });
    return ref.id;
  }

  @override
  Future<void> update(String shareId, LatLng position) => _shares.doc(shareId).update({
        'position': pointToJson(position),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> end(String shareId) => _shares.doc(shareId).update({
        'status': 'ended',
        'position': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Uri link(String shareId) => trackingLink(shareId);

  @override
  Future<void> deleteAllMine() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final shares = await _shares.where('ownerId', isEqualTo: user.uid).get();
    for (final doc in shares.docs) {
      await doc.reference.delete();
    }
  }
}

/// Kurallar enlem/boylamı sınırlar; fazla hane gereksiz (5 hane ≈ 1 m).
Map<String, double> pointToJson(LatLng point) => {
      'lat': double.parse(point.latitude.toStringAsFixed(5)),
      'lng': double.parse(point.longitude.toStringAsFixed(5)),
    };
