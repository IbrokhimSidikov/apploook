# ------------------------
# Keep all classes in androidx.media3
# ------------------------
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ------------------------
# XML parsing
# ------------------------
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# ------------------------
# Common Android / AndroidX
# ------------------------
-keep class android.** { *; }
-keep class androidx.** { *; }

# ------------------------
# Firebase + Google Play Services
# ------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ------------------------
# Flutter
# ------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }

# ------------------------
# Your app package
# ------------------------
-keep class com.loook.v1.** { *; }

# ------------------------
# Ignore Play Core warnings (we don't use deferred components)
# ------------------------
-dontwarn com.google.android.play.core.**
