/// Grup açılamadığında cihazda ölçülen durum. Testçiler cihaz kaydına bakamadığı için ekranda gösterilir.
class GroupDiagnostics {
  final bool signedIn;

  /// Kullanıcı kimliğinin başı; numara ya da anahtar içermez.
  final String? userIdPrefix;

  /// Oturum yenilenirken ve sunucudan okurken alınan hata kodu; sorun yoksa null.
  final String? tokenError;
  final String? readError;

  /// Sunucunun saati; ölçülemediyse null.
  final DateTime? serverTime;

  /// Ölçüm anındaki telefon saati.
  final DateTime localTime;

  const GroupDiagnostics({
    required this.signedIn,
    required this.localTime,
    this.userIdPrefix,
    this.tokenError,
    this.readError,
    this.serverTime,
  });

  /// Telefon saatinin sunucudan farkı; eksi ise telefon geride.
  Duration? get clockSkew => serverTime == null ? null : localTime.difference(serverTime!);
}

enum GroupFailureSuspect { signedOut, session, readDenied, clock, network, rules, unknown }

const String _permissionDenied = 'permission-denied';

/// En olası neden. Sırası önemli: oturum ya da okuma bozuksa saat sonucu tek başına açıklamaz.
GroupFailureSuspect groupFailureSuspect({
  required String errorCode,
  required GroupDiagnostics diagnostics,
  required DateTime departure,
}) {
  if (!diagnostics.signedIn) return GroupFailureSuspect.signedOut;
  if (errorCode.contains('unavailable') || errorCode.contains('network')) return GroupFailureSuspect.network;

  final tokenError = diagnostics.tokenError;
  if (tokenError != null) {
    return tokenError.contains('network') ? GroupFailureSuspect.network : GroupFailureSuspect.session;
  }
  if (!errorCode.contains(_permissionDenied)) return GroupFailureSuspect.unknown;
  if (diagnostics.readError?.contains(_permissionDenied) ?? false) return GroupFailureSuspect.readDenied;

  // Kural kalkışı sunucu saatiyle karşılaştırır.
  final serverTime = diagnostics.serverTime;
  if (serverTime == null) return GroupFailureSuspect.unknown;
  return departure.isAfter(serverTime) ? GroupFailureSuspect.rules : GroupFailureSuspect.clock;
}

/// Ekran görüntüsünde okunacak teknik özet; geliştirici için olduğundan çevrilmez.
String groupDiagnosticsReport({
  required String errorCode,
  required GroupDiagnostics diagnostics,
  required DateTime departure,
}) {
  final skew = diagnostics.clockSkew;
  final server = diagnostics.serverTime;
  return [
    'error: $errorCode',
    'signedIn: ${diagnostics.signedIn}',
    'uid: ${diagnostics.userIdPrefix ?? '-'}',
    'token: ${diagnostics.tokenError ?? 'ok'}',
    'read: ${diagnostics.readError ?? 'ok'}',
    'clockSkewSec: ${skew?.inSeconds ?? 'unknown'}',
    'departureAheadSec: ${server == null ? 'unknown' : departure.difference(server).inSeconds}',
  ].join('\n');
}
