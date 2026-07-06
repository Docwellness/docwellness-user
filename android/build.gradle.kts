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
    }

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
