plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cl.raulisaac.ruli_os"
    compileSdk = flutter.compileSdkVersion

    // Fijada a mano y no a `flutter.ndkVersion`: los paquetes de avisos y de
    // almacenamiento piden esta version y la compilacion se detiene si el
    // proyecto declara una mas baja. Las versiones del NDK son compatibles
    // hacia atras, asi que poner la mas alta que pida algun paquete es lo
    // correcto.
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Necesario para las alarmas: flutter_local_notifications usa clases
        // de fecha y hora de Java 8 que los Android antiguos no traen. El
        // "desugaring" las reescribe para que funcionen igual en todos.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cl.raulisaac.ruli_os"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
