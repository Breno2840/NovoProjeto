plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.calculadora.my"
    // A versão do SDK de compilação é gerenciada pelo Flutter.
    compileSdk = 34

    defaultConfig {
        applicationId = "com.calculadora.my"
        // A SDK mínima é 21 para os pacotes de áudio.
        minSdk = 21
        // A SDK alvo é gerenciada pelo Flutter.
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    signingConfigs {
        create("release") {
            // Você pode configurar a assinatura do seu app de release aqui no futuro.
        }
    }

    buildTypes {
        release {
            // Enables code shrinking, obfuscation, and optimization for only
            // your project's release build type.
            isMinifyEnabled = true
            // Enables resource shrinking, which is performed by the
            // Android Gradle plugin.
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}
