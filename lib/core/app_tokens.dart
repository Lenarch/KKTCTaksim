/// Spacing scale used for paddings, gaps and margins.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal padding for full-page forms.
  static const double page = 24;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Top corners of modal bottom sheets.
  static const double sheet = 30;
}

/// Animation and delay durations.
class AppDurations {
  AppDurations._();

  static const Duration splashAnimation = Duration(milliseconds: 1500);
  static const Duration splashHold = Duration(seconds: 3);
  static const Duration driverSearch = Duration(seconds: 4);

  /// Demo: sürücünün yolcuya gelişi ve yolculuk, gerçek süreden bağımsız olarak bu sürede oynatılır.
  static const Duration driverApproachDemo = Duration(seconds: 20);
  static const Duration tripDemo = Duration(seconds: 30);
  static const Duration simulationTick = Duration(milliseconds: 250);

  /// Gerçek çağrıda bu süre içinde şoför kabul etmezse çağrı iptal edilir.
  static const Duration driverSearchTimeout = Duration(minutes: 3);

  /// Şoför konumu: yolculuk sırasında ve çevrimiçi beklerken en fazla bu aralıklarla yazılır.
  static const Duration driverRidePositionInterval = Duration(seconds: 5);
  static const Duration driverIdlePositionInterval = Duration(seconds: 30);

  /// Şoför rotadan saparsa rota en fazla bu aralıkla yeniden istenir (OSRM demo sunucusu).
  static const Duration driverRerouteInterval = Duration(seconds: 15);

  /// Canlı konum paylaşımında konum en fazla bu aralıkla yazılır (Firestore yazma kotası).
  static const Duration liveShareInterval = Duration(seconds: 10);

  /// Adres aramasında yazmayı bitirmeyi bekleme süresi.
  static const Duration searchDebounce = Duration(milliseconds: 400);
}
