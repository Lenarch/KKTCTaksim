import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kktc_taksim/core/http_headers.dart';
import 'package:kktc_taksim/core/fare_calculator.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/map_style_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  const lefkosa = LatLng(35.1856, 33.3823);
  const girne = LatLng(35.3412, 33.3196);

  group('FareCalculator', () {
    test('mesafeye göre artar ve ±%10 aralık verir', () {
      final fare = FareCalculator.estimate(10, TaxiType.economy);
      // 100 + 40 × 10 = 500
      expect(fare.low, 450);
      expect(fare.high, 550);
      expect(fare.typical, 500);
      expect(FareCalculator.estimate(30, TaxiType.economy).low, greaterThan(fare.high));
    });

    test('büyük araç daha pahalı, kısa yolculukta en düşük ücret uygulanır', () {
      final economy = FareCalculator.estimate(5, TaxiType.economy);
      final xl = FareCalculator.estimate(5, TaxiType.xl);
      expect(xl.low, greaterThan(economy.low));
      expect(FareCalculator.estimate(0.1, TaxiType.economy).typical, greaterThanOrEqualTo(Tariff.minimumFare - 10));
    });
  });

  group('geo', () {
    test('Lefkoşa–Girne kuş uçuşu yaklaşık 18 km', () {
      expect(distanceMeters(lefkosa, girne), inInclusiveRange(17000, 19000));
    });

    test('pointAlong çizginin başını, ortasını ve sonunu verir', () {
      const path = [LatLng(35.0, 33.0), LatLng(35.0, 33.2)];
      expect(pointAlong(path, 0), path.first);
      expect(pointAlong(path, 1), path.last);
      expect(pointAlong(path, 0.5).longitude, closeTo(33.1, 0.001));
    });
  });

  group('RoutingService', () {
    test('OSRM yanıtından rota, mesafe ve süre okunur', () async {
      final client = MockClient((_) async => http.Response(
            '{"code":"Ok","routes":[{"distance":20500.5,"duration":1500,'
            '"geometry":{"coordinates":[[33.38,35.18],[33.35,35.25],[33.32,35.34]]}}]}',
            200,
          ));
      final route = await RoutingService(client: client).route(lefkosa, girne);
      expect(route.isApproximate, isFalse);
      expect(route.points, hasLength(3));
      expect(route.points.first, const LatLng(35.18, 33.38));
      expect(route.durationMinutes, 25);
    });

    test('servis hata verirse kuş uçuşundan tahmin edilir', () async {
      final client = MockClient((_) async => http.Response('hata', 500));
      final route = await RoutingService(client: client).route(lefkosa, girne);
      expect(route.isApproximate, isTrue);
      expect(route.distanceMeters, greaterThan(distanceMeters(lefkosa, girne)));
    });
  });

  test("Photon'a uygulamanın kimliğiyle istek gider (varsayılan Dart kimliği 403 alıyordu)", () async {
    http.Request? sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response('{"features":[]}', 200);
    });
    await GeocodingService(client: client).search('Girne');
    expect(sent!.headers['User-Agent'], appUserAgent);
  });

  test('Adres aramasında Güney Kıbrıs sonuçları elenir', () {
    Map<String, dynamic> feature(String name, String? state) => {
          'properties': {'name': name, if (state != null) 'state': state},
          'geometry': {
            'coordinates': [33.3, 35.2],
          },
        };
    final places = parsePhotonFeatures({
      'features': [
        feature('Girne', northCyprusState),
        feature('Λάρνακα', 'Κύπρος'),
        feature('Bilinmeyen', null),
      ],
    });
    expect(places.map((p) => p.name), ['Girne', 'Bilinmeyen']);
  });

  test('Kıbrıs dışındaki konum hizmet bölgesi sayılmaz', () {
    expect(isInCyprus(const LatLng(35.1856, 33.3823)), isTrue);
    expect(isInCyprus(const LatLng(37.4220, -122.0841)), isFalse);
    expect(isInCyprus(const LatLng(41.0082, 28.9784)), isFalse);
  });

  test('Photon sonuçları ad, adres ve konuma çevrilir', () {
    final places = parsePhotonFeatures({
      'features': [
        {
          'geometry': {
            'coordinates': [33.5035, 35.1517],
          },
          'properties': {'name': 'Ercan Uluslararası Havalimanı', 'city': 'Meriç', 'county': 'Lefkoşa ilçesi'},
        },
        {
          'geometry': {
            'coordinates': [33.36, 35.19],
          },
          'properties': {'street': 'Dereboyu Caddesi', 'housenumber': '12', 'city': 'Lefkoşa'},
        },
        {'geometry': null, 'properties': {'name': 'Konumsuz'}},
      ],
    });

    expect(places, hasLength(2));
    expect(places[0].name, 'Ercan Uluslararası Havalimanı');
    expect(places[0].address, 'Meriç, Lefkoşa ilçesi');
    expect(places[0].position, const LatLng(35.1517, 33.5035));
    expect(places[1].name, 'Dereboyu Caddesi 12');
    expect(places[1].address, 'Lefkoşa');
  });

  test('Ters aramada dükkân adı yerine sokak ve semt kullanılır', () {
    const point = LatLng(35.19, 33.38);
    final place = parsePhotonReverse({
      'features': [
        {
          'geometry': {
            'coordinates': [33.3801, 35.1902],
          },
          'properties': {'name': 'Bir Dükkân', 'street': 'Mehmet Akif Caddesi', 'district': 'Dereboyu', 'city': 'Lefkoşa'},
        },
      ],
    }, point);

    expect(place!.name, 'Mehmet Akif Caddesi');
    expect(place.address, 'Dereboyu, Lefkoşa');
    expect(place.position, point);
    expect(parsePhotonReverse({'features': []}, point), isNull);
  });

  test('Telefon doğrulayıcı', () {
    final l10n = lookupAppLocalizations(const Locale('tr'));
    expect(Validators.phone(l10n, ''), l10n.phoneRequired);
    expect(Validators.phone(l10n, '123'), l10n.phoneInvalid);
    expect(Validators.phone(l10n, '+90 533 123 45 67'), isNull);
  });

  test('Harita etiketleri istenen dile çevrilir, ad içermeyenlere dokunulmaz', () {
    final style = <String, dynamic>{
      'layers': [
        {
          'id': 'place',
          'layout': {
            'text-field': ['coalesce', ['get', 'name:latin'], ['get', 'name']],
          },
        },
        {
          'id': 'road_shield',
          'layout': {'text-field': '{ref}'},
        },
        {'id': 'water'},
      ],
    };

    localizeLabels(style, 'tr');

    final layers = style['layers'] as List;
    expect(layers[0]['layout']['text-field'], [
      'coalesce',
      ['get', 'name:tr'],
      ['get', 'name:latin'],
      ['get', 'name'],
    ]);
    expect(layers[1]['layout']['text-field'], '{ref}');
  });
}
