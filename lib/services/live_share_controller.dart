import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/data/repositories/live_share_repository.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Bir yolculuğun canlı konum paylaşımını yönetir: ilk "paylaş"ta başlatır (sonrakiler aynı
/// bağlantıyı verir), yolculuk sürdükçe konumu en fazla [interval]'da bir yazar, yolculuk bitince
/// ya da iptal edilince paylaşımı sonlandırır. Aralık dolmadan gelen son konum kaybolmaz; aralık
/// dolunca yazılır (taksi durunca yeni konum gelmediği için yoksa eski konumda kalıyordu).
class LiveShareController {
  final LiveShareRepository _repository;
  final ValueListenable<RideSession?> _session;
  final Duration interval;
  final DateTime Function() _now;

  String? _shareId;
  Future<String>? _starting;
  DateTime? _lastWrite;

  /// Aralık dolmadan gelmiş, henüz yazılmamış son konum.
  LatLng? _pending;
  Timer? _pendingTimer;

  LiveShareController(
    this._repository,
    this._session, {
    this.interval = AppDurations.liveShareInterval,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _session.addListener(_onSessionChanged);
  }

  bool get isSharing => _shareId != null;

  /// Paylaşımı başlatır (zaten sürüyorsa onu kullanır) ve takip bağlantısını döner.
  Future<Uri> share(LiveShareInfo info, LatLng position) async {
    final starting = _starting ??= _repository.start(info, position);
    try {
      final id = await starting;
      _shareId ??= id;
      _lastWrite ??= _now();
      return _repository.link(id);
    } catch (_) {
      // Başlatılamadıysa bir sonraki denemede yeniden denensin.
      if (identical(_starting, starting)) _starting = null;
      rethrow;
    }
  }

  void _onSessionChanged() {
    final id = _shareId;
    if (id == null) return;
    final session = _session.value;
    if (session == null || session.status.isFinished) {
      stop();
      return;
    }
    final position = session.progress?.position;
    if (position == null) return;
    final last = _lastWrite;
    final wait = last == null ? Duration.zero : interval - _now().difference(last);
    if (wait <= Duration.zero) {
      _write(id, position);
    } else {
      _pending = position;
      _pendingTimer ??= Timer(wait, _flushPending);
    }
  }

  void _flushPending() {
    _pendingTimer = null;
    final id = _shareId;
    final position = _pending;
    if (id != null && position != null) _write(id, position);
  }

  void _write(String id, LatLng position) {
    _pending = null;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _lastWrite = _now();
    // Tek bir yazma düşerse bir sonraki konumla yenisi gider.
    _repository.update(id, position).catchError((_) {});
  }

  /// Paylaşımı bitirir; takip sayfasında "yolculuk bitti" görünür.
  Future<void> stop() async {
    final id = _shareId;
    _shareId = null;
    _starting = null;
    _lastWrite = null;
    _pending = null;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    if (id == null) return;
    try {
      await _repository.end(id);
    } catch (_) {
      // Bitirilemese de paylaşım en geç LiveShareRepository.maxDuration sonra kapanır.
    }
  }

  void dispose() {
    _session.removeListener(_onSessionChanged);
    stop();
  }
}
