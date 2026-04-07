# ─────────────────────────────────────────────────────────────────────────────
# Nabour App — ProGuard / R8 Rules
# Activat doar în buildType release (isMinifyEnabled = true)
# ─────────────────────────────────────────────────────────────────────────────

# ✅ Flutter Engine — nu obfusca clasele interne Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ✅ Firebase — toate SDK-urile Firebase necesită keep
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ✅ Mapbox — nu obfusca SDK-ul de hărți
-keep class com.mapbox.** { *; }
-dontwarn com.mapbox.**

# ✅ Sentry — necesar pentru stack traces corecte în producție
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**
# Păstrează numerele de linie pentru Sentry
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ✅ Facebook SDK
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# ✅ OkHttp / Retrofit (folosit intern de Firebase și HTTP)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ✅ Gson / JSON Serialization
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ✅ Kotlin Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ✅ Retenție generală pentru reflection
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,EnclosingMethod

# ✅ Nabour custom — păstrează modelele de date (Firestore deserialization)
-keep class com.florin.nabour.** { *; }
