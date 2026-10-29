import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// [DestinationSheet]'in sonucu: bir yer seçildi ya da haritadan seçilmek istendi.
sealed class DestinationChoice {
  const DestinationChoice();
}

class PlaceChosen extends DestinationChoice {
  final GeoPlace place;

  const PlaceChosen(this.place);
}

class PickOnMapChosen extends DestinationChoice {
  const PickOnMapChosen();
}

/// Varış noktası seçtirir: adres arama, son gidilen yerler veya haritadan seçme.
class DestinationSheet extends StatefulWidget {
  final GeocodingService geocoding;

  /// Arama sonuçları bu noktaya yakın olanlar öne çıkacak şekilde sıralanır.
  final LatLng near;

  const DestinationSheet({super.key, required this.geocoding, required this.near});

  @override
  State<DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<DestinationSheet> {
  Timer? _debounce;
  String _query = '';
  List<GeoPlace> _results = const [];
  bool _loading = false;
  bool _failed = false;

  /// Yavaş gelen eski bir aramanın sonucu yenisinin üzerine yazılmasın diye.
  int _requestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
    if (_query.length < 2) {
      _requestId++;
      setState(() {
        _results = const [];
        _loading = false;
        _failed = false;
      });
      return;
    }
    _debounce = Timer(AppDurations.searchDebounce, () => _search(_query));
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await widget.geocoding.search(query, near: widget.near);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = const [];
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final searching = _query.length >= 2;

    return SheetContainer(
      heightFactor: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              if (value.trim().length >= 2) _search(value.trim());
            },
            decoration: InputDecoration(
              hintText: l10n.whereTo,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryYellow,
              child: Icon(Icons.pin_drop_outlined, color: AppTheme.primaryBlack),
            ),
            title: Text(l10n.pickOnMap, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(l10n.pickOnMapHint),
            onTap: () => Navigator.pop(context, const PickOnMapChosen()),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                if (!searching) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(l10n.recentPlaces, style: theme.textTheme.labelLarge?.copyWith(color: mutedStyle.color)),
                  ),
                  for (final place in MockData.recentDestinations)
                    _PlaceTile(place: place, icon: Icons.history),
                ] else if (_failed)
                  _Message(text: l10n.searchFailed)
                else if (!_loading && _results.isEmpty)
                  _Message(text: l10n.searchNoResults)
                else
                  for (final place in _results) _PlaceTile(place: place, icon: Icons.place_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final GeoPlace place;
  final IconData icon;

  const _PlaceTile({required this.place, required this.icon});

  @override
  Widget build(BuildContext context) {
    final address = place.address;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(place.name),
      subtitle: address == null ? null : Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => Navigator.pop(context, PlaceChosen(place)),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
