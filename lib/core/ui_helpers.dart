import 'package:flutter/material.dart';

/// Henüz yapılmamış özellikler için kullanıcıya kısa bir bilgi gösterir.
void showComingSoon(BuildContext context, [String feature = 'Bu özellik']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature yakında eklenecek.')));
}
