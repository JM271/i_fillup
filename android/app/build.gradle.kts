import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val placesSecrets = Properties().apply {
    val source = rootProject.file("secrets.properties")
    if (source.exists()) source.inputStream().use { load(it) }
}

// Upload key for Google Play; created by tool/create_upload_key.sh.
val uploadKey = Properties().apply {
    val source = rootProject.file("key.properties")
    if (source.exists()) source.inputStream().use { load(it) }
}

android {
    namespace = "com.example.i_fillup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The Google Play ID; it can never change once the app is published.
        applicationId = "com.jonasmuehle.ifillup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        buildConfigField("String", "PLACES_API_KEY", "\"${placesSecrets.getProperty("PLACES_API_KEY", "").trim()}\"")
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "i fillup")
    }

    buildFeatures {
        resValues = true
        buildConfig = true
    }

    signingConfigs {
        if (!uploadKey.isEmpty) {
            create("release") {
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
                storeFile = file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties, release builds fall back to the debug
            // key so `flutter run --release` still works; Play rejects those.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
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

dependencies {
    implementation("com.google.android.libraries.places:places:6.0.2")
}
