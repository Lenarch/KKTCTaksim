# KKTC Taksim: Backend Planı (Firebase)

Son güncelleme: **29 Ekim 2026**. Karar: backend **Firebase** ile kurulacak, acele etmeden ve
aşama aşama. Bu dosya yol haritası; her aşama bittiğinde güncellenir.

## Aşama 0: Hazırlık katmanı ✅ (tamamlandı, hesap gerektirmedi)
Ekranlar veriye yalnızca `Backend.instance` üzerinden erişiyor (`lib/data/backend.dart`).
Arayüzler `lib/data/repositories/`, bugünkü örnek uygulamalar `lib/data/mock/` altında:

| Arayüz | Görevi | Firebase karşılığı |
|---|---|---|
| `AuthRepository` | Telefon + SMS kodu ile giriş, ad, çıkış | Firebase Authentication (telefon) |
| `TripRepository` | Yolculuk geçmişi, planlanmış yolculuklar | Firestore `users/{uid}/trips` |
| `SharedRideRepository` | Paylaşımlı gruplar, katılma/ayrılma | Firestore `sharedRides` |
| `RideRepository` | Canlı çağrı: arama → sürücü → yolculuk → bitiş | Firestore `rides` + Cloud Functions |

Firebase bağlanınca yapılacak tek şey: bu dört arayüzün Firebase uygulamalarını yazmak ve
`Backend.instance`'ı onlarla kurmak. Ekranlar değişmeyecek.

`test/backend_test.dart` bu arayüzlerin **sözleşme testleri**; Firebase uygulamaları da aynı
testlerden (Firebase emülatörüne karşı) geçmeli.

