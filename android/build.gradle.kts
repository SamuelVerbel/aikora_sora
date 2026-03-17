buildscript {
    extra.set("kotlin_version", "1.9.20")  // Actualizado
    
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")  // Actualizado
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${extra["kotlin_version"]}")
    }
}