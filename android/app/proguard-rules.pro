# Keep android_alarm_manager_plus classes (required for background alarm execution)
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep flutter_local_notifications classes
-keep class com.dexterous.** { *; }

# Keep flutter_ringtone_player classes
-keep class io.inway.ringtone.player.** { *; }

# Suppress warnings for Google Play Core (not used, referenced by Flutter engine)
-dontwarn com.google.android.play.core.**
