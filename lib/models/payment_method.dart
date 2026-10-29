import 'package:flutter/material.dart';

enum PaymentMethod {
  cash(Icons.payments_outlined),
  card(Icons.credit_card);

  final IconData icon;

  const PaymentMethod(this.icon);
}
