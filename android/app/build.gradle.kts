plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services for Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.dmstyles.installment_calculator"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dmstyles.installment_calculator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = "installment_hub"
            keyPassword = "installment123"
            storeFile = file("installment_hub.keystore")
            storePassword = "installment123"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Firebase BOM — manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:34.14.1"))
    // Firebase Cloud Messaging
    implementation("com.google.firebase:firebase-messaging")
    // Firestore
    implementation("com.google.firebase:firebase-firestore")
}
