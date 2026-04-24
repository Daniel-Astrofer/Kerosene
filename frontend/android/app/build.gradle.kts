plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.teste.kersosene"
    compileSdk = 36 // ATUALIZADO PARA 36 (exigido pelos seus plugins)
    ndkVersion = "28.2.13676358"

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.teste.kersosene"
        minSdk = flutter.minSdkVersion // Definido manualmente para garantir compatibilidade
        targetSdk = 36 // ATUALIZADO PARA 36
        versionCode = 1
        versionName = "1.0.0"
    }

    // ADICIONADO PARA RESOLVER O ERRO DO LOCAL_NOTIFICATIONS
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // LINHA OBRIGATÓRIA PARA O DESUGARING FUNCIONAR
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
