# KKTC Taksim: Uyarılar

Son güncelleme: **29 Ekim 2026** (backend hazırlığından sonra). Uygulama şu an demo; aşağıdakiler yayından önce bilinmesi ve
çözülmesi gereken noktalar.

## Harici servisler
- **Adres arama (Photon)** ve **rota (OSRM)** ücretsiz, herkese açık demo sunucularını kullanıyor.
  Test için yeterli ama kullanım sınırları olduğu için **yayın için uygun değil**; kendi sunucumuz
  ya da ücretli bir servis gerekecek.
  İlgili dosyalar: `lib/services/geocoding_service.dart`, `lib/services/routing_service.dart`.
- OSRM bazı rotaları olduğundan uzun çiziyor. Örnek: Lefkoşa → Bellapais 35,7 km çıktı; karayoluyla
  yaklaşık 22 km olmalı. Fiyat tahmini bu mesafeye göre hesaplandığı için fiyat da yüksek çıkar.
- Şoför haritasındaki rota da OSRM demo sunucusundan gelir: şoför saptıkça en fazla 15 sn'de bir yeni
  rota istenir. Çok şoförle demo sunucusu sınıra takılabilir; yayından önce kendi OSRM sunucumuz şart.
  Sesli ya da adım adım tarif yok; şoför isterse "Google Haritalar'da aç" ile dış uygulamaya geçer.
- Rota servisine ulaşılamazsa mesafe kuş uçuşunun 1,3 katı olarak tahmin edilir ve ekranda
  "Yaklaşık" yazar.

## Adres ve konum
- Photon, Dart'ın varsayılan User-Agent'ını reddediyor; harici servis isteklerine
  `externalServiceHeaders` eklenmeli (`lib/core/http_headers.dart`).
- Adres araması yalnızca KKTC sonuçlarını gösterir (31 Ekim). Photon'un `state` alanına dayanır;
  alan boş gelen sonuçlar elenmez.
- Uygulama Kıbrıs dışından açılırsa (örneğin bilgisayardan ya da emülatörden test) gerçek konum
  kullanılmaz; harita Lefkoşa merkezde açılır ve "hizmet bölgesinin dışındasın" mesajı çıkar.
- Keşfet'teki yerlerin koordinatları **yaklaşık**; görseller yer tutucu (renkli arka plan + ikon).

## Fiyat
- Tarife **örnek**: açılış ₺100, km başı ₺40, en az ₺150; Konfor ×1,3, XL ×1,8; ekranda ±%10 aralık.
- Gerçek tarife belli olunca yalnızca `lib/core/fare_calculator.dart` içindeki `Tariff` değişir.

## Grup sohbeti
- Yeni mesaj gelince **bildirim gelmez**; okunmamış mesaj yalnızca Paylaşımlı sekmesindeki rozetle
  görünür. Push bildirim Aşama 5'te.
- Mesajlarda telefon numarası görünmez, yalnızca kayıttaki ad; adı olmayan "Yolcu" görünür.
- Şikâyet/engelleme ve küfür filtresi yok; yayından önce düşünülmeli (App Store kullanıcı içeriği
  olan uygulamalarda şikâyet etme ve engelleme ister).

## Güvenlik özellikleri
- "Yolculuğumu paylaş" artık **canlı takip bağlantısı** gönderir (Aşama 4); başlatılamazsa (ör.
  internet yok) eskisi gibi o anki konumun linki gider.
- Konumu yolcunun uygulaması yazar: uygulama arka plandayken ya da telefon kilitliyken
  güncelleme durur (sayfa 2 dakika sonra "konum bir süredir güncellenmedi" uyarısı gösterir).
  Aşama 5'te konum şoför uygulamasından geleceği için bu sorun büyük ölçüde kalkar.
- Takip sayfasında gösterilen konum **haritadaki taksinin konumu**; demoda bu simülasyondur, yani
  telefonun gerçek GPS'i değil. Aşama 5'te şoförün gerçek konumu olacak.
- Bağlantıyı alan herkes (iletirse onun ilettikleri de) yolculuk bitene kadar konumu görür; en
  fazla 4 saat sonra bağlantı kapanır. Süresi dolan kayıtlar Firestore'da okunamaz halde kalır
  (otomatik silme ileride Cloud Function ile).
- Paylaşım menüsü olmayan tarayıcılarda bilgiler panoya kopyalanır.

## Demo davranışları
- Sürücü arama, sürücünün gelişi (20 sn) ve yolculuk (30 sn) **simülasyondur**; gerçek süreden
  bağımsız olarak hızlandırılmış oynatılır (`AppDurations`, `lib/core/app_tokens.dart`).
- Giriş **gerçek Firebase** ile: gerçek numaraya gerçek SMS gider (ücretli, günde en fazla 1.000).
  Denemelerde test numarasını kullan: `+90 533 000 00 00`, kod `123456` (SMS gitmez).
- Firebase'de denemeden kalan bir test kullanıcısı var ("Test Kullanıcı", `+905330000000`);
  yayından önce test numarasıyla birlikte silinmeli.
- iPhone'da yerel Wi-Fi testi için bilgisayarın IP'si Firebase'in yetkili alan adlarına eklenmeli.
- Yolculuk geçmişi ve rezervasyonlar **Firestore'da kalıcı**. Paylaşımlı gruplar da Firestore'a
  taşındı (30 Ekim, kurallar yüklendi; tek hesapla denendi, iki hesapla katılma henüz denenmedi). Firestore boş başladığı için örnek gruplar görünmez. Taksi çağırma hâlâ örnek veri.
