import 'dart:math' as math;

import 'package:kktc_taksim/models/fare_estimate.dart';
import 'package:kktc_taksim/models/taxi_type.dart';

/// Ekonomik taksi için örnek tarife (TL). Gerçek tarife belli olunca yalnızca
/// buradaki değerler değiştirilir; diğer sınıflar [TaxiType.fareMultiplier] ile hesaplanır.
class Tariff {
  Tariff._();

  static const int openingFare = 100;
  static const int perKm = 40;
  static const int minimumFare = 150;

  /// Tahmini aralığın genişliği: ±%10.
  static const double spread = 0.10;
}

class FareCalculator {
  FareCalculator._();

  static FareEstimate estimate(double distanceKm, TaxiType type) {
    final base = (Tariff.openingFare + Tariff.perKm * distanceKm) * type.fareMultiplier;
    final fare = math.max(base, Tariff.minimumFare * type.fareMultiplier);
    return FareEstimate(
      low: _roundToTen(fare * (1 - Tariff.spread)),
      high: _roundToTen(fare * (1 + Tariff.spread)),
    );
  }

  static int _roundToTen(double value) => (value / 10).round() * 10;
}
