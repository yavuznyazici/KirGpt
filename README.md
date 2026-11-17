# KirGpt

KirGpt, Android ekranını seçilen renkte tam ekran bir ışık paneline dönüştürür. Varsayılan renk kırmızıdır.

## Özellikler

- Uygulama açılınca tam ekran renk alanı gösterir.
- Ekran parlaklığı varsayılan olarak %20'den başlar.
- 15 saniyede %100'e yükselir, 4 saniye en yüksek seviyede kalır ve 15 saniyede %20'ye iner.
- Döngü otomatik olarak tekrar eder.
- Ekrana iki kez hızlı dokununca ayarlar açılır.
- Renk seçenekleri: kırmızı, mavi, yeşil, mor, turuncu ve beyaz.
- Parlaklık değişim süresi ayarlanabilir (5–60 saniye).
- Zirvede bekleme süresi ayarlanabilir (0–15 saniye).
- Yumuşak geçiş açılıp kapatılabilir.
- En yüksek parlaklığa ulaşınca kısa titreşim açılabilir.
- Ekranın kapanması engellenir ve sistem gezinme çubukları gizlenir.

## Gereksinimler

- Flutter SDK (stable)
- Android Studio / Android SDK
- Android cihaz veya emülatör (minSdk 23)

## Yerelde çalıştırma

```bash
flutter pub get
flutter run
```

## APK oluşturma

```bash
flutter build apk --release
```

APK konumu:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub'a yükleme

Bu klasörü GitHub deposuna gönderin. GitHub Actions, her push işleminde Android APK oluşturur ve APK'yı workflow artifact'i olarak saklar.

> Not: Android uygulama içi parlaklık ayarı, Android'in uygulama penceresi parlaklığını kontrol eder. Bazı üretici arayüzleri veya otomatik parlaklık ayarları ekranın gerçek parlaklığını etkileyebilir. En tutarlı sonuç için cihazın otomatik parlaklığını kapatın.