- Sürücü fotoğrafı yok; avatar yerine baş harfler gösteriliyor.

## Dil
- İngilizce metinler bir anadil konuşana kontrol ettirilmeli. Rusça ileride eklenebilir.
- Yeni bir metin eklerken hem `lib/l10n/app_tr.arb` hem `lib/l10n/app_en.arb` dosyasına eklenmeli.

## Yeni paketler
- `intl`, `share_plus`, `shared_preferences`, `firebase_core`, `firebase_auth`, `cloud_firestore`.
- Firestore kural testleri için `firestore-tests/` (npm) ve bilgisayarda Java (Temurin JDK 21).

## Android
- Test APK'sı **debug anahtarıyla** imzalı; mağazaya yüklenemez. Yayın için ayrı bir yükleme
  anahtarı oluşturulmalı ve onun SHA parmak izleri de Firebase'e eklenmeli.
- Web'de gerçek numarayla giriş `localhost`'ta `invalid-app-credential` veriyor; gerçek alan adında
  denenmeli.

- Android'de giriş şimdilik **reCAPTCHA** ile (kısa bir tarayıcı sayfası, bazen resim
  bulmacası): Play Store dışı APK'yı Play Integrity tanımıyor. Play Store'a çıkınca
  `FirebaseAuthRepository.init`'teki `forceRecaptchaFlow` kaldırılmalı.
- Aynı cihazdan çok sayıda kod isteyince Firebase cihazı birkaç saat engelliyor
  (`too-many-requests`); denemelerde test numarasını kullan.

## Şoför modu (31 Ekim)
- **Demo taksi artık yok:** yolcu çağrısı gerçek bir şoförün kabul etmesini bekler; 3 dakika içinde
  çevrimiçi şoför yoksa "uygun taksi bulunamadı" der. Test için bir telefonu şoför moduna almak gerekir.
- Şoför konumu yalnızca **uygulama açıkken** yazılır (arka plan konumu ve bildirim yok, B2'de
  bildirim gelecek). Şoför uygulamayı kapatırsa yolcu taksiyi hareketsiz görür.
- Şoför kendi çağrısını kabul edebiliyor (tek test numarasıyla deneme için); yayından önce
  kurallarda `driverId != passengerId` şartı eklenmeli.
- Ücret tahminidir; şoför bitirince yolcunun geçmişine aralığın ortası yazılır. Gerçek ücret/taksimetre yok.
- Puanlar `rides` belgesinde duruyor ama şoför ortalaması hesaplanmıyor (her şoför 5.0 görünür).

## Yayından önce mutlaka
- Backend: Firebase seçildi; plan ve senin yapacakların `docs/BACKEND_PLANI.md` içinde
  (Blaze planı + kart, Firestore bölgesi sonradan değiştirilemez)
- ⚠️ **İLETİŞİM ADRESİ YER TUTUCUSU:** `hosting/public/gizlilik.html` ve `kosullar.html`
  sayfalarında (TR ve EN, toplam 4 yerde) iletişim adresi olarak **`[İLETİŞİM E-POSTASI]`** yazıyor.
  Yayından önce gerçek bir e-posta adresiyle değiştirilip `firebase deploy --only hosting` ile
  yüklenmeli. App Store ve Google Play gizlilik politikasında çalışan bir iletişim adresi ister;
  eksik kalırsa uygulama **reddedilir**, ayrıca kişisel veri mevzuatı (KVKK / KKTC Kişisel Verilerin
  Korunması Yasası) açısından **hukuki risk** doğar. Kontrol: `grep -r "İLETİŞİM E-POSTASI" hosting/`.
- Gizlilik politikası ve kullanım koşulları **taslak**: yayından önce bir hukukçuya okutulmalı.
- **Şoför onayı (1 Kasım 2026):** şoför kaydı artık başvuru; `drivers/{uid}.approved: true` alanını
  yalnızca yönetici Firebase konsolundan verir (kurallar istemcinin yazmasını engeller). Onaysız şoför
  çevrimiçi olamaz, çağrı göremez, kabul edemez; uygulama "Başvurun inceleniyor" der. Şoför kendi
  çağrısını da alamaz. Onay verme adımı: Firebase konsolu → Firestore → `drivers` → şoförün belgesi →
  alan ekle `approved` (boolean) `true`.
- ⚠️ **Yayından önce hâlâ eksik:** ehliyet, ruhsat, taksi plakası ve sigorta belgelerinin yüklenip
  kontrol edilmesi ve onay için bir yönetici paneli (şimdilik onay elle, konsoldan verilir).
- Sohbet şikâyetlerini inceleyecek bir süreç: şikâyetler şimdilik yalnızca Firebase konsolunda
  (`reports` koleksiyonu) görülüyor.
- Şoför uygulaması (rol seçiminde hâlâ "yakında")
- Firebase test numarası (`+90 533 000 00 00`) silinmeli: bu numara + kodla herkes giriş yapabilir
- Firestore otomatik yedeklemeyi aç; App Check'i etkinleştir
- AdMob test kimlikleri gerçek kimliklerle değişmeli
