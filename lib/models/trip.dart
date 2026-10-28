enum TripStatus { upcoming, completed, cancelled }

class Trip {
  final String from;
  final String to;
  final String date;
  final int price;
  final TripStatus status;

  const Trip({
    required this.from,
    required this.to,
    required this.date,
    required this.price,
    required this.status,
  });
}
