import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kktc_taksim/data/firebase/firebase_live_share_repository.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// `rides/{rideId}` belgesinin biçimi (yolcu ve şoför tarafı ortak). Kurallar: firestore.rules.

Map<String, dynamic> placeToJson(GeoPlace place) => {
      'name': place.name,
      ...pointToJson(place.position),
    };

GeoPlace placeFromJson(Map<String, dynamic> json) => GeoPlace(
      name: json['name'] as String,
      position: LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble()),
    );

LatLng? pointFromJson(Object? json) {
  if (json is! Map) return null;
  return LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
}

/// Yolcunun yeni çağrısı.
Map<String, dynamic> rideRequestToDocument(RideRequest request, String passengerId) => {
      'passengerId': passengerId,
      'pickup': placeToJson(request.pickup),
      'destination': placeToJson(request.destination),
      'distanceMeters': request.route.distanceMeters,
      'durationSeconds': request.route.durationSeconds,
      'taxiType': request.taxiType.name,
      'payment': request.payment.name,
      'fareLow': request.fare.low,
      'fareHigh': request.fare.high,
      'status': RideStatus.searching.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

RideOffer rideOfferFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  final driver = data['driver'];
  return RideOffer(
    id: doc.id,
    passengerId: data['passengerId'] as String,
    pickup: placeFromJson((data['pickup'] as Map).cast<String, dynamic>()),
    destination: placeFromJson((data['destination'] as Map).cast<String, dynamic>()),
    distanceMeters: (data['distanceMeters'] as num).toDouble(),
    durationSeconds: (data['durationSeconds'] as num).toDouble(),
    taxiType: TaxiType.values.byName(data['taxiType'] as String),
    payment: PaymentMethod.values.byName(data['payment'] as String),
    fareLow: data['fareLow'] as int,
    fareHigh: data['fareHigh'] as int,
    status: RideStatus.values.byName(data['status'] as String),
    driver: driver is Map ? driverFromSnapshot(driver.cast<String, dynamic>()) : null,
    driverPosition: pointFromJson(data['driverPosition']),
  );
}

/// Oluşturma zamanı [cutoff]'tan eskiyse true. Sunucu zamanı henüz yazılmamışsa (yeni çağrı) false.
bool isRequestExpired(Object? createdAt, DateTime cutoff) =>
    createdAt is Timestamp && createdAt.toDate().isBefore(cutoff);
