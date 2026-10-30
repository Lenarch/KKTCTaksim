import 'package:kktc_taksim/models/shared_ride.dart';

enum SharedRideError { full, notFound }

class SharedRideException implements Exception {
  final SharedRideError error;

  const SharedRideException(this.error);

  @override
  String toString() => 'SharedRideException($error)';
}

/// Paylaşımlı yolculuk grupları; herkes görür, üyeliği yalnızca kullanıcı kendisi değiştirir.
abstract class SharedRideRepository {
  /// Kalkış zamanı gelmemiş gruplar, en yakın kalkış başta.
  Stream<List<SharedRide>> watchActive();

  /// Grubu oluşturur; oluşturan kişi ilk üye olur. Kimliği repository verir.
  Future<void> create(SharedRide ride);

  /// Dolu gruba katılmak [SharedRideException] fırlatır.
  Future<void> join(String rideId);

  /// Son üye ayrılırsa grup silinir.
  Future<void> leave(String rideId);
}

/// [userId] katılınca üye listesi; zaten üyeyse liste aynen döner.
/// Dolu grupta [SharedRideException] fırlatır.
List<String> membersAfterJoin(SharedRide ride, String userId) {
  if (ride.hasMember(userId)) return ride.memberIds;
  if (ride.isFull) throw const SharedRideException(SharedRideError.full);
  return [...ride.memberIds, userId];
}

/// [userId] ayrılınca üye listesi; boşsa grup silinmelidir.
List<String> membersAfterLeave(SharedRide ride, String userId) =>
    ride.memberIds.where((id) => id != userId).toList();
