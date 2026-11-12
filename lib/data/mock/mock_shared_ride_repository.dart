import 'dart:async';

import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/mock/watch_value.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/group_diagnostics.dart';
import 'package:kktc_taksim/models/pickup.dart';
import 'package:kktc_taksim/models/shared_ride.dart';

class MockSharedRideRepository implements SharedRideRepository {
  final AuthRepository _auth;
  final List<SharedRide> _rides = MockData.sharedRides();
  final Map<String, List<ChatMessage>> _messages = {};

  /// Grup kimliği -> kullanıcı kimliği -> toplama noktası.
  final Map<String, Map<String, Pickup>> _pickups = {};
  final Set<String> _blocked = {};

  /// Testler için: gönderilen şikâyetler (grup, mesaj, neden).
  final List<(String, ChatMessage, ReportReason)> reports = [];
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
  Future<void> create(SharedRide draft, Pickup pickup) async {
    final userId = _userId;
    final id = 'group-${_nextId++}';
    _rides.add(newGroup(draft, userId, pickup.detourMeters).copyWith(id: id));
    _pickups[id] = {userId: pickup};
    _changes.add(null);
  }

  @override
  Future<GroupDiagnostics> diagnose() async {
    final now = DateTime.now();
    return GroupDiagnostics(signedIn: _auth.currentUser != null, localTime: now, serverTime: now);
  }

  @override
  Future<void> join(String rideId, Pickup pickup) async {
    final userId = _userId;
    final index = _indexOf(rideId);
    final ride = _rides[index];
    final joined = rideAfterJoin(ride, userId, pickup.detourMeters);
    if (identical(joined, ride)) return;
    _rides[index] = joined;
    (_pickups[rideId] ??= {})[userId] = pickup;
    _changes.add(null);
  }

  @override
  Future<void> changePickup(String rideId, Pickup pickup) async {
    final userId = _userId;
    final index = _indexOf(rideId);
    _rides[index] = rideAfterRepick(_rides[index], userId, pickup.detourMeters);
    (_pickups[rideId] ??= {})[userId] = pickup;
    _changes.add(null);
  }

  @override
  Future<Pickup?> myPickup(String rideId) async {
    final userId = _auth.currentUser?.id;
    return userId == null ? null : _pickups[rideId]?[userId];
  }

  @override
  Future<void> leave(String rideId) async {
    final index = _indexOf(rideId);
    final ride = _rides[index];
    final left = rideAfterLeave(ride, _userId);
    if (left == null) {
      _rides.removeAt(index);
      _messages.remove(rideId);
      _pickups.remove(rideId);
    } else {
      _rides[index] = left;
      _pickups[rideId]?.remove(_userId);
    }
    _changes.add(null);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String rideId) {
    final userId = _auth.currentUser?.id;
    if (!_rides[_indexOf(rideId)].hasMember(userId)) {
      return Stream.error(const SharedRideException(SharedRideError.notMember));
    }
    return watchValue(_changes.stream, () {
      final messages = _messages[rideId] ?? const [];
      return messages.skip(messages.length > chatHistoryLimit ? messages.length - chatHistoryLimit : 0).toList();
    });
  }

  @override
  Stream<ChatMessage?> watchLatestMessage(String rideId) =>
      watchMessages(rideId).map((messages) => messages.isEmpty ? null : messages.last);

  @override
  Future<void> sendMessage(String rideId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan mesaj gönderilemez');
    if (!_rides[_indexOf(rideId)].hasMember(user.id)) {
      throw const SharedRideException(SharedRideError.notMember);
    }
    final normalized = normalizeMessage(text);
    if (normalized == null) return;
    (_messages[rideId] ??= []).add(ChatMessage(
      id: 'message-${_nextId++}',
      senderId: user.id,
      senderName: user.name,
      text: normalized,
      sentAt: DateTime.now(),
    ));
    _changes.add(null);
  }

  @override
  Future<void> removeMe() async {
    final userId = _userId;
    for (final messages in _messages.values) {
      messages.removeWhere((m) => m.senderId == userId);
    }
    for (final ride in _rides.where((r) => r.hasMember(userId)).toList()) {
      await leave(ride.id);
    }
    _blocked.clear();
    _changes.add(null);
  }

  @override
  Future<void> report(String rideId, ChatMessage message, ReportReason reason) async {
    _userId;
    reports.add((rideId, message, reason));
  }

  @override
  Future<void> block(String userId) async {
    if (userId == _userId) return;
    _blocked.add(userId);
    _changes.add(null);
  }

  @override
  Future<void> unblock(String userId) async {
    _blocked.remove(userId);
    _changes.add(null);
  }

  @override
  Stream<Set<String>> watchBlocked() => watchValue(_changes.stream, () => Set.of(_blocked));

  int _indexOf(String rideId) {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) throw const SharedRideException(SharedRideError.notFound);
    return index;
  }
}
