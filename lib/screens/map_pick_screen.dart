import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/widgets/home/map_pick_overlay.dart';
import 'package:kktc_taksim/widgets/home/ride_map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Haritayı kaydırıp ortadaki iğneyle bir yer seçtirir; adı adres servisinden alınır
/// (ana sayfadaki "Haritadan seç" ile aynı). Seçilen [GeoPlace] ile, vazgeçilirse null ile kapanır.
/// [requireName] ise adı bulunamayan nokta (KKTC dışı, deniz, servis hatası) seçilmez: grubun yer
/// bilgisi "İşaretlenen konum" olmasın.
class MapPickScreen extends StatefulWidget {
  final GeocodingService geocoding;
  final LatLng initialCenter;
  final bool requireName;

  const MapPickScreen({super.key, required this.geocoding, required this.initialCenter, this.requireName = false});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  final GlobalKey<RideMapState> _mapKey = GlobalKey();
  bool _busy = false;

  Future<void> _confirm() async {
    final point = _mapKey.currentState?.center ?? widget.initialCenter;
    final l10n = context.l10n;
    final fallbackName = l10n.pinnedLocation;
    setState(() => _busy = true);
    GeoPlace? place;
    try {
      place = await widget.geocoding.reverse(point);
    } catch (_) {
      // Adı bulunamazsa nokta "İşaretlenen konum" olarak kullanılır.
    }
    if (!mounted) return;
    if (place == null && widget.requireName) {
      setState(() => _busy = false);
      showMessage(context, l10n.pickedPlaceNotFound);
      return;
    }
    Navigator.pop(context, place ?? GeoPlace(name: fallbackName, position: point));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          RideMap(key: _mapKey, initialCenter: widget.initialCenter),
          const MapCenterPin(),
          MapTopBanner(text: l10n.moveMapToPickPlace),
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xxxl,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _confirm,
                      child: _busy
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.selectThisPoint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
