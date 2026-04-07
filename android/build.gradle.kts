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

// removed subprojects evaluationDependsOn :app to fix flutter_contacts plugin evaluation issue

// Fix for plugins (e.g. flutter_contacts) that don't declare a namespace,
// which is required by AGP 8+. Excludem :app pentru a evita evaluarea prematură.
subprojects {
    if (project.name != "app") {
        plugins.withId("com.android.library") {
            configure<com.android.build.gradle.LibraryExtension> {
                if (namespace == null) {
                    namespace = project.group.toString().ifBlank {
                        "com.plugin.${project.name.replace("-", "_")}"
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
