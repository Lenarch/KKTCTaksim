import 'package:flutter/material.dart';

class Place {
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final String badge;
  final Color imageColor;

  const Place({
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.badge,
    required this.imageColor,
  });
}
