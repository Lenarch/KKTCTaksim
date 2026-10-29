import 'package:kktc_taksim/models/fare_estimate.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/taxi_type.dart';

/// Yolcunun taksi seçim ekranında onayladığı çağrı.
class RideRequest {
  /// Yolcunun alınacağı yer (çoğunlukla o anki konumu).
  final GeoPlace pickup;
  final GeoPlace destination;
  final RouteInfo route;
  final TaxiType taxiType;
  final PaymentMethod payment;
  final FareEstimate fare;

  /// İleri tarihli rezervasyonsa kalkış zamanı; hemen çağrıysa null.
  final DateTime? scheduledAt;

  const RideRequest({
    required this.pickup,
    required this.destination,
    required this.route,
    required this.taxiType,
    required this.payment,
    required this.fare,
    this.scheduledAt,
  });
}
