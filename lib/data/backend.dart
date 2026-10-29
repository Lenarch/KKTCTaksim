import 'package:kktc_taksim/data/firebase/firebase_auth_repository.dart';
import 'package:kktc_taksim/data/firebase/firebase_trip_repository.dart';
import 'package:kktc_taksim/data/mock/mock_auth_repository.dart';
import 'package:kktc_taksim/data/mock/mock_ride_repository.dart';
import 'package:kktc_taksim/data/mock/mock_shared_ride_repository.dart';
import 'package:kktc_taksim/data/mock/mock_trip_repository.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/data/repositories/ride_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';

/// Ekranların veriye eriştiği tek nokta. Uygulama `Backend.firebase()` ile, testler
/// `Backend.mock()` ile çalışır; ekranlar hangisinin kullanıldığını bilmez.
class Backend {
  final AuthRepository auth;
  final TripRepository trips;
  final SharedRideRepository sharedRides;
  final RideRepository rides;

  Backend({required this.auth, required this.trips, required this.sharedRides, required this.rides});

  factory Backend.mock() {
    final auth = MockAuthRepository();
    final trips = MockTripRepository();
    return Backend(
      auth: auth,
      trips: trips,
      sharedRides: MockSharedRideRepository(auth),
      rides: MockRideRepository(trips: trips),
    );
  }

  /// Firebase'e taşınan bölümler gerçek, diğerleri şimdilik örnek veri. Aşama ilerledikçe
  /// buradaki mock'lar tek tek Firebase uygulamalarıyla değişecek (bkz. docs/BACKEND_PLANI.md).
  factory Backend.firebase() {
    final auth = FirebaseAuthRepository();
    final trips = FirebaseTripRepository();
    return Backend(
      auth: auth,
      trips: trips,
      sharedRides: MockSharedRideRepository(auth),
      rides: MockRideRepository(trips: trips),
    );
  }

  /// Testler her seferinde yeni bir örnek verebilir.
  static Backend instance = Backend.mock();

  Future<void> init() => auth.init();
}
