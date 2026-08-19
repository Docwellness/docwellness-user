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

    plugins.withId("com.android.library") {
        val libraryExtension = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (libraryExtension.namespace.isNullOrEmpty()) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val pkg = Regex("""package\s*=\s*"([^"]+)"""")
                    .find(manifestFile.readText())?.groupValues?.get(1)
                if (!pkg.isNullOrEmpty()) {
                    libraryExtension.namespace = pkg
                }
            }
        }

        // flutter_jailbreak_detection (added for Phase 9, P9-U8) declares
        // neither compileOptions nor kotlinOptions, so its Java compilation
        // defaults to 1.8 while its Kotlin compilation drifts to whatever
        // JVM is running Gradle - "Inconsistent JVM-target compatibility".
        // Scoped to this one plugin by name (not applied to every
        // android-library subproject) - see docwellness-dietician's
        // identical fix for why a blanket override is wrong: it broke
        // audioplayers_android, which correctly declares its own Java 17
        // target.
        if (project.name == "flutter_jailbreak_detection") {
            libraryExtension.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_1_8
                targetCompatibility = JavaVersion.VERSION_1_8
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                kotlinOptions {
                    jvmTarget = "1.8"
                }
            }
        }
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
