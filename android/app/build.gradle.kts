// 🔥 FINAL ANDROID BUILD (PRO MAX++ ENTERPRISE RELEASE v6 STABLE)

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {

    namespace = "com.royal.academy.app"

    compileSdk = 36
    buildToolsVersion = "34.0.0"

    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.royal.academy.app"

        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = 1
        versionName = "1.0.0"

        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        /// 🔥 FIX مهم
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-Xjvm-default=all",
            "-Xopt-in=kotlin.RequiresOptIn"
        )
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {

            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }

            /// 🔥 FIX نهائي (حل مشكلة R8)
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    /// 🔥 SPLIT APK
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true
        }
    }

    /// 🔥 Packaging Fix
    packaging {
        resources {
            excludes += setOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module"
            )
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

dependencies {

    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))

    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")

    implementation("androidx.multidex:multidex:2.0.1")

    implementation("androidx.core:core-ktx:1.13.1")

    /// 🔥 REQUIRED FIX
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}