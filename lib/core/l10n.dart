import 'package:flutter/widgets.dart';
import 'package:kktc_taksim/l10n/app_localizations.dart';

export 'package:kktc_taksim/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Uygulama metinleri; `lib/l10n/app_*.arb` dosyalarından üretilir.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
