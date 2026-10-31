# KKTC Taksim: İlerleme Kaydı

Son güncelleme: **30 Ekim 2026**. Bu dosya Claude Code ile yapılan çalışma
oturumlarının özetidir; yeni bir oturuma başlarken "nerede kalmıştık" sorusunun cevabı buradadır.
İlgili belgeler: `docs/BACKEND_PLANI.md` (Firebase yol haritası), `docs/UYARILAR.md` (bilinmesi
gerekenler ve yayından önce yapılacaklar).

## Kaldığımız yer (30 Ekim 2026)
- **Backend Aşama 0, 1 ve 2 bitti; Aşama 3'ün kodu ve kuralları hazır** (dal
  `backend/asama-3-paylasimli-gruplar`, 30 Ekim'de `main`'e birleştirildi ve gönderildi: `4b42b83`). Kurallar 30 Ekim'de
  **Firebase'e yüklendi**.
- **Web'de tek hesapla denendi (30 Ekim):** grup oluştu (1/4), sayfa yenilenince duruyor, son üye
  ayrılınca silindi; konsolda hata yok. **Başka hesabın katılması gerçek Firebase'de denenmedi**
  (yalnızca kural testleriyle doğrulandı): ikinci test numarasını Claude'un eklemesine izin
  verilmedi; kullanıcı konsoldan `+90 533 000 00 01` / `123456` ekleyince denenebilir.
- **Grup sohbeti yazıldı** (dal `ozellik/grup-sohbeti`, 30 Ekim'de `main`'e birleştirildi). Kuralları 30 Ekim'de
  **yüklendi**; web'de tek hesapla denendi: sohbet açıldı, iki mesaj sırayla gitti, yenileyince
  duruyor, son üye ayrılınca grup mesajlarıyla silindi, konsolda hata yok. Denemede bulunan hata
  (Enter'la gönderince yazı alanı odağı kaybediyordu) düzeltildi. İki hesapla (rozet, başkasının
  mesajı) gerçek Firebase'de denenmedi; widget testi kapsıyor.
