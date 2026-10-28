class SharedRide {
  final String from;
  final String to;
  final String date;
  final String time;
  final int capacity;
  final int current;
  final int price;
  final bool joined;

  const SharedRide({
    required this.from,
    required this.to,
    required this.date,
    required this.time,
    required this.capacity,
    required this.current,
    required this.price,
    this.joined = false,
  });

  bool get isFull => current >= capacity;
  int get seatsLeft => capacity - current;
  double get fillRatio => current / capacity;

  SharedRide copyWith({int? current, bool? joined}) {
    return SharedRide(
      from: from,
      to: to,
      date: date,
      time: time,
      capacity: capacity,
      current: current ?? this.current,
      price: price,
      joined: joined ?? this.joined,
    );
  }
}
