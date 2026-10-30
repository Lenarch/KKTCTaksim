import 'package:kktc_taksim/data/repositories/live_share_repository.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Demo: paylaşımlar yalnızca bellekte; bağlantı gerçek bir sayfaya gitmez.
class MockLiveShareRepository implements LiveShareRepository {
  final Map<String, LatLng?> _positions = {};
  int _nextId = 0;

  /// Testler için: paylaşımın son konumu; bitmişse null.
  LatLng? positionOf(String shareId) => _positions[shareId];

  bool isActive(String shareId) => _positions[shareId] != null;

  @override
  Future<String> start(LiveShareInfo info, LatLng position) async {
    final id = 'demo-share-${_nextId++}';
    _positions[id] = position;
    return id;
  }

  @override
  Future<void> update(String shareId, LatLng position) async {
    if (_positions[shareId] == null) throw StateError('Paylaşım bitmiş ya da yok: $shareId');
    _positions[shareId] = position;
  }

  @override
  Future<void> end(String shareId) async => _positions[shareId] = null;

  @override
  Uri link(String shareId) => trackingLink(shareId);
}
