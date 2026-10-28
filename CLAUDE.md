# KKTC Taksim

KKTC için taksi çağırma uygulaması (Flutter). Kullanıcıyla Türkçe konuş.

**Önce `docs/ILERLEME.md` dosyasını oku**: yapılanlar, kararlar, açık bulgular ve sıradaki iş orada.
Her oturumun sonunda o dosyayı güncelle.

## Komutlar
Flutter komutlarını `C:\src\kktc` (projeye açılan ASCII junction) içinden çalıştır; proje yolundaki
"Masaüstü" kelimesi `flutter analyze`'ı çökertiyor.
```
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build web --release
python -u tool/serve_https.py build/web tool/certs   # iPhone testi, bkz. tool/README.md
```

## Kod kuralları
- Renk, boşluk, köşe ve süreler `lib/core/app_theme.dart` ve `lib/core/app_tokens.dart`'tan gelir;
  ekranlarda sabit değer yazma. Metin stilleri `Theme.of(context).textTheme` üzerinden.
- Açık ve koyu tema birlikte desteklenir: `colorScheme.surface`, `onSurfaceVariant` vb. kullan.
- Örnek veriler `lib/data/mock_data.dart`, modeller `lib/models/` altında.
- Rotalar `lib/core/app_routes.dart`. Henüz yapılmamış özellikler `showComingSoon()` gösterir.
- Harita: MapLibre + OpenFreeMap (`lib/widgets/home/ride_map.dart`,
  `lib/services/map_style_service.dart`). Konum: `lib/services/location_service.dart`.
- Değişiklikten sonra `flutter analyze` temiz ve `flutter test` yeşil olmalı.
