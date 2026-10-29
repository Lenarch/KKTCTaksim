import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/services/map_style_service.dart';

/// Kullanıcının konumunu, taksileri ve rotayı gösteren harita. Etiketler
/// uygulamanın dilinde, renkler temasına (açık/koyu) göre gelir.
class RideMap extends StatefulWidget {
  final LatLng initialCenter;
  final LatLng? userLocation;
  final List<LatLng> taxis;

  /// Yolcuya atanan taksi; konumu değiştikçe işaret yerinde kaydırılır.
  final LatLng? assignedTaxi;
  final List<LatLng> route;
  final LatLng? destination;

  const RideMap({
    super.key,
    required this.initialCenter,
    this.userLocation,
    this.taxis = const [],
    this.assignedTaxi,
    this.route = const [],
    this.destination,
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
  (bool, String)? _loadedStyle;
  bool _styleReady = false;
  bool _syncing = false;
  bool _needsResync = false;

  /// Son çizilen sabit işaretlerin (rota, varış, taksiler, kullanıcı) özeti;
  /// yalnızca atanan taksi hareket ettiyse her şey yeniden çizilmez.
  int? _drawnKey;
  Symbol? _assignedSymbol;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    if ((dark, languageCode) != _loadedStyle) _loadStyle(dark, languageCode);
  }

  @override
  void didUpdateWidget(RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMarkers();
  }

  Future<void> _loadStyle(bool dark, String languageCode) async {
    _loadedStyle = (dark, languageCode);
    _styleReady = false;
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

  /// Noktaların hepsini gösterir; [bottomInset] kadar alt kısım (açık sheet) boş bırakılır.
  Future<void> fitPoints(List<LatLng> points, {double bottomInset = 0}) async {
    if (points.isEmpty) return;
    if (points.length == 1) return moveTo(points.first);
    const margin = AppSpacing.huge;
    await _controller?.animateCamera(CameraUpdate.newLatLngBounds(
      boundsOf(points),
      left: margin,
      top: margin * 2,
      right: margin,
      bottom: margin + bottomInset,
    ));
  }

  /// Ekranın ortasındaki nokta ("haritadan seç" için).
  LatLng? get center => _controller?.cameraPosition?.target;

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.addImage(_taxiImage, await _renderTaxiIcon());
    _drawnKey = null;
    _assignedSymbol = null;
    _styleReady = true;
    await _syncMarkers();
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

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
        final user = widget.userLocation;
        final destination = widget.destination;
        final key = Object.hashAll([user, destination, ...widget.taxis, ...widget.route]);

        if (key != _drawnKey) {
          await controller.clearLines();
          await controller.clearCircles();
          await controller.clearSymbols();
          _assignedSymbol = null;

          if (widget.route.length >= 2 && mounted) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            await controller.addLine(LineOptions(
              geometry: widget.route,
              lineColor: _hex(dark ? AppTheme.primaryYellow : AppTheme.primaryBlack),
              lineWidth: 5,
              lineOpacity: 0.85,
              lineJoin: 'round',
            ));
          }
          if (user != null) {
            await controller.addCircle(CircleOptions(
              geometry: user,
              circleRadius: 8,
              circleColor: _hex(AppTheme.locationBlue),
              circleStrokeWidth: 3,
              circleStrokeColor: _hex(AppTheme.white),
            ));
          }
          if (destination != null) {
            await controller.addCircle(CircleOptions(
              geometry: destination,
              circleRadius: 9,
              circleColor: _hex(AppTheme.errorRed),
              circleStrokeWidth: 3,
              circleStrokeColor: _hex(AppTheme.white),
            ));
          }
          if (widget.taxis.isNotEmpty) {
            await controller.addSymbols([
              for (final taxi in widget.taxis)
                SymbolOptions(geometry: taxi, iconImage: _taxiImage, iconSize: 0.4),
            ]);
          }
          _drawnKey = key;
        }

        final assigned = widget.assignedTaxi;
        final symbol = _assignedSymbol;
        if (assigned == null) {
          if (symbol != null) await controller.removeSymbol(symbol);
          _assignedSymbol = null;
        } else if (symbol == null) {
          _assignedSymbol = await controller.addSymbol(
            SymbolOptions(geometry: assigned, iconImage: _taxiImage, iconSize: 0.5),
          );
        } else {
          await controller.updateSymbol(symbol, SymbolOptions(geometry: assigned));
        }
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
                Text(context.l10n.mapLoadError, textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => _loadStyle(
                    Theme.of(context).brightness == Brightness.dark,
                    Localizations.localeOf(context).languageCode,
                  ),
                  child: Text(context.l10n.retry),
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
      trackCameraPosition: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      compassEnabled: false,
    );
  }
}
