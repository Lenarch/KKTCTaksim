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
Future<int> groupBaseMeters(RoutingService routing, LatLng from, LatLng to) async {
  final route = await routing.route(from, to);
  return math.max(route.distanceMeters, distanceMeters(from, to)).round();
}
