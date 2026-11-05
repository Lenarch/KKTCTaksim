import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kktc_taksim/models/ride_session.dart';

/// Yolculuk durumu backend'den değiştiğinde (örn. şoför yolculuğu başlattı) paneli kapatır.
/// [closeOn] durumlarından birine geçilince [onClosed], [resultFor] sonucuyla çağrılır.
mixin RideSheetCloser<T extends StatefulWidget> on State<T> {
  ValueListenable<RideSession?> get session;
  Set<RideStatus> get closeOn;
  bool resultFor(RideStatus status);
  ValueChanged<bool> get onClosed;

  bool _closed = false;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final status = session.value?.status;
    if (_closed || status == null || !closeOn.contains(status) || !mounted) return;
    close(resultFor(status));
  }

  /// Birden fazla kez çağrılması güvenli.
  void close(bool result) {
    if (_closed) return;
    _closed = true;
    onClosed(result);
  }
}
