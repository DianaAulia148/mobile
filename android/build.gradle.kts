buildscript {
    ext.kotlin_version = "1.9.22" // Pastikan versi terbaru
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1") // Versi terbaru
        classpath("com.google.gms:google-services:4.4.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Tambahkan maven TensorFlow Lite jika perlu
        maven {
            url = uri("https://maven.google.com/")
        }
        maven {
            url = uri("https://google.bintray.com/tensorflow")
        }
    }
}

rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}