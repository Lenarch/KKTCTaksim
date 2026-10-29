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
