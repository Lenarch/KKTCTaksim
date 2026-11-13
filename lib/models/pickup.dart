import 'package:kktc_taksim/models/geo_place.dart';

/// Bir yolcunun gruptan bineceği nokta ve grup güzergâhına eklediği sapma (metre).
class Pickup {
  final GeoPlace place;
  final int detourMeters;

  const Pickup({required this.place, required this.detourMeters});
}
