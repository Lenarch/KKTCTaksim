import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

const double _earthRadiusMeters = 6371000;

double _radians(double degrees) => degrees * math.pi / 180;

/// Kıbrıs adasını kapsayan kutu (adres araması da bununla sınırlı).
const double cyprusWest = 32.2, cyprusSouth = 34.5, cyprusEast = 34.7, cyprusNorth = 35.8;

/// Konum Kıbrıs dışındaysa (ör. bilgisayardan test) gerçek konum yerine Lefkoşa kullanılır.
bool isInCyprus(LatLng point) =>
    point.longitude >= cyprusWest &&
    point.longitude <= cyprusEast &&
    point.latitude >= cyprusSouth &&
    point.latitude <= cyprusNorth;

/// İki nokta arasındaki kuş uçuşu mesafe (metre).
double distanceMeters(LatLng a, LatLng b) {
  final dLat = _radians(b.latitude - a.latitude);
  final dLng = _radians(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_radians(a.latitude)) * math.cos(_radians(b.latitude)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
}

/// Çizginin toplam uzunluğu (metre).
double pathLength(List<LatLng> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += distanceMeters(path[i - 1], path[i]);
  }
  return total;
}

/// Çizginin başından itibaren uzunluğunun [fraction] kadarındaki nokta (0 = baş, 1 = son).
LatLng pointAlong(List<LatLng> path, double fraction) {
  if (path.length == 1 || fraction <= 0) return path.first;
  if (fraction >= 1) return path.last;

  var remaining = pathLength(path) * fraction;
  for (var i = 1; i < path.length; i++) {
    final a = path[i - 1];
    final b = path[i];
    final segment = distanceMeters(a, b);
    if (remaining <= segment && segment > 0) {
      final t = remaining / segment;
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }
    remaining -= segment;
  }
  return path.last;
}

/// Noktaların hepsini içine alan en küçük dikdörtgen.
LatLngBounds boundsOf(List<LatLng> points) {
  var south = points.first.latitude, north = south;
  var west = points.first.longitude, east = west;
  for (final p in points.skip(1)) {
    south = math.min(south, p.latitude);
    north = math.max(north, p.latitude);
    west = math.min(west, p.longitude);
    east = math.max(east, p.longitude);
  }
  return LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
}
