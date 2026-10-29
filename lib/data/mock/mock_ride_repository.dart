import 'dart:async';

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/repositories/ride_repository.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';
import 'package:kktc_taksim/models/ride_progress.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:kktc_taksim/services/routing_service.dart';

/// Şoför tarafı olmadan çağrıyı taklit eder: kısa bir aramadan sonra örnek sürücü atanır,
/// sürücü rota boyunca yolcuya gelir; yolculuk "(DEMO)" butonlarıyla başlatılıp bitirilir.
/// Süreler gerçek süreden bağımsızdır (demo için hızlandırılmış).
class MockRideRepository implements RideRepository {
  final TripRepository _trips;
  final RoutingService _routing;
  final Duration searchDelay;
  final Duration approachDuration;
  final Duration tripDuration;
  final Duration tick;

  StreamController<RideSession>? _controller;
  RideSession? _session;
  Timer? _timer;

  MockRideRepository({
    required TripRepository trips,
    RoutingService? routing,
    this.searchDelay = AppDurations.driverSearch,
    this.approachDuration = AppDurations.driverApproachDemo,
    this.tripDuration = AppDurations.tripDemo,
    this.tick = AppDurations.simulationTick,
  })  : _trips = trips,
        _routing = routing ?? RoutingService();

  @override
  bool get hasDemoControls => true;

  @override
  Stream<RideSession> request(RideRequest request) {
    _stop();
    final controller = StreamController<RideSession>(onCancel: _stop);
    _controller = controller;
    _emit(RideSession(
        id: 'ride-${DateTime.now().microsecondsSinceEpoch}', request: request, status: RideStatus.searching));
    _timer = Timer(searchDelay, _assignDriver);
    return controller.stream;
  }

  Future<void> _assignDriver() async {
    final session = _session;
    if (session == null || session.status != RideStatus.searching) return;

    final pickup = session.request.pickup.position;
    final driverStart = MockData.offsetFrom(pickup, MockData.assignedTaxiOffset);
    final minutes = session.request.taxiType.pickupMinutes;
    _emit(session.copyWith(
      status: RideStatus.driverAssigned,
      driver: MockData.driver,
      progress: RideProgress(position: driverStart, fraction: 0, minutesLeft: minutes),
    ));

    final approach = await _routing.route(driverStart, pickup);
    if (_session?.id != session.id || _session?.status != RideStatus.driverAssigned) return;
    _animate(approach.points, approachDuration, minutes, onDone: RideStatus.driverArrived);
  }

  @override
  Future<void> startTripDemo(String rideId) async {
    final session = _current(rideId);
    if (session == null) return;
    if (session.status != RideStatus.driverAssigned && session.status != RideStatus.driverArrived) return;

    _timer?.cancel();
    final route = session.request.route;
    _emit(session.copyWith(
      status: RideStatus.inProgress,
      progress: RideProgress(position: route.points.first, fraction: 0, minutesLeft: route.durationMinutes),
    ));
    _animate(route.points, tripDuration, route.durationMinutes, onDone: RideStatus.arrived);
  }

  @override
  Future<void> completeDemo(String rideId) async {
    final session = _current(rideId);
    if (session == null) return;
    if (session.status != RideStatus.inProgress && session.status != RideStatus.arrived) return;

    _timer?.cancel();
    await _record(session, TripStatus.completed, price: session.request.fare.typical);
    _emit(session.copyWith(status: RideStatus.completed));
  }

  @override
  Future<void> cancel(String rideId) async {
    final session = _current(rideId);
    if (session == null) return;

    _timer?.cancel();
    // Sürücü yola çıkmadan iptal edilen arama geçmişe yazılmaz.
    if (session.status.hasDriver) await _record(session, TripStatus.cancelled, price: 0);
    _emit(session.copyWith(status: RideStatus.cancelled));
  }

  @override
  Future<void> rate(String rideId, int stars) async {
    // Demo: puan saklanmaz. Backend'de sürücünün ortalamasına eklenecek.
  }

  RideSession? _current(String rideId) {
    final session = _session;
    if (session == null || session.id != rideId || session.status.isFinished) return null;
    return session;
  }

  /// Sürücüyü [path] boyunca [duration] içinde ilerletir; kalan süre gerçek süreye göre azalır.
  void _animate(List<LatLng> path, Duration duration, int realMinutes, {required RideStatus onDone}) {
    _timer?.cancel();
    final startedAt = DateTime.now();

    void step() {
      final session = _session;
      if (session == null) return;
      final elapsed = DateTime.now().difference(startedAt).inMicroseconds;
      final fraction = (elapsed / duration.inMicroseconds).clamp(0.0, 1.0);
      final progress = RideProgress(
        position: pointAlong(path, fraction),
        fraction: fraction,
        minutesLeft: (realMinutes * (1 - fraction)).ceil(),
      );
      if (fraction >= 1) {
        _timer?.cancel();
        _emit(session.copyWith(status: onDone, progress: progress));
      } else {
        _emit(session.copyWith(progress: progress));
      }
    }

    step();
    _timer = Timer.periodic(tick, (_) => step());
  }

  /// Geçmişe yazamamak yolculuğu bozmasın: hata yutulur, yolculuk yine tamamlanır/iptal edilir.
  Future<void> _record(RideSession session, TripStatus status, {required int price}) async {
    final request = session.request;
    try {
      await _trips.add(Trip(
        id: _trips.newId(),
        from: request.pickup.name,
        to: request.destination.name,
        dateTime: DateTime.now(),
        price: price,
        status: status,
        taxiType: request.taxiType,
        payment: request.payment,
      ));
    } catch (_) {
      // Backend'e ulaşılamadı; Firestore çevrimdışıyken yazmayı zaten kuyruğa alır.
    }
  }

  void _emit(RideSession session) {
    _session = session;
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    controller.add(session);
    if (session.status.isFinished) {
      controller.close();
      _controller = null;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _controller = null;
  }
}
