import 'package:kktc_taksim/core/l10n.dart';

/// Form alanları için basit doğrulayıcılar. Hata yoksa null döner.
class Validators {
  Validators._();

  static String? required(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    return null;
  }

  static String? phone(AppLocalizations l10n, String? value) {
    if (value == null || value.trim().isEmpty) return l10n.phoneRequired;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return l10n.phoneInvalid;
    return null;
  }
}
