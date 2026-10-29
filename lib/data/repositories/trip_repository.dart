import 'package:kktc_taksim/models/trip.dart';

/// Giriş yapmış kullanıcının yolculuk geçmişi ve planlanmış yolculukları.
abstract class TripRepository {
  /// Yeni bir yolculuk için benzersiz kimlik.
  String newId();

  /// Yaklaşanlarda en yakın tarih, diğerlerinde en yeni yolculuk başta.
  Stream<List<Trip>> watch(TripStatus status);

  Future<void> add(Trip trip);

  /// Planlanmış yolculuğu iptal eder; ücreti sıfırlanır.
  Future<void> cancel(String id);
}
