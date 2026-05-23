# Keep ML Kit models and native code
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep OpenCV native library
-keep class org.opencv.** { *; }
-dontwarn org.opencv.**
-keep class io.github.opencv.** { *; }
-dontwarn io.github.opencv.**

# Keep Flutter/Framework classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Keep all JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Serializable classes for document model persistence
-keep class com.miguelaaga.docscanner.** { *; }
-keepclassmembers class com.miguelaaga.docscanner.** {
    <fields>;
    <methods>;
}

# Keep enum classes used in model serialization
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
