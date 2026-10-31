import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'KKTC Taksim'**
  String get appName;

  /// No description provided for @appNameUpper.
  ///
  /// In tr, this message translates to:
  /// **'KKTC TAKSİM'**
  String get appNameUpper;

  /// No description provided for @tagline.
  ///
  /// In tr, this message translates to:
  /// **'KKTC\'nin Akıllı Taksi Uygulaması'**
  String get tagline;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueLabel;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @change.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get change;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @cannotOpen.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem cihazında açılamadı.'**
  String get cannotOpen;

  /// No description provided for @comingSoon.
  ///
  /// In tr, this message translates to:
  /// **'{feature} yakında eklenecek.'**
  String comingSoon(String feature);

  /// No description provided for @estimated.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini'**
  String get estimated;

  /// No description provided for @minutesShort.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk'**
  String minutesShort(int count);

  /// No description provided for @chooseRole.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen devam etmek için rolünüzü seçin'**
  String get chooseRole;

  /// No description provided for @rolePassenger.
  ///
  /// In tr, this message translates to:
  /// **'Ben Yolcuyum'**
  String get rolePassenger;

  /// No description provided for @rolePassengerHint.
  ///
  /// In tr, this message translates to:
  /// **'Taksi çağırın, yolculuk paylaşın'**
  String get rolePassengerHint;

  /// No description provided for @roleDriver.
  ///
  /// In tr, this message translates to:
  /// **'Ben Şoförüm'**
  String get roleDriver;

  /// No description provided for @roleDriverHint.
  ///
  /// In tr, this message translates to:
  /// **'Çağrıları yönetin, kazanç sağlayın'**
  String get roleDriverHint;

  /// No description provided for @roleStand.
  ///
  /// In tr, this message translates to:
  /// **'Taksi Durağı'**
  String get roleStand;

  /// No description provided for @roleStandHint.
  ///
  /// In tr, this message translates to:
  /// **'Durağınızı ve filonuzu yönetin'**
  String get roleStandHint;

  /// No description provided for @driverLogin.
  ///
  /// In tr, this message translates to:
  /// **'Şoför girişi'**
  String get driverLogin;

  /// No description provided for @standLogin.
  ///
  /// In tr, this message translates to:
  /// **'Durak girişi'**
  String get standLogin;

  /// No description provided for @welcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaranı gir, sana bir doğrulama kodu gönderelim'**
  String get loginSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In tr, this message translates to:
  /// **'Telefon Numarası'**
  String get phoneNumber;

  /// No description provided for @phoneRequired.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası boş bırakılamaz'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir telefon numarası girin'**
  String get phoneInvalid;

  /// No description provided for @fieldRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan boş bırakılamaz'**
  String get fieldRequired;

  /// No description provided for @sendCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod Gönder'**
  String get sendCode;

  /// No description provided for @noAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız yok mu?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hesap Oluştur'**
  String get createAccount;

  /// No description provided for @signupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Adını ve telefon numaranı gir, numaranı SMS ile doğrulayalım'**
  String get signupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @termsPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt olarak '**
  String get termsPrefix;

  /// No description provided for @termsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşullarını'**
  String get termsOfUse;

  /// No description provided for @termsSuffix.
  ///
  /// In tr, this message translates to:
  /// **' kabul etmiş sayılırsınız.'**
  String get termsSuffix;

  /// No description provided for @verificationCode.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama Kodu'**
  String get verificationCode;

  /// No description provided for @enterCode.
  ///
  /// In tr, this message translates to:
  /// **'{phone} numarasına gönderilen {length} haneli kodu giriniz.'**
  String enterCode(String phone, int length);

  /// No description provided for @verify.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get verify;

  /// No description provided for @didntGetCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod gelmedi mi?'**
  String get didntGetCode;

  /// No description provided for @resend.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Gönder'**
  String get resend;

  /// No description provided for @codeResent.
  ///
  /// In tr, this message translates to:
  /// **'Kod {phone} numarasına tekrar gönderildi.'**
  String codeResent(String phone);

  /// No description provided for @verificationSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama başarılı! Hoş geldiniz.'**
  String get verificationSuccess;

  /// No description provided for @navHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get navHome;

  /// No description provided for @myTrips.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuklarım'**
  String get myTrips;

  /// No description provided for @navShared.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşımlı'**
  String get navShared;

  /// No description provided for @explore.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get explore;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @greeting.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {name} 👋'**
  String greeting(String name);

  /// No description provided for @whereToGo.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gitmek istersin?'**
  String get whereToGo;

  /// No description provided for @whereTo.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gitmek istiyorsun?'**
  String get whereTo;

  /// No description provided for @currentLocation.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut konumun'**
  String get currentLocation;

  /// No description provided for @tripStartPoint.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç noktası'**
  String get tripStartPoint;

  /// No description provided for @goToMyLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumuma git'**
  String get goToMyLocation;

  /// No description provided for @showingFallbackCity.
  ///
  /// In tr, this message translates to:
  /// **'Harita Lefkoşa merkezde gösteriliyor.'**
  String get showingFallbackCity;

  /// No description provided for @locationDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kapalı. Ayarlardan açabilirsin.'**
  String get locationDeniedForever;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Cihazının konum servisi kapalı.'**
  String get locationServiceDisabled;

  /// No description provided for @locationInsecure.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcı konumu yalnızca güvenli (https) bağlantıda paylaşır.'**
  String get locationInsecure;

  /// No description provided for @locationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konumun şu an alınamadı.'**
  String get locationUnavailable;

  /// No description provided for @mapLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Harita yüklenemedi. İnternet bağlantını kontrol et.'**
  String get mapLoadError;

  /// No description provided for @pickOnMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritadan seç'**
  String get pickOnMap;

  /// No description provided for @pickOnMapHint.
  ///
  /// In tr, this message translates to:
  /// **'Haritayı kaydırıp iğneyi gideceğin yere getir'**
  String get pickOnMapHint;

  /// No description provided for @moveMapToPick.
  ///
  /// In tr, this message translates to:
  /// **'Haritayı kaydırarak iğneyi varış noktasına getir'**
  String get moveMapToPick;

  /// No description provided for @selectThisPoint.
  ///
  /// In tr, this message translates to:
  /// **'Bu Noktayı Seç'**
  String get selectThisPoint;

  /// No description provided for @pinnedLocation.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlenen konum'**
  String get pinnedLocation;

  /// No description provided for @recentPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Son gidilen yerler'**
  String get recentPlaces;

  /// No description provided for @searchFailed.
  ///
  /// In tr, this message translates to:
  /// **'Adres araması yapılamadı. İnternet bağlantını kontrol et.'**
  String get searchFailed;

  /// No description provided for @searchNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı. Farklı yazmayı ya da haritadan seçmeyi dene.'**
  String get searchNoResults;

  /// No description provided for @calculatingRoute.
  ///
  /// In tr, this message translates to:
  /// **'Rota hesaplanıyor...'**
  String get calculatingRoute;

  /// No description provided for @finishCurrentRideFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce devam eden yolculuğunu tamamla.'**
  String get finishCurrentRideFirst;

  /// No description provided for @approximateRoute.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık {summary}'**
  String approximateRoute(String summary);

  /// No description provided for @taxiEconomy.
  ///
  /// In tr, this message translates to:
  /// **'Ekonomik'**
  String get taxiEconomy;

  /// No description provided for @taxiComfort.
  ///
  /// In tr, this message translates to:
  /// **'Konfor'**
  String get taxiComfort;

  /// No description provided for @taxiXl.
  ///
  /// In tr, this message translates to:
  /// **'XL'**
  String get taxiXl;

  /// No description provided for @pickupIn.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk içinde yanında'**
  String pickupIn(int count);

  /// No description provided for @fareDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatlar tahminidir; trafik ve bekleme süresine göre değişebilir.'**
  String get fareDisclaimer;

  /// No description provided for @paymentMethod.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme yöntemi'**
  String get paymentMethod;

  /// No description provided for @paymentCash.
  ///
  /// In tr, this message translates to:
  /// **'Nakit'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In tr, this message translates to:
  /// **'Kart'**
  String get paymentCard;

  /// No description provided for @when.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman?'**
  String get when;

  /// No description provided for @now.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi'**
  String get now;

  /// No description provided for @later.
  ///
  /// In tr, this message translates to:
  /// **'İleri tarih'**
  String get later;

  /// No description provided for @scheduleTooSoon.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon en erken {minutes} dakika sonrası için yapılabilir.'**
  String scheduleTooSoon(int minutes);

  /// No description provided for @callTaxi.
  ///
  /// In tr, this message translates to:
  /// **'TAKSİ ÇAĞIR'**
  String get callTaxi;

  /// No description provided for @reserveTaxi.
  ///
  /// In tr, this message translates to:
  /// **'REZERVE ET'**
  String get reserveTaxi;

  /// No description provided for @rideScheduled.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun {when} için planlandı. Yolculuklarım > Yaklaşan\'dan görebilirsin.'**
  String rideScheduled(String when);

  /// No description provided for @searchingTaxi.
  ///
  /// In tr, this message translates to:
  /// **'Taksi aranıyor...'**
  String get searchingTaxi;

  /// No description provided for @searchingTaxiHint.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki sürücülerle eşleştiriliyorsun'**
  String get searchingTaxiHint;

  /// No description provided for @driverOnTheWay.
  ///
  /// In tr, this message translates to:
  /// **'Sürücün yolda, yaklaşık {count} dk'**
  String driverOnTheWay(int count);

  /// No description provided for @driverArrived.
  ///
  /// In tr, this message translates to:
  /// **'Sürücün geldi! Plakayı kontrol ederek bin.'**
  String get driverArrived;

  /// No description provided for @plateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Plaka {plate}'**
  String plateLabel(String plate);

  /// No description provided for @carWhite.
  ///
  /// In tr, this message translates to:
  /// **'Beyaz'**
  String get carWhite;

  /// No description provided for @carSilver.
  ///
  /// In tr, this message translates to:
  /// **'Gri'**
  String get carSilver;

  /// No description provided for @carBlack.
  ///
  /// In tr, this message translates to:
  /// **'Siyah'**
  String get carBlack;

  /// No description provided for @message.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get message;

  /// No description provided for @call.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get call;

  /// No description provided for @startRideDemo.
  ///
  /// In tr, this message translates to:
  /// **'YOLCULUĞU BAŞLAT (DEMO)'**
  String get startRideDemo;

  /// No description provided for @cancelRide.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu İptal Et'**
  String get cancelRide;

  /// No description provided for @cancelRideTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk iptal edilsin mi?'**
  String get cancelRideTitle;

  /// No description provided for @cancelRideMessage.
  ///
  /// In tr, this message translates to:
  /// **'Sürücün yola çıktı. İptal edersen yolculuk İptal Edilenler\'e eklenir.'**
  String get cancelRideMessage;

  /// No description provided for @tripInProgress.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun devam ediyor'**
  String get tripInProgress;

  /// No description provided for @arrivedAtDestination.
  ///
  /// In tr, this message translates to:
  /// **'Varış noktasına ulaştın'**
  String get arrivedAtDestination;

  /// No description provided for @minutesLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count} dk kaldı'**
  String minutesLeft(int count);

  /// No description provided for @completeRide.
  ///
  /// In tr, this message translates to:
  /// **'TAMAMLA'**
  String get completeRide;

  /// No description provided for @finishDemo.
  ///
  /// In tr, this message translates to:
  /// **'BİTİR (DEMO)'**
  String get finishDemo;

  /// No description provided for @safetyTools.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get safetyTools;

  /// No description provided for @shareTrip.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğumu paylaş'**
  String get shareTrip;

  /// No description provided for @shareTripHint.
  ///
  /// In tr, this message translates to:
  /// **'Sürücü, plaka, varış saati ve canlı konum bağlantısı bir yakınına gönderilir; yolculuk bitince bağlantı kapanır'**
  String get shareTripHint;

  /// No description provided for @shareTripText.
  ///
  /// In tr, this message translates to:
  /// **'KKTC Taksim ile yolculuktayım.\nSürücü: {driver}\nPlaka: {plate} – {car}\nVarış: {destination}, tahmini {arrival}\nŞu anki konum: {link}'**
  String shareTripText(String driver, String plate, String car,
      String destination, String arrival, String link);

  /// No description provided for @shareTripLiveText.
  ///
  /// In tr, this message translates to:
  /// **'KKTC Taksim ile yolculuktayım.\nSürücü: {driver}\nPlaka: {plate} – {car}\nVarış: {destination}, tahmini {arrival}\nCanlı takip (yolculuk bitene kadar): {link}'**
  String shareTripLiveText(String driver, String plate, String car,
      String destination, String arrival, String link);

  /// No description provided for @tripDetailsCopied.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk bilgileri panoya kopyalandı; mesaj olarak yapıştırabilirsin.'**
  String get tripDetailsCopied;

  /// No description provided for @emergencyCall.
  ///
  /// In tr, this message translates to:
  /// **'Acil arama'**
  String get emergencyCall;

  /// No description provided for @police.
  ///
  /// In tr, this message translates to:
  /// **'Polis'**
  String get police;

  /// No description provided for @ambulance.
  ///
  /// In tr, this message translates to:
  /// **'Ambulans'**
  String get ambulance;

  /// No description provided for @fireDepartment.
  ///
  /// In tr, this message translates to:
  /// **'İtfaiye'**
  String get fireDepartment;

  /// No description provided for @tripCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk Tamamlandı'**
  String get tripCompleted;

  /// No description provided for @totalAmount.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Tutar: {amount}'**
  String totalAmount(String amount);

  /// No description provided for @howWasTrip.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğun nasıl geçti?'**
  String get howWasTrip;

  /// No description provided for @starCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} yıldız'**
  String starCount(int count);

  /// No description provided for @submitRating.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeyi Gönder'**
  String get submitRating;

  /// No description provided for @tabUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan'**
  String get tabUpcoming;

  /// No description provided for @tabPast.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get tabPast;

  /// No description provided for @tabCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edilen'**
  String get tabCancelled;

  /// No description provided for @noUpcomingTrips.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan yolculuğun yok'**
  String get noUpcomingTrips;

  /// No description provided for @noUpcomingTripsHint.
  ///
  /// In tr, this message translates to:
  /// **'Taksi çağırırken \"İleri tarih\"i seçerek yolculuk planlayabilirsin.'**
  String get noUpcomingTripsHint;

  /// No description provided for @noPastTrips.
  ///
  /// In tr, this message translates to:
  /// **'Henüz tamamlanmış yolculuğun yok'**
  String get noPastTrips;

  /// No description provided for @noCancelledTrips.
  ///
  /// In tr, this message translates to:
  /// **'İptal edilmiş yolculuğun yok'**
  String get noCancelledTrips;

  /// No description provided for @callTaxiShort.
  ///
  /// In tr, this message translates to:
  /// **'Taksi Çağır'**
  String get callTaxiShort;

  /// No description provided for @statusScheduled.
  ///
  /// In tr, this message translates to:
  /// **'Planlandı'**
  String get statusScheduled;

  /// No description provided for @statusCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get statusCancelled;

  /// No description provided for @cancelReservation.
  ///
  /// In tr, this message translates to:
  /// **'İptal Et'**
  String get cancelReservation;

  /// No description provided for @cancelReservationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rezervasyon iptal edilsin mi?'**
  String get cancelReservationTitle;

  /// No description provided for @cancelReservationMessage.
  ///
  /// In tr, this message translates to:
  /// **'{when} tarihli yolculuğun iptal edilecek.'**
  String cancelReservationMessage(String when);

  /// No description provided for @sharedRides.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşımlı Yolculuk'**
  String get sharedRides;

  /// No description provided for @howItWorks.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl çalışır?'**
  String get howItWorks;

  /// No description provided for @sharedRidesInfo.
  ///
  /// In tr, this message translates to:
  /// **'Aynı yöne giden yolcularla bir araç (Vito) paylaşırsın. Kartta yazan ücret kişi başıdır; herkes kendi payını öder. Kalkış saati geldiğinde yolculuk başlar.'**
  String get sharedRidesInfo;

  /// No description provided for @sharedPromoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birlikte yolculuk et,\ndaha avantajlı öde.'**
  String get sharedPromoTitle;

  /// No description provided for @sharedPromoSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı yöne giden kişilerle maliyeti paylaş.'**
  String get sharedPromoSubtitle;

  /// No description provided for @activeGroups.
  ///
  /// In tr, this message translates to:
  /// **'Aktif Gruplar'**
  String get activeGroups;

  /// No description provided for @noActiveGroups.
  ///
  /// In tr, this message translates to:
  /// **'Şu an aktif grup yok. İlk grubu sen oluştur!'**
  String get noActiveGroups;

  /// No description provided for @createGroup.
  ///
  /// In tr, this message translates to:
  /// **'Grup Oluştur'**
  String get createGroup;

  /// No description provided for @perPerson.
  ///
  /// In tr, this message translates to:
  /// **'kişi başı'**
  String get perPerson;

  /// No description provided for @peopleCount.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {capacity} kişi'**
  String peopleCount(int current, int capacity);

  /// No description provided for @seatsLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count} koltuk kaldı'**
  String seatsLeft(int count);

  /// No description provided for @full.
  ///
  /// In tr, this message translates to:
  /// **'Dolu'**
  String get full;

  /// No description provided for @join.
  ///
  /// In tr, this message translates to:
  /// **'Katıl'**
  String get join;

  /// No description provided for @joinedGroup.
  ///
  /// In tr, this message translates to:
  /// **'{from} → {to} grubuna katıldın.'**
  String joinedGroup(String from, String to);

  /// No description provided for @leaveGroup.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıl'**
  String get leaveGroup;

  /// No description provided for @leaveGroupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan ayrılmak istiyor musun?'**
  String get leaveGroupTitle;

  /// No description provided for @leaveGroupMessage.
  ///
  /// In tr, this message translates to:
  /// **'{from} → {to} grubundaki yerin boşaltılacak.'**
  String leaveGroupMessage(String from, String to);

  /// No description provided for @leftGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gruptan ayrıldın.'**
  String get leftGroup;

  /// No description provided for @createRide.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk Oluştur'**
  String get createRide;

  /// No description provided for @stepOf.
  ///
  /// In tr, this message translates to:
  /// **'Adım {step} / {total}'**
  String stepOf(int step, int total);

  /// No description provided for @fromQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Nereden?'**
  String get fromQuestion;

  /// No description provided for @toQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Nereye?'**
  String get toQuestion;

  /// No description provided for @startPoint.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç noktası'**
  String get startPoint;

  /// No description provided for @endPoint.
  ///
  /// In tr, this message translates to:
  /// **'Varış noktası'**
  String get endPoint;

  /// No description provided for @rideDetails.
  ///
  /// In tr, this message translates to:
  /// **'Tarih, Saat ve Ücret'**
  String get rideDetails;

  /// No description provided for @rideDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get rideDate;

  /// No description provided for @rideTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get rideTime;

  /// No description provided for @departureInPast.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış zamanı geçmişte kalamaz.'**
  String get departureInPast;

  /// No description provided for @vitoCapacity.
  ///
  /// In tr, this message translates to:
  /// **'Vito kapasitesi: {count}'**
  String vitoCapacity(int count);

  /// No description provided for @pricePerPersonLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı ücret'**
  String get pricePerPersonLabel;

  /// No description provided for @pricePerPersonHelp.
  ///
  /// In tr, this message translates to:
  /// **'Her yolcunun ödeyeceği tutar'**
  String get pricePerPersonHelp;

  /// No description provided for @pricePerPersonInvalid.
  ///
  /// In tr, this message translates to:
  /// **'1 ile {max} arasında bir tutar gir'**
  String pricePerPersonInvalid(String max);

  /// No description provided for @createRideButton.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu Oluştur'**
  String get createRideButton;

  /// No description provided for @exploreSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Yakınında ne arıyorsun?'**
  String get exploreSearchHint;

  /// No description provided for @categoryAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get categoryAll;

  /// No description provided for @categoryRestaurant.
  ///
  /// In tr, this message translates to:
  /// **'Restoran'**
  String get categoryRestaurant;

  /// No description provided for @categoryCafe.
  ///
  /// In tr, this message translates to:
  /// **'Kafe'**
  String get categoryCafe;

  /// No description provided for @categoryHotel.
  ///
  /// In tr, this message translates to:
  /// **'Otel'**
  String get categoryHotel;

  /// No description provided for @categoryEntertainment.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence'**
  String get categoryEntertainment;

  /// No description provided for @categoryShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get categoryShopping;

  /// No description provided for @categoryHistoric.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi Yerler'**
  String get categoryHistoric;

  /// No description provided for @popularPlaces.
  ///
  /// In tr, this message translates to:
  /// **'Popüler Yerler'**
  String get popularPlaces;

  /// No description provided for @noPlacesFound.
  ///
  /// In tr, this message translates to:
  /// **'Aramana uygun yer bulunamadı'**
  String get noPlacesFound;

  /// No description provided for @discountBadge.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} İndirim'**
  String discountBadge(int percent);

  /// No description provided for @callTaxiHere.
  ///
  /// In tr, this message translates to:
  /// **'Buraya taksi'**
  String get callTaxiHere;

  /// No description provided for @personalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get personalInfo;

  /// No description provided for @savedAddresses.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı Adresler'**
  String get savedAddresses;

  /// No description provided for @paymentMethods.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Yöntemleri'**
  String get paymentMethods;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @campaigns.
  ///
  /// In tr, this message translates to:
  /// **'Kampanyalar'**
  String get campaigns;

  /// No description provided for @helpSupport.
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve Destek'**
  String get helpSupport;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun dili'**
  String get languageSystem;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @termsOfUseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get termsOfUseTitle;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı Sil'**
  String get deleteAccount;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın ve sana ait bütün veriler (profil, yolculuk geçmişi, grup üyeliklerin ve mesajların, konum paylaşımların) kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek için telefonuna bir doğrulama kodu göndereceğiz.'**
  String get deleteAccountMessage;

  /// No description provided for @accountDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın ve verilerin silindi.'**
  String get accountDeleted;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In tr, this message translates to:
  /// **'Hesap silinemedi. İnternet bağlantını kontrol edip tekrar dene.'**
  String get deleteAccountFailed;

  /// No description provided for @logoutMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hesabından çıkmak istediğine emin misin?'**
  String get logoutMessage;

  /// No description provided for @greetingNoName.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba 👋'**
  String get greetingNoName;

  /// No description provided for @authInvalidCode.
  ///
  /// In tr, this message translates to:
  /// **'Kod hatalı. Lütfen SMS ile gelen kodu kontrol et.'**
  String get authInvalidCode;

  /// No description provided for @authTooManyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.'**
  String get authTooManyRequests;

  /// No description provided for @networkError.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok gibi görünüyor. Bağlantını kontrol et.'**
  String get networkError;

  /// No description provided for @actionFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı. Lütfen tekrar dene.'**
  String get actionFailed;

  /// No description provided for @actionFailedWithCode.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tamamlanamadı ({code}). Lütfen tekrar dene.'**
  String actionFailedWithCode(String code);

  /// No description provided for @signInRequiredForGroups.
  ///
  /// In tr, this message translates to:
  /// **'Grup açmak ya da gruba katılmak için giriş yapmalısın.'**
  String get signInRequiredForGroups;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signIn;

  /// No description provided for @loadError.
  ///
  /// In tr, this message translates to:
  /// **'Veriler yüklenemedi.'**
  String get loadError;

  /// No description provided for @noDriverFound.
  ///
  /// In tr, this message translates to:
  /// **'Şu an uygun taksi bulunamadı. Biraz sonra tekrar dene.'**
  String get noDriverFound;

  /// No description provided for @groupFull.
  ///
  /// In tr, this message translates to:
  /// **'Bu grup doldu.'**
  String get groupFull;

  /// No description provided for @groupChat.
  ///
  /// In tr, this message translates to:
  /// **'Grup sohbeti'**
  String get groupChat;

  /// No description provided for @groupChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'{from} → {to}'**
  String groupChatTitle(String from, String to);

  /// No description provided for @chatEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz mesaj yok. Buluşma yerini ve saatini konuşmak için ilk mesajı sen yaz!'**
  String get chatEmpty;

  /// No description provided for @chatPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaran gruptakilere gösterilmez; yalnızca adın görünür.'**
  String get chatPrivacyNote;

  /// No description provided for @locationOutsideServiceArea.
  ///
  /// In tr, this message translates to:
  /// **'Hizmet bölgesinin (KKTC) dışındasın.'**
  String get locationOutsideServiceArea;

  /// No description provided for @chatRulesNote.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz bir mesajı şikâyet etmek ya da kişiyi engellemek için mesaja uzun bas.'**
  String get chatRulesNote;

  /// No description provided for @reportMessage.
  ///
  /// In tr, this message translates to:
  /// **'Şikâyet et'**
  String get reportMessage;

  /// No description provided for @reportReasonTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şikâyet nedeni'**
  String get reportReasonTitle;

  /// No description provided for @reasonSpam.
  ///
  /// In tr, this message translates to:
  /// **'Spam ya da reklam'**
  String get reasonSpam;

  /// No description provided for @reasonHarassment.
  ///
  /// In tr, this message translates to:
  /// **'Hakaret veya taciz'**
  String get reasonHarassment;

  /// No description provided for @reasonInappropriate.
  ///
  /// In tr, this message translates to:
  /// **'Uygunsuz içerik'**
  String get reasonInappropriate;

  /// No description provided for @reasonOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get reasonOther;

  /// No description provided for @reportSent.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler, şikâyetin incelenmek üzere iletildi.'**
  String get reportSent;

  /// No description provided for @blockUser.
  ///
  /// In tr, this message translates to:
  /// **'Bu kişiyi engelle'**
  String get blockUser;

  /// No description provided for @blockUserTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellensin mi?'**
  String blockUserTitle(String name);

  /// No description provided for @blockUserMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu kişinin mesajlarını artık görmeyeceksin. Engeli, gizlenen mesajına uzun basarak kaldırabilirsin.'**
  String get blockUserMessage;

  /// No description provided for @userBlocked.
  ///
  /// In tr, this message translates to:
  /// **'{name} engellendi.'**
  String userBlocked(String name);

  /// No description provided for @unblockUser.
  ///
  /// In tr, this message translates to:
  /// **'Engeli kaldır'**
  String get unblockUser;

  /// No description provided for @unblockUserMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu kişinin mesajları yeniden görünecek.'**
  String get unblockUserMessage;

  /// No description provided for @userUnblocked.
  ///
  /// In tr, this message translates to:
  /// **'Engel kaldırıldı.'**
  String get userUnblocked;

  /// No description provided for @blockedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Engellediğin bir kişinin mesajı'**
  String get blockedMessage;

  /// No description provided for @messageHint.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz…'**
  String get messageHint;

  /// No description provided for @sendMessage.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get sendMessage;

  /// No description provided for @unnamedPassenger.
  ///
  /// In tr, this message translates to:
  /// **'Yolcu'**
  String get unnamedPassenger;

  /// No description provided for @newMessages.
  ///
  /// In tr, this message translates to:
  /// **'Yeni mesaj var'**
  String get newMessages;

  /// No description provided for @notGroupMember.
  ///
  /// In tr, this message translates to:
  /// **'Bu grubun üyesi değilsin.'**
  String get notGroupMember;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
