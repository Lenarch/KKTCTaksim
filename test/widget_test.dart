import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/assistant_repository.dart';
import 'package:kktc_taksim/data/mock/mock_assistant_repository.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/home/active_trip_sheet.dart';
import 'package:kktc_taksim/widgets/group_failure_dialog.dart';
import 'package:kktc_taksim/widgets/home/assistant_sheet.dart';
import 'package:kktc_taksim/widgets/home/driver_found_sheet.dart';
import 'package:kktc_taksim/screens/group_chat_screen.dart';
import 'package:kktc_taksim/data/mock/mock_shared_ride_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/pickup.dart';
import 'package:kktc_taksim/screens/driver/driver_shell.dart';
import 'package:kktc_taksim/data/mock/mock_driver_repository.dart';
import 'package:kktc_taksim/models/ride_offer.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/main.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/screens/home_screen.dart';
import 'package:kktc_taksim/screens/main_navigation_screen.dart';
import 'package:kktc_taksim/screens/my_trips_screen.dart';
import 'package:kktc_taksim/screens/profile_screen.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/services/chat_read_state.dart';
import 'package:kktc_taksim/core/group_fare.dart';
import 'package:kktc_taksim/widgets/join_group_sheet.dart';
import 'package:kktc_taksim/widgets/pickup_chooser.dart';
import 'package:intl/intl.dart';
import 'package:kktc_taksim/services/trusted_clock.dart';
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

