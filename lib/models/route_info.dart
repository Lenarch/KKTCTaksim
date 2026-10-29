import 'package:maplibre_gl/maplibre_gl.dart';

class RouteInfo {
  /// Haritada çizilecek yol (başlangıçtan varışa).
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// Rota servisine ulaşılamadığında kuş uçuşu mesafeden tahmin edilir.
  final bool isApproximate;

  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isApproximate = false,
  });

  double get distanceKm => distanceMeters / 1000;
  int get durationMinutes => (durationSeconds / 60).ceil();
}
