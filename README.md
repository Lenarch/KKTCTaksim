# KKTC Taksim

KKTC için taksi çağırma ve paylaşımlı yolculuk uygulaması (Flutter).

## Özellikler (demo)
- Rol seçimi (yolcu / şoför / durak), e-posta ile giriş, kayıt ve SMS kodu doğrulama ekranları
- Harita üzerinde taksi çağırma akışı: varış noktası → taksi tipi → sürücü arama → yolculuk → puanlama
- Paylaşımlı yolculuk grupları: listeleme, katılma, yeni grup oluşturma
- Keşfet: kategori ve isimle filtrelenen popüler yerler
- Açık ve koyu tema (telefonun ayarını izler)

Şu an backend yok; tüm veriler `lib/data/mock_data.dart` içindeki örnek verilerdir.

## Proje yapısı
```
lib/
  core/      tema, tasarım token'ları (boşluk/köşe/süre), rotalar, doğrulayıcılar
  data/      örnek (mock) veriler
  models/    Trip, Place, SharedRide, Driver, TaxiOption
  services/  konum (geolocator) ve harita stili (MapLibre + OpenFreeMap, cihaz dilinde etiketler)
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
- `android/app/build.gradle.kts` içindeki `com.example.kktc_taksim` paket adı değiştirilmeli
- AdMob test kimlikleri (AndroidManifest, Info.plist, `main_navigation_screen.dart`) gerçek kimliklerle değiştirilmeli
- Gerçek kimlik doğrulama ve yolculuk servisleri bağlanmalı
