import 'package:flutter/material.dart';

class TaxiOption {
  final String name;
  final String eta;
  final int price;
  final IconData icon;

  const TaxiOption({
    required this.name,
    required this.eta,
    required this.price,
    required this.icon,
  });
}
