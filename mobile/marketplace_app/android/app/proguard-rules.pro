# Keep Flutter's generated plugin entry point visible to R8.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# FlutterFire and Google Play Services ship their own consumer rules. These
# warning suppressions avoid optional dependency noise without retaining code.
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Keep annotations and generic signatures for proper deserialization.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Firebase Messaging — keep notification payload handling classes.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Sign-In — keep account classes used by the plugin.
-keep class com.google.android.gms.auth.** { *; }

# image_picker / file_provider — prevent stripping of FileProvider authority.
-keep class androidx.core.content.FileProvider { *; }

# Prevent stripping of classes passed across the Dart/Java bridge.
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Suppress harmless warnings from optional okhttp/conscrypt integration.
-dontwarn okhttp3.**
-dontwarn okio.**
