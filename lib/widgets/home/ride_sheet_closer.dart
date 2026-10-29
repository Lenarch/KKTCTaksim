import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kktc_taksim/models/ride_session.dart';

/// Yolculuk durumu backend'den değiştiğinde (örn. şoför yolculuğu başlattı) açık sheet'i
/// kendiliğinden kapatır. [closeOn] durumlarından birine geçilince sheet,
/// [resultFor] ile verilen sonuçla kapanır; üstünde açık başka bir sheet varsa o da kapanır.
mixin RideSheetCloser<T extends StatefulWidget> on State<T> {
  ValueListenable<RideSession?> get session;
  Set<RideStatus> get closeOn;
  bool resultFor(RideStatus status);

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

  /// Sheet'i (ve üstündeki varsa güvenlik sheet'ini) kapatır; birden fazla kez çağrılması güvenli.
  void close(bool result) {
    if (_closed) return;
    _closed = true;
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r == route);
    navigator.pop(result);
  }
}
