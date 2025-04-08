# Keep all classes in androidx.media3
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep required classes for XML parsing
-keep class org.xmlpull.** { *; }
-dontwarn org.xmlpull.**

# Keep common Android classes
-keep class android.** { *; }
-keep class androidx.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }

# Keep your application classes
-keep class com.example.apploook.** { *; }
