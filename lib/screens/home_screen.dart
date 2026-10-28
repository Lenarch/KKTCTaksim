import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/taxi_option.dart';
import 'package:kktc_taksim/services/location_service.dart';
import 'package:kktc_taksim/widgets/home/active_trip_sheet.dart';
import 'package:kktc_taksim/widgets/home/destination_sheet.dart';
import 'package:kktc_taksim/widgets/home/driver_found_sheet.dart';
import 'package:kktc_taksim/widgets/home/ride_map.dart';
import 'package:kktc_taksim/widgets/home/taxi_selection_sheet.dart';
import 'package:kktc_taksim/widgets/home/trip_completed_dialog.dart';

enum RideState { idle, selectingTaxi, searching, driverFound, activeTrip, tripCompleted }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RideMapState> _mapKey = GlobalKey();
  final LocationService _locationService = LocationService();
  StreamSubscription<LatLng>? _positionSubscription;
  LatLng? _userLocation;
  LocationStatus? _locationStatus;

  RideState _state = RideState.idle;
  Timer? _searchTimer;
  String? _destination;
  TaxiOption? _taxiOption;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Taksilerin ve haritanın merkezi: gerçek konum, yoksa Lefkoşa merkez.
  LatLng get _origin => _userLocation ?? MockData.fallbackLocation;

  Future<void> _locate({bool userInitiated = false}) async {
    final result = await _locationService.current();
    if (!mounted) return;
    setState(() {
      _locationStatus = result.status;
      if (result.isGranted) _userLocation = result.position;
    });

    if (result.isGranted) {
      _mapKey.currentState?.moveTo(result.position!);
      _positionSubscription ??= _locationService.watch().listen((position) {
        if (mounted) setState(() => _userLocation = position);
      });
    } else if (userInitiated || result.status != LocationStatus.denied) {
      _showLocationProblem(result.status);
    }
  }

  void _showLocationProblem(LocationStatus status) {
    final canOpenSettings = !kIsWeb &&
        (status == LocationStatus.deniedForever || status == LocationStatus.serviceDisabled);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${LocationService.describe(status)} Harita Lefkoşa merkezde gösteriliyor.'),
        action: canOpenSettings
            ? SnackBarAction(label: 'Ayarlar', onPressed: () => _locationService.openSettings(status))
            : null,
      ));
  }

  void _reset() {
    _searchTimer?.cancel();
    setState(() {
      _state = RideState.idle;
      _destination = null;
      _taxiOption = null;
    });
  }

  Future<void> _chooseDestination() async {
    final destination = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DestinationSheet(),
    );
    if (!mounted || destination == null) return;
    _destination = destination;
    await _chooseTaxi(destination);
  }

  Future<void> _chooseTaxi(String destination) async {
    setState(() => _state = RideState.selectingTaxi);
    final option = await showModalBottomSheet<TaxiOption>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaxiSelectionSheet(destination: destination),
    );
    if (!mounted) return;
    if (option == null) {
      _reset();
      return;
    }
    _taxiOption = option;
    _startSearching();
  }

  void _startSearching() {
    setState(() => _state = RideState.searching);
    _searchTimer?.cancel();
    _searchTimer = Timer(AppDurations.driverSearch, _onDriverFound);
  }

  Future<void> _onDriverFound() async {
    if (!mounted) return;
    setState(() => _state = RideState.driverFound);
    final started = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const DriverFoundSheet(driver: MockData.driver),
    );
    if (!mounted) return;
    if (started != true) {
      _reset();
      return;
    }
    await _startTrip();
  }

  Future<void> _startTrip() async {
    setState(() => _state = RideState.activeTrip);
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ActiveTripSheet(destination: _destination!, option: _taxiOption!),
    );
    if (!mounted) return;
    if (completed == true) {
      setState(() => _state = RideState.tripCompleted);
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TripCompletedDialog(price: _taxiOption!.price),
      );
      if (!mounted) return;
    }
    _reset();
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
    final showAssignedTaxi = _state == RideState.driverFound || _state == RideState.activeTrip;

    return Scaffold(
      body: Stack(
        children: [
          RideMap(
            key: _mapKey,
            initialCenter: _origin,
            userLocation: _userLocation,
            taxis: _state == RideState.idle
                ? [for (final offset in MockData.nearbyTaxiOffsets) MockData.offsetFrom(_origin, offset)]
                : const [],
            assignedTaxi: showAssignedTaxi ? MockData.offsetFrom(_origin, MockData.assignedTaxiOffset) : null,
          ),
          if (_state == RideState.idle) const _IdleHeader(),
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
                  tooltip: 'Konumuma git',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  onPressed: _recenter,
                  child: const Icon(Icons.gps_fixed),
                ),
                if (_state == RideState.idle) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SearchCard(onTap: _chooseDestination),
                ],
              ],
            ),
          ),
          if (_state == RideState.searching)
            Positioned.fill(child: _SearchingOverlay(onCancel: _reset)),
        ],
      ),
    );
  }
}

class _IdleHeader extends StatelessWidget {
  const _IdleHeader();

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      'Merhaba ${MockData.userName} 👋',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Nereye gitmek istersin?',
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

class _SearchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  Text('Mevcut konumun', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
                  Text(
                    'Nereye gitmek istiyorsun?',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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

class _SearchingOverlay extends StatelessWidget {
  final VoidCallback onCancel;

  const _SearchingOverlay({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'Taksi aranıyor...',
              style: textTheme.headlineSmall?.copyWith(color: AppTheme.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Yakındaki sürücülerle eşleştiriliyorsun',
              style: textTheme.bodyMedium?.copyWith(color: AppTheme.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: AppSpacing.huge),
            ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.white,
                foregroundColor: AppTheme.primaryBlack,
                minimumSize: const Size(200, 50),
              ),
              child: const Text('İptal Et'),
            ),
          ],
        ),
      ),
    );
  }
}
