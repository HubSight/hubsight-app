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

subprojects {
    project.plugins.withId("com.android.library") {
        project.extensions.findByName("androidComponents")?.let { comp ->
            try {
                val finalizeDslMethod = comp.javaClass.methods.firstOrNull { 
                    it.name == "finalizeDsl" && it.parameterTypes.size == 1 && it.parameterTypes[0] == org.gradle.api.Action::class.java
                }
                if (finalizeDslMethod != null) {
                    val action = object : org.gradle.api.Action<Any> {
                        override fun execute(ext: Any) {
                            try {
                                val setCompileSdk = ext.javaClass.methods.firstOrNull { 
                                    it.name == "setCompileSdk" && it.parameterTypes.size == 1 && it.parameterTypes[0] == Int::class.javaObjectType
                                } ?: ext.javaClass.methods.firstOrNull { 
                                    it.name == "compileSdkVersion" && it.parameterTypes.size == 1 && it.parameterTypes[0] == Int::class.java
                                }
                                setCompileSdk?.invoke(ext, 36)
                            } catch (_: Throwable) {}
                        }
                    }
                    finalizeDslMethod.invoke(comp, action)
                }
            } catch (_: Throwable) {}
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
