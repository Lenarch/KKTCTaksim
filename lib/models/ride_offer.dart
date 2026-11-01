import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Şoförün gördüğü çağrı: bekleyen bir istek ya da üstlendiği yolculuk.
class RideOffer {
  final String id;
  final String passengerId;
  final GeoPlace pickup;
  final GeoPlace destination;
  final double distanceMeters;
  final double durationSeconds;
  final TaxiType taxiType;
  final PaymentMethod payment;
  final int fareLow;
  final int fareHigh;
  final RideStatus status;

  /// Atanan şoför ve son konumu; bekleyen çağrıda null.
  final Driver? driver;
  final LatLng? driverPosition;

  const RideOffer({
    required this.id,
    required this.passengerId,
    required this.pickup,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.taxiType,
    required this.payment,
    required this.fareLow,
    required this.fareHigh,
    required this.status,
    this.driver,
    this.driverPosition,
  });

  int get durationMinutes => (durationSeconds / 60).ceil();

  RideOffer copyWith({RideStatus? status, Driver? driver, LatLng? driverPosition}) => RideOffer(
        id: id,
        passengerId: passengerId,
        pickup: pickup,
        destination: destination,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        taxiType: taxiType,
        payment: payment,
        fareLow: fareLow,
        fareHigh: fareHigh,
        status: status ?? this.status,
        driver: driver ?? this.driver,
        driverPosition: driverPosition ?? this.driverPosition,
      );
}
