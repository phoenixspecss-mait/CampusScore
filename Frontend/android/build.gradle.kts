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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ---------------------------------------------------------------------
// FIX: Force older dependencies to maintain NDK 25 compatibility
// This prevents Google Maps and Flutter from pulling futuristic Kotlin/AndroidX
// libraries that crash on older setups.
// ---------------------------------------------------------------------
subprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            // Lock Kotlin standard libraries to 2.1.0
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
            // Lock Android Maps Utils to an older version
            if (requested.group == "com.google.maps.android") {
                useVersion("3.8.2")
            }
            // Lock AndroidX Core to keep AGP 8.3.2 happy
            if (requested.group == "androidx.core") {
                useVersion("1.13.1")
            }
        }
    }
}