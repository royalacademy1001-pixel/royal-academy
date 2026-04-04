# ================= 🔥 FLUTTER =================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ================= 🔥 FIREBASE =================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ================= 🔥 FIRESTORE =================
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firestore.**

# ================= 🔥 STORAGE =================
-keep class com.google.firebase.storage.** { *; }

# ================= 🔥 FCM =================
-keep class com.google.firebase.messaging.** { *; }

# ================= 🔥 VIDEO PLAYER (EXOPLAYER) =================
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# 🔥 codecs / media safety
-dontwarn android.media.**
-dontwarn android.media.AudioTrack
-dontwarn android.media.MediaCodec

# ================= 🔥 CHEWIE =================
-keep class com.brianegan.chewie.** { *; }

# ================= 🔥 YOUTUBE / WEBVIEW =================
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keep class android.webkit.** { *; }

# ================= 🔥 IMAGE PICKER =================
-keep class io.flutter.plugins.imagepicker.** { *; }

# ================= 🔥 FILE PICKER =================
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ================= 🔥 IMAGE CROPPER =================
-keep class com.yalantis.ucrop.** { *; }

# ================= 🔥 PDF VIEWER =================
-keep class com.syncfusion.** { *; }

# ================= 🔥 URL LAUNCHER =================
-keep class io.flutter.plugins.urllauncher.** { *; }

# ================= 🔥 SHARE =================
-keep class dev.fluttercommunity.plus.share.** { *; }

# ================= 🔥 KEEP ANNOTATIONS =================
-keepattributes *Annotation*

# ================= 🔥 JSON / MODELS SAFETY =================
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ================= 🔥 ENUM SAFETY =================
-keep class * extends java.lang.Enum { *; }

# ================= 🔥 KOTLIN =================
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**

# ================= 🔥 JAVA ANNOTATIONS =================
-dontwarn javax.annotation.**

# ================= 🔥 MULTIDEX =================
-keep class androidx.multidex.** { *; }

# ================= 🔥 REFLECTION SAFE =================
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ================= 🔥 CONSTRUCTORS =================
-keepclassmembers class * {
    public <init>(...);
}

# ================= 🔥 SERIALIZATION / MAP =================
-keepclassmembers class * {
    public <fields>;
}

# ================= 🔥 PREVENT CRASH IN RELEASE =================
-keepnames class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# ================= 🔥 SAFE FALLBACK =================
-dontwarn org.json.**
-dontwarn java.lang.invoke.**