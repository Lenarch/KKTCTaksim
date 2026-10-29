import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/place.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/models/trip.dart';

/// Örnek veriler. Yalnızca `lib/data/mock/` altındaki repository'ler ve harita yerleşimi kullanır;
/// ekranlar veriye `Backend.instance` üzerinden erişir.
class MockData {
  MockData._();

  /// Konum alınamazsa haritanın açılacağı yer (Lefkoşa merkez).
  static const LatLng fallbackLocation = LatLng(35.1856, 33.3823);

  /// Demo taksiler kullanıcının o anki konumuna göre bu kaymalarla (enlem, boylam) yerleştirilir.
  static const List<(double, double)> nearbyTaxiOffsets = [
    (0.0044, 0.0027),
    (-0.0056, -0.0073),
  ];
  static const (double, double) assignedTaxiOffset = (0.0074, 0.0087);

  static LatLng offsetFrom(LatLng origin, (double, double) offset) =>
      LatLng(origin.latitude + offset.$1, origin.longitude + offset.$2);

  static const List<GeoPlace> recentDestinations = [
    GeoPlace(
      name: 'Ercan Havalimanı',
      address: 'Lefkoşa',
      position: LatLng(35.1518, 33.5035),
    ),
    GeoPlace(
      name: 'Girne Yat Limanı',
      address: 'Girne',
      position: LatLng(35.3412, 33.3196),
    ),
    GeoPlace(
      name: 'Gazimağusa Surlariçi',
      address: 'Gazimağusa',
      position: LatLng(35.1247, 33.9408),
    ),
  ];

  static const Driver driver = Driver(
    name: 'Ahmet Yılmaz',
    rating: 4.9,
    car: 'Toyota Corolla',
    carColor: CarColor.white,
    plate: 'TAB 123',
    phone: '+905331112233',
  );

  static final List<Trip> trips = [
    Trip(
      id: 'demo-1',
      from: 'Lefkoşa Merkez',
      to: 'Ercan Havalimanı',
      dateTime: DateTime(2026, 8, 24, 9, 15),
      price: 1060,
      status: TripStatus.completed,
      taxiType: TaxiType.economy,
      payment: PaymentMethod.cash,
    ),
    Trip(
      id: 'demo-2',
      from: 'Girne Yat Limanı',
      to: 'Lefkoşa Surlariçi',
      dateTime: DateTime(2026, 8, 20, 18, 40),
      price: 1420,
      status: TripStatus.completed,
      taxiType: TaxiType.comfort,
      payment: PaymentMethod.card,
    ),
    Trip(
      id: 'demo-3',
      from: 'Gönyeli',
      to: 'Gazimağusa',
      dateTime: DateTime(2026, 8, 15, 13, 5),
      price: 0,
      status: TripStatus.cancelled,
      taxiType: TaxiType.economy,
    ),
  ];

  /// Tarihleri hep ileride kalsın diye bugüne göre üretilir.
  static List<SharedRide> sharedRides() {
    final today = DateUtils.dateOnly(DateTime.now());
    return [
      SharedRide(
        id: 'demo-group-1',
        from: 'Lefkoşa',
        to: 'Ercan Havalimanı',
        departure: today.add(const Duration(days: 1, hours: 14, minutes: 30)),
        capacity: 8,
        memberIds: const ['demo-a', 'demo-b', 'demo-c'],
        pricePerPerson: 250,
      ),
      SharedRide(
        id: 'demo-group-2',
        from: 'Girne',
        to: 'Lefkoşa',
        departure: today.add(const Duration(days: 2, hours: 10)),
        capacity: 8,
        memberIds: const ['demo-a', 'demo-b', 'demo-c', 'demo-d', 'demo-e'],
        pricePerPerson: 200,
      ),
    ];
  }

  // Konumlar yaklaşık; görseller gelene kadar kartlar renkli arka planla gösterilir.
  static const List<Place> places = [
    Place(
      name: 'Girne Kalesi',
      category: PlaceCategory.historic,
      rating: 4.8,
      position: LatLng(35.3412, 33.3222),
      imageColor: Color(0xFFBBDEFB),
    ),
    Place(
      name: 'Bellapais Manastırı',
      category: PlaceCategory.historic,
      rating: 4.9,
      position: LatLng(35.3069, 33.3547),
      imageColor: Color(0xFFFFE0B2),
    ),
    Place(
      name: 'Salamis Antik Kenti',
      category: PlaceCategory.historic,
      rating: 4.7,
      position: LatLng(35.1846, 33.9008),
      imageColor: Color(0xFFD7CCC8),
    ),
    Place(
      name: 'Büyük Han',
      category: PlaceCategory.cafe,
      rating: 4.7,
      position: LatLng(35.1774, 33.3629),
      imageColor: Color(0xFFFFF9C4),
    ),
    Place(
      name: 'Girne Limanı Kafeleri',
      category: PlaceCategory.cafe,
      rating: 4.5,
      position: LatLng(35.3407, 33.3188),
      imageColor: Color(0xFFB2EBF2),
      discountPercent: 10,
    ),
    Place(
      name: 'Nezih Restoran',
      category: PlaceCategory.restaurant,
      rating: 4.5,
      position: LatLng(35.1923, 33.3601),
      imageColor: Color(0xFFC8E6C9),
      discountPercent: 15,
    ),
    Place(
      name: 'Elexus Resort',
      category: PlaceCategory.hotel,
      rating: 4.7,
      position: LatLng(35.3583, 33.1560),
      imageColor: Color(0xFFE1BEE7),
    ),
    Place(
      name: 'Dereboyu Caddesi',
      category: PlaceCategory.entertainment,
      rating: 4.4,
      position: LatLng(35.1930, 33.3575),
      imageColor: Color(0xFFF8BBD0),
    ),
    Place(
      name: 'Alagadi Kaplumbağa Plajı',
      category: PlaceCategory.entertainment,
      rating: 4.8,
      position: LatLng(35.3318, 33.4870),
      imageColor: Color(0xFFB3E5FC),
    ),
    Place(
      name: 'Arasta Çarşısı',
      category: PlaceCategory.shopping,
      rating: 4.3,
      position: LatLng(35.1762, 33.3640),
      imageColor: Color(0xFFFFCCBC),
    ),
  ];
}
