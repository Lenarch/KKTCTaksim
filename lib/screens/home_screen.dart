import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/data/repositories/live_share_repository.dart';
import 'package:kktc_taksim/data/repositories/ride_repository.dart';
import 'package:kktc_taksim/models/app_user.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/live_share_controller.dart';
import 'package:kktc_taksim/services/location_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/home/active_trip_sheet.dart';
import 'package:kktc_taksim/widgets/home/assistant_sheet.dart';
import 'package:kktc_taksim/widgets/home/destination_sheet.dart';
import 'package:kktc_taksim/widgets/home/driver_found_sheet.dart';
import 'package:kktc_taksim/widgets/home/ride_map.dart';
import 'package:kktc_taksim/widgets/home/safety_sheet.dart';
import 'package:kktc_taksim/widgets/home/taxi_selection_sheet.dart';
import 'package:kktc_taksim/widgets/home/trip_completed_dialog.dart';

enum RideState {
  idle,
  pickingOnMap,
  routing,
  selectingTaxi,
  searching,
  driverFound,
  activeTrip,
  tripCompleted,
}

class HomeScreen extends StatefulWidget {
  /// Testler sahte servis verebilir.
  final GeocodingService? geocoding;
  final RoutingService? routing;

  const HomeScreen({super.key, this.geocoding, this.routing});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  /// Açık bir sheet haritanın bu kadarını kapatır; rota bunun üstüne sığdırılır.
  static const double _sheetCoverage = 0.55;

  final GlobalKey<RideMapState> _mapKey = GlobalKey();
  final LocationService _locationService = LocationService();
  late final GeocodingService _geocoding = widget.geocoding ?? GeocodingService();
  late final RoutingService _routing = widget.routing ?? RoutingService();
  StreamSubscription<LatLng>? _positionSubscription;
  LatLng? _userLocation;
  LocationStatus? _locationStatus;

  RideState _state = RideState.idle;
  GeoPlace? _destination;
  RouteInfo? _route;

  /// Başlangıç noktasının adı (ters aramayla); bulunamazsa "Mevcut konumun".
  String? _pickupName;

  /// Devam eden çağrının backend'den gelen son hâli; sürücü sheet'leri de bunu dinler.
  final ValueNotifier<RideSession?> _session = ValueNotifier(null);
  StreamSubscription<RideSession>? _rideSubscription;

  /// Şoför bulundu / yolculuk paneli ve kapanınca verdiği sonuç. Panel modal değildir: yolcu yolculuk
  /// sürerken menüde gezebilsin diye ana sekmenin içinde durur.
  RideSession? _panelSession;
  Completer<bool>? _panelResult;

  /// Açık güvenlik sheet'i; yolculuk biterse o da kapanır.
  BuildContext? _safetySheetContext;

  /// Yolcu "Yolculuğumu paylaş" derse canlı konum paylaşımı; yolculuk bitince kendiliğinden kapanır.
  late final LiveShareController _liveShare = LiveShareController(Backend.instance.liveShares, _session);

  RideRepository get _rides => Backend.instance.rides;

