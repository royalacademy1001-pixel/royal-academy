// 🔥 FINAL FIXED BUILD.GRADLE.KTS (NO CONFLICT VERSION)

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false

    // 🔥 FIX: إزالة version علشان نمنع التضارب
    id("com.google.gms.google-services") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/// 🔧 تحسين build folder (اختياري)
val newBuildDir =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

/// 🔧 حل مشاكل dependency
subprojects {
    project.evaluationDependsOn(":app")
}

/// 🧹 clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}