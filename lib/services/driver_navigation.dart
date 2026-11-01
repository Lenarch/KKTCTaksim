import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Şoför bu kadar metre rotadan uzaklaşırsa rota yeniden istenir.
const double rerouteDistanceMeters = 60;

/// Şoförün o an gitmesi gereken yer: yolcuyu alana kadar alış noktası, sonra varış.
LatLng? navigationTarget(RideOffer ride) => switch (ride.status) {
      RideStatus.driverAssigned || RideStatus.driverArrived => ride.pickup.position,
      RideStatus.inProgress => ride.destination.position,
      _ => null,
    };

/// Şoförün konumuna göre rotanın kalan mesafesi ve süresi.
({double meters, double seconds}) remainingAlong(RouteInfo route, LatLng position) {
  final left = 1 - fractionAlong(route.points, position);
  return (meters: route.distanceMeters * left, seconds: route.durationSeconds * left);
}

/// Rota hiç yoksa ya da hedef değiştiyse hemen; şoför rotadan saptıysa en fazla
/// [AppDurations.driverRerouteInterval]'da bir yeni rota istenir.
bool needsReroute({
  required RouteInfo? route,
  required LatLng? routeTarget,
  required LatLng target,
  required LatLng position,
  required DateTime? lastFetch,
  required DateTime now,
}) {
  if (route == null || routeTarget != target) return true;
  if (lastFetch != null && now.difference(lastFetch) < AppDurations.driverRerouteInterval) return false;
  return distanceToPath(route.points, position) > rerouteDistanceMeters;
}
