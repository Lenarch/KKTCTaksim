import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/main.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/screens/my_trips_screen.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/widgets/home/taxi_selection_sheet.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ekranı uygulamanın teması ve dil dosyalarıyla sarar.
Widget localized(Widget home, {Locale locale = const Locale('tr')}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: home,
  );
}

Future<void> signIn({String? name}) async {
  final auth = Backend.instance.auth;
  await auth.sendCode('+90 533 123 45 67');
  await auth.verifyCode('1' * auth.codeLength);
  if (name != null) await auth.updateName(name);
}

Future<void> openSplashAndChooseRole(WidgetTester tester) async {
  await tester.pumpWidget(const TaxiApp(showAds: false));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Testlerde fontlar internetten indirilmesin.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.locale.value = const Locale('tr');
    Backend.instance = Backend.mock();
  });

  testWidgets('Splash ekranı açılır ve rol seçimine geçer', (tester) async {
    await tester.pumpWidget(const TaxiApp(showAds: false));

    expect(find.text('KKTC TAKSİM'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Ben Yolcuyum'), findsOneWidget);
  });

  testWidgets('Daha önce giriş yapılmışsa açılışta doğrudan ana sayfaya gidilir', (tester) async {
    await signIn(name: 'Ayşe Demir');
    await openSplashAndChooseRole(tester);

    expect(find.text('Ben Yolcuyum'), findsNothing);
    expect(find.text('Merhaba Ayşe 👋'), findsOneWidget);
  });

  testWidgets('Dil İngilizce seçilince metinler İngilizce görünür', (tester) async {
    AppSettings.instance.locale.value = const Locale('en');
    await openSplashAndChooseRole(tester);

    expect(find.text("I'm a Passenger"), findsOneWidget);
  });

  testWidgets('Giriş yalnızca telefonla yapılır; boş numarayla ilerlemez', (tester) async {
    await openSplashAndChooseRole(tester);
    await tester.tap(find.text('Ben Yolcuyum'));
    await tester.pumpAndSettle();

    expect(find.text('E-posta'), findsNothing);
    await tester.tap(find.text('Kod Gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Telefon numarası boş bırakılamaz'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '+90 533 123 45 67');
    await tester.tap(find.text('Kod Gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Doğrulama Kodu'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(Backend.instance.auth.codeLength));
  });

  testWidgets('Grup oluştururken 2. adımın alanı 1. adımın yazısını taşımaz', (tester) async {
    await tester.pumpWidget(localized(const Scaffold(body: CreateSharedRideSheet())));

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

  testWidgets('Grup oluşturmanın son adımında tarih ve kişi başı ücret sorulur', (tester) async {
    await tester.pumpWidget(localized(const Scaffold(body: CreateSharedRideSheet())));

    for (final place in ['Girne', 'Lefkoşa']) {
      await tester.enterText(find.byType(TextFormField), place);
      await tester.pump();
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Tarih'), findsOneWidget);
    expect(find.text('Kişi başı ücret'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    final create = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur'));
    expect(create.onPressed, isNull, reason: 'Ücret girilmeden grup oluşturulamaz');
  });

  testWidgets('Paylaşımlı yolculukta katılınan gruptan ayrılınabilir', (tester) async {
    await signIn();
    await tester.pumpWidget(localized(const SharedRideScreen()));
    await tester.pumpAndSettle();

    expect(find.text('kişi başı'), findsWidgets);
    await tester.tap(find.text('Katıl').first);
    await tester.pumpAndSettle();
    expect(find.text('Ayrıl'), findsOneWidget);

    await tester.tap(find.text('Ayrıl'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ayrıl'));
    await tester.pumpAndSettle();

    expect(find.text('Ayrıl'), findsNothing);
    expect(find.text('Katıl'), findsNWidgets(2));
  });

  testWidgets('Taksi seçiminde tahmini fiyat, ödeme yöntemi ve zaman seçilir', (tester) async {
    const route = RouteInfo(
      points: [LatLng(35.1856, 33.3823), LatLng(35.1518, 33.5035)],
      distanceMeters: 25000,
      durationSeconds: 1800,
    );
    RideRequest? result;

    await tester.pumpWidget(localized(Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            result = await showModalBottomSheet<RideRequest>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const TaxiSelectionSheet(
                pickup: GeoPlace(name: 'Lefkoşa', position: LatLng(35.1856, 33.3823)),
                destination: GeoPlace(name: 'Ercan Havalimanı', position: LatLng(35.1518, 33.5035)),
                route: route,
              ),
            );
          },
          child: const Text('aç'),
        ),
      ),
    )));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.text('25,0 km • 30 dk'), findsOneWidget);
    // Ekonomik, 25 km: (100 + 40 × 25) ± %10
    expect(find.text('₺990 – ₺1.210'), findsOneWidget);

    await tester.tap(find.text('Kart'));
    await tester.pump();
    await tester.tap(find.text('Konfor'));
    await tester.pump();
    await tester.ensureVisible(find.text('TAKSİ ÇAĞIR'));
    await tester.tap(find.text('TAKSİ ÇAĞIR'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.payment, PaymentMethod.card);
    expect(result!.taxiType, TaxiType.comfort);
    expect(result!.scheduledAt, isNull);
  });

  testWidgets('Planlanan yolculuk Yaklaşan sekmesinde görünür ve iptal edilebilir', (tester) async {
    await Backend.instance.trips.add(Trip(
      id: 'test',
      from: 'Lefkoşa',
      to: 'Ercan Havalimanı',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      price: 1100,
      status: TripStatus.upcoming,
      taxiType: TaxiType.economy,
      payment: PaymentMethod.cash,
    ));
    await tester.pumpWidget(localized(MyTripsScreen(onCallTaxi: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Planlandı'), findsOneWidget);
    await tester.tap(find.text('İptal Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'İptal Et').last);
    await tester.pumpAndSettle();

    expect(find.text('Planlandı'), findsNothing);
    // Akışı burada `await ... .first` ile okumak sahte zamanlı widget testinde takılıyor;
    // sonucu ekrandan, "İptal Edilen" sekmesinden kontrol ediyoruz.
    await tester.tap(find.text('İptal Edilen'));
    await tester.pumpAndSettle();
    expect(find.text('Ercan Havalimanı'), findsOneWidget);
  });
}
