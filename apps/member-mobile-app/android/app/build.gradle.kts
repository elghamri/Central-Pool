import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Central Pool - Production Release Signing Configuration Hook
// ---------------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Resolve signing properties from Environment Variables OR key.properties (Gitignored)
val releaseStoreFile = System.getenv("ANDROID_STORE_FILE")
    ?: System.getenv("ANDROID_KEYSTORE_PATH")
    ?: keystoreProperties.getProperty("storeFile")

val releaseStorePassword = System.getenv("ANDROID_STORE_PASSWORD")
    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
    ?: keystoreProperties.getProperty("storePassword")

val releaseKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
    ?: keystoreProperties.getProperty("keyAlias")

val releaseKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")
    ?: keystoreProperties.getProperty("keyPassword")

val hasValidReleaseSigning = !releaseStoreFile.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.example.member_mobile_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "finance.collaborative.centralpool"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasValidReleaseSigning) {
            val keyStoreResolved = if (File(releaseStoreFile!!).isAbsolute) {
                File(releaseStoreFile)
            } else {
                rootProject.file(releaseStoreFile)
            }

            if (keyStoreResolved.exists()) {
                create("release") {
                    storeFile = keyStoreResolved
                    storePassword = releaseStorePassword
                    keyAlias = releaseKeyAlias
                    keyPassword = releaseKeyPassword
                }
            }
        }
    }

    buildTypes {
        release {
            // INVARIANT: RELEASE_STORE_SIGNING_MUST_NOT_FALL_BACK_TO_DEBUG
            // If production signing credentials are provided and valid, use the production release signingConfig.
            // If credentials are absent, signingConfig is intentionally left unassigned (fail-closed / unsigned).
            // Under NO circumstances will a production release build silently fall back to debug signing.
            if (hasValidReleaseSigning && signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

