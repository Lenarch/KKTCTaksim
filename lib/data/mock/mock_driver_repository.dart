import 'dart:async';

import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/data/mock/watch_value.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Şoför tarafı yalnızca bellekte (testler ve demo). Bekleyen çağrılar [addRequest] ile eklenir.
class MockDriverRepository implements DriverRepository {
  final AuthRepository _auth;
  final StreamController<void> _changes = StreamController.broadcast();
  final Map<String, DriverProfile> _profiles = {};
  final List<RideOffer> _rides = [];
  LatLng? lastPosition;

  MockDriverRepository(this._auth);

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Giriş yapılmadan şoför işlemi yapılamaz');
    return user.id;
  }

  /// Testler için: yolcunun yeni çağrısı.
  void addRequest(RideOffer offer) {
    _rides.add(offer);
    _changes.add(null);
  }

  RideOffer? rideById(String id) => _rides.where((r) => r.id == id).firstOrNull;

  @override
  Stream<DriverProfile?> watchProfile() => watchValue(_changes.stream, () {
        final user = _auth.currentUser;
        return user == null ? null : _profiles[user.id];
      });

  @override
  Future<void> register(DriverProfile profile) async {
    final current = _profiles[_userId];
    _profiles[_userId] = DriverProfile(
      name: profile.name.trim(),
      plate: profile.plate.trim().toUpperCase(),
      car: profile.car.trim(),
      carColor: profile.carColor,
      online: current?.online ?? false,
    );
    _changes.add(null);
  }

  @override
  Future<void> setOnline(bool online, LatLng? position) async {
    if (online && position == null) throw const DriverException(DriverError.noLocation);
    final profile = _profiles[_userId];
    if (profile == null) throw const DriverException(DriverError.notRegistered);
    _profiles[_userId] = DriverProfile(
      name: profile.name,
      plate: profile.plate,
      car: profile.car,
      carColor: profile.carColor,
      online: online,
    );
    lastPosition = position ?? lastPosition;
    _changes.add(null);
  }

  @override
  Future<void> updatePosition(LatLng position) async => lastPosition = position;

  @override
  Stream<List<RideOffer>> watchOpenRequests(LatLng? near) => watchValue(_changes.stream, () {
        final offers = _rides.where((r) => r.status == RideStatus.searching).toList();
        if (near != null) {
          offers.sort((a, b) =>
              distanceMeters(near, a.pickup.position).compareTo(distanceMeters(near, b.pickup.position)));
        }
        return offers;
      });

  @override
  Stream<RideOffer?> watchActiveRide() => watchValue(_changes.stream, () {
        final user = _auth.currentUser;
        if (user == null) return null;
        return _rides.where((r) => r.driver != null && _assignedTo[r.id] == user.id && r.status.hasDriver).firstOrNull;
      });

  final Map<String, String> _assignedTo = {};

  @override
  Future<void> accept(RideOffer offer, LatLng position) async {
    final profile = _profiles[_userId];
    if (profile == null) throw const DriverException(DriverError.notRegistered);
    final index = _rides.indexWhere((r) => r.id == offer.id);
    if (index == -1 || _rides[index].status != RideStatus.searching) {
      throw const DriverException(DriverError.rideTaken);
    }
    _assignedTo[offer.id] = _userId;
    _rides[index] = _rides[index].copyWith(
      status: RideStatus.driverAssigned,
      driver: driverFromSnapshot(driverSnapshot(profile, _auth.currentUser?.phone ?? '')),
      driverPosition: position,
    );
    _changes.add(null);
  }

  @override
  Future<void> updateRidePosition(String rideId, LatLng position) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;
    _rides[index] = _rides[index].copyWith(driverPosition: position);
    _changes.add(null);
  }

  @override
  Future<void> advance(String rideId, RideStatus next, LatLng? position) async {
    final index = _rides.indexWhere((r) => r.id == rideId);
    if (index == -1) return;
    _rides[index] = _rides[index].copyWith(status: next, driverPosition: position);
    _changes.add(null);
  }

  @override
  Future<void> cancelRide(String rideId) => advance(rideId, RideStatus.cancelled, null);
}
