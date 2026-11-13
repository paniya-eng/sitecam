# سایت‌کم (SiteCam) 🦺

اپ دوربین ثبت پروژه‌های ساختمانی — عکس و فیلم با **مُهر روی تصویر** شامل:

- 📅 تاریخ و ساعت (شمسی با اعداد فارسی، یا میلادی)
- 📍 موقعیت GPS
- 🏗️ نام پروژه و متن دلخواه (مثلاً: «طبقه ۳ — بتن‌ریزی سقف»)

ساخته‌شده با **Flutter** — یک کد برای **اندروید، iOS و ویندوز** و ریسپانسیو برای موبایل و تبلت.

---

## راه‌اندازی (قدم‌به‌قدم)

### 🅰️ راه ساده: ساخت APK با گیت‌هاب (بدون نصب چیزی روی کامپیوتر)

داخل پروژه یک فایل آماده است: `.github/workflows/build-apk.yml`

1. فایل ZIP پروژه را از حالت فشرده خارج کن.
2. وارد [github.com](https://github.com) شو (یا حساب بساز).
3. دکمه **New repository** را بزن، یک نام مثل `sitecam` بده و **Create repository** را بزن.
4. در صفحه مخزن، روی **uploading an existing file** کلیک کن و **محتویات** پوشه sitecam را (نه خود پوشه) بکش و رها کن. سپس **Commit changes** را بزن.
5. برو به تب **Actions** — یک کار به نام **Build Android APK** خودکار شروع می‌شود (حدود ۵–۱۰ دقیقه طول می‌کشد).
6. وقتی تمام شد (✅ سبز)، همان صفحه را باز کن و پایین صفحه بخش **Artifacts** → روی **sitecam-apk** کلیک کن تا فایل APK دانلود شود.
7. فایل APK را به گوشی اندرویدی منتقل کن و نصب کن (اگه گفت «منابع ناشناس»، اجازه بده).

### 🅱️ راه محلی: اجرای مستقیم با Flutter روی کامپیوترت

### ۱) نصب Flutter

1. از سایت [flutter.dev](https://flutter.dev) آخرین نسخه Flutter را دانلود و نصب کن.
2. ترمینال را باز کن و این دستور را بزن تا مطمئن شوی همه‌چیز درسته:
   ```bash
   flutter doctor
   ```
   هر خطی که علامت ❌ دارد را درست کن (معمولاً Android Studio لازم است).

### ۲) ساخت پوشه‌های پلتفرم‌ها

داخل پوشه‌ای که این فایل‌ها را دانلود کردی، ترمینال را باز کن و بزن:

```bash
flutter create . --project-name sitecam
```

> ⚠️ این دستور پوشه‌های `android` و `ios` و `windows` را می‌سازد و فایل‌های ما (`lib` و `pubspec.yaml`) را **دست نمی‌زند**.

### ۳) نصب پکیج‌ها

```bash
flutter pub get
```

### ۴) دادن مجوزها

**اندروید** — فایل `android/app/src/main/AndroidManifest.xml` را باز کن و داخل تگ `<manifest>` (قبل از تگ `<application>`) این خطوط را اضافه کن:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**iOS** — فایل `ios/Runner/Info.plist` را باز کن و داخل تگ `<dict>` این‌ها را اضافه کن:

```xml
<key>NSCameraUsageDescription</key>
<string>برای ثبت عکس و فیلم از پروژه ساختمانی</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>برای درج موقعیت روی عکس</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>برای ذخیره عکس در گالری گوشی</string>
```

### ۵) اجرا

```bash
flutter run          # اجرا روی گوشی/شبیه‌ساز متصل
flutter run -d windows   # اجرا روی ویندوز
```

---

## ساخت خروجی نهایی

```bash
flutter build apk --release     # فایل نصب اندروید (APK)
flutter build ios --release     # خروجی iOS (نیاز به مک دارد)
flutter build windows --release # نسخه ویندوز (.exe)
```

---

## ساختار پروژه

```
lib/
├── main.dart                  ← نقطه شروع اپ + ناوبری (ریسپانسیو)
├── models/
│   └── app_settings.dart      ← مدل تنظیمات کاربر
├── services/
│   ├── settings_service.dart  ← ذخیره تنظیمات در گوشی
│   ├── location_service.dart  ← موقعیت GPS
│   ├── stamp_service.dart     ← سوزاندن مُهر فارسی روی عکس ⭐
│   └── media_service.dart     ← ذخیره عکس/فیلم در اپ و گالری گوشی
├── widgets/
│   └── stamp_overlay.dart     ← پیش‌نمایش زنده مُهر روی دوربین
└── screens/
    ├── camera_screen.dart     ← صفحه دوربین (عکس + فیلم)
    ├── gallery_screen.dart    ← گالری عکس‌های ثبت‌شده
    └── settings_screen.dart   ← تنظیمات (نام پروژه، متن، GPS...)
```

---

## نقشه راه فاز ۲

- [ ] سوزاندن مُهر داخل فایل **فیلم** (با ffmpeg) — فعلاً مُهر فقط روی پیش‌نمایش فیلم دیده می‌شود
- [ ] پخش فیلم داخل گالری
- [ ] همگام‌سازی ابری بین گوشی همکاران (Firebase)
- [ ] خروجی گزارش PDF از عکس‌های یک پروژه
- [ ] لاگین کاربری و مدیریت چند پروژه
