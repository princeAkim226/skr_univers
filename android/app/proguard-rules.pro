# Configuration ProGuard pour RAAGA

# Garder les classes Supabase
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }

# Garder les classes de sérialisation JSON
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Garder les classes de réseau
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Garder les classes Flutter
-keep class io.flutter.** { *; }

# Garder les classes de l'application
-keep class com.prince.raaga.** { *; }
-keep class com.example.skr_univers.** { *; }

# Règles pour Google Play Core (correction de l'erreur R8)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Règles pour les classes manquantes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Désactiver les avertissements pour les classes manquantes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Règles générales pour éviter les erreurs R8
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Garder les classes de géolocalisation
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Garder les classes d'images
-keep class androidx.exifinterface.** { *; }
