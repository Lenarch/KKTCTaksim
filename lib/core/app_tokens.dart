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
}
