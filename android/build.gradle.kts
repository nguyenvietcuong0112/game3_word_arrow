import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.services.BuildService
import org.gradle.api.services.BuildServiceParameters

// Global single-slot BuildService mutex: guarantees that all CMake / ExternalNativeBuild / Cxx
// tasks across every subproject (:app, :jni, etc.) and every ABI run strictly sequentially,
// preventing Windows file-lock collisions on generate_cxx_metadata_*_timing.txt in Android Studio.
abstract class SerialNativeBuildService : BuildService<BuildServiceParameters.None>

val serialNativeBuildService =
    gradle.sharedServices.registerIfAbsent(
        "serialNativeBuildService",
        SerialNativeBuildService::class.java,
    ) {
        maxParallelUsages.set(1)
    }

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    tasks.configureEach {
        if (name.contains("CMake", ignoreCase = true) ||
            name.contains("ExternalNative", ignoreCase = true) ||
            name.contains("Cxx", ignoreCase = true)
        ) {
            usesService(serialNativeBuildService)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    if (project.projectDir.toPath().root == rootProject.projectDir.toPath().root) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }

    plugins.withId("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.apply {
            defaultConfig {
                if (ndk.abiFilters.isEmpty()) {
                    // Align native library ABIs with Flutter's supported Android ABIs (skip obsolete 32-bit x86)
                    ndk.abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64"))
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    subprojects {
        delete(project.layout.buildDirectory)
        delete(project.file(".cxx"))
    }
}
