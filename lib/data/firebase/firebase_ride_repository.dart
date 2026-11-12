import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/data/firebase/ride_documents.dart';
import 'package:kktc_taksim/data/repositories/ride_repository.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_progress.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Yolcu tarafı gerçek çağrı: `rides/{rideId}` belgesi oluşturulur, gerçek şoför kabul edip
/// ilerletir (şoför uygulaması). Belli bir sürede kimse almazsa çağrı iptal edilir.
class FirebaseRideRepository implements RideRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final TripRepository _trips;
  final Duration searchTimeout;

  FirebaseRideRepository({
    required TripRepository trips,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    this.searchTimeout = AppDurations.driverSearchTimeout,
  })  : _trips = trips,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rides => _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _locks => _firestore.collection('rideLocks');

  @override
  bool get hasDemoControls => false;

  /// Uygulama yolculuk sırasında kapanırsa çağrı sunucuda açık kalır ama ekrana geri gelmez; kilit
  /// de yeni çağrıyı engeller. Yeni çağrıdan önce yarım kalan çağrı iptal edilir (şoför de görür).
  /// Yolculuk başlamışsa iptal edilemez; o çağrı şoför bitirene kadar sürer.
  Future<void> _releasePrevious(String userId) async {
    try {
      final previousId = (await _locks.doc(userId).get()).data()?['rideId'] as String?;
      if (previousId == null) return;
      final previous = await _rides.doc(previousId).get();
      if (passengerCanCancel(previous.data()?['status'] as String?)) await cancel(previousId);
    } catch (_) {
      // Okunamadıysa ya da iptal reddedildiyse yeni çağrının sonucunu kurallar belirler.
    }
  }

  @override
  Stream<RideSession> request(RideRequest request) {
    final user = _auth.currentUser;
    if (user == null) return Stream.error(StateError('Giriş yapılmadan taksi çağrılamaz'));
    final ref = _rides.doc();
    late final StreamController<RideSession> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? timeout;
    var recorded = false;

    Future<void> record(RideSession session) async {
      if (recorded) return;
      recorded = true;
      final completed = session.status == RideStatus.completed;
      try {
        await _trips.add(Trip(
          id: _trips.newId(),
          from: request.pickup.name,
          to: request.destination.name,
          dateTime: DateTime.now(),
          price: completed ? request.fare.typical : 0,
          status: completed ? TripStatus.completed : TripStatus.cancelled,
          taxiType: request.taxiType,
          payment: request.payment,
        ));
      } catch (_) {
        // Geçmişe yazılamasa da yolculuk biter; Firestore çevrimdışıyken yazmayı kuyruğa alır.
      }
    }

    Future<void> close() async {
      timeout?.cancel();
      await subscription?.cancel();
      if (!controller.isClosed) await controller.close();
    }

    controller = StreamController<RideSession>(
      onListen: () async {
        await _releasePrevious(user.uid);
        try {
          // Kurallar yolcunun aynı anda tek etkin çağrısına izin verir: çağrı, kilidi kendine
          // çeviren yazımla birlikte gider (önceki çağrı bitmemişse ikisi de reddedilir).
          final batch = _firestore.batch()
            ..set(ref, rideRequestToDocument(request, user.uid))
            ..set(_locks.doc(user.uid), {
              'rideId': ref.id,
              'at': FieldValue.serverTimestamp(),
            });
          await batch.commit();
        } catch (e) {
          controller.addError(e);
          await close();
          return;
        }
        // Kimse almazsa yolcu sonsuza kadar beklemesin; ekran "uygun taksi bulunamadı" der.
        timeout = Timer(searchTimeout, () => cancel(ref.id));
        subscription = ref.snapshots().listen((doc) async {
          if (!doc.exists) return;
          final offer = rideOfferFromDocument(doc);
          if (offer.status != RideStatus.searching) timeout?.cancel();
          final session = sessionFromOffer(offer, request);
          controller.add(session);
          if (offer.status.isFinished) {
            // Sürücü atanmadan iptal edilen arama geçmişe yazılmaz.
            if (offer.status == RideStatus.completed || offer.driver != null) await record(session);
            await close();
          }
        }, onError: (Object e) {
          controller.addError(e);
          close();
        });
      },
      onCancel: close,
    );
    return controller.stream;
  }

  @override
  Future<void> cancel(String rideId) => _rides.doc(rideId).update({
        'status': RideStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> rate(String rideId, int stars) => _rides.doc(rideId).update({
        'rating': stars,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Gerçek sistemde şoför başlatır/bitirir; yolcu ekranında bu düğmeler görünmez.
  @override
  Future<void> startTripDemo(String rideId) async {}

  @override
  Future<void> completeDemo(String rideId) async {}
}

/// Yolcu yalnızca yolculuk başlamadan iptal edebilir (firestore.rules'taki yolcu iptali ile aynı liste).
bool passengerCanCancel(String? status) =>
    status == 'searching' || status == 'driverAssigned' || status == 'driverArrived';

/// Şoförün bildirdiği konumdan yolcu ekranının beklediği ilerleme hesaplanır.
RideSession sessionFromOffer(RideOffer offer, RideRequest request) {
  return RideSession(
    id: offer.id,
    request: request,
    status: offer.status,
    driver: offer.driver,
    progress: progressFor(offer.status, offer.driverPosition, request),
  );
}

RideProgress? progressFor(RideStatus status, LatLng? driverPosition, RideRequest request) {
  if (driverPosition == null) return null;
  if (status == RideStatus.inProgress || status == RideStatus.arrived || status == RideStatus.completed) {
    final fraction = fractionAlong(request.route.points, driverPosition);
    return RideProgress(
      position: driverPosition,
      fraction: fraction,
      minutesLeft: (request.route.durationMinutes * (1 - fraction)).ceil(),
    );
  }
  // Yolcuya gelirken: kuş uçuşu mesafeden şehir içi ortalama hızla kaba tahmin.
  final meters = distanceMeters(driverPosition, request.pickup.position);
  return RideProgress(
    position: driverPosition,
    fraction: 0,
    minutesLeft: (meters / approachMetersPerMinute).ceil(),
  );
}

/// Şehir içinde ~30 km/sa.
const double approachMetersPerMinute = 500;
