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
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/repositories/driver_repository.dart';
import 'package:kktc_taksim/models/fare_estimate.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/services/driver_navigation.dart';
import 'package:kktc_taksim/services/location_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/home/ride_map.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Şoförün ana ekranı: tam ekran harita, üstte çevrimiçi anahtarı, altta bekleyen çağrılar ya da
/// yolculuk kartı. Yolculukta rota (şoför → alış, sonra → varış) uygulama içinde çizilir.
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

  final GlobalKey<RideMapState> _mapKey = GlobalKey();
  final RoutingService _routing = RoutingService();
  RouteInfo? _route;
  LatLng? _routeTarget;
  DateTime? _routeFetchedAt;
  bool _fetchingRoute = false;

  /// Yolculukta kamera şoförü izler; şoför haritayı elle kaydırınca durur, "Konumuma git" açar.
  bool _follow = true;

  /// Son görülen yolculuk ve durumu; değişince rota ve kamera yenilenir.
  String? _activeKey;

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
    final first = _position == null;
    setState(() {
      _position = result.position;
      _openRequests ??= _drivers.watchOpenRequests(result.position);
    });
    if (first) _mapKey.currentState?.moveTo(result.position!);
    _positionSubscription ??= _location.watch().listen(_onPosition);
    return true;
  }

  /// Yolculuktayken sık, beklerken seyrek yazılır (Firestore yazma kotası).
  void _onPosition(LatLng position) {
    if (!mounted) return;
    setState(() => _position = position);
    if (_active != null) {
      if (_follow) _mapKey.currentState?.moveTo(position, zoom: _followZoom);
      _updateRoute();
    }
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
        showMessage(
            context,
            switch (e.error) {
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

  static const double _followZoom = 16;

  /// Haritanın üstündeki çevrimiçi kartı; rota bu kartın altına sığdırılır.
  static const double _statusCardInset = 72;

  /// Yolculuk başlayınca, şoför vardığında ya da yolculuk bitince rota yenilenir ve harita
  /// şoförle hedefi birlikte gösterir.
  void _watchActiveChange(RideOffer? active) {
    final key = active == null ? null : '${active.id}/${active.status.name}';
    if (key == _activeKey) return;
    _activeKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (active == null) {
        setState(() {
          _route = null;
          _routeTarget = null;
        });
        final position = _position;
        if (position != null) _mapKey.currentState?.moveTo(position);
      } else {
        _follow = true;
        _updateRoute();
      }
    });
  }

  /// Rota yoksa, hedef değiştiyse ya da şoför saptıysa OSRM'den yeni rota (bkz. [needsReroute]).
  Future<void> _updateRoute() async {
    final active = _active;
    final position = _position;
    final target = active == null ? null : navigationTarget(active);
    if (target == null || position == null || _fetchingRoute) return;
    final now = DateTime.now();
    final reroute = needsReroute(
      route: _route,
      routeTarget: _routeTarget,
      target: target,
      position: position,
      lastFetch: _routeFetchedAt,
      now: now,
    );
    if (!reroute) return;
    final targetChanged = _routeTarget != target;
    _fetchingRoute = true;
    _routeFetchedAt = now;
    try {
      final route = await _routing.route(position, target);
      final current = _active;
      if (!mounted || current == null || navigationTarget(current) != target) return;
      setState(() {
        _route = route;
        _routeTarget = target;
      });
      if (targetChanged) _fitRoute();
    } finally {
      _fetchingRoute = false;
    }
  }

  /// Rotanın tamamı panelin üstünde kalan alana sığdırılır.
  void _fitRoute() {
    final route = _route;
    if (route == null) return;
    _mapKey.currentState?.fitPoints(route.points, bottomInset: _panelHeight, topInset: _statusCardInset);
  }

  void _recenter() {
    final position = _position;
    if (position == null) return;
    if (_active != null) {
      _follow = true;
      _mapKey.currentState?.moveTo(position, zoom: _followZoom);
    } else {
      _mapKey.currentState?.moveTo(position);
    }
  }

  /// Bekleyen çağrının alış noktası şoförle birlikte gösterilir.
  void _showOnMap(RideOffer offer) {
    final position = _position;
    _mapKey.currentState?.fitPoints(
      [offer.pickup.position, if (position != null) position],
      bottomInset: _panelHeight,
      topInset: _statusCardInset,
    );
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
          _watchActiveChange(active);
          return StreamBuilder<List<RideOffer>>(
            stream: _openRequests,
            builder: (context, requests) {
              final offers =
                  active == null && widget.profile.online ? requests.data ?? const <RideOffer>[] : const <RideOffer>[];
              final target = active == null ? null : navigationTarget(active);
              final panelHeight = _panelHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    // Haritayı elle kaydıran şoförü kamera takibi geri çekmesin.
                    child: Listener(
                      onPointerDown: (_) => _follow = false,
                      child: RideMap(
                        key: _mapKey,
                        initialCenter: _position ?? MockData.fallbackLocation,
                        assignedTaxi: _position,
                        route: active != null ? _route?.points ?? const [] : const [],
                        pickup: active != null && active.status != RideStatus.inProgress ? target : null,
                        destination: active?.status == RideStatus.inProgress ? target : null,
                        requestPins: [for (final offer in offers) offer.pickup.position],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _statusCard(active),
                  ),
                  if (_position != null)
                    Positioned(
                      right: AppSpacing.lg,
                      bottom: panelHeight + AppSpacing.lg,
                      child: FloatingActionButton.small(
                        heroTag: 'driver-recenter',
                        tooltip: l10n.goToMyLocation,
                        onPressed: _recenter,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: panelHeight),
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: _panel(active, requests),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Alt panel en fazla ekranın bu kadarını kaplar; harita kalan kısımda rotayı gösterir.
  double get _panelHeight => MediaQuery.sizeOf(context).height * 0.45;

  Widget _statusCard(RideOffer? active) {
    final l10n = context.l10n;
    final online = widget.profile.online;
    if (!widget.profile.approved) {
      return Card(
        key: const ValueKey('pending'),
        child: ListTile(
          leading: const Icon(Icons.hourglass_top),
          title: Text(l10n.driverPendingTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${widget.profile.name} • ${widget.profile.plate}'),
        ),
      );
    }
    return Card(
      child: SwitchListTile(
        key: const ValueKey('online'),
        value: online,
        onChanged: _busy || active != null ? null : _setOnline,
        title:
            Text(online ? l10n.driverOnline : l10n.driverOffline, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${widget.profile.name} • ${widget.profile.plate}'),
        activeThumbColor: AppTheme.primaryBlack,
        activeTrackColor: AppTheme.primaryYellow,
      ),
    );
  }

  Widget _panel(RideOffer? active, AsyncSnapshot<List<RideOffer>> requests) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (active != null) {
      return _ActiveRideCard(
        ride: active,
        busy: _busy,
        remaining: _remainingText(active),
        onAdvance: (next) => _advance(active, next),
        onCancel: () => _cancel(active),
        onNavigate: _navigate,
      );
    }
    if (!widget.profile.approved) return _Hint(text: l10n.driverPendingHint);
    if (!widget.profile.online) return _Hint(text: l10n.driverOfflineHint);
    if (_openRequests == null) {
      // Çevrimiçi ama konum alınamadı (izin yok ya da Kıbrıs dışı): çağrılar konuma göre sıralanır.
      return Column(
        children: [
          _Hint(text: l10n.driverNeedsLocation),
          TextButton(onPressed: _startLocation, child: Text(l10n.retry)),
        ],
      );
    }
    if (requests.hasError) {
      return Column(
        children: [
          _Hint(text: l10n.actionFailedWithCode(errorCode(requests.error!))),
          TextButton(
            onPressed: () => setState(() => _openRequests = _drivers.watchOpenRequests(_position)),
            child: Text(l10n.retry),
          ),
        ],
      );
    }
    final offers = requests.data;
    if (offers == null) return const Center(child: CircularProgressIndicator());
    if (offers.isEmpty) return _Hint(text: l10n.noOpenRequests);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.openRequests, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.lg),
        for (final offer in offers)
          _OfferCard(
            offer: offer,
            from: _position,
            busy: _busy,
            onShow: () => _showOnMap(offer),
            onAccept: () => _accept(offer),
          ),
      ],
    );
  }

  /// "Yolcuya 2,3 km • 6 dk"; rota servisine ulaşılamadıysa başında "Yaklaşık".
  String? _remainingText(RideOffer ride) {
    final route = _route;
    final position = _position;
    if (route == null || position == null || _routeTarget != navigationTarget(ride)) return null;
    final left = remainingAlong(route, position);
    final distance = context.distance(left.meters);
    final duration = context.minutes((left.seconds / 60).ceil());
    final l10n = context.l10n;
    final summary = ride.status == RideStatus.inProgress
        ? l10n.remainingToDestination(distance, duration)
        : l10n.remainingToPickup(distance, duration);
    return route.isApproximate ? l10n.approximateRoute(summary) : summary;
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
  final VoidCallback onShow;
  final VoidCallback onAccept;

  const _OfferCard({
    required this.offer,
    required this.from,
    required this.busy,
    required this.onShow,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);
    final position = from;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShow,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Route(ride: offer),
              const SizedBox(height: AppSpacing.md),
              Text(
                [
                  if (position != null)
                    l10n.pickupDistance(context.distance(distanceMeters(position, offer.pickup.position))),
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

  /// Kalan mesafe ve süre; rota henüz alınmadıysa null.
  final String? remaining;

  const _ActiveRideCard({
    required this.ride,
    required this.busy,
    required this.remaining,
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
            if (remaining case final remaining?) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                remaining,
                key: const ValueKey('remaining'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
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
              label: Text(l10n.openInGoogleMaps),
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
