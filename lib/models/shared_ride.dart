import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/models/geo_place.dart';

/// Grubun yaşam döngüsü; Aşama 1'de yalnızca [open] yazılır.
enum SharedRideStatus { open, claimed, enRoute, inTrip, completed, cancelled }

class SharedRide {
  /// Firestore kurallarındaki sınırlarla aynı (firestore.rules, sharedRides).
  static const int maxPlaceLength = 200;
  static const int maxCapacity = 8;
  static const int maxPricePerPerson = 100000;

  final String id;
  final String from;
  final String to;
  final DateTime departure;
  final int capacity;

  /// Gruba katılan kullanıcıların kimlikleri; ilk sıradaki grubu oluşturan kişidir.
  final List<String> memberIds;

  /// Her yolcunun ödediği ücret (TL). Taslakta henüz hesaplanmadığı için 0 olabilir.
  final int pricePerPerson;

  /// Buluşma ve varış noktaları; eski biçimli (noktasız) gruplarda null.
  final LatLng? fromPoint;
  final LatLng? toPoint;

  /// Buluşma noktasından varışa güzergâhın uzunluğu (metre).
  final int baseMeters;

  /// Üye kimliği -> o üyenin güzergâha eklediği sapma (metre).
  final Map<String, int> detours;

  final SharedRideStatus status;

  const SharedRide({
    required this.id,
    required this.from,
    required this.to,
    required this.departure,
    required this.capacity,
    required this.memberIds,
    this.pricePerPerson = 0,
    this.fromPoint,
    this.toPoint,
    this.baseMeters = 0,
    this.detours = const {},
    this.status = SharedRideStatus.open,
  });

  int get current => memberIds.length;
  bool get isFull => current >= capacity;
  int get seatsLeft => capacity - current;
  double get fillRatio => current / capacity;

  /// Koordinatsız eski biçimli grup; yalnızca ayrılınabilir.
  bool get isLegacy => fromPoint == null;

  /// Üyelerin toplam sapması (metre).
  int get extraMeters => detours.values.fold(0, (sum, d) => sum + d);

  GeoPlace? get meetingPlace => fromPoint == null ? null : GeoPlace(name: from, position: fromPoint!);

  bool get joinable => !isLegacy && status == SharedRideStatus.open && !isFull;

  bool hasMember(String? userId) => userId != null && memberIds.contains(userId);

  SharedRide copyWith({String? id, List<String>? memberIds, Map<String, int>? detours, int? pricePerPerson}) {
    return SharedRide(
      id: id ?? this.id,
      from: from,
      to: to,
      departure: departure,
      capacity: capacity,
      memberIds: memberIds ?? this.memberIds,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      fromPoint: fromPoint,
      toPoint: toPoint,
      baseMeters: baseMeters,
      detours: detours ?? this.detours,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
        'departure': departure.millisecondsSinceEpoch,
        'capacity': capacity,
        'memberIds': memberIds,
        'pricePerPerson': pricePerPerson,
        if (fromPoint != null) 'fromPoint': _pointToJson(fromPoint!),
        if (toPoint != null) 'toPoint': _pointToJson(toPoint!),
        'baseMeters': baseMeters,
        'detours': detours,
        'extraMeters': extraMeters,
        'status': status.name,
      };

  factory SharedRide.fromJson(Map<String, dynamic> json) => SharedRide(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        departure: DateTime.fromMillisecondsSinceEpoch(json['departure'] as int),
        capacity: json['capacity'] as int,
        memberIds: (json['memberIds'] as List).cast<String>(),
        pricePerPerson: json['pricePerPerson'] as int,
        fromPoint: _pointFromJson(json['fromPoint']),
        toPoint: _pointFromJson(json['toPoint']),
        baseMeters: (json['baseMeters'] as num?)?.toInt() ?? 0,
        detours: ((json['detours'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        status: SharedRideStatus.values.asNameMap()[json['status']] ?? SharedRideStatus.open,
      );

  static Map<String, double> _pointToJson(LatLng p) => {'lat': p.latitude, 'lng': p.longitude};

  static LatLng? _pointFromJson(Object? json) {
    if (json is! Map) return null;
    return LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
  }
}
