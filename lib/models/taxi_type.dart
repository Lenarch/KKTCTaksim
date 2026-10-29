import 'package:flutter/material.dart';

/// Taksi sınıfları. Fiyat, [fareMultiplier] ile ekonomik tarifeden hesaplanır.
enum TaxiType {
  economy(icon: Icons.directions_car, fareMultiplier: 1.0, pickupMinutes: 3),
  comfort(icon: Icons.local_taxi, fareMultiplier: 1.3, pickupMinutes: 5),
  xl(icon: Icons.airport_shuttle, fareMultiplier: 1.8, pickupMinutes: 8);

  final IconData icon;
  final double fareMultiplier;

  /// Taksinin yolcuya ortalama ulaşma süresi (demo).
  final int pickupMinutes;

  const TaxiType({required this.icon, required this.fareMultiplier, required this.pickupMinutes});
}
