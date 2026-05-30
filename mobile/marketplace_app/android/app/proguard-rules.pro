# Keep Flutter's generated plugin entry point visible to R8.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# FlutterFire and Google Play Services ship their own consumer rules. These
# warning suppressions avoid optional dependency noise without retaining code.
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
