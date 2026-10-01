import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imzosi `android/key.properties` dan o'qiladi (git'ga tushmaydi):
//   storePassword=...
//   keyPassword=...
//   keyAlias=upload
//   storeFile=/absolute/path/upload-keystore.jks
// Fayl yo'q bo'lsa release build debug kaliti bilan imzolanadi — lokal
// `flutter run --release` ishlashi uchun. Play Store'ga faqat haqiqiy kalit.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "uz.warderdo.app"
    // flutter_secure_storage SDK 37 ga qarshi kompilyatsiya qilinadi, Flutter'ning
    // joriy default'i esa 36. compileSdk orqaga mos, shuning uchun eng yuqorisini
    // qo'yamiz. Plugin default'dan orqada qolganda qaytadan `flutter.compileSdkVersion`
    // ga o'tsa bo'ladi.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Play Store'ga chiqqandan keyin o'zgartirib bo'lmaydi.
        applicationId = "uz.warderdo.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
