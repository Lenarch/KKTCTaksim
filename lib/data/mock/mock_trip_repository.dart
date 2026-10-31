import 'dart:async';

import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/mock/watch_value.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';
import 'package:kktc_taksim/models/trip.dart';

/// Yolculuklar yalnızca bellekte; uygulama kapanınca örnek verilere döner.
class MockTripRepository implements TripRepository {
  final List<Trip> _trips = List.of(MockData.trips);
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 0;

  @override
  String newId() => 'trip-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  List<Trip> _withStatus(TripStatus status) {
    final trips = _trips.where((t) => t.status == status).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return status == TripStatus.upcoming ? trips : trips.reversed.toList();
  }

  @override
  Stream<List<Trip>> watch(TripStatus status) => watchValue(_changes.stream, () => _withStatus(status));

  @override
  Future<void> add(Trip trip) async {
    _trips.add(trip);
    _changes.add(null);
  }

  @override
  Future<void> cancel(String id) async {
    final index = _trips.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _trips[index] = _trips[index].copyWith(status: TripStatus.cancelled, price: 0);
    _changes.add(null);
  }

  @override
  Future<void> deleteAll() async {
    _trips.clear();
    _changes.add(null);
  }
}
