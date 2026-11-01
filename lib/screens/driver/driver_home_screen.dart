import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/fare_estimate.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/services/location_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Şoförün ana ekranı: çevrimiçi ol, bekleyen çağrıları gör ve kabul et, yolculuğu ilerlet.
/// Konum yalnızca uygulama açıkken yazılır (arka plan konumu henüz yok; docs/UYARILAR.md).
class DriverHomeScreen extends StatefulWidget {
  final DriverProfile profile;

  const DriverHomeScreen({super.key, required this.profile});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  DriverRepository get _drivers => Backend.instance.drivers;
  final LocationService _location = LocationService();

  late final Stream<RideOffer?> _activeRide = _drivers.watchActiveRide();
  Stream<List<RideOffer>>? _openRequests;
  StreamSubscription<LatLng>? _positionSubscription;

  LatLng? _position;
  RideOffer? _active;
  DateTime? _lastWrite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile.online) _startLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _startLocation() async {
    final result = await _location.current();
    if (!mounted) return false;
    if (!result.isGranted) {
      showMessage(context, '${result.status.label(context.l10n)} ${context.l10n.driverNeedsLocation}');
      return false;
    }
    setState(() {
      _position = result.position;
      _openRequests ??= _drivers.watchOpenRequests(result.position);
    });
    _positionSubscription ??= _location.watch().listen(_onPosition);
    return true;
  }

  /// Yolculuktayken sık, beklerken seyrek yazılır (Firestore yazma kotası).
  void _onPosition(LatLng position) {
    if (!mounted) return;
    setState(() => _position = position);
    final active = _active;
    final interval = active != null ? AppDurations.driverRidePositionInterval : AppDurations.driverIdlePositionInterval;
    final last = _lastWrite;
    if (last != null && DateTime.now().difference(last) < interval) return;
    _lastWrite = DateTime.now();
    final write = active != null ? _drivers.updateRidePosition(active.id, position) : _drivers.updatePosition(position);
    write.catchError((Object e) => debugPrint('Şoför konumu yazılamadı: $e'));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await action();
    } on DriverException catch (e) {
      if (mounted) {
        showMessage(context, switch (e.error) {
          DriverError.rideTaken => l10n.rideTaken,
          DriverError.noLocation => l10n.driverNeedsLocation,
          DriverError.notRegistered => l10n.actionFailed,
          DriverError.notApproved => l10n.driverPendingTitle,
        });
      }
    } catch (e) {
      debugPrint('Şoför işlemi başarısız: $e');
      if (mounted) showMessage(context, l10n.actionFailedWithCode(errorCode(e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setOnline(bool online) async {
    if (online) {
      if (!await _startLocation()) return;
      await _run(() => _drivers.setOnline(true, _position));
    } else {
      await _run(() => _drivers.setOnline(false, null));
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      // Firestore akışı bir kez dinlenebilir; tekrar çevrimiçi olunca yenisi açılır.
      if (mounted) setState(() => _openRequests = null);
    }
  }

  Future<void> _accept(RideOffer offer) async {
    final position = _position;
    if (position == null) {
      showMessage(context, context.l10n.driverNeedsLocation);
      return;
    }
    await _run(() => _drivers.accept(offer, position));
  }

  Future<void> _advance(RideOffer ride, RideStatus next) async {
    final l10n = context.l10n;
    await _run(() => _drivers.advance(ride.id, next, _position));
    if (next == RideStatus.completed && mounted) showMessage(context, l10n.rideFinishedDriver);
  }

  Future<void> _cancel(RideOffer ride) async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.cancelRideDriver,
      message: l10n.cancelRideDriverMessage,
      confirmLabel: l10n.cancelRideDriver,
      destructive: true,
    );
    if (confirmed && mounted) await _run(() => _drivers.cancelRide(ride.id));
  }

  /// Telefonun harita uygulamasında yol tarifi.
  Future<void> _navigate(LatLng to) async {
    final message = context.l10n.cannotOpen;
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${to.latitude},${to.longitude}&travelmode=driving');
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened && mounted) showMessage(context, message);
  }

  Future<void> _switchToPassenger() async {
    if (widget.profile.online) await _drivers.setOnline(false, null).catchError((_) {});
    await AppSettings.instance.setRole(AppRole.passenger);
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.logout,
      message: l10n.logoutMessage,
      confirmLabel: l10n.logout,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    if (widget.profile.online) await _drivers.setOnline(false, null).catchError((_) {});
    await Backend.instance.auth.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final online = widget.profile.online;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverMode),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => value == 'passenger' ? _switchToPassenger() : _logout(),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'passenger', child: Text(l10n.switchToPassenger)),
              PopupMenuItem(value: 'logout', child: Text(l10n.logout)),
            ],
          ),
        ],
      ),
      body: StreamBuilder<RideOffer?>(
        stream: _activeRide,
        builder: (context, snapshot) {
          final active = snapshot.data;
          // Konum yazarken hangi belgeye yazılacağı için (çağrı mı, şoför mü).
          _active = active;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              if (!widget.profile.approved)
                Card(
                  key: const ValueKey('pending'),
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_top),
                    title: Text(l10n.driverPendingTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${widget.profile.name} • ${widget.profile.plate}\n${l10n.driverPendingHint}'),
                  ),
                )
              else
                Card(
                  child: SwitchListTile(
                    key: const ValueKey('online'),
                    value: online,
                    onChanged: _busy || active != null ? null : _setOnline,
                    title: Text(online ? l10n.driverOnline : l10n.driverOffline,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${widget.profile.name} • ${widget.profile.plate}'),
                    activeThumbColor: AppTheme.primaryBlack,
                    activeTrackColor: AppTheme.primaryYellow,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              if (active != null)
                _ActiveRideCard(
                  ride: active,
                  busy: _busy,
                  onAdvance: (next) => _advance(active, next),
                  onCancel: () => _cancel(active),
                  onNavigate: _navigate,
                )
              else if (!widget.profile.approved)
                const SizedBox.shrink()
              else if (!online)
                _Hint(text: l10n.driverOfflineHint)
              else if (_openRequests == null)
                // Çevrimiçi ama konum alınamadı (izin yok ya da Kıbrıs dışı): çağrılar konuma göre sıralanır.
                Column(
                  children: [
                    _Hint(text: l10n.driverNeedsLocation),
                    TextButton(onPressed: _startLocation, child: Text(l10n.retry)),
                  ],
                )
              else
                StreamBuilder<List<RideOffer>>(
                  stream: _openRequests,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          _Hint(text: l10n.actionFailedWithCode(errorCode(snapshot.error!))),
                          TextButton(
                            onPressed: () => setState(() => _openRequests = _drivers.watchOpenRequests(_position)),
                            child: Text(l10n.retry),
                          ),
                        ],
                      );
                    }
                    final offers = snapshot.data;
                    if (offers == null) return const Center(child: CircularProgressIndicator());
                    if (offers.isEmpty) return _Hint(text: l10n.noOpenRequests);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.openRequests,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        for (final offer in offers)
                          _OfferCard(
                            offer: offer,
                            from: _position,
                            busy: _busy,
                            onAccept: () => _accept(offer),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Route extends StatelessWidget {
  final RideOffer ride;

  const _Route({required this.ride});

  @override
  Widget build(BuildContext context) {
    const placeStyle = TextStyle(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.circle, color: AppTheme.primaryYellow, size: 12),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(ride.pickup.name, style: placeStyle)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          const Icon(Icons.location_on, color: AppTheme.errorRed, size: 12),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(ride.destination.name, style: placeStyle)),
        ]),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final RideOffer offer;
  final LatLng? from;
  final bool busy;
  final VoidCallback onAccept;

  const _OfferCard({required this.offer, required this.from, required this.busy, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
    final position = from;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Route(ride: offer),
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                if (position != null) l10n.pickupDistance(context.distance(distanceMeters(position, offer.pickup.position))),
                '${context.distance(offer.distanceMeters)} • ${context.minutes(offer.durationMinutes)}',
              ].join('  •  '),
              style: muted,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${context.fareRange(FareEstimate(low: offer.fareLow, high: offer.fareHigh))}  •  '
              '${offer.taxiType.label(l10n)}  •  ${offer.payment.label(l10n)}',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: busy ? null : onAccept, child: Text(l10n.acceptRide)),
          ],
        ),
      ),
    );
  }
}