/// Grup formunda "Konum seç"e basıp son gidilen yerlerden birini seçer (ağ gerekmez).
Future<void> chooseRecentPlace(WidgetTester tester, String name) async {
  await tester.tap(find.text('Konum seç'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Rota servisi her istekte [meters] metrelik bir yol döndürür (kuş uçuşundan uzun seçilmeli).
RoutingService groupRouting([int meters = 40000]) => RoutingService(
      client: MockClient((_) async => http.Response(
          '{"code":"Ok","routes":[{"distance":$meters,"duration":300,'
          '"geometry":{"coordinates":[[33.32,35.34],[33.33,35.35]]}}]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'})),
    );

/// Grup formunda nereden ve nereye yerlerini seçip 3. adıma kadar ilerler.
Future<void> fillGroupPlaces(WidgetTester tester, List<String> places) async {
  for (final place in places) {
    await chooseRecentPlace(tester, place);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    await tester.pumpAndSettle();
  }
}

/// Açılan katılma sayfasındaki onay düğmesine basar.
Future<void> confirmJoinSheet(WidgetTester tester, {String label = 'Katıl'}) async {
  final button = find.descendant(of: find.byType(JoinGroupSheet), matching: find.widgetWithText(ElevatedButton, label));
  await tester.tap(button);
  await tester.pumpAndSettle();
}

String liraTr(int amount) => '₺${NumberFormat.decimalPattern('tr').format(amount)}';

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
    ChatReadState.instance.lastRead.value = const {};
    // Testler ağa çıkmasın.
    TrustedClock.instance.reset();
    TrustedClock.instance.serverTimeSource = () async => null;
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

  testWidgets('Grup formunda nereden/nereye yazılamaz, yalnızca konum seçilir', (tester) async {
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(routing: groupRouting()))));

    // Serbest yazı yok: küfür, selam ya da isim girilemez.
    expect(find.byType(TextField), findsNothing);
    Finder next() => find.widgetWithText(ElevatedButton, 'Devam Et');
    expect(tester.widget<ElevatedButton>(next()).onPressed, isNull);

    await chooseRecentPlace(tester, 'Ercan Havalimanı');
    expect(find.text('Ercan Havalimanı'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(next()).onPressed, isNotNull);

    await tester.tap(next());
    await tester.pumpAndSettle();
    // 2. adım boş başlar, 1. adımın seçimini taşımaz.
    expect(find.text('Nereye?'), findsOneWidget);
    expect(find.text('Ercan Havalimanı'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.widget<ElevatedButton>(next()).onPressed, isNull);
  });

  testWidgets('Grup formunda konum haritadan da seçilir, adı adres servisinden gelir', (tester) async {
    const reverse = '{"features":[{"properties":{"name":"Kafe","street":"Ziya Rızkı Caddesi","city":"Girne",'
        '"state":"Kuzey Kıbrıs Türk Cumhuriyeti"},"geometry":{"coordinates":[33.32,35.34]}}]}';
    final geocoding = GeocodingService(
      client: MockClient((_) async => http.Response(reverse, 200, headers: {'content-type': 'application/json; charset=utf-8'})),
    );
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(geocoding: geocoding, routing: groupRouting()))));

    await tester.tap(find.text('Konum seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haritadan seç'));
    // Harita sürekli çizildiği için pumpAndSettle beklemez.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Bu Noktayı Seç'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Ziya Rızkı Caddesi'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNotNull);
  });

  testWidgets('Haritada adı bulunamayan nokta gruba yer olarak seçilemez', (tester) async {
    // KKTC dışı ya da denizde: adres servisi sonuç vermez.
    final geocoding = GeocodingService(client: MockClient((_) async => http.Response('{"features":[]}', 200)));
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(geocoding: geocoding, routing: groupRouting()))));

    await tester.tap(find.text('Konum seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haritadan seç'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Bu Noktayı Seç'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Burada bir adres bulunamadı. İğneyi KKTC içinde bir yere getir.'), findsOneWidget);
    expect(find.text('İşaretlenen konum'), findsNothing);
    // Harita açık kalır; vazgeçilince seçim boş kalır.
    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Konum seç'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNull);
  });

  testWidgets('Grupta nereden ve nereye aynı yer olamaz', (tester) async {
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(routing: groupRouting()))));
    await chooseRecentPlace(tester, 'Ercan Havalimanı');
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await chooseRecentPlace(tester, 'Ercan Havalimanı');

    expect(find.text('Varış noktası başlangıç noktasıyla aynı olamaz.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNull);

    // Geri dönünce ilk seçim durur.
    await tester.tap(find.text('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Ercan Havalimanı'), findsOneWidget);
  });

  testWidgets('Oluşturulan grup seçilen yerlerin adını, noktalarını ve varsayılan toplama noktasını taşır', (tester) async {
    ({SharedRide draft, Pickup pickup})? created;
    await tester.pumpWidget(localized(Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async => created = await showModalBottomSheet<({SharedRide draft, Pickup pickup})>(
            context: context,
            isScrollControlled: true,
            builder: (_) => CreateSharedRideSheet(routing: groupRouting()),
          ),
          child: const Text('aç'),
        ),
      ),
    )));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await fillGroupPlaces(tester, ['Girne Yat Limanı', 'Ercan Havalimanı']);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur'));
    await tester.pumpAndSettle();

    expect(created?.draft.from, 'Girne Yat Limanı');
    expect(created?.draft.to, 'Ercan Havalimanı');
    expect(created?.draft.fromPoint, isNotNull);
    expect(created!.draft.baseMeters, greaterThan(0));
    expect(created!.pickup.detourMeters, 0);
    expect(created!.pickup.place.name, 'Girne Yat Limanı');
  });

  testWidgets('Grup formunda kişi başı ücret sorulmaz; 3. adımda tahmin görünür ve kapasiteyle değişir', (tester) async {
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(routing: groupRouting()))));
    await fillGroupPlaces(tester, ['Girne Yat Limanı', 'Ercan Havalimanı']);

    expect(find.text('Tarih'), findsOneWidget);
    expect(find.text('Kişi başı ücret'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    // 40 km yol: toplam ₺1.700; 4 kişide kişi başı ₺430.
    expect(find.text('Tek kişiyle ₺1.700, grup dolarsa kişi başı yaklaşık ₺430'), findsOneWidget);
    expect(find.text('5 ve üzeri kişilik gruplar büyük araç tarifesiyle hesaplanır.'), findsNothing);

    // 5 kişi: büyük araç tarifesi (×1,8) → toplam ₺3.060; kişi başı ₺620.
    tester.widget<Slider>(find.byType(Slider)).onChanged!(5);
    await tester.pump();
    expect(find.text('Tek kişiyle ₺3.060, grup dolarsa kişi başı yaklaşık ₺620'), findsOneWidget);
    expect(find.text('5 ve üzeri kişilik gruplar büyük araç tarifesiyle hesaplanır.'), findsOneWidget);
  });

  testWidgets('Rota hesaplanırken 3. adımda ilerleme görünür ve Devam kapalıdır', (tester) async {
    final response = Completer<http.Response>();
    final routing = RoutingService(client: MockClient((_) => response.future));
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(routing: routing))));
    await chooseRecentPlace(tester, 'Girne Yat Limanı');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    await tester.pumpAndSettle();
    await chooseRecentPlace(tester, 'Ercan Havalimanı');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    // İlerleme göstergesi sürekli çizildiği için pumpAndSettle beklemez (ve rota zaman aşımına uğrardı).
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Tek kişiyle'), findsNothing);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNull);

    response.complete(http.Response(
        '{"code":"Ok","routes":[{"distance":40000,"duration":300,"geometry":{"coordinates":[[33.32,35.34],[33.33,35.35]]}}]}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Tek kişiyle'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNotNull);
  });

  testWidgets('Toplama noktası adımı nereden seçimini buluşma noktası yapar; nereden değişince sıfırlanır', (tester) async {
    await tester.pumpWidget(localized(Scaffold(body: CreateSharedRideSheet(routing: groupRouting()))));
    await fillGroupPlaces(tester, ['Girne Yat Limanı', 'Ercan Havalimanı']);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('Seni nereden alalım?'), findsOneWidget);
    expect(find.text('Girne Yat Limanı'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur')).onPressed, isNotNull);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Geri'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Girne Yat Limanı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gazimağusa Surlariçi'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Gazimağusa Surlariçi'), findsOneWidget);
    expect(find.text('Girne Yat Limanı'), findsNothing);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur')).onPressed, isNotNull);
  });

  testWidgets('Giriş yapmadan grup açılmak istenirse giriş yapılması söylenir', (tester) async {
    await tester.pumpWidget(localized(const SharedRideScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grup Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Grup açmak ya da gruba katılmak için giriş yapmalısın.'), findsOneWidget);
    expect(find.text('Nereden?'), findsNothing);
  });

  test('Hata kodu Firebase mesajından çıkarılır', () {
    expect(errorCode(Exception('[cloud_firestore/permission-denied] Missing or insufficient permissions.')),
        'cloud_firestore/permission-denied');
    expect(errorCode(StateError('x')), 'StateError');
  });

  testWidgets('Paylaşımlı yolculukta katılınan gruptan ayrılınabilir', (tester) async {
    await signIn();
    await tester.pumpWidget(localized(const SharedRideScreen()));
    await tester.pumpAndSettle();

    expect(find.text('kişi başı'), findsWidgets);
    await tester.tap(find.text('Katıl').first);
    await tester.pumpAndSettle();
    await confirmJoinSheet(tester);
    expect(find.text('Ayrıl'), findsOneWidget);

    await tester.tap(find.text('Ayrıl'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ayrıl'));
    await tester.pumpAndSettle();

    expect(find.text('Ayrıl'), findsNothing);
    expect(find.text('Katıl'), findsNWidgets(2));
  });

  testWidgets('Katılınan grubun sohbetine mesaj yazılır; başkasının mesajı rozet gösterir', (tester) async {
    final shared = Backend.instance.sharedRides;
    // Önce başka bir yolcu gruba katılıp yazar.
    await signIn(name: 'Mehmet');
    await shared.join('demo-group-1', Pickup(place: MockData.sharedRides().first.meetingPlace!, detourMeters: 0));
    await shared.sendMessage('demo-group-1', 'Havalimanına bavulla geleceğim');

    await Backend.instance.auth.sendCode('+90 542 111 22 33');
    await Backend.instance.auth.verifyCode('1' * Backend.instance.auth.codeLength);
    await tester.pumpWidget(localized(const SharedRideScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Grup sohbeti'), findsNothing);

    await tester.tap(find.text('Katıl').first);
    await tester.pumpAndSettle();
    await confirmJoinSheet(tester);
    expect(find.text('Grup sohbeti • Yeni mesaj var'), findsOneWidget);

    // "Gruba katıldın" bildirimi kaybolsun; düğmenin üstünü kapatıyor.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Grup sohbeti • Yeni mesaj var'));
    await tester.tap(find.text('Grup sohbeti • Yeni mesaj var'));
    await tester.pumpAndSettle();
    expect(find.text('Havalimanına bavulla geleceğim'), findsOneWidget);
    expect(find.text('Mehmet'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('chatInput')), 'Ben de, 14:00 görüşürüz');
    await tester.tap(find.byTooltip('Gönder'));
    await tester.pumpAndSettle();
    expect(find.text('Ben de, 14:00 görüşürüz'), findsOneWidget);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Grup sohbeti'), findsOneWidget);
  });

  testWidgets('Profil > Hesabımı Sil: onay ve SMS kodundan sonra hesap silinir', (tester) async {
    await signIn(name: 'Ayşe');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      routes: {
        '/': (_) => const ProfileScreen(),
        AppRoutes.roleSelection: (_) => const Scaffold(body: Text('ROL SEÇİMİ')),
      },
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Hesabımı Sil'), 200);
    await tester.tap(find.text('Hesabımı Sil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kalıcı olarak silinecek'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Hesabımı Sil'));
    await tester.pumpAndSettle();

    // Yeniden doğrulama ekranı
    expect(find.text('Doğrulama Kodu'), findsOneWidget);
    for (var i = 0; i < Backend.instance.auth.codeLength; i++) {
      await tester.enterText(find.byType(TextField).at(i), '1');
      await tester.pump();
    }
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    expect(Backend.instance.auth.currentUser, isNull);
    expect(find.text('ROL SEÇİMİ'), findsOneWidget);
    expect(find.text('Hesabın ve verilerin silindi.'), findsOneWidget);
  });

  testWidgets('Sohbette başkasının mesajı şikâyet edilir; engellenen kişinin mesajı gizlenir', (tester) async {
    final shared = Backend.instance.sharedRides as MockSharedRideRepository;
    await signIn(name: 'Mehmet');
    await shared.join('demo-group-1', Pickup(place: MockData.sharedRides().first.meetingPlace!, detourMeters: 0));
    await shared.sendMessage('demo-group-1', 'Kaba bir mesaj');
    final mehmet = Backend.instance.auth.currentUser!.id;

    await Backend.instance.auth.sendCode('+90 542 111 22 33');
    await Backend.instance.auth.verifyCode('1' * Backend.instance.auth.codeLength);
    await shared.join('demo-group-1', Pickup(place: MockData.sharedRides().first.meetingPlace!, detourMeters: 0));
    // Widget testinde akışı `await ….first` ile beklemek testi kilitler; grup örnek veriden alınır.
    final ride = MockData.sharedRides().firstWhere((r) => r.id == 'demo-group-1');
    await tester.pumpWidget(localized(GroupChatScreen(ride: ride)));
    await tester.pumpAndSettle();

    // Şikâyet
    await tester.longPress(find.text('Kaba bir mesaj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Şikâyet et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hakaret veya taciz'));
    await tester.pumpAndSettle();
    expect(find.text('Teşekkürler, şikâyetin incelenmek üzere iletildi.'), findsOneWidget);
    expect(shared.reports.single.$2.senderId, mehmet);
    expect(shared.reports.single.$3, ReportReason.harassment);

    // Engelle
    await tester.longPress(find.text('Kaba bir mesaj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu kişiyi engelle'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Bu kişiyi engelle'));
    await tester.pumpAndSettle();
    expect(find.text('Kaba bir mesaj'), findsNothing);
    expect(find.text('Engellediğin bir kişinin mesajı'), findsOneWidget);
    final latest = await tester.runAsync(() => shared.watchLatestMessage('demo-group-1').first);
    final blocked = await tester.runAsync(() => shared.watchBlocked().first);
    expect(blocked, {mehmet});
    expect(
      ChatReadState.instance.isUnread('demo-group-1', latest, Backend.instance.auth.currentUser!.id, blocked: blocked!),
      isFalse,
    );

    // Engeli kaldır
    await tester.longPress(find.text('Engellediğin bir kişinin mesajı'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Engeli kaldır'));
    await tester.pumpAndSettle();
    expect(find.text('Kaba bir mesaj'), findsOneWidget);
  });

  testWidgets('Şoför modu: kayıt formu, ardından kabul edilen yolculuk sırayla ilerletilir', (tester) async {
    await signIn(name: 'Ahmet Yılmaz');
    final drivers = Backend.instance.drivers as MockDriverRepository;
    await tester.pumpWidget(localized(const DriverShell()));
    await tester.pumpAndSettle();

    // İlk giriş: kayıt formu (ad girişten gelir).
    expect(find.text('Şoför kaydı'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Plaka'), 'abc 123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Araç (marka, model)'), 'Toyota Corolla');
    await tester.tap(find.text('Kaydı tamamla'));
    await tester.pumpAndSettle();
    expect(find.text('Çevrimdışısın'), findsOneWidget);
    expect(find.text('Ahmet Yılmaz • ABC 123'), findsOneWidget);

    // Konum eklentisi testte çalışmadığı için çevrimiçi olma ve kabul repository üzerinden.
    const here = LatLng(35.1856, 33.3823);
    await drivers.setOnline(true, here);
    const offer = RideOffer(
      id: 'r1',
      passengerId: 'yolcu',
      pickup: GeoPlace(name: 'Lefkoşa Surlariçi', position: here),
      destination: GeoPlace(name: 'Girne Limanı', position: LatLng(35.3412, 33.3196)),
      distanceMeters: 25000,
      durationSeconds: 1800,
      taxiType: TaxiType.economy,
      payment: PaymentMethod.cash,
      fareLow: 990,
      fareHigh: 1210,
      status: RideStatus.searching,
    );
    drivers.addRequest(offer);
    await drivers.accept(offer, here);
    await tester.pumpAndSettle();

    expect(find.text('Yolcuya git'), findsOneWidget);
    expect(find.text('Lefkoşa Surlariçi'), findsOneWidget);
    // Uygulama içi rota haritada; sesli tarif isteyen için Google Haritalar yedek.
    expect(find.text("Google Haritalar'da aç"), findsOneWidget);
    await tester.tap(find.text('Vardım'));
    await tester.pumpAndSettle();
    expect(find.text('Yolcuyu al'), findsOneWidget);
    await tester.tap(find.text('Yolculuğu başlat'));
    await tester.pumpAndSettle();
    expect(find.text('Yolculuk sürüyor'), findsOneWidget);
    expect(find.text('Çağrıyı iptal et'), findsNothing);
    await tester.tap(find.text('Yolculuğu bitir'));
    await tester.pumpAndSettle();
    expect(find.text('Yolculuk tamamlandı.'), findsOneWidget);
    expect(drivers.rideById('r1')!.status, RideStatus.completed);
    expect(find.text('Şu an bekleyen çağrı yok. Yeni çağrılar burada görünecek.'), findsNothing);
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

  group('YZ asistanı', () {
    const photon = '{"features":[{"properties":{"name":"Girne Antik Limanı","state":"Kuzey Kıbrıs Türk Cumhuriyeti"},'
        '"geometry":{"coordinates":[33.32,35.34]}}]}';

    Future<GeoPlace?> openAssistant(WidgetTester tester, {Future<void> Function()? afterAsk}) async {
      GeoPlace? chosen;
      await tester.pumpWidget(localized(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              chosen = await showModalBottomSheet<GeoPlace>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AssistantSheet(
                  geocoding: GeocodingService(client: MockClient((_) async => http.Response(photon, 200, headers: {'content-type': 'application/json; charset=utf-8'}))),
                  near: const LatLng(35.18, 33.38),
                ),
              );
            },
            child: const Text('aç'),
          ),
        ),
      )));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await afterAsk?.call();
      return chosen;
    }

    testWidgets('ilk kullanımda onay ister, öneri gelir, Taksi çağır yeri döndürür', (tester) async {
      Backend.instance = Backend.mock();
      GeoPlace? chosen;
      await tester.pumpWidget(localized(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              chosen = await showModalBottomSheet<GeoPlace>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AssistantSheet(
                  geocoding: GeocodingService(client: MockClient((_) async => http.Response(photon, 200, headers: {'content-type': 'application/json; charset=utf-8'}))),
                  near: const LatLng(35.18, 33.38),
                ),
              );
            },
            child: const Text('aç'),
          ),
        ),
      )));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Akşam yemeği'));
      await tester.pumpAndSettle();
      expect(find.text('Yapay zekâ ile paylaşım'), findsOneWidget);
      await tester.tap(find.text('Devam et'));
      await tester.pumpAndSettle();

      expect(find.text('Girne Antik Limanı'), findsWidgets);
      await tester.ensureVisible(find.text('Taksi çağır').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taksi çağır').first);
      await tester.pumpAndSettle();
      expect(chosen?.name, 'Girne Antik Limanı');
      expect(await AppSettings.instance.assistantConsented(), isTrue);
    });

    testWidgets('servis hata verirse anlaşılır mesaj gösterilir', (tester) async {
      (Backend.instance.assistant as MockAssistantRepository).failWith = AssistantError.failed;
      SharedPreferences.setMockInitialValues({'assistantConsent': true});
      await openAssistant(tester);
      await tester.tap(find.text('Doğa ve deniz'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ulaşılamıyor'), findsOneWidget);
    });

    test('günlük soru hakkı dolunca durur, ertesi gün yenilenir', () async {
      final day = DateTime(2026, 11, 2);
      for (var i = 0; i < AppSettings.assistantDailyLimit; i++) {
        expect(await AppSettings.instance.takeAssistantQuota(day), isTrue);
      }
      expect(await AppSettings.instance.takeAssistantQuota(day), isFalse);
      expect(await AppSettings.instance.takeAssistantQuota(day.add(const Duration(days: 1))), isTrue);
    });
  });

  testWidgets('Yolculuk sırasında menüde gezilir, çıkış engellenir', (tester) async {
    // Profil listesinin tamamı ekrana sığsın.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Profil listesinin tamamı ekrana sığsın.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await signIn(name: 'Ayşe');
    // Servisler hata verir: ad bulunmaz, rota kuş uçuşundan tahmin edilir.
    final offline = MockClient((_) async => http.Response('hata', 500));
    await tester.pumpWidget(localized(MainNavigationScreen(
      showAds: false,
      geocoding: GeocodingService(client: offline),
      routing: RoutingService(client: offline),
    )));
    await tester.pump();

    tester
        .state<HomeScreenState>(find.byType(HomeScreen))
        .rideTo(const GeoPlace(name: 'Girne Limanı', position: LatLng(35.3412, 33.3196)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('TAKSİ ÇAĞIR'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('TAKSİ ÇAĞIR'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(AppDurations.driverSearch + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DriverFoundSheet).hitTestable(), findsOneWidget);

    // Şoför bulunmuşken menü çalışır.
    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DriverFoundSheet).hitTestable(), findsNothing);

    await tester.ensureVisible(find.text('Çıkış Yap'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Çıkış Yap'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Önce devam eden yolculuğunu tamamla.'), findsOneWidget);
    expect(Backend.instance.auth.currentUser, isNotNull);

    // Ana sekmeye dönünce panel yerinde; demo yolculuk başlayınca yolculuk paneline geçer.
    await tester.tap(find.text('Ana Sayfa'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DriverFoundSheet).hitTestable(), findsOneWidget);
    final session = tester.widget<DriverFoundSheet>(find.byType(DriverFoundSheet)).session;
    await Backend.instance.rides.startTripDemo(session.value!.id);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ActiveTripSheet).hitTestable(), findsOneWidget);

    await tester.tap(find.text('Paylaşımlı'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ActiveTripSheet).hitTestable(), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Grup açılamayınca teşhis penceresi kodu ve en olası nedeni gösterir', (tester) async {
    await signIn();
    await tester.pumpWidget(localized(Scaffold(
      body: GroupFailureDialog(
        errorCode: 'cloud_firestore/permission-denied',
        departure: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    )));
    await tester.pumpAndSettle();

    // Sahte ortamda telefon saati doğru: kalkış form açıkken geçmiş sayılır.
    expect(find.textContaining('Daha ileri bir saat'), findsOneWidget);
    expect(find.textContaining('error: cloud_firestore/permission-denied'), findsOneWidget);
    expect(find.text('Kopyala'), findsOneWidget);
  });

  testWidgets('Telefon saati geride olsa da form sunucuya göre gelecek bir kalkış seçer', (tester) async {
    await signIn();
    // Arkadaşın telefonu: sunucu 1 saat ileride.
    TrustedClock.instance.serverTimeSource = () async => DateTime.now().add(const Duration(seconds: 3657));
    await tester.pumpWidget(localized(SharedRideScreen(routing: groupRouting())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grup Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Nereden?'), findsOneWidget);
    await fillGroupPlaces(tester, ['Gazimağusa Surlariçi', 'Girne Yat Limanı']);

    expect(find.textContaining('Kıbrıs saati'), findsWidgets);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Devam Et')).onPressed, isNotNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Devam Et'));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur')).onPressed, isNotNull);

    await tester.ensureVisible(find.text('Yolculuğu Oluştur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yolculuğu Oluştur'));
    await tester.pumpAndSettle();
    // `first` testWidgets'in sahte zamanında takılır; gerçek zamanda okunur.
    final rides = await tester.runAsync(() => Backend.instance.sharedRides.watchActive().first);
    final mine = rides!.where((r) => r.from == 'Gazimağusa Surlariçi' && r.to == 'Girne Yat Limanı');
    expect(mine.single.departure.isAfter(TrustedClock.instance.now), isTrue);
    expect(find.textContaining('Kıbrıs saati'), findsWidgets);
  });

  group('Gruba katılma ve toplama noktası', () {
    // Ercan Havalimanı'nın (son gidilen yerler) yaklaşık 1 km yakınında bir buluşma noktası.
    const meetingPoint = LatLng(35.1600, 33.5000);
    final nearRide = SharedRide(
      id: 'near-group',
      from: 'Buluşma Durağı',
      to: 'Girne Yat Limanı',
      departure: DateTime.now().add(const Duration(days: 1)),
      capacity: 8,
      memberIds: const ['demo-x', 'demo-y', 'demo-z'],
      pricePerPerson: groupPricePerPerson(baseMeters: 20000, extraMeters: 0, capacity: 8, members: 3),
      fromPoint: meetingPoint,
      toPoint: const LatLng(35.3417, 33.3192),
      baseMeters: 20000,
      detours: const {'demo-x': 0, 'demo-y': 0, 'demo-z': 0},
    );

    MockSharedRideRepository mockRides() => Backend.instance.sharedRides as MockSharedRideRepository;

    testWidgets('katılma sayfası yeni ücreti gösterir; onaydan sonra kullanıcı üye olur', (tester) async {
      await signIn();
      mockRides().addForTest(nearRide);
      await tester.pumpWidget(localized(SharedRideScreen(routing: groupRouting(9000))));
      await tester.pumpAndSettle();

      final card = find.ancestor(of: find.text('Buluşma Durağı'), matching: find.byType(Card));
      await tester.tap(find.descendant(of: card, matching: find.text('Katıl')));
      await tester.pumpAndSettle();

      final after = groupPricePerPerson(baseMeters: 20000, extraMeters: 0, capacity: 8, members: 4);
      expect(find.text('Seni nereden alalım?'), findsOneWidget);
      expect(
        find.text('Katılırsan kişi başı ${liraTr(after)} olur (şu an ${liraTr(nearRide.pricePerPerson)}).'),
        findsOneWidget,
      );

      await confirmJoinSheet(tester);
      expect(find.byType(JoinGroupSheet), findsNothing);
      expect(find.text('Toplama noktam: Buluşma Durağı'), findsOneWidget);
      expect(find.text('Değiştir'), findsOneWidget);
      final mine = await mockRides().myPickup('near-group');
      expect(mine!.place.name, 'Buluşma Durağı');
      expect(mine.detourMeters, 0);
    });

    testWidgets('karttan "Değiştir" ile başka nokta seçilince yeni ad ve yeni ücret görünür', (tester) async {
      await signIn();
      mockRides().addForTest(nearRide);
      await mockRides().join('near-group', Pickup(place: nearRide.meetingPlace!, detourMeters: 0));
      await tester.pumpWidget(localized(SharedRideScreen(routing: groupRouting(9000))));
      await tester.pumpAndSettle();

      final before = groupPricePerPerson(baseMeters: 20000, extraMeters: 0, capacity: 8, members: 4);
      final changed = groupPricePerPerson(baseMeters: 20000, extraMeters: 9000, capacity: 8, members: 4);
      expect(changed, isNot(before));
      expect(find.text('≈ ${liraTr(before)}'), findsOneWidget);
      expect(find.text('Toplama noktam: Buluşma Durağı'), findsOneWidget);

      await tester.tap(find.text('Değiştir'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Kaydet'), findsOneWidget);
      await tester.tap(find.text('Başka bir yerden alınmak istiyorum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ercan Havalimanı'));
      await tester.pumpAndSettle();
      expect(find.text('Katılırsan kişi başı ${liraTr(changed)} olur (şu an ${liraTr(before)}).'), findsOneWidget);

      await confirmJoinSheet(tester, label: 'Kaydet');
      expect(find.text('Toplama noktam: Ercan Havalimanı'), findsOneWidget);
      expect(find.text('≈ ${liraTr(changed)}'), findsOneWidget);
    });

    testWidgets('eski biçimli grup kartında kapalı "Eski sürüm grubu" düğmesi vardır; liste çökmez', (tester) async {
      await signIn();
      mockRides().addForTest(SharedRide(
        id: 'legacy-group',
        from: 'Eski Başlangıç',
        to: 'Eski Varış',
        departure: DateTime.now().add(const Duration(days: 1)),
        capacity: 4,
        memberIds: const ['demo-x'],
        pricePerPerson: 100,
      ));
      await tester.pumpWidget(localized(const SharedRideScreen()));
      await tester.pumpAndSettle();

      final card = find.ancestor(of: find.text('Eski Başlangıç'), matching: find.byType(Card));
      final button = find.descendant(of: card, matching: find.widgetWithText(ElevatedButton, 'Eski sürüm grubu'));
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(find.descendant(of: card, matching: find.textContaining('≈')), findsNothing);
      expect(find.descendant(of: card, matching: find.text('Kişi sayısına göre değişir')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('eski biçimli grubun üyesi "Ayrıl" ile çıkabilir, toplama satırı görünmez', (tester) async {
      await signIn();
      final userId = Backend.instance.auth.currentUser!.id;
      mockRides().addForTest(SharedRide(
        id: 'legacy-group',
        from: 'Eski Başlangıç',
        to: 'Eski Varış',
        departure: DateTime.now().add(const Duration(days: 1)),
        capacity: 4,
        memberIds: ['demo-x', userId],
        pricePerPerson: 100,
      ));
      await tester.pumpWidget(localized(const SharedRideScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Toplama noktam'), findsNothing);
      await tester.tap(find.text('Ayrıl'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Ayrıl'));
      await tester.pumpAndSettle();
      expect(find.text('Ayrıl'), findsNothing);
      expect(find.text('Eski sürüm grubu'), findsOneWidget);
    });
  });

  group('Toplama noktası seçici', () {
    // Ercan Havalimanı'nın (son gidilen yerler listesinde) yaklaşık 1 km yakını.
    const meeting = GeoPlace(name: 'Buluşma Durağı', position: LatLng(35.1600, 33.5000));
    const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

    RoutingService routingWith(int meters) => RoutingService(
          client: MockClient((_) async => http.Response(
              '{"code":"Ok","routes":[{"distance":$meters,"duration":300,'
              '"geometry":{"coordinates":[[33.32,35.34],[33.33,35.35]]}}]}',
              200,
              headers: jsonHeaders)),
        );

    Future<List<Pickup?>> pumpChooser(WidgetTester tester, RoutingService routing, {Pickup? initial}) async {
      final reported = <Pickup?>[];
      await tester.pumpWidget(localized(Scaffold(
        body: PickupChooser(
          meeting: meeting,
          geocoding: GeocodingService(client: MockClient((_) async => http.Response('{"features":[]}', 200))),
          routing: routing,
          initial: initial,
          onChanged: reported.add,
        ),
      )));
      await tester.pumpAndSettle();
      return reported;
    }

    testWidgets('varsayılan seçim buluşma noktasıdır ve sapma 0 bildirir', (tester) async {
      final reported = await pumpChooser(tester, routingWith(2400));
      expect(reported, hasLength(1));
      expect(reported.single!.place.name, 'Buluşma Durağı');
      expect(reported.single!.detourMeters, 0);
      expect(find.text('Buluşma noktasından binerim'), findsOneWidget);
      expect(find.text('Bu noktayı yalnızca sen ve şoför görür.'), findsOneWidget);
    });

    testWidgets('başka yer seçilince adı ve eklenen mesafe görünür', (tester) async {
      final reported = await pumpChooser(tester, routingWith(2400));
      await tester.tap(find.text('Başka bir yerden alınmak istiyorum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ercan Havalimanı'));
      await tester.pumpAndSettle();
      expect(find.text('Ercan Havalimanı'), findsOneWidget);
      expect(find.text('Ücrete eklenen mesafe: 2,4 km'), findsOneWidget);
      expect(reported.last!.detourMeters, 2400);
      expect(reported.last!.place.name, 'Ercan Havalimanı');
    });

    testWidgets('10 km üstü nokta reddedilir', (tester) async {
      final reported = await pumpChooser(tester, routingWith(12000));
      await tester.tap(find.text('Başka bir yerden alınmak istiyorum'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ercan Havalimanı'));
      await tester.pumpAndSettle();
      expect(find.textContaining('çok uzak'), findsOneWidget);
      expect(find.textContaining('en fazla 10 km'), findsOneWidget);
      expect(reported.last, isNull);
    });

    testWidgets('seçici iptal edilirse önceki seçime dönülür', (tester) async {
      final reported = await pumpChooser(tester, routingWith(2400));
      await tester.tap(find.text('Başka bir yerden alınmak istiyorum'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // sayfayı kapat
      await tester.pumpAndSettle();
      expect(find.text('Ücrete eklenen mesafe: 0 m'), findsNothing);
      expect(reported.last!.detourMeters, 0);
      expect(reported.last!.place.name, 'Buluşma Durağı');
    });

    testWidgets('başlangıç değeri başka bir yerse "başka yer" açık gelir', (tester) async {
      const other = GeoPlace(name: 'Başka Durak', position: LatLng(35.1700, 33.5000));
      await pumpChooser(tester, routingWith(2400), initial: const Pickup(place: other, detourMeters: 1500));
      expect(find.text('Başka Durak'), findsOneWidget);
      expect(find.text('Ücrete eklenen mesafe: 1,5 km'), findsOneWidget);
    });
  });
}
