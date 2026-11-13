import 'dart:math' as math;

import 'package:kktc_taksim/core/fare_calculator.dart';

/// Ortak yolculukta bir yolcunun alınması için en fazla kabul edilen sapma (metre).
const int maxPickupDetourMeters = 10000;

/// Bu ve üstü kapasiteli araçlar büyük araç tarifesiyle (×1,8) hesaplanır.
const int largeGroupCapacity = 5;

/// Yolcunun sapma mesafesini 100 metreye yukarı yuvarlar; negatif değerler 0 sayılır.
int roundDetour(double meters) {
  if (meters <= 0) return 0;
  return (meters.ceil() + 99) ~/ 100 * 100;
}

/// Grubun toplam ücreti (TL). Yalnızca tamsayı işlemleri kullanılır; kurallardaki
/// hesapla birebir aynı olmalıdır.
int groupTotalFare({required int baseMeters, required int extraMeters, required int capacity}) {
  final metered = Tariff.openingFare + (Tariff.perKm * (baseMeters + extraMeters)) ~/ 1000;
  final fare = math.max(metered, Tariff.minimumFare);
  return capacity >= largeGroupCapacity ? fare * 18 ~/ 10 : fare;
}

/// Toplam ücretin eşit bölünmüş kişi başı payı; 10 TL'ye yukarı yuvarlanır.
int groupPricePerPerson({
  required int baseMeters,
  required int extraMeters,
  required int capacity,
  required int members,
}) {
  final total = groupTotalFare(baseMeters: baseMeters, extraMeters: extraMeters, capacity: capacity);
  return ((total + members * 10 - 1) ~/ (members * 10)) * 10;
}
