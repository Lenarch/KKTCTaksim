import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kktc_taksim/core/app_tokens.dart';

/// Telefon saatini sunucuya göre düzeltir: telefon saati yanlışsa Firestore kuralları geçerli bir kalkışı
/// reddediyordu. Fark mutlak zamanda ölçülür; telefonun hangi saat diliminde olduğu önemli değildir.
class TrustedClock {
  TrustedClock._();

  static final TrustedClock instance = TrustedClock._();

  Duration _offset = Duration.zero;

  /// Testler sunucu saatini buradan verir.
  @visibleForTesting
  Future<DateTime?> Function() serverTimeSource = fetchServerTime;

  /// Düzeltilmiş şimdiki zaman. Hiç ölçülemediyse telefon saatidir.
  DateTime get now => DateTime.now().add(_offset);

  /// Farkı yeniden ölçer; hata fırlatmaz, ölçülemezse son bilinen fark kalır.
  Future<void> sync() async {
    final serverTime = await serverTimeSource();
    if (serverTime != null) _offset = serverTime.difference(DateTime.now());
  }

  @visibleForTesting
  void reset() {
    _offset = Duration.zero;
    serverTimeSource = fetchServerTime;
  }
}

/// Firestore sunucu saatini vermiyor; aynı alan adının yanıt başlığından okunur (saniye hassasiyetinde).
Future<DateTime?> fetchServerTime({http.Client? client}) async {
  final uri = Uri.parse('https://firestore.googleapis.com/');
  try {
    final response = await (client?.head(uri) ?? http.head(uri)).timeout(AppDurations.clockCheckTimeout);
    return parseHttpDate(response.headers['date']);
  } catch (e) {
    debugPrint('Sunucu saati ölçülemedi: $e');
    return null;
  }
}

/// HTTP `Date` başlığı ("Thu, 05 Nov 2026 13:02:24 GMT"); okunamazsa null.
@visibleForTesting
DateTime? parseHttpDate(String? value) {
  if (value == null) return null;
  try {
    return DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(value.replaceAll(' GMT', ''));
  } on FormatException {
    return null;
  }
}
