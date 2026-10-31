import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/http_headers.dart';
import 'package:kktc_taksim/models/geo_place.dart';

/// Photon (OpenStreetMap verisi) ile adres arama ve haritadaki bir noktanın adını bulma.
/// Ücretsiz ve anahtarsız; yayından önce kendi sunucumuza taşınmalı.
class GeocodingService {
  static const String _baseUrl = 'https://photon.komoot.io';

  /// Aramaları Kıbrıs adasıyla sınırlar (batı, güney, doğu, kuzey).
  static const String _cyprusBbox = '$cyprusWest,$cyprusSouth,$cyprusEast,$cyprusNorth';

  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<GeoPlace>> search(String query, {LatLng? near}) async {
    final params = {
      'q': query,
      'limit': '8',
      'bbox': _cyprusBbox,
      if (near != null) 'lat': '${near.latitude}',
      if (near != null) 'lon': '${near.longitude}',
    };
    final json = await _get(Uri.parse('$_baseUrl/api/').replace(queryParameters: params));
    return parsePhotonFeatures(json);
  }

  /// Noktaya en yakın adres; bulunamazsa null.
  Future<GeoPlace?> reverse(LatLng point) async {
    final params = {'lat': '${point.latitude}', 'lon': '${point.longitude}', 'limit': '1'};
    final json = await _get(Uri.parse('$_baseUrl/reverse').replace(queryParameters: params));
    return parsePhotonReverse(json, point);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client.get(uri, headers: externalServiceHeaders).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Adres servisi yanıt vermedi (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

/// Photon'un KKTC'deki yerler için verdiği `state`.
const String northCyprusState = 'Kuzey Kıbrıs Türk Cumhuriyeti';

/// Ters aramada en yakın sonuç çoğu zaman bir dükkân ya da bina olur; yolcuya
/// tanıdık gelsin diye ad olarak sokak, yoksa semt/şehir kullanılır.
/// Konum olarak sonucun kendisi değil, seçilen [point] döner.
@visibleForTesting
GeoPlace? parsePhotonReverse(Map<String, dynamic> json, LatLng point) {
  final features = (json['features'] as List? ?? const []).cast<Map<String, dynamic>>();
  if (features.isEmpty) return null;
  final props = features.first['properties'] as Map<String, dynamic>? ?? const {};

  final street = [props['street'], props['housenumber']].whereType<String>().join(' ');
  final area = [props['district'], props['city']].whereType<String>().toSet().join(', ');
  final name = street.isNotEmpty ? street : (area.isNotEmpty ? area : props['name'] as String?);
  if (name == null) return null;
  return GeoPlace(name: name, address: name == area || area.isEmpty ? null : area, position: point);
}

@visibleForTesting
List<GeoPlace> parsePhotonFeatures(Map<String, dynamic> json) {
  final places = <GeoPlace>[];
  for (final feature in (json['features'] as List? ?? const []).cast<Map<String, dynamic>>()) {
    final props = feature['properties'] as Map<String, dynamic>? ?? const {};
    // Hizmet yalnızca KKTC'de; Güney Kıbrıs sonuçlarında `state` "Κύπρος" geliyor.
    final state = props['state'];
    if (state is String && state != northCyprusState) continue;
    final coordinates = (feature['geometry']?['coordinates'] as List?)?.cast<num>();
    if (coordinates == null || coordinates.length < 2) continue;

    final street = [props['street'], props['housenumber']].whereType<String>().join(' ');
    final name = props['name'] as String? ?? (street.isNotEmpty ? street : props['city'] as String?);
    if (name == null) continue;

    final details = <String>{
      if (street.isNotEmpty && street != name) street,
      for (final key in ['district', 'city', 'county'])
        if (props[key] is String && props[key] != name) props[key] as String,
    };

    places.add(GeoPlace(
      name: name,
      address: details.isEmpty ? null : details.take(2).join(', '),
      position: LatLng(coordinates[1].toDouble(), coordinates[0].toDouble()),
    ));
  }
  return places;
}
