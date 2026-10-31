import 'package:maplibre_gl/maplibre_gl.dart';

/// Takip sayfasında gösterilen, paylaşım boyunca değişmeyen yolculuk bilgileri.
class LiveShareInfo {
  final String from;
  final String to;
  final LatLng destination;
  final String driverName;
  final String plate;

  /// Araç ve rengi, örn. "Toyota Corolla (Beyaz)".
  final String car;

  const LiveShareInfo({
    required this.from,
    required this.to,
    required this.destination,
    required this.driverName,
    required this.plate,
    required this.car,
  });
}

/// Yolculuk sırasında bir yakınla paylaşılan canlı konum. Bağlantıyı açan kişinin uygulaması ve
/// hesabı olması gerekmez (Firebase Hosting'deki takip sayfası). Paylaşım yolculuk bitince
/// sonlandırılır; unutulsa bile [maxDuration] sonra okunamaz.
abstract class LiveShareRepository {
  static const Duration maxDuration = Duration(hours: 4);

  /// Paylaşımı başlatır ve kimliğini döner.
  Future<String> start(LiveShareInfo info, LatLng position);

  Future<void> update(String shareId, LatLng position);

  /// Paylaşımı bitirir; konum silinir, sayfada "yolculuk bitti" görünür.
  Future<void> end(String shareId);

  /// Paylaşılacak takip bağlantısı.
  Uri link(String shareId);

  /// Hesap silinirken: kullanıcının bütün paylaşımlarını siler.
  Future<void> deleteAllMine();
}

/// Takip sayfası Firebase Hosting'de: `https://<proje>.web.app/t/<kimlik>`.
Uri trackingLink(String shareId) => Uri.parse('https://kktctaksim-1ea24.web.app/t/$shareId');
