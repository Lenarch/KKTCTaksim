import 'package:kktc_taksim/core/l10n.dart';

/// Form alanları için basit doğrulayıcılar. Hata yoksa null döner.
class Validators {
  Validators._();

  static String? required(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    return null;
  }

  /// Ad soyad: boş olamaz, uygulamanın kendisi ya da destek ekibi gibi görünemez.
  static String? name(AppLocalizations l10n, String? value) {
    final missing = required(l10n, value);
    if (missing != null) return missing;
    if (isReservedName(value!)) return l10n.nameReserved;
    return null;
  }

  static String? phone(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.phoneRequired;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return l10n.phoneInvalid;
    return null;
  }
}

/// Grup sohbetinde ad görünür; "KKTC Taksim Destek" gibi adlar dolandırıcılığa açık.
/// `firestore.rules`'taki `isReservedName` ile aynı liste: ikisi birlikte değişmeli.
final RegExp _reservedName = RegExp(r'(kktc ?taksim|destek|support|admin|y[öo]net|moderat)');

bool isReservedName(String name) => _reservedName.hasMatch(name.toLowerCase());
