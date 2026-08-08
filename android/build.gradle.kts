allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Compatibility shim: on_audio_query_android 1.1.0 (bundled by on_audio_query 2.9.0)
// predates AGP's mandatory `namespace` requirement and only declares its package
// via the legacy AndroidManifest `package` attribute. Backfill it here rather than
// patching the pub cache, so `flutter pub get` stays safe to re-run.
subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExtension != null && androidExtension.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestFile.readText())
                if (packageMatch != null) {
                    androidExtension.namespace = packageMatch.groupValues[1]
                }
            }
        }

        // Compatibility shim: on_audio_query_android 1.1.0 hardcodes compileSdkVersion 33,
        // which is now too low for transitively-pulled AndroidX libraries (require >=34).
        // Raising compileSdk is backward-compatible, so force it to match the app's (36).
        androidExtension?.compileSdkVersion(36)

        // Compatibility shim: on_audio_query_android 1.1.0 doesn't declare Java 17
        // compileOptions itself, so its Java task ends up on JVM 11 while its Kotlin
        // task inherits 17 from the app's toolchain, breaking Gradle's consistency
        // check. Align both to 17 for every subproject that doesn't opt out.
        androidExtension?.compileOptions?.apply {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
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
