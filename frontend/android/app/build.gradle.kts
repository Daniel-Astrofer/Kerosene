import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun stringProperty(name: String): String? {
    return (project.findProperty(name) as String?)
        ?: System.getenv(name)
        ?: keystoreProperties.getProperty(name)
}

val releaseStoreFile = stringProperty("KEROSENE_UPLOAD_STORE_FILE")
val releaseStorePassword = stringProperty("KEROSENE_UPLOAD_STORE_PASSWORD")
val releaseKeyAlias = stringProperty("KEROSENE_UPLOAD_KEY_ALIAS")
val releaseKeyPassword = stringProperty("KEROSENE_UPLOAD_KEY_PASSWORD")
val hasReleaseSigningConfig = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }
val allowDebugReleaseSigning =
    stringProperty("KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING") == "true"

android {
    namespace = "com.teste.kersosene"
    compileSdk = 36 // ATUALIZADO PARA 36 (exigido pelos seus plugins)
    ndkVersion = "28.2.13676358"

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = stringProperty("KEROSENE_ANDROID_APPLICATION_ID")
            ?: "com.teste.kersosene"
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

    signingConfigs {
        if (hasReleaseSigningConfig) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseSigningConfig -> signingConfigs.getByName("release")
                allowDebugReleaseSigning -> signingConfigs.getByName("debug")
                else -> null
            }
            if (!hasReleaseSigningConfig && !allowDebugReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Set KEROSENE_UPLOAD_STORE_FILE, " +
                        "KEROSENE_UPLOAD_STORE_PASSWORD, KEROSENE_UPLOAD_KEY_ALIAS and " +
                        "KEROSENE_UPLOAD_KEY_PASSWORD, or set " +
                        "KEROSENE_ALLOW_DEBUG_RELEASE_SIGNING=true for local non-production builds."
                )
            }
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
