import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/services/map_style_service.dart';

/// Kullanıcının konumunu ve taksileri gösteren harita. Etiketler cihazın
/// dilinde, renkler uygulamanın temasına (açık/koyu) göre gelir.
class RideMap extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? userLocation;
  final List<LatLng> taxis;
  final LatLng? assignedTaxi;

  const RideMap({
    super.key,
    required this.initialCenter,
    this.userLocation,
    this.taxis = const [],
    this.assignedTaxi,
  });

  @override
  State<RideMap> createState() => RideMapState();
}

class RideMapState extends State<RideMap> {
  static const double _defaultZoom = 14.5;
  static const String _taxiImage = 'taxi';
  static final MapStyleService _styles = MapStyleService();

  MapLibreMapController? _controller;
  String? _style;
  Object? _styleError;
  bool? _loadedDark;
  bool _styleReady = false;
  bool _syncing = false;
  bool _needsResync = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark != _loadedDark) _loadStyle(dark);
  }

  @override
  void didUpdateWidget(RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMarkers();
  }

  Future<void> _loadStyle(bool dark) async {
    _loadedDark = dark;
    _styleReady = false;
    final languageCode = View.of(context).platformDispatcher.locale.languageCode;
    try {
      final style = await _styles.load(dark: dark, languageCode: languageCode);
      if (!mounted) return;
      setState(() {
        _style = style;
        _styleError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _styleError = e);
    }
  }

  /// Haritayı verilen noktaya kaydırır.
  Future<void> moveTo(LatLng target, {double zoom = _defaultZoom}) async {
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.addImage(_taxiImage, await _renderTaxiIcon());
    _styleReady = true;
    await _syncMarkers();
  }

  /// Ardışık widget güncellemelerinde işaretleri tek tek, sırayla yeniden çizer.
  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;
    if (_syncing) {
      _needsResync = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _needsResync = false;
        await controller.clearCircles();
        await controller.clearSymbols();

        final user = widget.userLocation;
        if (user != null) {
          await controller.addCircle(CircleOptions(
            geometry: user,
            circleRadius: 8,
            circleColor: '#1E88E5',
            circleStrokeWidth: 3,
            circleStrokeColor: '#FFFFFF',
          ));
        }

        final assigned = widget.assignedTaxi;
        await controller.addSymbols([
          for (final taxi in widget.taxis)
            SymbolOptions(geometry: taxi, iconImage: _taxiImage, iconSize: 0.4),
          if (assigned != null)
            SymbolOptions(geometry: assigned, iconImage: _taxiImage, iconSize: 0.5),
        ]);
      } while (_needsResync && mounted);
    } finally {
      _syncing = false;
    }
  }

  /// Sarı daire içinde taksi ikonu çizip PNG olarak döndürür.
  static Future<Uint8List> _renderTaxiIcon() async {
    const size = 96.0;
    const center = Offset(size / 2, size / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(center, size / 2, Paint()..color = AppTheme.primaryBlack);
    canvas.drawCircle(center, size / 2 - 5, Paint()..color = AppTheme.primaryYellow);

    const icon = Icons.local_taxi;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size * 0.55,
          color: AppTheme.primaryBlack,
        ),
      ),
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_styleError != null) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: AppSpacing.md),
                const Text('Harita yüklenemedi. İnternet bağlantını kontrol et.', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => _loadStyle(Theme.of(context).brightness == Brightness.dark),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final style = _style;
    if (style == null) {
      return ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MapLibreMap(
      styleString: style,
      initialCameraPosition: CameraPosition(target: widget.initialCenter, zoom: _defaultZoom),
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: _onStyleLoaded,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
    );
  }
}
