import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.shelat.shelat"
    compileSdk = 36
    ndkVersion = "28.0.13004108" // Required for 16 KB page size

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shelat.shelat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
   signingConfigs {
        create("release") {
            storeFile = file("shelat-keystore.jks")
            storePassword = "12345678"
            keyAlias = "shelat.shelat"
            keyPassword = "12345678"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    implementation("com.google.android.play:integrity:1.5.0")
    implementation("com.google.android.gms:play-services-ads:24.5.0")
    implementation("com.google.android.gms:play-services-auth:20.6.0")
    implementation("com.unity3d.ads-mediation:adquality-sdk:7.26.2") // ✅
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    dependencies 
    implementation ("com.unity3d.ads-mediation:adquality-sdk:9.0.1")

    implementation ("com.unity3d.ads-mediation:adquality-sdk:9.0.0")
    }