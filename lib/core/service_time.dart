import 'package:kktc_taksim/services/trusted_clock.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Kıbrıs duvar saati taşıyan zaman: `hour`, `day` gibi alanları Kıbrıs'taki değerdir.
typedef ServiceDateTime = tz.TZDateTime;

/// Kalkışlar şimdilik yalnızca KKTC'de; grup saati telefonun değil, kalkış yerinin saatidir.
/// KKTC kışın UTC+2, yazın UTC+3. Başka ülkede hizmet açılınca saat dilimi grupla saklanmalı.
final tz.Location _serviceLocation = () {
  tz_data.initializeTimeZones();
  return tz.getLocation('Asia/Nicosia');
}();

ServiceDateTime toServiceTime(DateTime instant) => tz.TZDateTime.from(instant, _serviceLocation);

/// Sunucuya göre düzeltilmiş şu an, Kıbrıs saatiyle.
ServiceDateTime serviceNow() => toServiceTime(TrustedClock.instance.now);

/// Kıbrıs saatiyle verilen tarih ve saat.
ServiceDateTime serviceDateTime(int year, int month, int day, [int hour = 0, int minute = 0]) =>
    tz.TZDateTime(_serviceLocation, year, month, day, hour, minute);
