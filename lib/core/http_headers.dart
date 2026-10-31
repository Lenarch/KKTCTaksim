import 'package:flutter/foundation.dart';

/// Harici servislere (Photon, OSRM, OpenFreeMap) giden isteklerde uygulamanın kimliği.
/// Photon, Dart'ın varsayılan "Dart/x (dart:io)" kimliğini 403 ile reddediyordu; Android'de adres
/// araması hiç çalışmıyordu. Servislerin kullanım koşulları da tanımlayıcı bir kimlik istiyor.
const String appUserAgent = 'KKTCTaksim/1.0 (+https://kktctaksim-1ea24.web.app)';

/// Web'de tarayıcı bu başlığı kendisi koyar ve değiştirilmesine izin vermez; orada boş.
Map<String, String> get externalServiceHeaders => kIsWeb ? const {} : const {'User-Agent': appUserAgent};
