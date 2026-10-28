import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/validators.dart';
import 'package:kktc_taksim/main.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/services/map_style_service.dart';

void main() {
  setUpAll(() {
    // Testlerde fontlar internetten indirilmesin.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash ekranı açılır ve rol seçimine geçer', (tester) async {
    await tester.pumpWidget(const TaxiApp(showAds: false));

    expect(find.text('KKTC TAKSİM'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Ben Yolcuyum'), findsOneWidget);
  });

  testWidgets('Giriş formu boşken ana sayfaya geçmez', (tester) async {
    await tester.pumpWidget(const TaxiApp(showAds: false));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ben Yolcuyum'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giriş Yap'));
    await tester.pumpAndSettle();

    expect(find.text('E-posta boş bırakılamaz'), findsOneWidget);
    expect(find.text('Hoş Geldiniz'), findsOneWidget);
  });

  testWidgets('Grup oluştururken 2. adımın alanı 1. adımın yazısını taşımaz', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: CreateSharedRideSheet()),
    ));

    await tester.enterText(find.byType(TextFormField), 'Gazimağusa');
    await tester.pump();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('Nereye?'), findsOneWidget);
    expect(find.text('Gazimağusa'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Lefkoşa');
    await tester.pump();
    final next = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et'));
    expect(next.onPressed, isNotNull);
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

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b.com'), isNull);
    });

    test('password', () {
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('phone', () {
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone('+90 533 123 45 67'), isNull);
    });
  });
}
