allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.plugins.withType<com.android.build.gradle.LibraryPlugin> {
        project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            if (namespace.isNullOrEmpty()) {
                namespace = "com.mr.flutter.plugin.filepicker"
            }
        }
    }

    project.plugins.withType<com.android.build.gradle.AppPlugin> {
        project.extensions.configure<com.android.build.gradle.AppExtension>("android") {
            if (namespace.isNullOrEmpty()) {
                namespace = "com.example.mators_car"
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
