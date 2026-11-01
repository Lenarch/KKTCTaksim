import 'package:flutter_test/flutter_test.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/services/driver_navigation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  const pickup = LatLng(35.1856, 33.3823);
  const destination = LatLng(35.3412, 33.3196);

  RideOffer ride(RideStatus status) => RideOffer(
        id: 'r1',
        passengerId: 'yolcu',
        pickup: const GeoPlace(name: 'Lefkoşa', position: pickup),
        destination: const GeoPlace(name: 'Girne', position: destination),
        distanceMeters: 25000,
        durationSeconds: 1800,
        taxiType: TaxiType.economy,
        payment: PaymentMethod.cash,
        fareLow: 990,
        fareHigh: 1210,
        status: status,
      );

  // Doğu yönünde düz bir yol: 0,01° boylam ≈ 910 m (35° enlemde).
  const start = LatLng(35.0, 33.0);
  const end = LatLng(35.0, 33.02);
  const route = RouteInfo(points: [start, LatLng(35.0, 33.01), end], distanceMeters: 1820, durationSeconds: 180);

  test('Şoför yolcuyu alana kadar alış noktasına, sonra varışa gider', () {
    expect(navigationTarget(ride(RideStatus.driverAssigned)), pickup);
    expect(navigationTarget(ride(RideStatus.driverArrived)), pickup);
    expect(navigationTarget(ride(RideStatus.inProgress)), destination);
    expect(navigationTarget(ride(RideStatus.completed)), isNull);
  });

  test('Kalan mesafe ve süre şoförün rotadaki yerine göre azalır', () {
    final atStart = remainingAlong(route, start);
    expect(atStart.meters, closeTo(1820, 1));
    expect(atStart.seconds, closeTo(180, 1));

    final halfway = remainingAlong(route, const LatLng(35.0, 33.01));
    expect(halfway.meters, closeTo(910, 20));
    expect(halfway.seconds, closeTo(90, 2));

    expect(remainingAlong(route, end).meters, closeTo(0, 1));
  });

  test('Yol parçasına uzaklık köşe noktalarından bağımsız ölçülür', () {
    // Parçanın ortasından 100 m kuzey (0,0009° enlem ≈ 100 m); köşelere uzaklık yüzlerce metre.
    final distance = distanceToPath(const [start, end], const LatLng(35.0009, 33.01));
    expect(distance, closeTo(100, 2));
  });

  test('Rota yoksa, hedef değiştiyse ya da şoför saptıysa (bekleme süresi dolunca) yeniden istenir', () {
    final now = DateTime(2026, 11, 1, 12);
    final recent = now.subtract(const Duration(seconds: 5));
    final old = now.subtract(const Duration(seconds: 30));
    const onRoute = LatLng(35.0, 33.005);
    const offRoute = LatLng(35.002, 33.005); // ~220 m kuzeyde

    bool check(
            {RouteInfo? r,
            LatLng? routeTarget = end,
            LatLng target = end,
            LatLng position = onRoute,
            DateTime? last}) =>
        needsReroute(route: r, routeTarget: routeTarget, target: target, position: position, lastFetch: last, now: now);

    expect(check(r: null), isTrue);
    expect(check(r: route, target: pickup, last: recent), isTrue);
    expect(check(r: route, last: old), isFalse);
    expect(check(r: route, position: offRoute, last: recent), isFalse);
    expect(check(r: route, position: offRoute, last: old), isTrue);
  });
}
