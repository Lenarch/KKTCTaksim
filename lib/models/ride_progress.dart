import 'package:maplibre_gl/maplibre_gl.dart';

/// Taksinin rota üzerindeki o anki durumu (yolcuya gelirken veya yolculukta).
class RideProgress {
  final LatLng position;

  /// 0 = rotanın başı, 1 = varıldı.
  final double fraction;
  final int minutesLeft;

  const RideProgress({required this.position, required this.fraction, required this.minutesLeft});

  bool get arrived => fraction >= 1;
}
