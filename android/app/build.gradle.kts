plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.blood_link_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"

    compileOptions {
        // Core library desugaring සක්‍රීය කිරීම (Syntax වෙනස් වී ඇත)
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.example.blood_link_app"

        // minSdk එක අඩුම 21 ක් වත් කරන්න (Notification වැඩ කිරීමට)
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring සඳහා අවශ්‍ය ලයිබ්‍රරි එක මෙතනට දාන්න
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
