import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/taxi_type.dart';

enum TripStatus { upcoming, completed, cancelled }

class Trip {
  final String id;
  final String from;
  final String to;
  final DateTime dateTime;
  final int price;
  final TripStatus status;
  final TaxiType? taxiType;
  final PaymentMethod? payment;

  const Trip({
    required this.id,
    required this.from,
    required this.to,
    required this.dateTime,
    required this.price,
    required this.status,
    this.taxiType,
    this.payment,
  });

  Trip copyWith({TripStatus? status, int? price}) {
    return Trip(
      id: id,
      from: from,
      to: to,
      dateTime: dateTime,
      price: price ?? this.price,
      status: status ?? this.status,
      taxiType: taxiType,
      payment: payment,
    );
  }

  /// Veritabanına yazılan biçim. Enum'lar adlarıyla, tarih milisaniye olarak saklanır.
  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'dateTime': dateTime.millisecondsSinceEpoch,
        'price': price,
        'status': status.name,
        'taxiType': taxiType?.name,
        'payment': payment?.name,
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime'] as int),
        price: json['price'] as int,
        status: TripStatus.values.byName(json['status'] as String),
        taxiType: json['taxiType'] == null ? null : TaxiType.values.byName(json['taxiType'] as String),
        payment: json['payment'] == null ? null : PaymentMethod.values.byName(json['payment'] as String),
      );
}
