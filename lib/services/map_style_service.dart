import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenFreeMap (OpenStreetMap verisi) harita stillerini indirir ve etiketleri
/// istenen dile çevirir. Vektör karolarda her yerin adı birçok dilde
/// (`name:tr`, `name:en`...) bulunduğu için hangisinin gösterileceğini stil belirler.
class MapStyleService {
  static const String _baseUrl = 'https://tiles.openfreemap.org/styles/';

  final http.Client _client;
  final Map<String, String> _cache = {};

  MapStyleService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> load({required bool dark, required String languageCode}) async {
    final styleName = dark ? 'dark' : 'liberty';
    final cacheKey = '$styleName/$languageCode';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final response = await _client.get(Uri.parse('$_baseUrl$styleName'));
    if (response.statusCode != 200) {
      throw Exception('Harita stili yüklenemedi (${response.statusCode})');
    }

    final style = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    localizeLabels(style, languageCode);
    return _cache[cacheKey] = jsonEncode(style);
  }
}

/// Yer adı gösteren her etiketi önce [languageCode] dilindeki adı, yoksa
/// Latin harfli adı, o da yoksa yerel adı gösterecek şekilde değiştirir.
@visibleForTesting
void localizeLabels(Map<String, dynamic> style, String languageCode) {
  final localizedName = [
    'coalesce',
    ['get', 'name:$languageCode'],
    ['get', 'name:latin'],
    ['get', 'name'],
  ];

  for (final layer in (style['layers'] as List).cast<Map<String, dynamic>>()) {
    final layout = layer['layout'] as Map<String, dynamic>?;
    final textField = layout?['text-field'];
    // Yol numarası ("ref") veya kapı numarası gibi ad içermeyen etiketlere dokunma.
    if (textField == null || !jsonEncode(textField).contains('"name')) continue;
    layout!['text-field'] = localizedName;
  }
}
