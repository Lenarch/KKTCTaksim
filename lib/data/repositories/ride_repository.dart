import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';

/// Taksi çağırma ve eşleştirme. Çağrının bütün yaşamı tek bir akıştan izlenir:
/// searching → driverAssigned → driverArrived → inProgress → arrived → completed (ya da cancelled).
abstract class RideRepository {
  /// Çağrıyı başlatır. Akış hemen `searching` ile başlar, `completed`/`cancelled` ile kapanır.
  /// Tamamlanan veya sürücü atandıktan sonra iptal edilen yolculuk geçmişe yazılır.
  Stream<RideSession> request(RideRequest request);

  Future<void> cancel(String rideId);

  Future<void> rate(String rideId, int stars);

  /// Gerçek sistemde yolculuğu şoför başlatır ve bitirir. Şoför tarafı olmayan demoda bu
  /// adımları yolcu ekranındaki "(DEMO)" butonları yapar; yalnızca bu true iken gösterilir.
  bool get hasDemoControls;

  Future<void> startTripDemo(String rideId);

  Future<void> completeDemo(String rideId);
}
