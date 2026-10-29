class SharedRide {
  final String id;
  final String from;
  final String to;
  final DateTime departure;
  final int capacity;

  /// Gruba katılan kullanıcıların kimlikleri; ilk sıradaki grubu oluşturan kişidir.
  final List<String> memberIds;

  /// Her yolcunun ödediği ücret (TL).
  final int pricePerPerson;

  const SharedRide({
    required this.id,
    required this.from,
    required this.to,
    required this.departure,
    required this.capacity,
    required this.memberIds,
    required this.pricePerPerson,
  });

  int get current => memberIds.length;
  bool get isFull => current >= capacity;
  int get seatsLeft => capacity - current;
  double get fillRatio => current / capacity;

  bool hasMember(String? userId) => userId != null && memberIds.contains(userId);

  SharedRide copyWith({String? id, List<String>? memberIds}) {
    return SharedRide(
      id: id ?? this.id,
      from: from,
      to: to,
      departure: departure,
      capacity: capacity,
      memberIds: memberIds ?? this.memberIds,
      pricePerPerson: pricePerPerson,
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
      };

  factory SharedRide.fromJson(Map<String, dynamic> json) => SharedRide(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        departure: DateTime.fromMillisecondsSinceEpoch(json['departure'] as int),
        capacity: json['capacity'] as int,
        memberIds: (json['memberIds'] as List).cast<String>(),
        pricePerPerson: json['pricePerPerson'] as int,
      );
}
