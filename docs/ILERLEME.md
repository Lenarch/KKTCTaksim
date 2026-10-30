# KKTC Taksim: İlerleme Kaydı

Son güncelleme: **30 Ekim 2026**. Bu dosya Claude Code ile yapılan çalışma
oturumlarının özetidir; yeni bir oturuma başlarken "nerede kalmıştık" sorusunun cevabı buradadır.
İlgili belgeler: `docs/BACKEND_PLANI.md` (Firebase yol haritası), `docs/UYARILAR.md` (bilinmesi
gerekenler ve yayından önce yapılacaklar).

## Kaldığımız yer (30 Ekim 2026)
- **Backend Aşama 0, 1 ve 2 bitti; Aşama 3'ün kodu ve kuralları hazır** (dal
  `backend/asama-3-paylasimli-gruplar`, GitHub'a gönderildi; `main`'e henüz birleştirilmedi). Kurallar 30 Ekim'de
  **Firebase'e yüklendi**.
- **Web'de tek hesapla denendi (30 Ekim):** grup oluştu (1/4), sayfa yenilenince duruyor, son üye
  ayrılınca silindi; konsolda hata yok. **Başka hesabın katılması gerçek Firebase'de denenmedi**
  (yalnızca kural testleriyle doğrulandı): ikinci test numarasını Claude'un eklemesine izin
  verilmedi; kullanıcı konsoldan `+90 533 000 00 01` / `123456` ekleyince denenebilir.
- **Sıradaki iş:** isteğe bağlı iki hesapla deneme, sonra dalı `main`'e birleştir.
- Taksi çağırma hâlâ örnek veri.
- Bugünkü işin tamamı commit edilip GitHub'a gönderildi (`c8e4074`, gizli depo
  `Lenarch/KKTCTaksim`). `CLAUDE.md` artık **yalnızca yerelde**: kullanıcı GitHub'dan sildi,
  `.gitignore`'da. Git kimliği bu depoda `Berkay <43513762+Lenarch@users.noreply.github.com>`.
- Durum (30 Ekim): `flutter analyze` temiz, `flutter test` 34/34, Firestore kural testleri 20/20.

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
| Android SDK | **Kurulu değil**: Android Studio kurulunca emülatör/telefon testi yapılabilir |
| iPhone testi | Web sürümü yerel Wi-Fi üzerinden https ile yayınlanıyor (aşağıya bak) |

Bilinen tuzaklar:
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

## Alınan kararlar
- **Backend: Firebase**, acele etmeden aşama aşama. Her aşamada: repository → kurallar → kural
  testleri (emülatör) → `firebase deploy --only firestore:rules` → web'de uçtan uca deneme.
- **Paket adı:** `com.kktctaksim.app` (kullanıcı seçti).
- **Test numarası** hayali (kullanıcının kendi numarası değil); yayından önce silinecek.
- **Bütçe:** kullanıcıya aylık 10 $ / ~500 TL bütçe uyarısı önerildi (kurulup kurulmadığı doğrulanmadı).
- **Dil:** Türkçe + İngilizce; Rusça ileride.
- **Harita:** şimdilik OpenFreeMap; yayına yaklaşırken kendi PMTiles karo sunucumuz.
- **Yayın:** internete yayın kurulmadı.

## Açık bulgular / eksikler (öncelik sırasıyla)
1. **Backend Aşama 3'ün yüklenmesi, Aşama 4–5**: canlı konum paylaşımı, yolcu–şoför eşleştirme
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
1. **Aşama 3'ü bitirmek:** isteğe bağlı iki hesapla deneme (ikinci test numarasını kullanıcı
   ekler), sonra dalı `main`'e birleştir.
   Firestore boş başlar; örnek gruplar artık görünmez.
2. Sonra **Aşama 4: canlı konum paylaşımı** (`docs/BACKEND_PLANI.md`).
3. İsteğe bağlı: iPhone testi için IP'yi yetkili alan adlarına eklemek (kullanıcı onayıyla).
