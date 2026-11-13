import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/group_fare.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/pickup.dart';
import 'package:kktc_taksim/screens/map_pick_screen.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/pickup_detour.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/home/destination_sheet.dart';

/// Yolcunun gruptan nereden bineceğini seçtirir: grubun buluşma noktası (sapma 0) ya da
/// buluşma noktasına en fazla [maxPickupDetourMeters] uzaklıkta başka bir yer.
/// Geçerli bir seçim yokken (sapma hesaplanıyor ya da çok uzak) [onChanged] null bildirir.
class PickupChooser extends StatefulWidget {
  final GeoPlace meeting;
  final GeocodingService geocoding;
  final RoutingService routing;
  final Pickup? initial;
  final ValueChanged<Pickup?> onChanged;

  const PickupChooser({
    super.key,
    required this.meeting,
    required this.geocoding,
    required this.routing,
    this.initial,
    required this.onChanged,
  });

  @override
  State<PickupChooser> createState() => _PickupChooserState();
}

class _PickupChooserState extends State<PickupChooser> {
  /// Buluşma noktası dışında seçilmiş yer; null ise buluşma noktası seçili.
  GeoPlace? _place;
  int _detourMeters = 0;
  bool _computing = false;
  bool _tooFar = false;

  /// Seçim sayfası açıkken ikinci dokunuş yeni sayfa açmasın.
  bool _choosing = false;

  /// Yavaş biten eski bir hesap yenisinin sonucunu ezmesin diye.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      // Varsayılan seçimi build bitince bildir; build sırasında üst widget'ı güncelleyemeyiz.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _place == null && !_computing) widget.onChanged(_meetingPickup);
      });
    } else if (initial.place.position != widget.meeting.position) {
      _place = initial.place;
      _detourMeters = initial.detourMeters;
    }
  }

  Pickup get _meetingPickup => Pickup(place: widget.meeting, detourMeters: 0);

  void _chooseMeeting() {
    _requestId++;
    setState(() {
      _place = null;
      _detourMeters = 0;
      _computing = false;
      _tooFar = false;
    });
    widget.onChanged(_meetingPickup);
  }

  Future<void> _chooseElsewhere() async {
    if (_choosing) return;
    _choosing = true;
    try {
      await _choosePlaceOnce();
    } finally {
      _choosing = false;
    }
  }

  Future<void> _choosePlaceOnce() async {
    final near = widget.meeting.position;
    final choice = await showModalBottomSheet<DestinationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DestinationSheet(geocoding: widget.geocoding, near: near),
    );
    if (!mounted || choice == null) return;
    final place = switch (choice) {
      PlaceChosen(:final place) => place,
      PickOnMapChosen() => await Navigator.push<GeoPlace>(
          context,
          MaterialPageRoute(builder: (_) => MapPickScreen(geocoding: widget.geocoding, initialCenter: near, requireName: true)),
        ),
    };
    if (!mounted || place == null) return;
    await _computeDetour(place);
  }

  Future<void> _computeDetour(GeoPlace place) async {
    final requestId = ++_requestId;
    setState(() {
      _place = place;
      _computing = true;
      _tooFar = false;
    });
    widget.onChanged(null);
    final detour = await pickupDetourMeters(widget.routing, place.position, widget.meeting.position);
    if (!mounted || requestId != _requestId) return;
    final tooFar = detour > maxPickupDetourMeters;
    setState(() {
      _computing = false;
      _tooFar = tooFar;
      _detourMeters = detour;
    });
    widget.onChanged(tooFar ? null : Pickup(place: place, detourMeters: detour));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final place = _place;
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.pickupTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(place == null ? Icons.radio_button_checked : Icons.radio_button_off),
          title: Text(l10n.pickupAtMeeting),
          subtitle: Text(widget.meeting.name),
          onTap: _chooseMeeting,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(place != null ? Icons.radio_button_checked : Icons.radio_button_off),
          title: Text(l10n.pickupElsewhere),
          subtitle: place == null ? null : Text(place.name),
          onTap: _chooseElsewhere,
        ),
        if (place != null && _computing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (place != null && _tooFar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              l10n.pickupTooFar(maxPickupDetourMeters ~/ 1000),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          )
        else if (place != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(l10n.pickupExtra(context.distance(_detourMeters.toDouble())), style: muted),
          ),
        Text(l10n.pickupPrivacy, style: theme.textTheme.bodySmall?.merge(muted)),
      ],
    );
  }
}
