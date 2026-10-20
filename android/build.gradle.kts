allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// mapbox_maps_flutter_mobile coi AGP 9 là đã có Kotlin sẵn nên không tự áp
// plugin Kotlin, nhưng dự án này tắt `android.builtInKotlin` (gradle.properties)
// → khối `kotlin {}` trong build.gradle của plugin không tồn tại. Áp Kotlin cho
// riêng nó ngay khi nó áp com.android.library (trước khi tới khối đó).
subprojects {
    if (name == "mapbox_maps_flutter_mobile") {
        plugins.withId("com.android.library") {
            apply(plugin = "org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
