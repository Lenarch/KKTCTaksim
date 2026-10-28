/// Form alanları için basit doğrulayıcılar. Hata yoksa null döner.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName boş bırakılamaz';
    return null;
  }

  static String? email(String? value) {
    final error = required(value, 'E-posta');
    if (error != null) return error;
    if (!_emailPattern.hasMatch(value!.trim())) return 'Geçerli bir e-posta girin';
    return null;
  }

  static String? password(String? value) {
    final error = required(value, 'Şifre');
    if (error != null) return error;
    if (value!.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  static String? phone(String? value) {
    final error = required(value, 'Telefon numarası');
    if (error != null) return error;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Geçerli bir telefon numarası girin';
    return null;
  }
}
