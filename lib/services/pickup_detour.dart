import 'dart:math' as math;

import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/group_fare.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Buluşma noktasına bu kadar yakın bir yer buluşma noktasının kendisi sayılır (metre).
const double _samePointMeters = 30;

/// Yolcuyu [pickup] noktasından almanın grup güzergâhına kattığı mesafe (metre, 100'e yukarı).
/// Yol, kuş uçuşundan kısa olamaz; rota servisi yanlış kısa dönerse kuş uçuşu esas alınır.
Future<int> pickupDetourMeters(RoutingService routing, LatLng pickup, LatLng meeting) async {
  final straight = distanceMeters(pickup, meeting);
  if (straight < _samePointMeters) return 0;
  final route = await routing.route(pickup, meeting);
  return roundDetour(math.max(route.distanceMeters, straight));
}

/// Grubun kalkış-varış arasındaki temel mesafesi (metre): rota ya da kuş uçuşu, hangisi uzunsa.
/// Kurallar `baseMeters <= kuş uçuşu × 4 + 5000` ister (kuralların mesafe yaklaşığı haversine'den
/// %1'den az sapar); çok dolambaçlı rota dürüst bir oluşturmayı reddettirmesin diye 3,9 ile sınırlanır.
Future<int> groupBaseMeters(RoutingService routing, LatLng from, LatLng to) async {
  final route = await routing.route(from, to);
  final straight = distanceMeters(from, to);
  final base = math.max(route.distanceMeters, straight).round();
  return math.min(base, (straight * 3.9 + 5000).floor());
}
