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
        
        // TAMBAHAN UNTUK TFLITE: START
        // Konfigurasi untuk TensorFlow Lite
        ndk {
            // Pilih arsitektur yang didukung
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
        }
        
        // Konfigurasi untuk ML Kit
        manifestPlaceholders["com.google.mlkit.vision.DEPENDENCIES"] = "barcode"
        // TAMBAHAN UNTUK TFLITE: END
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // TAMBAHAN UNTUK RELEASE: START
            // Optimasi untuk release
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            isMinifyEnabled = true
            isShrinkResources = true
            // TAMBAHAN UNTUK RELEASE: END
        }
        
        debug {
            // TAMBAHAN UNTUK DEBUG: START
            // Untuk testing dengan model TFLite
            isDebuggable = true
            // TAMBAHAN UNTUK DEBUG: END
        }
    }
    
    // TAMBAHAN UNTUK TFLITE: START
    // Konfigurasi untuk kompresi file model
    aaptOptions {
        noCompress("tflite")
        noCompress("lite")
        noCompress("tfile")
        noCompress("bin")
    }
    
    // Packaging options untuk menghindari duplikasi file
    packagingOptions {
        resources {
            excludes.addAll(
                listOf(
                    "META-INF/DEPENDENCIES",
                    "META-INF/LICENSE",
                    "META-INF/LICENSE.txt",
                    "META-INF/license.txt",
                    "META-INF/NOTICE",
                    "META-INF/NOTICE.txt",
                    "META-INF/notice.txt",
                    "META-INF/INDEX.LIST",
                    "META-INF/ASL2.0",
                    "META-INF/*.kotlin_module",
                    "META-INF/services/javax.annotation.processing.Processor",
                    "META-INF/proguard/androidx-annotations.pro",
                    "kotlin/**",
                    "kotlinx/**",
                    "**/*.kotlin_builtins",
                    "**/*.kotlin_metadata",
                    "**/kotlin/**",
                    "**/*.txt",
                    "**/*.xml",
                    "**/*.properties"
                )
            )
        }
    }
    
    // Build features untuk view binding (opsional)
    buildFeatures {
        viewBinding = true
        buildConfig = true
    }
    // TAMBAHAN UNTUK TFLITE: END
}

flutter {
    source = "../.."
}

// TAMBAHAN UNTUK DEPENDENCIES: START
dependencies {
    // TensorFlow Lite dependencies
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0")
    
    // Google ML Kit dependencies
    implementation("com.google.mlkit:pose-detection:18.0.0-beta3")
    implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta3")
    implementation("com.google.mlkit:vision-common:17.3.0")
    
    // CameraX dependencies (untuk camera yang lebih baik)
    implementation("androidx.camera:camera-core:1.3.0")
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")
    
    // Lifecycle dependencies
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")
    
    // Coroutines untuk async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
}
// TAMBAHAN UNTUK DEPENDENCIES: END