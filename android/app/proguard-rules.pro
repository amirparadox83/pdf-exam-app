# Flutter / Dart reflection — keep these
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# SQLite native libs
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

# drift runtime
-keep class drift.** { *; }
-keep class drift.runtime.** { *; }
-keepclassmembers class * extends drift.runtime.DriftDatabase { *; }

# pdfrx / pdfium
-keep class com.rallo.pdfrx.** { *; }
-keep class pdfium.** { *; }

# riverpod
-keep class riverpod.** { *; }
-keepclassmembers class * extends riverpod.ProviderBase { *; }

# Preserve Flutter JNI entry points
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.app.** { *; }