- Firestore'da kullanıcının kendi açtığı bir deneme grubu var ("kürşaddan → allaha"); dokunulmadı.
- **Aşama 4 (canlı konum paylaşımı) yazıldı** (dal `backend/asama-4-canli-konum`, 30 Ekim'de
  `main`'e birleştirildi). Kurallar ve takip sayfası 30 Ekim'de **yüklendi** (`https://kktctaksim-1ea24.web.app`).
  Gerçek Firebase'de uçtan uca denendi: web uygulamasında demo yolculuk → "Yolculuğumu paylaş" →
  link açıldı, konum 10 sn'de bir güncellendi, taksi varınca son konum yazıldı, "Tamamla" ile sayfa
  "Yolculuk tamamlandı"ya geçti ve konum silindi; girişsiz listeleme 403. Denemede iki hata
  bulunup düzeltildi: aralık dolmadan gelen son konum hiç yazılmıyordu (taksi durunca sayfa eski
  konumda kalıyordu) ve başlangıç yeri bağlantıyı açana "Mevcut konumun" görünüyordu.
- Firestore'da denemeden kalan iki bitmiş paylaşım var (`liveShares`, konumsuz, 4 saatte okunamaz olur).
- **Android test APK'sı** (30 Ekim): `flutter build apk --release` (debug anahtarıyla imzalı,
  89,9 MB), kopyası proje klasörünün yanında `apk/KKTCTaksim-test.apk`. İlk APK telefonda açılır
  açılmaz çöküyordu (R8, WorkManager'ın `WorkDatabase_Impl` sınıfını siliyordu); keep kuralı
  `android/app/proguard-rules.pro`. Emülatörde (`kktc_test`, Pixel 7, Android 15 + Play) denendi:
  açılış, test numarasıyla giriş, konum izni, harita.
- **Android'de gerçek numaraya SMS gitmiyordu:** `app-not-authorized … Invalid app info in
  play_integrity_token` (APK Play Store'dan gelmediği için Play Integrity tanımıyor). Android'de
  `setSettings(forceRecaptchaFlow: true)` ile reCAPTCHA'ya geçildi
  (`FirebaseAuthRepository.init`). Emülatörde istek reCAPTCHA'dan geçip Firebase'e ulaştı; ancak
  çok deneme yüzünden emülatör geçici engellendi (`too-many-requests`), SMS'in geldiği henüz
  görülmedi. Kullanıcının arkadaşı kendi telefonunda deneyecek.
- **31 Ekim, arkadaşın telefonunda grup açılamıyordu** (ekran kaydı: "Nereden?" alanı seçili ama
  klavye hiç açılmıyor; Xiaomi/MIUI benzeri). Alt penceredeki `autofocus` odağı açılış kayması
  sırasında istiyordu; artık `focusAfterTransition` (`lib/core/focus_after_transition.dart`) ile
  kayma bitince odaklanıyor (grup formu ve "Nereye?" araması). Emülatörde doğrulandı; gerçek
  Xiaomi'de denenmedi.
- Aynı gün bulunanlar: **Android'de adres araması hiç çalışmıyordu** (Photon, Dart'ın varsayılan
  User-Agent'ını 403 ile reddediyor; `lib/core/http_headers.dart` ile uygulama kimliği gönderiliyor,
  web'de gönderilmez). Form fiyatı/yer adını kurallarla aynı sınırlıyor (kişi başı ≤ 100.000 ₺,
  yer adı ≤ 200). Yeni gruptaki sohbet dinleyicisi grup sunucuya ulaşmadan "izin yok" alıyordu;
  `retryWhilePermissionDenied` ile yeniden deniyor. Firebase Android uygulamasına debug anahtarının
  SHA-1/SHA-256'sı eklendi (telefonla giriş için).
- **Web'de gerçek numarayla giriş `localhost`'ta çalışmıyor:** `invalid-app-credential` (Firebase
  localhost'tan gelen reCAPTCHA'yı reddediyor). Test numarası çalışır. Web gerçek bir adreste
  yayınlanınca denenmeli.
- **Sıradaki iş:** Aşama 5 (şoför uygulaması ve eşleştirme).
- Taksi çağırma hâlâ örnek veri.
- Bugünkü işin tamamı commit edilip GitHub'a gönderildi (`c8e4074`, gizli depo
  `Lenarch/KKTCTaksim`). `CLAUDE.md` artık **yalnızca yerelde**: kullanıcı GitHub'dan sildi,
  `.gitignore`'da. Git kimliği bu depoda `Berkay <43513762+Lenarch@users.noreply.github.com>`.
- Durum (30 Ekim): `flutter analyze` temiz, `flutter test` 39/39, Firestore kural testleri 31/31.

## Uygulamanın amacı
KKTC'ye özel taksi çağırma platformu. Üç rol var: **yolcu**, **şoför**, **taksi durağı** (şoför ve
durak henüz "yakında"). Yolcu tarafında taksi çağırma, paylaşımlı yolculuk (Vito grupları), keşfet
(gezilecek yerler) ve profil bölümleri var.

## Geliştirme ortamı (Windows)
| Ne | Nerede / Nasıl |
|---|---|
| Proje | `C:\Users\MONSTER\OneDrive\Masaüstü\kktctaksim\KKTCTaksim` (git deposu, `origin/main`) |
| ASCII junction | `C:\src\kktc` → aynı klasör. **Flutter komutlarını buradan çalıştır**: yoldaki "Masaüstü" kelimesi `flutter analyze`'ı çökertiyor. Git Bash `cd /c/src/kktc` yapınca gerçek yola çözümlüyor ve analiz yine çöküyor; **PowerShell'de `Set-Location C:\src\kktc` kullan.** |
| Flutter SDK | `C:\src\flutter` (stable 3.47.8, Dart 3.13.7) |
| Firebase CLI | `firebase` (npm global, 15.34.2), `firebase login` yapıldı: berkayserin1290@gmail.com |
| FlutterFire CLI | `%LOCALAPPDATA%\Pub\Cache\bin\flutterfire.bat` (PATH'te değil, tam yolla çağır) |
| Java | Eclipse Temurin JDK 21 (Firestore emülatörü için). Eski açık terminallerde PATH'te olmayabilir |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` (Android Studio yok; komut satırı araçları 23, platform 35/36, build-tools 35/36, NDK 28.2.13676358, `ANDROID_HOME` ayarlı). Emülatör yok |
| iPhone testi | Web sürümü yerel Wi-Fi üzerinden https ile yayınlanıyor (aşağıya bak) |

Bilinen tuzaklar:
- Emülatör: `%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd kktc_test`; APK kurmak
  `adb install -r <apk>`, çökme kaydı `adb logcat -b crash`.
- Yeni Android komut satırı araçlarında `sdkmanager` yerine `android sdk install <paket/yol>`
  (ör. `ndk/28.2.13676358`). Gradle NDK'yı kendisi kuramıyor ("Package ndk not found"); elle kur.
- `google_mobile_ads` 5.x Gradle 9 ile derlenmiyor (`configurations.all`); 9.2.0'a yükseltildi.
- `flutter build web` "arb-dir doesn't allow reading and writing" derse: OneDrive `lib\l10n`'e
  salt-okunur işareti koymuş; `attrib -R` ile kaldır.
- `flutter test` bazen `build\unit_test_assets` silinemedi diye düşüyor (OneDrive kilidi).
  Önce `Remove-Item -Recurse -Force build\unit_test_assets` çalıştır.
- Widget testlerinde (`testWidgets`) bir akışı `await stream.first` ile beklemek testi
  **sonsuza kadar kilitliyor** (sahte zaman). Sonucu ekrandan kontrol et.
- Git Bash heredoc'ları bazen bozuluyor; uzun düzenlemeler için Write/Edit aracı ya da
  scratchpad'e yazılmış Python betiği kullan. Python'da Windows yollarındaki `\b`, `\f` kaçış
  karakterine dönüşüyor: dikkat.

### iPhone'da test (yerel Wi-Fi, https)
Safari konumu yalnızca https'te paylaştığı için kendi imzaladığımız sertifika kullanılıyor.
```bash
cd C:/src/kktc
flutter build web --release
# sertifika (bir kez, 30 gün geçerli): tool/README içindeki openssl komutu
python -u tool/serve_https.py build/web tool/certs
```
- Telefondan: `https://192.168.1.104:8080` (IP değişirse `ipconfig` ile bak). Safari uyarısında
  "Ayrıntıları Göster → bu web sitesini ziyaret et".
- Windows'ta Wi-Fi ağı **Özel** profilde olmalı. Güvenlik duvarı kuralı:
  `KKTC Taksim test sunucusu` (TCP 8080, yalnızca Özel ağ).
- ⚠️ Firebase girişi artık gerçek: telefondan denemeden önce bilgisayarın IP'si Firebase
  Authentication > Ayarlar > **Yetkili alan adları**'na eklenmeli (henüz eklenmedi; kullanıcı onayı gerekir).

### Bilgisayardan web testi
`build/web` klasöründe `python -m http.server 8090 --bind 127.0.0.1`, tarayıcıda
`http://localhost:8090` (Firebase'in yetkili alan adlarında `localhost` var, `127.0.0.1` yok).
Bu bilgisayarın gerçek konumu Kıbrıs dışında; mesafeler yüzlerce km çıkabilir, normal.

## Yapılanlar (28 Ekim 2026)
1. **Derleme hataları** düzeltildi (silinmiş renkler, var olmayan `MyApp`).
2. **Akış**: splash → rol seçimi → giriş/kayıt → OTP → ana sayfa bağlandı.
3. **Ana sayfa taksi akışı**: varış → taksi tipi → arama → sürücü → yolculuk → puanlama.
4. **Kod yapısı**: tasarım token'ları, açık/koyu tema, modeller, ana sayfa sheet'leri ayrıldı.
5. **Platform**: Android/iOS izinleri, iOS AdMob kimliği, web desteği (web'de reklam yok).
6. **Harita**: MapLibre + OpenFreeMap vektör karoları (ücretsiz, anahtarsız), etiketler uygulama dilinde.
7. **Gerçek konum**: `geolocator`; izin yoksa Lefkoşa merkez.

## Yapılanlar (29 Ekim 2026)
### Öneri listesinin 1–11. maddeleri
1. **Adres arama**: Photon (OSM) ile canlı arama, Kıbrıs'la sınırlı; **haritadan seç** (ortadaki iğne,
   ters aramayla sokak/semt adı).
2. **Rota, mesafe, süre**: OSRM demo sunucusu; hata olursa kuş uçuşu × 1,3 ("Yaklaşık").
3. **Tahmini fiyat**: `lib/core/fare_calculator.dart` örnek tarife (açılış ₺100 + km ₺40, en az ₺150;
   Konfor ×1,3, XL ×1,8; ±%10). Gerçek tarife gelince yalnızca `Tariff` değişir.
4. **Ödeme yöntemi** (Nakit/Kart) ve **ileri tarihli rezervasyon** (30 dk – 30 gün).
5. **Yolculuk geçmişi** (bugün Firestore'da, aşağıya bak).
6. **Sürücü kartı** (baş harfli avatar, büyük plaka, araç rengi); taksi rota boyunca hareket eder.
7. **Güvenlik**: yolculuğu paylaşma (anlık konum linki), acil arama 155 / 112 / 199.
8. **Dil**: Türkçe + İngilizce (`lib/l10n/*.arb`); Profil > Dil.
9. **Giriş**: yalnızca telefon + SMS kodu.
10. **Keşfet**: 10 yer, 6 kategori, gerçek mesafe, "Buraya taksi".
11. **Paylaşımlı**: kişi başı fiyat, gruptan ayrılma, tarih seçimi.

### Backend (Firebase)
- **Aşama 0:** ekranlar veriye yalnızca `Backend.instance` üzerinden erişiyor (`lib/data/backend.dart`);
  arayüzler `lib/data/repositories/`, örnek uygulamalar `lib/data/mock/`, sözleşme testleri
  `test/backend_test.dart`. Sürücü simülasyonu `MockRideRepository`'de; sheet'ler durum değişince
  kendiliğinden kapanıyor. SMS kodu 6 haneli.
- **Firebase projesi:** `kktctaksim-1ea24`, Blaze, Firestore `europe-west1`, telefon girişi, SMS
  yalnızca Türkiye, test numarası `+90 533 000 00 00` / `123456`.
- **Paket adı:** `com.kktctaksim.app` (Android + iOS). `flutterfire configure` ile Web/Android/iOS kayıtlı.
- **Aşama 1:** `FirebaseAuthRepository` (gerçek SMS girişi). Uygulama `Backend.firebase()`, testler
  `Backend.mock()` kullanıyor.
- **Aşama 2:** `FirebaseTripRepository` (`users/{uid}/trips`), kurallar `firestore.rules`,
  kural testleri `firestore-tests/` (`npm test`, 13 test). Web'de uçtan uca denendi.

## Yapılanlar (30 Ekim 2026)
- **Backend Aşama 3 (paylaşımlı gruplar):** `lib/data/firebase/firebase_shared_ride_repository.dart`
  (`sharedRides/{id}`); katılma/ayrılma transaction ile, son üye ayrılınca grup silinir. Üyelik
  hesabı mock ile ortak: `membersAfterJoin` / `membersAfterLeave`
  (`lib/data/repositories/shared_ride_repository.dart`). `Backend.firebase()` buna bağlandı.
- **Kurallar** (`firestore.rules`): giriş yapan okur; oluşturan tek ilk üye; alanlar doğrulanır
  (kapasite 1–8, fiyat > 0, kalkış gelecekte); güncellemede yalnızca `memberIds` değişir ve yalnızca
  kendini sona ekleyerek (kapasite ve kalkış kontrolüyle) ya da kendini çıkararak; listeyi boşaltmak
  yerine son üye grubu siler. 7 yeni kural testi.
- **Grup sohbeti** (kullanıcı istedi: Vito grubundakilerin haberleşecek yeri yoktu):
  `sharedRides/{id}/messages` (`senderId`, `senderName`, `text` ≤ 500, `sentAt` sunucu zamanı).
  Yalnızca o anki üyeler okur/yazar; telefon numarası gösterilmez, yalnızca ad; mesajlar
  değiştirilemez; son üye ayrılırken uygulama önce mesajları siler (alt koleksiyon belgeyle
  silinmez), sonra grubu. Ekran `lib/screens/group_chat_screen.dart`; kartta üyelere "Grup sohbeti"
  düğmesi ve okunmamış mesaj rozeti (`lib/services/chat_read_state.dart`, cihazda saklanır).
  **Push bildirim yok** (kullanıcı kararı: Aşama 5'te FCM + Cloud Functions ile).

- **Aşama 4: canlı konum paylaşımı.** Güvenlik menüsündeki "Yolculuğumu paylaş" artık
  `https://kktctaksim-1ea24.web.app/t/<kimlik>` takip bağlantısı gönderiyor (uygulama ve hesap
  gerekmez). `liveShares/{kimlik}`: rastgele kimlik, listeleme kapalı, girişsiz okuma yalnızca
  `expiresAt`'e kadar (en fazla 6 saat; uygulama 4 saat veriyor). Konum en fazla 10 sn'de bir
  yazılır (`AppDurations.liveShareInterval`); yolculuk bitince/iptalde paylaşım `ended` olur ve
  konum silinir. Konum kaynağı: haritadaki taksi konumu (`RideSession.progress`; demoda
  simülasyon, Aşama 5'te şoförün gerçek konumu). Başlatılamazsa eski "o anki konum" bağlantısı.
  Kod: `lib/data/repositories/live_share_repository.dart`, `lib/services/live_share_controller.dart`,
  sayfa `hosting/public/track.html` (MapLibre + OpenFreeMap + Firebase JS SDK, TR/EN).
  Yerel deneme: `firebase emulators:start --only firestore,hosting` →
  `http://localhost:5000/t/<kimlik>?emulator` (veriyi emülatöre REST ile yazarak).

## Alınan kararlar
- **Backend: Firebase**, acele etmeden aşama aşama. Her aşamada: repository → kurallar → kural
  testleri (emülatör) → `firebase deploy --only firestore:rules` → web'de uçtan uca deneme.
- **Paket adı:** `com.kktctaksim.app` (kullanıcı seçti).
- **Test numarası** hayali (kullanıcının kendi numarası değil); yayından önce silinecek.
- **Bütçe:** kullanıcıya aylık 10 $ / ~500 TL bütçe uyarısı önerildi (kurulup kurulmadığı doğrulanmadı).
- **Dil:** Türkçe + İngilizce; Rusça ileride.
- **Harita:** şimdilik OpenFreeMap; yayına yaklaşırken kendi PMTiles karo sunucumuz.
- **Yayın:** uygulama internete yayınlanmadı. Canlı takip sayfası için **Firebase Hosting** seçildi
  (kullanıcı kararı, 30 Ekim); Hosting'de yalnızca `hosting/public` (takip sayfası) var, Flutter
  uygulaması değil.

## Açık bulgular / eksikler (öncelik sırasıyla)
1. **Aşama 4'ün yüklenmesi, Aşama 5**: canlı konum paylaşımı, yolcu–şoför eşleştirme
   (`docs/BACKEND_PLANI.md`).
2. **Şoför modu / uygulaması** (Aşama 5 ile birlikte).
3. Photon ve OSRM demo sunucuları yayın için uygun değil; OSRM bazı rotaları uzun çiziyor.
4. Adres aramasında Güney Kıbrıs sonuçları da çıkıyor.
5. Kıbrıs dışındaki konum gerçek kabul ediliyor (Keşfet mesafeleri yüzlerce km).
6. Gerçek tarife, Keşfet görselleri ve kesin koordinatlar.
7. İngilizce metinlerin anadil kontrolü.
8. Yayından önce: AdMob test kimlikleri, Firebase test numarası ve test kullanıcısı, App Check,
   Firestore yedekleme, gizlilik metni, hesap silme (`docs/UYARILAR.md`).

## Sıradaki adım
1. İsteğe bağlı: iki hesapla katılma denemesi (ikinci test numarasını kullanıcı ekler).
   Firestore boş başlar; örnek gruplar artık görünmez.
2. Sonra **Aşama 4: canlı konum paylaşımı** (`docs/BACKEND_PLANI.md`).
3. İsteğe bağlı: iPhone testi için IP'yi yetkili alan adlarına eklemek (kullanıcı onayıyla).
