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

    project.evaluationDependsOn(":app")

    pluginManager.withPlugin("com.android.library") {
        val androidComponents = extensions.findByName("androidComponents")
        if (androidComponents != null) {
            try {
                val finalizeDslMethod = androidComponents.javaClass.getMethod("finalizeDsl", groovy.lang.Closure::class.java)
                // Se usi Kotlin standard
            } catch (_: Exception) {}
        }
        
        // Configurazione diretta sul DSL dell'estensione
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
