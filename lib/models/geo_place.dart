import 'package:maplibre_gl/maplibre_gl.dart';

/// Haritada bir yer: adres aramasının sonucu, haritadan seçilen nokta veya kayıtlı bir yer.
class GeoPlace {
  final String name;

  /// Sokak, semt, şehir gibi ayrıntılar; bilinmiyorsa null.
  final String? address;
  final LatLng position;

  const GeoPlace({required this.name, required this.position, this.address});
}
