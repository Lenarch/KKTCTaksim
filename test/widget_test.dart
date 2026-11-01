import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/screens/group_chat_screen.dart';
import 'package:kktc_taksim/data/mock/mock_shared_ride_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/data/mock_data.dart';
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
import 'package:kktc_taksim/screens/my_trips_screen.dart';
import 'package:kktc_taksim/screens/profile_screen.dart';
import 'package:kktc_taksim/screens/shared_ride_screen.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/services/chat_read_state.dart';
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
    ChatReadState.instance.lastRead.value = const {};
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

  testWidgets('Grup formu alttan açılınca, kayma bitince "Nereden?" alanı odaklanır', (tester) async {
    await tester.pumpWidget(localized(Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CreateSharedRideSheet(),
          ),
          child: const Text('aç'),
        ),
      ),
    )));
    await tester.tap(find.text('aç'));
    await tester.pump();
    // Kayma sürerken odak istenmez (bazı Android telefonlarda klavye açılmıyordu).
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);

    // Sonraki adımın alanı da odaklanır.
    await tester.enterText(find.byType(TextFormField), 'Girne');
    await tester.pump();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    // Klavye yeni alana bağlı: yazılan 2. adımın alanına gider.
    expect(tester.testTextInput.isVisible, isTrue);
    tester.testTextInput.enterText('Lefkoşa');
    await tester.pump();
    expect(find.text('Lefkoşa'), findsOneWidget);
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

    // Firestore kuralları 100.000 ₺ üstünü reddeder; form bunu önceden söyler.
    await tester.enterText(find.byType(TextFormField), '150000');
    await tester.pump();
    expect(find.text('1 ile ₺100.000 arasında bir tutar gir'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur')).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pump();
    expect(find.text('1 ile ₺100.000 arasında bir tutar gir'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Yolculuğu Oluştur')).onPressed,
      isNotNull,
    );
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
    await shared.join('demo-group-1');
    await shared.sendMessage('demo-group-1', 'Havalimanına bavulla geleceğim');

    await Backend.instance.auth.sendCode('+90 542 111 22 33');
    await Backend.instance.auth.verifyCode('1' * Backend.instance.auth.codeLength);
    await tester.pumpWidget(localized(const SharedRideScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Grup sohbeti'), findsNothing);

    await tester.tap(find.text('Katıl').first);
    await tester.pumpAndSettle();
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
    await shared.join('demo-group-1');
    await shared.sendMessage('demo-group-1', 'Kaba bir mesaj');
    final mehmet = Backend.instance.auth.currentUser!.id;

    await Backend.instance.auth.sendCode('+90 542 111 22 33');
    await Backend.instance.auth.verifyCode('1' * Backend.instance.auth.codeLength);
    await shared.join('demo-group-1');
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
}
