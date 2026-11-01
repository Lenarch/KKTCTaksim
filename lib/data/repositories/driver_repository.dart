import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Şoförün kendi bilgisi. Telefon, giriş yapılan numaradır (kurallar bunu denetler).
class DriverProfile {
  final String name;
  final String plate;
  final String car;
  final CarColor carColor;
  final bool online;

  /// Yönetici onayı (Firebase konsolundan verilir); onaysız şoför çevrimiçi olamaz.
  final bool approved;

  const DriverProfile({
    required this.name,
    required this.plate,
    required this.car,
    required this.carColor,
    this.online = false,
    this.approved = false,
  });
}

enum DriverError { notRegistered, notApproved, rideTaken, noLocation }

class DriverException implements Exception {
  final DriverError error;

  const DriverException(this.error);

  @override
  String toString() => 'DriverException($error)';
}

/// Şoför tarafı: kayıt, çevrimiçi olma, çağrıları görme ve kabul etme, yolculuğu ilerletme.
/// Şoför kaydı başvurudur: yönetici `approved` verene kadar çevrimiçi olunamaz.
abstract class DriverRepository {
  /// Giriş yapan kullanıcının şoför kaydı; kayıtlı değilse null.
  Stream<DriverProfile?> watchProfile();

  /// Şoför olarak kaydeder (çevrimdışı başlar) ya da bilgileri günceller.
  Future<void> register(DriverProfile profile);

  /// Çevrimiçi olmak konum ister ([DriverError.noLocation]).
  Future<void> setOnline(bool online, LatLng? position);

  Future<void> updatePosition(LatLng position);

  /// Çevrimiçiyken bekleyen çağrılar; [near]'a yakın olan başta.
  Stream<List<RideOffer>> watchOpenRequests(LatLng? near);

  /// Şoförün üstlendiği ve henüz bitmemiş yolculuk; yoksa null.
  Stream<RideOffer?> watchActiveRide();

  /// Çağrıyı kendine alır; başka bir şoför önce aldıysa [DriverError.rideTaken].
  Future<void> accept(RideOffer offer, LatLng position);

  Future<void> updateRidePosition(String rideId, LatLng position);

  /// Sırayla: driverAssigned → driverArrived → inProgress → completed.
  Future<void> advance(String rideId, RideStatus next, LatLng? position);

  /// Yolcu alınmadan önce iptal.
  Future<void> cancelRide(String rideId);
}

/// Yolcunun gördüğü şoför bilgisi (çağrı belgesinde saklanan kopya).
Map<String, dynamic> driverSnapshot(DriverProfile profile, String phone) => {
      'name': profile.name,
      'plate': profile.plate,
      'car': profile.car,
      'carColor': profile.carColor.name,
      'phone': phone,
    };

Driver driverFromSnapshot(Map<String, dynamic> json) => Driver(
      name: json['name'] as String? ?? '',
      // Puan ortalaması henüz tutulmuyor.
      rating: 5.0,
      car: json['car'] as String? ?? '',
      carColor: CarColor.values.firstWhere((c) => c.name == json['carColor'], orElse: () => CarColor.white),
      plate: json['plate'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
