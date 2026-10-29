import 'package:flutter/material.dart';

enum CarColor {
  white(Color(0xFFF5F5F5)),
  silver(Color(0xFFBDBDBD)),
  black(Color(0xFF212121));

  /// Renk noktası için örnek ton.
  final Color swatch;

  const CarColor(this.swatch);
}

class Driver {
  final String name;
  final double rating;
  final String car;
  final CarColor carColor;
  final String plate;
  final String phone;

  const Driver({
    required this.name,
    required this.rating,
    required this.car,
    required this.carColor,
    required this.plate,
    required this.phone,
  });

  /// Fotoğraf yokken avatarda gösterilen baş harfler, örn. "AY".
  String get initials => name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
}
