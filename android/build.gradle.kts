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
    
    val configureAndroid = {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileSdkVersion(36)
            }
            
            // Injeta o namespace caso a biblioteca não possua um definido
            val libraryExtension = project.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (libraryExtension != null && libraryExtension.namespace == null) {
                val groupStr = project.group.toString()
                libraryExtension.namespace = if (groupStr.isNotEmpty()) groupStr else "dev.isar.${project.name.replace("-", "_").replace("+", "_")}"
            }
        }
    }
    
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
