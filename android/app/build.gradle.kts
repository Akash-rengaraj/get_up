import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.johan.get_up"
    compileSdk = 36 // --- THIS IS THE FIX ---
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.johan.get_up"
        minSdk = 26 // Required by flutter_timezone
        targetSdk = 36 // --- THIS IS THE FIX ---
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            // ...
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.8.0"))

    // --- THIS IS THE FIX ---
    // This is the correct, stable version for our packages
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}