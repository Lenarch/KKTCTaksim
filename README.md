# KKTC Taksim

KKTC için taksi çağırma ve paylaşımlı yolculuk uygulaması (Flutter).

## Özellikler (demo)
- Rol seçimi (yolcu / şoför / durak), telefon numarası + SMS koduyla giriş ve kayıt
- Gerçek konum, adres arama ve haritadan seçme, rota/mesafe/süre, mesafeye göre tahmini fiyat
- Nakit/kart seçimi, ileri tarihli rezervasyon, sürücü takibi, yolculuk paylaşma ve acil arama
- Yolculuk geçmişi; paylaşımlı yolculuk grupları (katılma, ayrılma, kişi başı ücret)
- Keşfet: kategorili yerler ve "Buraya taksi"
- Türkçe ve İngilizce; açık ve koyu tema

Backend **Firebase** (proje `kktctaksim-1ea24`): giriş ve yolculuk geçmişi gerçek; paylaşımlı gruplar
ve taksi çağırma şimdilik örnek veri. Yol haritası: `docs/BACKEND_PLANI.md`.

## Proje yapısı
```
lib/
  core/      tema, token'lar, rotalar, doğrulayıcılar, fiyat tarifesi (fare_calculator.dart), biçimlendirme
  data/      Backend erişim noktası (backend.dart), repositories/ arayüzler,
             firebase/ Firebase uygulamaları, mock/ örnek uygulamalar
  models/    Trip, Place, SharedRide, Driver, TaxiOption
  l10n/      dil dosyaları (app_tr.arb şablon, app_en.arb); kod `flutter gen-l10n` ile üretilir
  services/  konum, adres arama (Photon), rota (OSRM), harita stili (MapLibre + OpenFreeMap), ayarlar
  screens/   tam sayfa ekranlar
  widgets/   ortak bileşenler; home/ altında ana sayfanın bottom sheet'leri
```

## Çalıştırma
```
flutter pub get
flutter analyze
flutter test
flutter run
```

> Windows notu: Proje yolunda Türkçe karakter varsa (örn. `Masaüstü`) `flutter analyze` çökebilir.
> Projeyi ASCII bir yola taşıyın ya da bir junction üzerinden çalıştırın.

iPhone'da yerel ağ üzerinden test için `tool/README.md`, geliştirme durumu için `docs/ILERLEME.md`.

## Yayından önce yapılacaklar
- AdMob test kimlikleri (AndroidManifest, Info.plist, `main_navigation_screen.dart`) gerçek kimliklerle değiştirilmeli
- Paylaşımlı gruplar, canlı konum ve yolcu–şoför eşleştirme Firebase'e taşınmalı
- Ayrıntılı liste: `docs/UYARILAR.md`
