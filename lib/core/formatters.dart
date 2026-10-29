import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/models/fare_estimate.dart';

/// Para, tarih ve mesafeyi uygulamanın o anki diline göre biçimlendirir.
extension Formatters on BuildContext {
  String get _locale => Localizations.localeOf(this).toString();

  /// `1100` -> `₺1.100` (Türkçe) / `₺1,100` (İngilizce).
  String lira(int amount) => '₺${NumberFormat.decimalPattern(_locale).format(amount)}';

  String fareRange(FareEstimate fare) => '${lira(fare.low)} – ${lira(fare.high)}';

  /// `24 Ağu 2026`
  String shortDate(DateTime value) => DateFormat.yMMMd(_locale).format(value);

  /// `Prş, 29 Eki`
  String weekdayDate(DateTime value) => DateFormat.MMMEd(_locale).format(value);

  String time(DateTime value) => DateFormat.Hm(_locale).format(value);

  String dateTime(DateTime value) => '${shortDate(value)} • ${time(value)}';

  /// `12,4 km`; 1 km'nin altında metre.
  String distance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${NumberFormat('0.0', _locale).format(meters / 1000)} km';
  }

  String minutes(int value) => l10n.minutesShort(value);
}
