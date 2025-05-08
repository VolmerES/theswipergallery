allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define una ubicación externa para los directorios de compilación
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Reubica el directorio de compilación de cada subproyecto
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Asegura que se evalúe primero el módulo :app
    evaluationDependsOn(":app")
}

// Tarea clean personalizada
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
