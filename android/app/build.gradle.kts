plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.calculadora.my"
    // CORREÇÃO AQUI: Atualizado de 34 para 36
    compileSdk = 36

    defaultConfig {
        applicationId = "com.calculadora.my"
        minSdk = 21
        // CORREÇÃO AQUI: Atualizado de 34 para 36
        targetSdk = 36
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
            isMinifyEnabled = true
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
