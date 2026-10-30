import 'dart:async';

import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/mock/watch_value.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

class MockSharedRideRepository implements SharedRideRepository {
  final AuthRepository _auth;
  final List<SharedRide> _rides = MockData.sharedRides();
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 0;

  MockSharedRideRepository(this._auth);

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan paylaşımlı yolculuk değiştirilemez');
    return user.id;
  }

  List<SharedRide> get _active {
    final now = DateTime.now();
    return _rides.where((r) => r.departure.isAfter(now)).toList()
      ..sort((a, b) => a.departure.compareTo(b.departure));
  }

  @override
  Stream<List<SharedRide>> watchActive() => watchValue(_changes.stream, () => _active);

  @override
  Future<void> create(SharedRide ride) async {
    _rides.add(ride.copyWith(id: 'group-${_nextId++}', memberIds: [_userId]));
    _changes.add(null);
  }

  @override
  Future<void> join(String rideId) async {
    final index = _indexOf(rideId);
    final ride = _rides[index];
    final members = membersAfterJoin(ride, _userId);
    if (identical(members, ride.memberIds)) return;
    _rides[index] = ride.copyWith(memberIds: members);
    _changes.add(null);
  }

  @override
  Future<void> leave(String rideId) async {
    final index = _indexOf(rideId);
    final ride = _rides[index];
    final members = membersAfterLeave(ride, _userId);
    if (members.isEmpty) {
      _rides.removeAt(index);
    } else {
      _rides[index] = ride.copyWith(memberIds: members);
    }
    _changes.add(null);
  }

  int _indexOf(String rideId) {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) throw const SharedRideException(SharedRideError.notFound);
    return index;
  }
}