  /// Çağrı açık mı; sürerken çıkış gibi işlemler çağrıyı sahipsiz bırakır.
  bool get hasActiveRide => const {
        RideState.searching,
        RideState.driverFound,
        RideState.activeTrip,
        RideState.tripCompleted,
      }.contains(_state);

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _positionSubscription?.cancel();
    _liveShare.dispose();
    _session.dispose();
    super.dispose();
  }

  /// Taksilerin ve haritanın merkezi: gerçek konum, yoksa Lefkoşa merkez.
  LatLng get _origin => _userLocation ?? MockData.fallbackLocation;

  double get _sheetInset => MediaQuery.sizeOf(context).height * _sheetCoverage;

  Future<void> _locate({bool userInitiated = false}) async {
    final result = await _locationService.current();
    if (!mounted) return;
    setState(() {
      _locationStatus = result.status;
      if (result.isGranted) _userLocation = result.position;
    });

    if (result.isGranted) {
      if (_state == RideState.idle) _mapKey.currentState?.moveTo(result.position!);
      _positionSubscription ??= _locationService.watch().listen((position) {
        if (mounted) setState(() => _userLocation = position);
      });
    } else if (userInitiated || result.status != LocationStatus.denied) {
      _showLocationProblem(result.status);
    }
  }

  void _showLocationProblem(LocationStatus status) {
    final l10n = context.l10n;
    final canOpenSettings = !kIsWeb &&
        (status == LocationStatus.deniedForever || status == LocationStatus.serviceDisabled);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${status.label(l10n)} ${l10n.showingFallbackCity}'),
        action: canOpenSettings
            ? SnackBarAction(label: l10n.settings, onPressed: () => _locationService.openSettings(status))
            : null,
      ));
  }

  void _reset() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
    _session.value = null;
    _panelSession = null;
    _panelResult = null;
    setState(() {
      _state = RideState.idle;
      _destination = null;
      _route = null;
      _pickupName = null;
    });
    _mapKey.currentState?.moveTo(_origin);
  }

  /// Keşfet gibi başka sekmelerden doğrudan bir yere taksi çağırmak için.
  void rideTo(GeoPlace place) {
    if (_state != RideState.idle) {
      showMessage(context, context.l10n.finishCurrentRideFirst);
      return;
    }
    _planRide(place);
  }

  Future<void> _chooseDestination() async {
    final choice = await showModalBottomSheet<DestinationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DestinationSheet(geocoding: _geocoding, near: _origin),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case PlaceChosen(:final place):
        await _planRide(place);
      case PickOnMapChosen():
        setState(() => _state = RideState.pickingOnMap);
    }
  }

  Future<void> _openAssistant() async {
    final place = await showModalBottomSheet<GeoPlace>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssistantSheet(geocoding: _geocoding, near: _origin),
    );
    if (!mounted || place == null || _state != RideState.idle) return;
    await _planRide(place);
  }

  Future<void> _confirmMapPick() async {
    final point = _mapKey.currentState?.center ?? _origin;
    setState(() => _state = RideState.routing);
    GeoPlace? place;
    try {
      place = await _geocoding.reverse(point);
    } catch (_) {
      // Adı bulunamazsa nokta "İşaretlenen konum" olarak kullanılır.
    }
    if (!mounted || _state != RideState.routing) return;
    await _planRide(place ?? GeoPlace(name: context.l10n.pinnedLocation, position: point));
  }

  Future<void> _planRide(GeoPlace destination) async {
    setState(() {
      _state = RideState.routing;
      _destination = destination;
      _route = null;
    });

    final origin = _origin;
    // Başlangıç noktasının adı yalnızca geçmişe yazmak için; rotayı bekletmesin.
    _geocoding.reverse(origin).then((pickup) {
      if (mounted && _destination == destination) _pickupName = pickup?.name;
    }, onError: (_) {});

    final route = await _routing.route(origin, destination.position);
    if (!mounted || _state != RideState.routing || _destination != destination) return;

    setState(() {
      _route = route;
      _state = RideState.selectingTaxi;
    });
    _mapKey.currentState?.fitPoints(route.points, bottomInset: _sheetInset);

    final pickup = GeoPlace(name: _pickupName ?? context.l10n.currentLocation, position: origin);
    final request = await showModalBottomSheet<RideRequest>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black12,
      builder: (_) => TaxiSelectionSheet(pickup: pickup, destination: destination, route: route),
    );
    if (!mounted) return;
    if (request == null) {
      _reset();
      return;
    }
    if (request.scheduledAt != null) {
      await _schedule(request);
    } else {
      _callTaxi(request);
    }
  }

  Future<void> _schedule(RideRequest request) async {
    final l10n = context.l10n;
    final scheduledAt = request.scheduledAt!;
    final when = context.dateTime(scheduledAt);
    final trips = Backend.instance.trips;
    try {
      await trips.add(Trip(
        id: trips.newId(),
        from: request.pickup.name,
        to: request.destination.name,
        dateTime: scheduledAt,
        price: request.fare.typical,
        status: TripStatus.upcoming,
        taxiType: request.taxiType,
        payment: request.payment,
      ));
      if (mounted) showMessage(context, l10n.rideScheduled(when));
    } catch (_) {
      if (mounted) showMessage(context, l10n.actionFailed);
    }
    if (mounted) _reset();
  }

  void _callTaxi(RideRequest request) {
    setState(() => _state = RideState.searching);
    _rideSubscription = _rides.request(request).listen(
      _onSession,
      onError: (_) {
        if (!mounted) return;
        showMessage(context, context.l10n.actionFailed);
        _reset();
      },
    );
  }

  /// Backend'den gelen her durum değişikliği. Sheet'ler aynı bilgiyi [_session]'dan izler.
  void _onSession(RideSession session) {
    _session.value = session;
    if (!mounted) return;
    switch (session.status) {
      case RideStatus.driverAssigned when _state == RideState.searching:
        _showDriver(session);
      case RideStatus.cancelled when _state == RideState.searching:
        // Arama sırasında backend iptal ettiyse (örn. uygun sürücü yok).
        showMessage(context, context.l10n.noDriverFound);
        _reset();
      default:
        break;
    }
  }

  Future<void> _cancelSearch() async {
    final session = _session.value;
    if (session != null) await _rides.cancel(session.id);
    if (mounted) _reset();
  }

  Future<void> _showDriver(RideSession session) async {
    final driver = session.driver!;
    setState(() {
      _panelSession = session;
      _state = RideState.driverFound;
    });
    final driverAt = session.progress?.position;
    _mapKey.currentState?.fitPoints(
      [if (driverAt != null) driverAt, session.request.pickup.position],
      bottomInset: _sheetInset,
    );

    final started = await _waitForPanel();
    if (!mounted || _state != RideState.driverFound) return;
    if (started != true) {
      await _rides.cancel(session.id);
      if (mounted) _reset();
      return;
    }
    await _showTrip(session.request, driver, session.id);
  }

  Future<void> _showTrip(RideRequest request, Driver driver, String rideId) async {
    setState(() => _state = RideState.activeTrip);
    _mapKey.currentState?.fitPoints(request.route.points, bottomInset: _sheetInset);

    final completed = await _waitForPanel();
    if (!mounted) return;
    if (completed == true) {
      setState(() => _state = RideState.tripCompleted);
      final rating = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TripCompletedDialog(price: request.fare.typical, payment: request.payment),
      );
      if (rating != null) await _rides.rate(rideId, rating);
      if (!mounted) return;
    }
    _reset();
  }

  Future<bool> _waitForPanel() {
    final result = Completer<bool>();
    _panelResult = result;
    return result.future;
  }

  void _onPanelClosed(bool result) {
    final safetySheet = _safetySheetContext;
    if (safetySheet != null && safetySheet.mounted) {
      final route = ModalRoute.of(safetySheet);
      final navigator = Navigator.of(safetySheet);
      navigator.popUntil((r) => r == route);
      navigator.pop();
    }
    _panelResult?.complete(result);
    _panelResult = null;
  }

  Widget? _buildRidePanel() {
    final session = _panelSession;
    final driver = session?.driver;
    if (session == null || driver == null) return null;
    return switch (_state) {
      RideState.driverFound => DriverFoundSheet(
          driver: driver,
          session: _session,
          onClosed: _onPanelClosed,
          onStartDemo: _rides.hasDemoControls ? () => _rides.startTripDemo(session.id) : null,
        ),
      RideState.activeTrip => ActiveTripSheet(
          request: session.request,
          driver: driver,
          session: _session,
          onSafety: _showSafetyTools,
          onClosed: _onPanelClosed,
          onCompleteDemo: _rides.hasDemoControls ? () => _rides.completeDemo(session.id) : null,
        ),
      _ => null,
    };
  }

  void _showSafetyTools() {
    final session = _session.value;
    final driver = session?.driver;
    if (session == null || driver == null) return;
    final l10n = context.l10n;
    final request = session.request;
    final position = session.progress?.position ?? _origin;
    final minutesLeft = session.progress?.minutesLeft ?? request.route.durationMinutes;
    final car = '${driver.car} (${driver.carColor.label(l10n)})';
    final arrival = context.time(DateTime.now().add(Duration(minutes: minutesLeft)));

    Future<String> shareText() async {
      try {
        final link = await _liveShare.share(
          LiveShareInfo(
            // "Mevcut konumun" bağlantıyı açan kişi için anlamsız.
            from: _pickupName ?? l10n.tripStartPoint,
            to: request.destination.name,
            destination: request.destination.position,
            driverName: driver.name,
            plate: driver.plate,
            car: car,
          ),
          position,
        );
        return l10n.shareTripLiveText(driver.name, driver.plate, car, request.destination.name, arrival, '$link');
      } catch (_) {
        // Canlı paylaşım başlatılamazsa (ör. internet yok) o anki konumun bağlantısı gönderilir.
        final mapLink = 'https://www.openstreetmap.org/?mlat=${position.latitude.toStringAsFixed(5)}'
            '&mlon=${position.longitude.toStringAsFixed(5)}#map=16/${position.latitude}/${position.longitude}';
        return l10n.shareTripText(driver.name, driver.plate, car, request.destination.name, arrival, mapLink);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        _safetySheetContext = sheetContext;
        return SafetySheet(shareText: shareText);
      },
    ).whenComplete(() => _safetySheetContext = null);
  }

  void _recenter() {
    final user = _userLocation;
    if (_locationStatus == LocationStatus.granted && user != null) {
      _mapKey.currentState?.moveTo(user);
    } else {
      _locate(userInitiated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showRoute = const {
      RideState.selectingTaxi,
      RideState.searching,
      RideState.driverFound,
      RideState.activeTrip,
    }.contains(_state);
    final showNearbyTaxis = _state == RideState.idle || _state == RideState.pickingOnMap;
    final ridePanel = _buildRidePanel();

    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder<RideSession?>(
            valueListenable: _session,
            builder: (context, session, _) => RideMap(
              key: _mapKey,
              initialCenter: _origin,
              // Yolculukta kullanıcı taksinin içinde; ayrı bir nokta göstermeye gerek yok.
              userLocation: _state == RideState.activeTrip ? null : _userLocation,
              taxis: showNearbyTaxis
                  ? [for (final offset in MockData.nearbyTaxiOffsets) MockData.offsetFrom(_origin, offset)]
                  : const [],
              assignedTaxi: session != null && session.status.hasDriver ? session.progress?.position : null,
              route: showRoute ? _route?.points ?? const [] : const [],
              destination: showRoute ? _destination?.position : null,
            ),
          ),
          if (_state == RideState.idle) const _IdleHeader(),
          if (_state == RideState.pickingOnMap) ...[
            const _CenterPin(),
            _TopBanner(text: l10n.moveMapToPick),
          ],
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xxxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: null,
                  tooltip: l10n.goToMyLocation,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  onPressed: _recenter,
                  child: const Icon(Icons.gps_fixed),
                ),
                if (_state == RideState.idle) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: _openAssistant,
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: AppTheme.primaryBlack,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.assistantTooltip),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SearchCard(onTap: _chooseDestination),
                ],
                if (_state == RideState.pickingOnMap) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
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
                        child: ElevatedButton(onPressed: _confirmMapPick, child: Text(l10n.selectThisPoint)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_state == RideState.routing)
            Positioned.fill(child: _BusyOverlay(title: l10n.calculatingRoute, onCancel: _reset)),
          if (_state == RideState.searching)
            Positioned.fill(
              child: _BusyOverlay(title: l10n.searchingTaxi, subtitle: l10n.searchingTaxiHint, onCancel: _cancelSearch),
            ),
          if (ridePanel != null)
            Positioned.fill(
              child: Align(alignment: Alignment.bottomCenter, child: _RidePanel(child: ridePanel)),
            ),
        ],
      ),
    );
  }
}

