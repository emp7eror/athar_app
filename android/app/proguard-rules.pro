# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*

# Keep notification sounds
-keep class **.R$raw { *; }
-dontwarn com.google.android.play.core.tasks.**