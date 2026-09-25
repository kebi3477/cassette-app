import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// `flutter run --dart-define=KEY=VALUE` 값을 매니페스트에 넘긴다 (카카오 키, 링크 도메인).
val dartDefines: Map<String, String> = run {
    val out = mutableMapOf<String, String>()
    val raw = project.findProperty("dart-defines") as String?
    raw?.split(",")?.forEach { encoded: String ->
        val decoded = Base64.getDecoder().decode(encoded).toString(Charsets.UTF_8)
        val i = decoded.indexOf('=')
        if (i > 0) out[decoded.substring(0, i)] = decoded.substring(i + 1)
    }
    out
}

android {
    namespace = "com.kebi.cassette"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.kebi.cassette"
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
        manifestPlaceholders["kakaoNativeAppKey"] = dartDefines["KAKAO_NATIVE_APP_KEY"] ?: "NONE"
        manifestPlaceholders["publicHost"] = dartDefines["PUBLIC_HOST"] ?: "cassette.example"
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
