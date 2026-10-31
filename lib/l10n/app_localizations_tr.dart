// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'KKTC Taksim';

  @override
  String get appNameUpper => 'KKTC TAKSİM';

  @override
  String get tagline => 'KKTC\'nin Akıllı Taksi Uygulaması';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get ok => 'Tamam';

  @override
  String get back => 'Geri';

  @override
  String get continueLabel => 'Devam Et';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get change => 'Değiştir';

  @override
  String get settings => 'Ayarlar';

  @override
  String get cannotOpen => 'Bu işlem cihazında açılamadı.';

  @override
  String comingSoon(String feature) {
    return '$feature yakında eklenecek.';
  }

  @override
  String get estimated => 'Tahmini';

  @override
  String minutesShort(int count) {
    return '$count dk';
  }

  @override
  String get chooseRole => 'Lütfen devam etmek için rolünüzü seçin';

  @override
  String get rolePassenger => 'Ben Yolcuyum';

  @override
  String get rolePassengerHint => 'Taksi çağırın, yolculuk paylaşın';

  @override
  String get roleDriver => 'Ben Şoförüm';

  @override
  String get roleDriverHint => 'Çağrıları yönetin, kazanç sağlayın';

  @override
  String get roleStand => 'Taksi Durağı';

  @override
  String get roleStandHint => 'Durağınızı ve filonuzu yönetin';

  @override
  String get driverLogin => 'Şoför girişi';

  @override
  String get standLogin => 'Durak girişi';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get loginSubtitle =>
      'Telefon numaranı gir, sana bir doğrulama kodu gönderelim';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get phoneRequired => 'Telefon numarası boş bırakılamaz';

  @override
  String get phoneInvalid => 'Geçerli bir telefon numarası girin';

  @override
  String get fieldRequired => 'Bu alan boş bırakılamaz';

  @override
  String get sendCode => 'Kod Gönder';

  @override
  String get noAccount => 'Hesabınız yok mu?';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get createAccount => 'Yeni Hesap Oluştur';

  @override
  String get signupSubtitle =>
      'Adını ve telefon numaranı gir, numaranı SMS ile doğrulayalım';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get termsPrefix => 'Kayıt olarak ';

  @override
  String get termsOfUse => 'Kullanım Koşullarını';

  @override
  String get termsSuffix => ' kabul etmiş sayılırsınız.';

  @override
  String get verificationCode => 'Doğrulama Kodu';

  @override
  String enterCode(String phone, int length) {
    return '$phone numarasına gönderilen $length haneli kodu giriniz.';
  }

  @override
  String get verify => 'Doğrula';

  @override
  String get didntGetCode => 'Kod gelmedi mi?';

  @override
  String get resend => 'Tekrar Gönder';

  @override
  String codeResent(String phone) {
    return 'Kod $phone numarasına tekrar gönderildi.';
  }

  @override
  String get verificationSuccess => 'Doğrulama başarılı! Hoş geldiniz.';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get myTrips => 'Yolculuklarım';

  @override
  String get navShared => 'Paylaşımlı';

  @override
  String get explore => 'Keşfet';

  @override
  String get profile => 'Profil';

  @override
  String greeting(String name) {
    return 'Merhaba $name 👋';
  }

  @override
  String get whereToGo => 'Nereye gitmek istersin?';

  @override
  String get whereTo => 'Nereye gitmek istiyorsun?';

  @override
  String get currentLocation => 'Mevcut konumun';

  @override
  String get tripStartPoint => 'Başlangıç noktası';

  @override
  String get goToMyLocation => 'Konumuma git';

  @override
  String get showingFallbackCity => 'Harita Lefkoşa merkezde gösteriliyor.';

  @override
  String get locationDenied => 'Konum izni verilmedi.';

  @override
  String get locationDeniedForever =>
      'Konum izni kapalı. Ayarlardan açabilirsin.';

  @override
  String get locationServiceDisabled => 'Cihazının konum servisi kapalı.';

  @override
  String get locationInsecure =>
      'Tarayıcı konumu yalnızca güvenli (https) bağlantıda paylaşır.';

  @override
  String get locationUnavailable => 'Konumun şu an alınamadı.';

  @override
  String get mapLoadError =>
      'Harita yüklenemedi. İnternet bağlantını kontrol et.';

  @override
  String get pickOnMap => 'Haritadan seç';

  @override
  String get pickOnMapHint => 'Haritayı kaydırıp iğneyi gideceğin yere getir';

  @override
  String get moveMapToPick =>
      'Haritayı kaydırarak iğneyi varış noktasına getir';

  @override
  String get selectThisPoint => 'Bu Noktayı Seç';

  @override
  String get pinnedLocation => 'İşaretlenen konum';

  @override
  String get recentPlaces => 'Son gidilen yerler';

  @override
  String get searchFailed =>
      'Adres araması yapılamadı. İnternet bağlantını kontrol et.';

  @override
  String get searchNoResults =>
      'Sonuç bulunamadı. Farklı yazmayı ya da haritadan seçmeyi dene.';

  @override
  String get calculatingRoute => 'Rota hesaplanıyor...';

  @override
  String get finishCurrentRideFirst => 'Önce devam eden yolculuğunu tamamla.';

  @override
  String approximateRoute(String summary) {
    return 'Yaklaşık $summary';
  }

  @override
  String get taxiEconomy => 'Ekonomik';

  @override
  String get taxiComfort => 'Konfor';

  @override
  String get taxiXl => 'XL';

  @override
  String pickupIn(int count) {
    return '$count dk içinde yanında';
  }

  @override
  String get fareDisclaimer =>
      'Fiyatlar tahminidir; trafik ve bekleme süresine göre değişebilir.';

  @override
  String get paymentMethod => 'Ödeme yöntemi';

  @override
  String get paymentCash => 'Nakit';

  @override
  String get paymentCard => 'Kart';

  @override
  String get when => 'Ne zaman?';

  @override
  String get now => 'Şimdi';

  @override
  String get later => 'İleri tarih';

  @override
  String scheduleTooSoon(int minutes) {
    return 'Rezervasyon en erken $minutes dakika sonrası için yapılabilir.';
  }

  @override
  String get callTaxi => 'TAKSİ ÇAĞIR';

  @override
  String get reserveTaxi => 'REZERVE ET';

  @override
  String rideScheduled(String when) {
    return 'Yolculuğun $when için planlandı. Yolculuklarım > Yaklaşan\'dan görebilirsin.';
  }

  @override
  String get searchingTaxi => 'Taksi aranıyor...';

  @override
  String get searchingTaxiHint => 'Yakındaki sürücülerle eşleştiriliyorsun';

  @override
  String driverOnTheWay(int count) {
    return 'Sürücün yolda, yaklaşık $count dk';
  }

  @override
  String get driverArrived => 'Sürücün geldi! Plakayı kontrol ederek bin.';

  @override
  String plateLabel(String plate) {
    return 'Plaka $plate';
  }

  @override
  String get carWhite => 'Beyaz';

  @override
  String get carSilver => 'Gri';

  @override
  String get carBlack => 'Siyah';

  @override
  String get message => 'Mesaj';

  @override
  String get call => 'Ara';

  @override
  String get startRideDemo => 'YOLCULUĞU BAŞLAT (DEMO)';

  @override
  String get cancelRide => 'Yolculuğu İptal Et';

  @override
  String get cancelRideTitle => 'Yolculuk iptal edilsin mi?';

  @override
  String get cancelRideMessage =>
      'Sürücün yola çıktı. İptal edersen yolculuk İptal Edilenler\'e eklenir.';

  @override
  String get tripInProgress => 'Yolculuğun devam ediyor';

  @override
  String get arrivedAtDestination => 'Varış noktasına ulaştın';

  @override
  String minutesLeft(int count) {
    return '$count dk kaldı';
  }

  @override
  String get completeRide => 'TAMAMLA';

  @override
  String get finishDemo => 'BİTİR (DEMO)';

  @override
  String get safetyTools => 'Güvenlik';

  @override
  String get shareTrip => 'Yolculuğumu paylaş';

  @override
  String get shareTripHint =>
      'Sürücü, plaka, varış saati ve canlı konum bağlantısı bir yakınına gönderilir; yolculuk bitince bağlantı kapanır';

  @override
  String shareTripText(String driver, String plate, String car,
      String destination, String arrival, String link) {
    return 'KKTC Taksim ile yolculuktayım.\nSürücü: $driver\nPlaka: $plate – $car\nVarış: $destination, tahmini $arrival\nŞu anki konum: $link';
  }

  @override
  String shareTripLiveText(String driver, String plate, String car,
      String destination, String arrival, String link) {
    return 'KKTC Taksim ile yolculuktayım.\nSürücü: $driver\nPlaka: $plate – $car\nVarış: $destination, tahmini $arrival\nCanlı takip (yolculuk bitene kadar): $link';
  }

  @override
  String get tripDetailsCopied =>
      'Yolculuk bilgileri panoya kopyalandı; mesaj olarak yapıştırabilirsin.';

  @override
  String get emergencyCall => 'Acil arama';

  @override
  String get police => 'Polis';

  @override
  String get ambulance => 'Ambulans';

  @override
  String get fireDepartment => 'İtfaiye';

  @override
  String get tripCompleted => 'Yolculuk Tamamlandı';

  @override
  String totalAmount(String amount) {
    return 'Toplam Tutar: $amount';
  }

  @override
  String get howWasTrip => 'Yolculuğun nasıl geçti?';

  @override
  String starCount(int count) {
    return '$count yıldız';
  }

  @override
  String get submitRating => 'Değerlendirmeyi Gönder';

  @override
  String get tabUpcoming => 'Yaklaşan';

  @override
  String get tabPast => 'Geçmiş';

  @override
  String get tabCancelled => 'İptal Edilen';

  @override
  String get noUpcomingTrips => 'Yaklaşan yolculuğun yok';

  @override
  String get noUpcomingTripsHint =>
      'Taksi çağırırken \"İleri tarih\"i seçerek yolculuk planlayabilirsin.';

  @override
  String get noPastTrips => 'Henüz tamamlanmış yolculuğun yok';

  @override
  String get noCancelledTrips => 'İptal edilmiş yolculuğun yok';

  @override
  String get callTaxiShort => 'Taksi Çağır';

  @override
  String get statusScheduled => 'Planlandı';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get statusCancelled => 'İptal Edildi';

  @override
  String get cancelReservation => 'İptal Et';

  @override
  String get cancelReservationTitle => 'Rezervasyon iptal edilsin mi?';

  @override
  String cancelReservationMessage(String when) {
    return '$when tarihli yolculuğun iptal edilecek.';
  }

  @override
  String get sharedRides => 'Paylaşımlı Yolculuk';

  @override
  String get howItWorks => 'Nasıl çalışır?';

  @override
  String get sharedRidesInfo =>
      'Aynı yöne giden yolcularla bir araç (Vito) paylaşırsın. Kartta yazan ücret kişi başıdır; herkes kendi payını öder. Kalkış saati geldiğinde yolculuk başlar.';

  @override
  String get sharedPromoTitle => 'Birlikte yolculuk et,\ndaha avantajlı öde.';

  @override
  String get sharedPromoSubtitle =>
      'Aynı yöne giden kişilerle maliyeti paylaş.';

  @override
  String get activeGroups => 'Aktif Gruplar';

  @override
  String get noActiveGroups => 'Şu an aktif grup yok. İlk grubu sen oluştur!';

  @override
  String get createGroup => 'Grup Oluştur';

  @override
  String get perPerson => 'kişi başı';

  @override
  String peopleCount(int current, int capacity) {
    return '$current / $capacity kişi';
  }

  @override
  String seatsLeft(int count) {
    return '$count koltuk kaldı';
  }

  @override
  String get full => 'Dolu';

  @override
  String get join => 'Katıl';

  @override
  String joinedGroup(String from, String to) {
    return '$from → $to grubuna katıldın.';
  }

  @override
  String get leaveGroup => 'Ayrıl';

  @override
  String get leaveGroupTitle => 'Gruptan ayrılmak istiyor musun?';

  @override
  String leaveGroupMessage(String from, String to) {
    return '$from → $to grubundaki yerin boşaltılacak.';
  }

  @override
  String get leftGroup => 'Gruptan ayrıldın.';

  @override
  String get createRide => 'Yolculuk Oluştur';

  @override
  String stepOf(int step, int total) {
    return 'Adım $step / $total';
  }

  @override
  String get fromQuestion => 'Nereden?';

  @override
  String get toQuestion => 'Nereye?';

  @override
  String get startPoint => 'Başlangıç noktası';

  @override
  String get endPoint => 'Varış noktası';

  @override
  String get rideDetails => 'Tarih, Saat ve Ücret';

  @override
  String get rideDate => 'Tarih';

  @override
  String get rideTime => 'Saat';

  @override
  String get departureInPast => 'Kalkış zamanı geçmişte kalamaz.';

  @override
  String vitoCapacity(int count) {
    return 'Vito kapasitesi: $count';
  }

  @override
  String get pricePerPersonLabel => 'Kişi başı ücret';

  @override
  String get pricePerPersonHelp => 'Her yolcunun ödeyeceği tutar';

  @override
  String pricePerPersonInvalid(String max) {
    return '1 ile $max arasında bir tutar gir';
  }

  @override
  String get createRideButton => 'Yolculuğu Oluştur';

  @override
  String get exploreSearchHint => 'Yakınında ne arıyorsun?';

  @override
  String get categoryAll => 'Hepsi';

  @override
  String get categoryRestaurant => 'Restoran';

  @override
  String get categoryCafe => 'Kafe';

  @override
  String get categoryHotel => 'Otel';

  @override
  String get categoryEntertainment => 'Eğlence';

  @override
  String get categoryShopping => 'Alışveriş';

  @override
  String get categoryHistoric => 'Tarihi Yerler';

  @override
  String get popularPlaces => 'Popüler Yerler';

  @override
  String get noPlacesFound => 'Aramana uygun yer bulunamadı';

  @override
  String discountBadge(int percent) {
    return '%$percent İndirim';
  }

  @override
  String get callTaxiHere => 'Buraya taksi';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get savedAddresses => 'Kayıtlı Adresler';

  @override
  String get paymentMethods => 'Ödeme Yöntemleri';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get campaigns => 'Kampanyalar';

  @override
  String get helpSupport => 'Yardım ve Destek';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get termsOfUseTitle => 'Kullanım Koşulları';

  @override
  String get deleteAccount => 'Hesabımı Sil';

  @override
  String get deleteAccountMessage =>
      'Hesabın ve sana ait bütün veriler (profil, yolculuk geçmişi, grup üyeliklerin ve mesajların, konum paylaşımların) kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek için telefonuna bir doğrulama kodu göndereceğiz.';

  @override
  String get accountDeleted => 'Hesabın ve verilerin silindi.';

  @override
  String get deleteAccountFailed =>
      'Hesap silinemedi. İnternet bağlantını kontrol edip tekrar dene.';

  @override
  String get logoutMessage => 'Hesabından çıkmak istediğine emin misin?';

  @override
  String get greetingNoName => 'Merhaba 👋';

  @override
  String get authInvalidCode =>
      'Kod hatalı. Lütfen SMS ile gelen kodu kontrol et.';

  @override
  String get authTooManyRequests =>
      'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';

  @override
  String get networkError =>
      'İnternet bağlantısı yok gibi görünüyor. Bağlantını kontrol et.';

  @override
  String get actionFailed => 'İşlem tamamlanamadı. Lütfen tekrar dene.';

  @override
  String actionFailedWithCode(String code) {
    return 'İşlem tamamlanamadı ($code). Lütfen tekrar dene.';
  }

  @override
  String get signInRequiredForGroups =>
      'Grup açmak ya da gruba katılmak için giriş yapmalısın.';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get loadError => 'Veriler yüklenemedi.';

  @override
  String get noDriverFound =>
      'Şu an uygun taksi bulunamadı. Biraz sonra tekrar dene.';

  @override
  String get groupFull => 'Bu grup doldu.';

  @override
  String get groupChat => 'Grup sohbeti';

  @override
  String groupChatTitle(String from, String to) {
    return '$from → $to';
  }

  @override
  String get chatEmpty =>
      'Henüz mesaj yok. Buluşma yerini ve saatini konuşmak için ilk mesajı sen yaz!';

  @override
  String get chatPrivacyNote =>
      'Telefon numaran gruptakilere gösterilmez; yalnızca adın görünür.';

  @override
  String get locationOutsideServiceArea =>
      'Hizmet bölgesinin (KKTC) dışındasın.';

  @override
  String get chatRulesNote =>
      'Uygunsuz bir mesajı şikâyet etmek ya da kişiyi engellemek için mesaja uzun bas.';

  @override
  String get reportMessage => 'Şikâyet et';

  @override
  String get reportReasonTitle => 'Şikâyet nedeni';

  @override
  String get reasonSpam => 'Spam ya da reklam';

  @override
  String get reasonHarassment => 'Hakaret veya taciz';

  @override
  String get reasonInappropriate => 'Uygunsuz içerik';

  @override
  String get reasonOther => 'Diğer';

  @override
  String get reportSent => 'Teşekkürler, şikâyetin incelenmek üzere iletildi.';

  @override
  String get blockUser => 'Bu kişiyi engelle';

  @override
  String blockUserTitle(String name) {
    return '$name engellensin mi?';
  }

  @override
  String get blockUserMessage =>
      'Bu kişinin mesajlarını artık görmeyeceksin. Engeli, gizlenen mesajına uzun basarak kaldırabilirsin.';

  @override
  String userBlocked(String name) {
    return '$name engellendi.';
  }

  @override
  String get unblockUser => 'Engeli kaldır';

  @override
  String get unblockUserMessage => 'Bu kişinin mesajları yeniden görünecek.';

  @override
  String get userUnblocked => 'Engel kaldırıldı.';

  @override
  String get blockedMessage => 'Engellediğin bir kişinin mesajı';

  @override
  String get messageHint => 'Mesaj yaz…';

  @override
  String get sendMessage => 'Gönder';

  @override
  String get unnamedPassenger => 'Yolcu';

  @override
  String get newMessages => 'Yeni mesaj var';

  @override
  String get notGroupMember => 'Bu grubun üyesi değilsin.';
}
