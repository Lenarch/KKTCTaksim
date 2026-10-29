import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

enum PlaceCategory {
  restaurant(Icons.restaurant),
  cafe(Icons.local_cafe),
  hotel(Icons.hotel),
  entertainment(Icons.celebration),
  shopping(Icons.shopping_bag),
  historic(Icons.account_balance);

  final IconData icon;

  const PlaceCategory(this.icon);
}

class Place {
  final String name;
  final PlaceCategory category;
  final double rating;
  final LatLng position;

  /// Kampanya indirimi yüzdesi; yoksa null.
  final int? discountPercent;

  /// Görsel gelene kadar kartın arka plan rengi.
  final Color imageColor;

  const Place({
    required this.name,
    required this.category,
    required this.rating,
    required this.position,
    required this.imageColor,
    this.discountPercent,
  });
}