/// Şoför ve yolculuk panellerinin zemini; sheet'lerle aynı görünür.
class _RidePanel extends StatelessWidget {
  final Widget child;

  const _RidePanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final sheetTheme = Theme.of(context).bottomSheetTheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: sheetTheme.backgroundColor,
        shape: sheetTheme.shape,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _IdleHeader extends StatelessWidget {
  const _IdleHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<AppUser?>(
                      stream: Backend.instance.auth.authState,
                      initialData: Backend.instance.auth.currentUser,
                      builder: (context, snapshot) {
                        final name = snapshot.data?.name;
                        return Text(
                          name == null || name.isEmpty ? l10n.greetingNoName : l10n.greeting(name.split(' ').first),
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        );
                      },
                    ),
                    Text(
                      l10n.whereToGo,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.primaryYellow,
                child: Icon(Icons.person, color: AppTheme.primaryBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBanner extends StatelessWidget {
  final String text;

  const _TopBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.pan_tool_alt_outlined),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Haritanın tam ortasını gösteren iğne; ucu merkezde olsun diye yukarı kaydırılır.
class _CenterPin extends StatelessWidget {
  static const double _size = 48;

  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: _size),
          child: Icon(Icons.location_on, size: _size, color: AppTheme.errorRed),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(AppRadius.xxl);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: borderRadius,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.locationBlue),
                  const SizedBox(width: AppSpacing.lg),
                  Text(l10n.currentLocation, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(indent: 40),
              ),
              Row(
                children: [
                  const Icon(Icons.circle, color: AppTheme.errorRed, size: 20),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      l10n.whereTo,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onCancel;

  const _BusyOverlay({required this.title, required this.onCancel, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(color: AppTheme.white, fontWeight: FontWeight.bold),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppTheme.white.withValues(alpha: 0.7)),
                ),
              ],
              const SizedBox(height: AppSpacing.huge),
              ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.white,
                  foregroundColor: AppTheme.primaryBlack,
                  minimumSize: const Size(200, 50),
                ),
                child: Text(context.l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