class _ActiveRideCard extends StatelessWidget {
  final RideOffer ride;
  final bool busy;
  final ValueChanged<RideStatus> onAdvance;
  final VoidCallback onCancel;
  final ValueChanged<LatLng> onNavigate;

  const _ActiveRideCard({
    required this.ride,
    required this.busy,
    required this.onAdvance,
    required this.onCancel,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (title, nextLabel, next, target) = switch (ride.status) {
      RideStatus.driverAssigned => (l10n.headToPickup, l10n.iArrived, RideStatus.driverArrived, ride.pickup.position),
      RideStatus.driverArrived => (l10n.waitingPassenger, l10n.startTrip, RideStatus.inProgress, ride.pickup.position),
      _ => (l10n.tripInProgressDriver, l10n.finishTrip, RideStatus.completed, ride.destination.position),
    };
    final canCancel = ride.status == RideStatus.driverAssigned || ride.status == RideStatus.driverArrived;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            _Route(ride: ride),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${context.fareRange(FareEstimate(low: ride.fareLow, high: ride.fareHigh))}  •  ${ride.payment.label(l10n)}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => onNavigate(target),
              icon: const Icon(Icons.navigation_outlined),
              label: Text(l10n.navigate),
            ),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              key: const ValueKey('advance'),
              onPressed: busy ? null : () => onAdvance(next),
              child: Text(nextLabel),
            ),
            if (canCancel) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: busy ? null : onCancel,
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                child: Text(l10n.cancelRideDriver),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
