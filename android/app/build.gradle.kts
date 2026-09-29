import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// API key Google Maps dibaca dari android/key.properties (file ini masuk
// .gitignore supaya rahasia tidak ter-push). Salin key.properties.example
// menjadi key.properties lalu isi GOOGLE_MAPS_API_KEY-nya.
// Kalau file tidak ada → value kosong: peta tampil polos, aplikasi tidak
// crash.
val googleMapsApiKey: String = run {
    val props = Properties()
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        f.inputStream().use { stream -> props.load(stream) }
    }
    props.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
}

android {
    namespace = "com.example.sehatly"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sehatly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Dipakai AndroidManifest.xml → com.google.android.geo.API_KEY
        // (placeholder, bukan resValue — AGP 9 mematikan resValue di defaultConfig)
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
