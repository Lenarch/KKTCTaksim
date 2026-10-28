import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,

  /// Tarayıcılar konumu yalnızca HTTPS (veya localhost) üzerinden verir.
  insecureContext,
  unavailable,
}

class LocationResult {
  final LocationStatus status;
  final LatLng? position;

  const LocationResult(this.status, [this.position]);

  bool get isGranted => status == LocationStatus.granted && position != null;
}

/// Cihaz konumunu okur; izin ve hata durumlarını [LocationStatus] ile bildirir.
class LocationService {
  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  static bool get _isInsecureWeb {
    if (!kIsWeb) return false;
    final uri = Uri.base;
    final isLocalhost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    return uri.scheme != 'https' && !isLocalhost;
  }

  Future<LocationResult> current() async {
    if (_isInsecureWeb) return const LocationResult(LocationStatus.insecureContext);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(LocationStatus.granted, LatLng(position.latitude, position.longitude));
    } catch (_) {
      return const LocationResult(LocationStatus.unavailable);
    }
  }

  /// Konum izni verildikten sonra kullanıcı hareket ettikçe yeni konumu yayar.
  Stream<LatLng> watch() => Geolocator.getPositionStream(locationSettings: _settings)
      .map((p) => LatLng(p.latitude, p.longitude));

  /// Kalıcı olarak reddedilen izin veya kapalı konum servisi için ayarları açar.
  Future<void> openSettings(LocationStatus status) async {
    if (kIsWeb) return;
    if (status == LocationStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static String describe(LocationStatus status) => switch (status) {
        LocationStatus.granted => '',
        LocationStatus.denied => 'Konum izni verilmedi.',
        LocationStatus.deniedForever => 'Konum izni kapalı. Ayarlardan açabilirsin.',
        LocationStatus.serviceDisabled => 'Cihazının konum servisi kapalı.',
        LocationStatus.insecureContext => 'Tarayıcı konumu yalnızca güvenli (https) bağlantıda paylaşır.',
        LocationStatus.unavailable => 'Konumun şu an alınamadı.',
      };
}
