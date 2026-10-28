# KKTC Taksim: İlerleme Kaydı

Son güncelleme: **28 Ekim 2026**. Bu dosya Claude Code ile yapılan çalışma oturumlarının
özetidir; yeni bir oturuma başlarken "nerede kalmıştık" sorusunun cevabı buradadır.

## Uygulamanın amacı
KKTC'ye özel taksi çağırma platformu. Üç rol var: **yolcu**, **şoför**, **taksi durağı**.
Yolcu tarafında taksi çağırma, paylaşımlı yolculuk (Vito grupları), keşfet (gezilecek yerler)
ve profil bölümleri bulunuyor. Şu an backend yok; tüm veriler `lib/data/mock_data.dart`
içindeki örnek verilerdir.

## Geliştirme ortamı (Windows)
| Ne | Nerede / Nasıl |
|---|---|
| Proje | `C:\Users\MONSTER\OneDrive\Masaüstü\kktctaksim\KKTCTaksim` |
| ASCII junction | `C:\src\kktc` → aynı klasör. **Flutter komutlarını buradan çalıştır**: yoldaki "Masaüstü" kelimesi `flutter analyze`'ı çökertiyor (Dart analiz sunucusu hatası). |
| Flutter SDK | `C:\src\flutter` (stable 3.47.8, Dart 3.13.7), kullanıcı PATH'ine eklendi |
| Android SDK | **Kurulu değil**: Android Studio kurulunca emülatör/telefon testi yapılabilir |
| Visual Studio | Yok (gerekmiyor); editör olarak VS Code var |
| iPhone testi | Web sürümü yerel Wi-Fi üzerinden https ile yayınlanıyor (aşağıya bak) |

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
  `KKTC Taksim test sunucusu` (TCP 8080, yalnızca Özel ağ). Kaldırmak için yönetici PowerShell'de
  `Remove-NetFirewallRule -DisplayName "KKTC Taksim test sunucusu"`.

## Yapılanlar (28 Ekim 2026)
1. **Derleme hataları**: son tema commit'i silinmiş renkleri (`primaryGreen` vb.) kullanan
   ekranlar bırakmıştı; proje derlenmiyordu. Test dosyası var olmayan `MyApp`'i çağırıyordu.
2. **Akış**: splash → rol seçimi → giriş/kayıt → OTP → ana sayfa akışı bağlandı (önceden giriş
   ekranlarına ulaşılamıyordu). Formlara doğrulama eklendi.
3. **Ana sayfa taksi akışı**: varış → taksi tipi → arama → sürücü → yolculuk → puanlama. Aramayı
   iptal etmek artık gerçekten iptal ediyor (Timer); geri tuşu akışı kilitlemiyor.
4. **Kod yapısı**: tasarım token'ları (`lib/core/app_tokens.dart`), tam açık/koyu tema,
   modeller (`lib/models`), örnek veri (`lib/data`), ana sayfa sheet'leri `lib/widgets/home`
   altına bölündü, rotalar `lib/core/app_routes.dart`.
5. **Platform**: Android INTERNET + konum izinleri, iOS AdMob kimliği (eksikti, açılışta
   çökerdi) + konum izin metni, web desteği eklendi (web'de reklamlar kapalı).
6. **Harita**: CARTO artık API anahtarı istiyordu, harita hiç görünmüyordu. Önce OSM raster'a,
   sonra **MapLibre + OpenFreeMap vektör karolarına** geçildi (ücretsiz, anahtarsız).
   Etiketler **telefonun dilinde** (`name:tr` → `name:latin` → `name`), koyu temada gerçek
   karanlık stil.
7. **Gerçek konum**: `geolocator` ile. İzin yoksa / https değilse Lefkoşa merkez + açıklayıcı mesaj.
   Demo taksiler kullanıcının konumunun etrafına yerleşiyor.
8. **Tarayıcıda gezinti incelemesi** yapıldı; bulunan form hatası (paylaşımlı grup oluşturma
   2. adımı 1. adımın yazısını taşıyordu) düzeltildi ve teste bağlandı.

Durum: `flutter analyze` temiz, `flutter test` 7/7 geçiyor.

## Alınan kararlar
- **Harita**: şimdilik OpenFreeMap (OSM verisi). Yayına yaklaşırken kendi karo sunucumuz:
  Kıbrıs'ın OSM verisi tek PMTiles dosyası olarak barındırılacak, stil sarı-siyah tasarıma göre
  yazılacak, Türkçe ad öncelikli.
- **Uygulama dili**: metinler şimdilik yalnızca Türkçe (İngilizce desteği öneri listesinde).
- **Backend**: henüz karar verilmedi; öneri Firebase (Auth + Firestore + Cloud Messaging).
- **Yayın**: internete yayın kurulmadı; yalnızca yerel Wi-Fi testi var.

## Açık bulgular / eksikler (öncelik sırasıyla)
1. **Şoför modu**: ← *sıradaki iş* (rol seçiminde "Ben Şoförüm" şu an "yakında" diyor)
2. Varış noktası seçimi: gerçek adres arama, haritada dokunarak seçme, rota/mesafe/süre
3. Fiyat mesafeye göre hesaplanmıyor (her yere aynı fiyat)
4. Tamamlanan yolculuklar "Geçmiş"e eklenmiyor
5. İleri tarihli rezervasyon yok (özellikle Ercan Havalimanı transferleri için önemli)
6. Ödeme yöntemi seçimi (nakit/kart) yok
7. "Güvenlik Araçları" boş: yolculuk paylaşma, acil arama (polis 155, ambulans 112)
8. Paylaşımlı: örnek grupların tarihi geçmiş, gruptan ayrılma yok, kişi başı/toplam fiyat belirsiz,
   grup oluştururken tarih seçilemiyor
9. Keşfet: kartlarda "Buraya taksi çağır" yok, 7 kategoriden 4'ü boş, görseller yer tutucu
10. Giriş e-posta+şifre, kayıt telefon+SMS ile yapılıyor; tutarlı olması için tek yöntem
    (telefon + SMS) önerildi
11. İngilizce dil desteği (turist ve öğrenciler için)
12. OSM'de Kaymaklı iç sokaklarının Türkçe adı yok (veri eksiği, OSM'ye katkıyla çözülebilir)
13. Yayından önce: paket adı `com.example.kktc_taksim`, AdMob test kimlikleri değişmeli

## Sıradaki adım
**Şoför modu.** Rol seçiminde "Ben Şoförüm" → şoför girişi → şoför ana ekranı
(çevrimiçi/çevrimdışı, gelen çağrı, kabul/ret, yolcuya gidiş, yolculuk, kazanç özeti).
Backend olmadığı için yolcu ve şoför tarafı şimdilik ayrı demo akışlar olacak.
