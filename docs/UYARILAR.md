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
- Rota servisine ulaşılamazsa mesafe kuş uçuşunun 1,3 katı olarak tahmin edilir ve ekranda
  "Yaklaşık" yazar.

## Adres ve konum
- Adres aramasında **Güney Kıbrıs sonuçları da** çıkıyor. İstenirse KKTC sınırına göre süzülebilir.
- Uygulama Kıbrıs dışından açılırsa (örneğin bilgisayardan test) **gerçek konum** kullanılıyor;
  Keşfet mesafeleri yüzlerce km görünüyor (testte 652 km). İstenirse hizmet bölgesi dışındayken
  harita Lefkoşa merkeze düşürülebilir.
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

## Yayından önce mutlaka
- Backend: Firebase seçildi; plan ve senin yapacakların `docs/BACKEND_PLANI.md` içinde
  (Blaze planı + kart, Firestore bölgesi sonradan değiştirilemez)
- Gizlilik metni, kullanım koşulları ve hesap silme seçeneği
- Şoför uygulaması (rol seçiminde hâlâ "yakında")
- Firebase test numarası (`+90 533 000 00 00`) silinmeli: bu numara + kodla herkes giriş yapabilir
- Firestore otomatik yedeklemeyi aç; App Check'i etkinleştir
- AdMob test kimlikleri gerçek kimliklerle değişmeli
