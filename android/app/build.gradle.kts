import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "br.com.vozesdacatedral.vozes_da_catedral"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.vozesdacatedral.vozes_da_catedral"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile =
                    rootProject.file(
                        requireNotNull(keystoreProperties.getProperty("storeFile")) {
                            "storeFile is required in android/key.properties"
                        },
                    )
                storePassword =
                    requireNotNull(keystoreProperties.getProperty("storePassword")) {
                        "storePassword is required in android/key.properties"
                    }
                keyAlias =
                    requireNotNull(keystoreProperties.getProperty("keyAlias")) {
                        "keyAlias is required in android/key.properties"
                    }
                keyPassword =
                    requireNotNull(keystoreProperties.getProperty("keyPassword")) {
                        "keyPassword is required in android/key.properties"
                    }
            }
        }
    }

    buildTypes {
        release {
            // Issue #26: never fall back to the debug key for release builds.
            // An APK signed with the debug key cannot be updated by the
            // release-signed one without uninstalling (and losing local data).
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Fail fast when a release artifact is requested without the release key,
// while keeping debug/profile builds working on machines without it.
gradle.taskGraph.whenReady {
    val buildsRelease =
        allTasks.any { task ->
            task.project == project &&
                (task.name == "assembleRelease" || task.name == "bundleRelease")
        }
    if (buildsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties not found: release builds must be signed " +
                "with the release keystore. See README (Android release signing).",
        )
    }
}

flutter {
    source = "../.."
}
