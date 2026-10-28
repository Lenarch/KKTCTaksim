import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/place.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/models/taxi_option.dart';
import 'package:kktc_taksim/models/trip.dart';

/// Demo data used until a real backend is connected.
class MockData {
  MockData._();

  static const String userName = 'Tacettin';
  static const String userPhone = '+90 533 123 45 67';

  /// Konum alınamazsa haritanın açılacağı yer (Lefkoşa merkez).
  static const LatLng fallbackLocation = LatLng(35.1856, 33.3823);

  /// Demo taksiler kullanıcının o anki konumuna göre bu kaymalarla (enlem, boylam) yerleştirilir.
  static const List<(double, double)> nearbyTaxiOffsets = [
    (0.0044, 0.0027),
    (-0.0056, -0.0073),
  ];
  static const (double, double) assignedTaxiOffset = (0.0024, 0.0037);

  static LatLng offsetFrom(LatLng origin, (double, double) offset) =>
      LatLng(origin.latitude + offset.$1, origin.longitude + offset.$2);

  static const List<String> recentDestinations = [
    'Ercan Havalimanı',
    'Girne Yat Limanı',
    'Gazimağusa Surlariçi',
  ];

  static const List<TaxiOption> taxiOptions = [
    TaxiOption(name: 'Ekonomik', eta: '3 dk', price: 120, icon: Icons.directions_car),
    TaxiOption(name: 'Konfor', eta: '5 dk', price: 160, icon: Icons.local_taxi),
    TaxiOption(name: 'XL', eta: '8 dk', price: 220, icon: Icons.airport_shuttle),
  ];

  static const Driver driver = Driver(
    name: 'Ahmet Yılmaz',
    rating: 4.9,
    car: 'Toyota Corolla',
    plate: 'TAB 123',
    eta: '3 dk',
    phone: '+905331112233',
  );

  static const List<Trip> trips = [
    Trip(
      from: 'Lefkoşa Merkez',
      to: 'Ercan Havalimanı',
      date: '24 Ağustos 2026',
      price: 420,
      status: TripStatus.completed,
    ),
    Trip(
      from: 'Girne Yat Limanı',
      to: 'Lefkoşa Surlariçi',
      date: '20 Ağustos 2026',
      price: 350,
      status: TripStatus.completed,
    ),
    Trip(
      from: 'Gönyeli',
      to: 'Gazimağusa',
      date: '15 Ağustos 2026',
      price: 0,
      status: TripStatus.cancelled,
    ),
  ];

  static const List<SharedRide> sharedRides = [
    SharedRide(
      from: 'Lefkoşa',
      to: 'Ercan Havalimanı',
      date: '24.08.2026',
      time: '14:30',
      capacity: 8,
      current: 3,
      price: 90,
    ),
    SharedRide(
      from: 'Girne',
      to: 'Lefkoşa',
      date: '25.08.2026',
      time: '10:00',
      capacity: 8,
      current: 5,
      price: 75,
    ),
  ];

  static const String allCategories = 'Hepsi';
  static const List<String> placeCategories = [
    allCategories,
    'Restoran',
    'Kafe',
    'Otel',
    'Eğlence',
    'Alışveriş',
    'Tarihi Yerler',
  ];

  static const List<Place> places = [
    Place(
      name: 'Girne Yat Limanı',
      category: 'Tarihi Yerler',
      rating: 4.8,
      distanceKm: 2.3,
      badge: '%10 İndirim',
      imageColor: Color(0xFFBBDEFB),
    ),
    Place(
      name: 'Bellapais Manastırı',
      category: 'Tarihi Yerler',
      rating: 4.9,
      distanceKm: 5.1,
      badge: 'Ücretsiz Giriş',
      imageColor: Color(0xFFFFE0B2),
    ),
    Place(
      name: 'Nezih Restoran',
      category: 'Restoran',
      rating: 4.5,
      distanceKm: 0.8,
      badge: '%15 İndirim',
      imageColor: Color(0xFFC8E6C9),
    ),
    Place(
      name: 'Elexus Resort',
      category: 'Otel',
      rating: 4.7,
      distanceKm: 12.0,
      badge: 'Özel Kampanya',
      imageColor: Color(0xFFE1BEE7),
    ),
  ];
}