## Firebase projesi ✅ (29 Ekim 2026)
| Ayar | Değer |
|---|---|
| Proje | `KKTCTaksim`, kimlik **`kktctaksim-1ea24`** |
| Plan | Blaze (90 günlük ücretsiz deneme kredisiyle) |
| Firestore | `(default)`, **`europe-west1` (Belçika)**, Standard sürüm, üretim modu (kurallar her şeyi kapalı tutuyor) |
| Authentication | Telefon girişi **etkin**; test numarası `+90 533 000 00 00` / kod `123456` (SMS gitmez) |
| SMS bölge politikası | **Yalnızca Türkiye (+90)** (KKTC cep numaraları da +90) |
| SMS kotası | Yeni projelerde günde en fazla 1.000 SMS (Firebase'in kendi sınırı) |
| Otomatik yedekleme | Kapalı; yayından önce açılacak |

Bütçe uyarısı kullanıcı tarafından Blaze'e geçerken ayarlanacaktı; Google Cloud > Faturalandırma >
Bütçeler ve uyarılar'dan kontrol edilmeli.

## Senin yapacakların (hesap)
1. https://console.firebase.google.com adresinde Google hesabınla yeni proje aç
   (öneri ad: `kktc-taksim`). Google Analytics isteğe bağlı.
2. **Firestore** veritabanı oluştururken konum olarak Avrupa'dan bir bölge seç
   (öneri: `europe-west`, Türkiye ve Kıbrıs'a yakın). **Bu sonradan değiştirilemez.**
3. **Blaze (kullandıkça öde) planına** geç ve bir kart tanımla. Telefonla SMS girişi ve sunucu
   kodu (Cloud Functions) için gerekli. Başlangıçta trafik düşük olduğu için maliyet de düşük
   olur; güncel SMS ve kullanım fiyatlarını kurulum günü birlikte kontrol edeceğiz.
   **Bütçe uyarısı** (örneğin aylık ₺500) kurmanı öneririm.
4. Projeye beni (geliştiriciyi) davet etmen gerekmez; bilgisayarında `firebase login` ile giriş
   yapman yeterli, kurulumu birlikte yaparız.

## Aşama 1: Kurulum + gerçek SMS girişi ✅ (29 Ekim 2026)
- Paket adı / Bundle ID: **`com.kktctaksim.app`** (Android ve iOS).
- `flutterfire configure` ile Web, Android ve iOS uygulamaları kaydedildi; ayarlar
  `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`.
- Paketler: `firebase_core`, `firebase_auth`, `cloud_firestore`.
- `lib/data/firebase/firebase_auth_repository.dart`: web'de `signInWithPhoneNumber` (görünmez
  reCAPTCHA), mobilde `verifyPhoneNumber`. Numara `+90…` biçimine çevrilir (`0533…` da olur).
  Ad `displayName`'de; profil `users/{uid}` → `{phone, name, updatedAt}`.
- `Backend.firebase()`: giriş Firebase'de; yolculuklar, gruplar ve çağrı hâlâ örnek veri.
- Güvenlik kuralları `firestore.rules` (yüklemek: `firebase deploy --only firestore:rules`):
  yalnızca kendi `users/{uid}` belgesi; geri kalan her şey kapalı.
- Web'de test numarasıyla uçtan uca denendi: giriş → konsolda kullanıcı ve profil belgesi →
  sayfa yenilenince oturum korunuyor.

Henüz yapılmayanlar (platforma özel):
- **iPhone'da yerel Wi-Fi testi:** Firebase Authentication > Ayarlar > Yetkili alan adları'na
  bilgisayarın IP'si (örn. `192.168.1.104`) eklenmeli; yoksa giriş "unauthorized-domain" hatası verir.
- **Android:** Android SDK kurulunca imza anahtarının SHA-1/SHA-256 parmak izleri Firebase'e eklenmeli.
- **iOS (Mac'te):** `GoogleService-Info.plist` ve APNs anahtarı.
- Kuralların otomatik testi (Firebase emülatörü) Aşama 2 ile birlikte.

## Aşama 2: Kalıcı yolculuk geçmişi ✅ (29 Ekim 2026)
- `lib/data/firebase/firebase_trip_repository.dart`: `users/{uid}/trips/{tripId}`; belge kimliği
  yolculuk kimliği, alanlar `Trip.toJson()` (tarih milisaniye). Liste giriş yapan kullanıcıyı izler
  (`switch_map.dart`: kullanıcı değişince eski kullanıcının akışı kapanır).
- Kurallar: yalnızca sahibi okur/ekler; alanlar ve değerler doğrulanır; tek izinli değişiklik
  "planlanmış → iptal (ücret 0)"; silme yok. Tamamlanan yolculuğu şimdilik uygulama yazıyor;
  Aşama 5'te bu sunucuya geçecek.
- **Kural testleri:** `firestore-tests/rules.test.js` (13 test). Çalıştırmak:
  `cd firestore-tests && npm test` (Java gerekir; Temurin JDK 21 kurulu). Kural değiştiren her
  aşamada önce bu testler genişletilip geçirilecek, sonra `firebase deploy --only firestore:rules`.
- Web'de denendi: yolculuk tamamlandı → sayfa yenilendi → "Geçmiş"te duruyor.

## Aşama 3: Paylaşımlı gruplar (kod hazır, kurallar yüklendi: 30 Ekim 2026)
- `lib/data/firebase/firebase_shared_ride_repository.dart`: `sharedRides/{rideId}` →
  `SharedRide.toJson()` (kimlik hariç, kalkış milisaniye); `memberIds` dizisi.
- Katılma/ayrılma **transaction** ile (iki kişi aynı anda son koltuğa katılamasın); son üye
  ayrılınca grup silinir. Liste `departure > şimdi` sorgusuyla, giriş yapan kullanıcıyı izler.
- Kurallar: giriş yapan okur; oluşturan tek ilk üye; kapasite 1–8, fiyat > 0, kalkış gelecekte;
  güncellemede yalnızca `memberIds`, yalnızca kendini ekleme (dolu/kalkışı geçmiş grupta değil) ya
  da çıkarma; silmeyi yalnızca tek kalan üye yapar. Kural testleri 20/20.
- Web'de tek hesapla denendi (oluştur → yenile → son üye ayrılınca silindi). Kalan: iki hesapla
  katılma denemesi (ikinci test numarası gerekir).

## Aşama 4: Canlı konum paylaşımı
- Paylaşılan link bugün anlık konum. Canlı takip için `rides/{rideId}` belgesini okuyabilen kısa
  ömürlü bir paylaşım bağlantısı (web sayfası) gerekecek.

## Aşama 5: Yolcu–şoför eşleştirme (şoför uygulamasıyla birlikte)
- `rides/{rideId}` → istek, durum (`RideStatus`), sürücü, sürücünün konumu.
- Çağrı yakındaki çevrimiçi şoförlere Cloud Messaging bildirimiyle gider; ilk kabul eden alır
  (transaction). Şoför yolculuğu başlatır/bitirir; yolcu ekranındaki "(DEMO)" butonları
  `RideRepository.hasDemoControls` false olunca kendiliğinden kaybolur.
- Fiyat tarifesi sunucuya taşınır; istemcinin hesapladığı fiyat yalnızca tahmin olur.

## Güvenlik kuralları taslağı (Firestore)
```
users/{uid}           → yalnızca uid sahibi okur/yazar
users/{uid}/trips/*   → yalnızca uid sahibi okur; yazma yalnızca sunucudan (tamamlanan yolculuk)
                        ya da sahibinden (rezervasyon, iptal)
sharedRides/*         → giriş yapmış herkes okur; oluşturan ilk üye olur;
                        memberIds'e yalnızca kendini ekleyip çıkarabilir, kapasite aşılamaz
rides/*               → yolcu ve atanan şoför okur; durum değişiklikleri kurallara/sunucuya bağlı
```

## Kişisel veriler (yayından önce)
- Telefon numarası ve konum kişisel veri: gizlilik metni (aydınlatma metni) ve kullanım koşulları
  gerekli; kayıt ekranındaki "Kullanım Koşulları" bağlantısı şu an "yakında" gösteriyor.
- Hesap silme seçeneği (App Store ve Google Play bunu istiyor).
