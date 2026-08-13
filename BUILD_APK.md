# راهنمای بیلد APK — اپلیکیشن آزمون PDF

این سند مراحل کامل تولید فایل APK قابل نصب روی اندروید را توضیح می‌دهد.

---

## ۱) بیلد با GitHub Actions (توصیه‌شده — بدون نیاز به نصب Flutter محلی)

ساده‌ترین راه: کافیست پروژه را به یک ریپو GitHubpush کنید؛ گردش‌کار `.github/workflows/build-apk.yml` به‌صورت خودکار APK را بیلد می‌کند.

### مراحل

1. ریپو جدید در GitHub بسازید:
   ```bash
   cd pdf_exam_app
   git init
   git add .
   git commit -m "Initial commit — Persian PDF Exam MVP"
   git branch -M main
   git remote add origin https://github.com/<USER>/<REPO>.git
   git push -u origin main
   ```

2. به تب **Actions** ریپو بروید. گردش‌کار «Build APK» به‌صورت خودکار اجرا می‌شود.

3. پس از پایان موفق (~۱۰ تا ۲۰ دقیقه)، در همان صفحه روی اجرای مربوطه بزنید و در پایین صفحه بخش **Artifacts** را باز کنید. دو فایل دانلود می‌شود:
   - `persian-pdf-exam-fat-apk` — APK یکپارچه (~۳۰ تا ۶۰ مگابایت، شامل همه‌ی ABIها)
   - `persian-pdf-exam-split-apks` — سه APK جداگانه برای arm64 / armv7 / x86_64 (حجم کمتر)

4. برای انتشار به‌عنوان Release، یک تگ بزنید:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
   گردش‌کار به‌طور خودکار APKها را به صفحه‌ی Releases همان تگ پیوست می‌کند.

---

## ۲) بیلد محلی (روی ماشین خودتان)

### پیش‌نیازها

| ابزار | نسخه | لینک |
|------|------|------|
| Flutter SDK | ۳.۲۴.۵ یا جدیدتر | https://docs.flutter.dev/get-started/install |
| JDK | ۱۷ (Temurin توصیه می‌شود) | https://adoptium.net/ |
| Android SDK | API ۳۴ + Build-Tools ۳۴.۰.۰ | از Android Studio یا `sdkmanager` |
| Android NDK | ۲۶.۳.۱۱۵۷۹۲۰ (Flutter پیشنهاد می‌دهد) | از `sdkmanager` |

### مراحل گام‌به‌گام

```bash
# 0) کلون پروژه
cd ~/projects
# (پروژه را اینجا قرار دهید)

# 1) نصب وابستگی‌های Dart
flutter pub get

# 2) راه‌اندازی Gradle Wrapper (یک‌بار)
bash scripts/setup-gradle-wrapper.sh

# 3) اجرای code generator (drift / freezed / json_serializable / riverpod)
dart run build_runner build --delete-conflicting-outputs

# 4) بیلد APK release (fat — شامل همه‌ی معماری‌ها)
flutter build apk --release

# خروجی:
# build/app/outputs/flutter-apk/app-release.apk
```

### بیلد APK سبک‌تر برای هر معماری

```bash
flutter build apk --release --split-per-abi
# خروجی‌ها:
#   app-armeabi-v7a-release.apk   (برای دستگاه‌های قدیمی‌تر)
#   app-arm64-v8a-release.apk     (برای اکثر دستگاه‌های امروزی — توصیه می‌شود)
#   app-x86_64-release.apk        (برای شبیه‌ساز)
```

### نصب روی دستگاه

```bash
# دستگاه را با USB وصل کنید و USB Debugging را فعال کنید
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

یا فایل APK را به گوشی منتقل کنید و به‌صورت دستی نصب کنید (نیاز به «Install unknown apps»).

---

## ۳) امضای production (برای انتشار در فروشگاه‌های غیر از Play Store)

بیلد پیش‌فرض از کلید debug استفاده می‌کند تا نصب سریع باشد. برای انتشار رسمی:

```bash
# 1) ساخت keystore
keytool -genkey -v -keystore ~/keystores/persian-pdf-exam.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias persian-pdf-exam

# 2) ساخت فایل android/key.properties
cat > android/key.properties <<EOF
storePassword=*****your-store-password*****
keyPassword=*****your-key-password*****
keyAlias=persian-pdf-exam
storeFile=/Users/YOU/keystores/persian-pdf-exam.jks
EOF

# 3) ویرایش android/app/build.gradle — بخش release:
#    signingConfig = signingConfigs.create("release") { ... }
#    (نمونه‌ی کامل در پایین این فایل)

# 4) بیلد نهایی
flutter build apk --release
```

نمونه‌ی پیکربندی keystore در `app/build.gradle`:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ...
        }
    }
}
```

> ⚠️ فایل `key.properties` و `*.jks` را هرگز commit نکنید — در `.gitignore` گذاشته شده‌اند.

---

## ۴) رفع اشکال رایج

| خطا | راه‌حل |
|------|--------|
| `Could not determine java version` | مطمئن شوید JDK ۱۷ نصب است: `java -version` باید `17.x` نشان دهد |
| `SDK location not found` | متغیر `ANDROID_HOME` را تنظیم کنید یا `android/local.properties` با `sdk.dir=/path/to/sdk` بسازید |
| `OutOfMemoryError: Metaspace` | در `android/gradle.properties` مقدار `XX:MaxMetaspaceSize` را به `3G` افزایش دهید |
| `MIN_SDK_VERSION` | پروژه روی minSdk=24 تنظیم شده (Android 7.0+). اگر نیاز به Android 5 دارید، `minSdk` را به ۲۱ کاهش دهید (اما برخی وابستگی‌ها ممکن است شکست بخورند) |
| `pub get` کند یا fail | از VPN استفاده کنید یا `PUB_HOSTED_URL` و `FLUTTER_STORAGE_BASE_URL` را روی mirror داخلی تنظیم کنید |
| `gradle-wrapper.jar not found` | `bash scripts/setup-gradle-wrapper.sh` را اجرا کنید |

---

## ۵) مشخصات بیلد نهایی

| ویژگی | مقدار |
|------|------|
| applicationId | `com.persianpdfexam.app` |
| versionName | ۱.۰.۰ |
| versionCode | ۱ |
| minSdk | ۲۴ (Android 7.0) |
| targetSdk | ۳۴ (Android 14) |
| compileSdk | ۳۴ |
| ABIs | armeabi-v7a, arm64-v8a, x86_64 |
| Java/Kotlin target | ۱۷ |
| Gradle | ۸.۷ |
| AGP | ۸.۳.۰ |
| Flutter Gradle Plugin | ۱.۰.۰ |

---

## ۶) اعتبارسنجی APK بیلد‌شده

```bash
# بررسی محتویات APK
unzip -l build/app/outputs/flutter-apk/app-release.apk | head -30

# بررسی اینکه APK هیچ مجوز اینترنتی ندارد (آفلاین بودن MVP)
aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
# انتظار: فقط READ_EXTERNAL_STORAGE با maxSdkVersion=32

# بررسی لیبل فارسی برنامه
aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | grep application-label
# انتظار: application-label:'آزمون PDF'
```

اگر همه‌ی موارد بالا مطابق انتظار بود، APK آماده‌ی توزیع است.
