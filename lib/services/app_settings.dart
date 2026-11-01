import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın hangi yüzüyle açılacağı (rol seçimi ekranında seçilir).
enum AppRole { passenger, driver }

/// Kullanıcının cihazda saklanan tercihleri.
class AppSettings {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _localeKey = 'locale';
  static const String _roleKey = 'role';

  /// Yolcu mu şoför mü; açılışta ve girişten sonra hangi ekrana gidileceğini belirler.
  final ValueNotifier<AppRole> role = ValueNotifier(AppRole.passenger);

  /// Seçilen uygulama dili; null ise telefonun dili kullanılır.
  final ValueNotifier<Locale?> locale = ValueNotifier(null);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      locale.value = code == null ? null : Locale(code);
      role.value = prefs.getString(_roleKey) == AppRole.driver.name ? AppRole.driver : AppRole.passenger;
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

  Future<void> setRole(AppRole value) async {
    role.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, value.name);
    } catch (_) {
      // Kaydedilemese de seçim bu oturum boyunca geçerli kalır.
    }
  }

  /// Girişten sonra ve açılışta gidilecek ekran.
  String get homeRoute => role.value == AppRole.driver ? '/driver' : '/main';
}
