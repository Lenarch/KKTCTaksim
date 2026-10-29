import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının cihazda saklanan tercihleri.
class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _localeKey = 'locale';

  /// Seçilen uygulama dili; null ise telefonun dili kullanılır.
  final ValueNotifier<Locale?> locale = ValueNotifier(null);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      locale.value = code == null ? null : Locale(code);
    } catch (_) {
      // Tercihler okunamazsa telefonun dili kullanılır.
    }
  }

  Future<void> setLocale(Locale? value) async {
    locale.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, value.languageCode);
      }
    } catch (_) {
      // Kaydedilemese de seçim bu oturum boyunca geçerli kalır.
    }
  }
}
