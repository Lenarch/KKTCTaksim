import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/ride_progress.dart';
import 'package:kktc_taksim/models/ride_request.dart';

enum RideStatus {
  /// Sürücü aranıyor.
  searching,

  /// Sürücü çağrıyı kabul etti, yolcuya geliyor.
  driverAssigned,

  /// Sürücü alış noktasında bekliyor.
  driverArrived,
  inProgress,

  /// Varış noktasına ulaşıldı; ödeme ve tamamlama bekleniyor.
  arrived,
  completed,
  cancelled;

  bool get isFinished => this == completed || this == cancelled;

  /// Sürücü atanmış ve haritada gösterilecek durumlar.
  bool get hasDriver => index >= driverAssigned.index && index <= arrived.index;
}

/// Devam eden bir taksi çağrısının o anki hâli. Backend'den akış (Stream) olarak gelir.
class RideSession {
  final String id;
  final RideRequest request;
  final RideStatus status;
  final Driver? driver;

  /// Sürücünün rota üzerindeki konumu: önce yolcuya gelirken, sonra yolculukta.
  final RideProgress? progress;

  const RideSession({
    required this.id,
    required this.request,
    required this.status,
    this.driver,
    this.progress,
  });

  RideSession copyWith({RideStatus? status, Driver? driver, RideProgress? progress}) {
    return RideSession(
      id: id,
      request: request,
      status: status ?? this.status,
      driver: driver ?? this.driver,
      progress: progress ?? this.progress,
    );
  }
}
