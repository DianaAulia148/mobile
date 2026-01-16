plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // KONFIGURASI UNTUK ML KIT & TFLITE: START
        // Pastikan minSdkVersion sesuai dengan requirement ML Kit
        // ML Kit membutuhkan minSdkVersion 21 atau lebih tinggi
        if (flutter.minSdkVersion < 21) {
            minSdk = 21
        }
        
        // TFLite perlu arsitektur yang spesifik
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
        
        // Metadata untuk ML Kit
        manifestPlaceholders["com.google.mlkit.vision.DEPENDENCIES"] = "pose_detection"
        // KONFIGURASI UNTUK ML KIT & TFLITE: END
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Optimasi untuk release
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            isMinifyEnabled = true
            isShrinkResources = true
        }
        
        debug {
            isDebuggable = true
        }
    }
    
    // KONFIGURASI UNTUK TFLITE: START
    // Agar file .tflite tidak dikompresi
    aaptOptions {
        noCompress.addAll(listOf("tflite", "lite", "tflite2"))
    }
    
    // Packaging options untuk menghindari konflik
    packagingOptions {
        resources {
            excludes.addAll(
                listOf(
                    "META-INF/DEPENDENCIES",
                    "META-INF/LICENSE",
                    "META-INF/LICENSE.txt",
                    "META-INF/NOTICE",
                    "META-INF/NOTICE.txt",
                    "**/kotlin/**",
                    "**/*.kotlin_builtins",
                    "**/*.kotlin_metadata"
                )
            )
        }
    }
    // KONFIGURASI UNTUK TFLITE: END
}

flutter {
    source = "../.."
}

// HAPUS SEMUA DEPENDENCIES DI BAWAH INI KARENA TIDAK DIPERLUKAN!
// Flutter plugin sudah menangani dependencies-nya sendiri