import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/models/route_info.dart';

/// OSRM ile araç rotası, mesafe ve süre. OSRM'nin herkese açık demo sunucusu
/// kullanılıyor; yayından önce kendi sunucumuza taşınmalı.
class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving/';

  /// Rota alınamadığında: yollar kuş uçuşundan bu kadar uzun ve ortalama hız bu kabul edilir.
  static const double _detourFactor = 1.3;
  static const double _averageSpeedKmh = 45;

  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Servis hata verirse kuş uçuşu tahmini döner; bu yüzden hiçbir zaman hata fırlatmaz.
  Future<RouteInfo> route(LatLng from, LatLng to) async {
    try {
      final coordinates = '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
      final response = await _client
          .get(Uri.parse('$_baseUrl$coordinates?overview=full&geometries=geojson'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final route = parseOsrmRoute(jsonDecode(response.body) as Map<String, dynamic>);
        if (route != null) return route;
      }
    } catch (_) {
      // Aşağıdaki tahmine düşülür.
    }
    return estimateRoute(from, to);
  }

  static RouteInfo estimateRoute(LatLng from, LatLng to) {
    final meters = distanceMeters(from, to) * _detourFactor;
    return RouteInfo(
      points: [from, to],
      distanceMeters: meters,
      durationSeconds: meters / (_averageSpeedKmh * 1000 / 3600),
      isApproximate: true,
    );
  }
}

@visibleForTesting
RouteInfo? parseOsrmRoute(Map<String, dynamic> json) {
  final routes = json['routes'] as List?;
  if (json['code'] != 'Ok' || routes == null || routes.isEmpty) return null;
  final route = routes.first as Map<String, dynamic>;
  final coordinates = (route['geometry']['coordinates'] as List).cast<List>();
  return RouteInfo(
    points: [
      for (final c in coordinates) LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ],
    distanceMeters: (route['distance'] as num).toDouble(),
    durationSeconds: (route['duration'] as num).toDouble(),
  );
}
