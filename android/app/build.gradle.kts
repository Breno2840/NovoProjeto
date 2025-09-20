plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun localProperties(): java.util.Properties {
    val localPropertiesFile = rootProject.file("local.properties")
    val properties = java.util.Properties()
    if (localPropertiesFile.exists()) {
        properties.load(java.io.FileInputStream(localPropertiesFile))
    }
    return properties
}

val flutterVersionCode: String by localProperties()
val flutterVersionName: String by localProperties()

android {
    namespace = "com.calculadora.my" // Seu package name aqui
    compileSdk = 34 // O Flutter define isso automaticamente

    defaultConfig {
        applicationId = "com.calculadora.my" // E aqui também
        minSdk = 21 // Requisito mínimo para os pacotes de áudio
        targetSdk = 34 // O Flutter define isso
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            // Configuração para assinatura do app de release
        }
    }

    buildTypes {
        release {
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

