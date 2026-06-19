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
    val configureAndroid = Action<Project> {
        if (hasProperty("android")) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(android)
                    if (currentNamespace == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        val fallbackNamespace = "com.fallback." + name.replace("-", ".").replace("_", ".")
                        setNamespace.invoke(android, fallbackNamespace)
                        logger.quiet("Auto-injected namespace for subproject $name: $fallbackNamespace")
                    }

                    // Clean up deprecated package attribute in AndroidManifest.xml to prevent AGP 8.x processing errors
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        var content = manifestFile.readText()
                        if (content.contains("package=")) {
                            content = content.replace(Regex("""package="[^"]*""""), "")
                            manifestFile.writeText(content)
                            logger.quiet("Cleaned up package attribute in AndroidManifest.xml for subproject $name")
                        }
                    }
                } catch (e: Exception) {
                    // Fail silently
                }

                try {
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    val javaVersionClass = Class.forName("org.gradle.api.JavaVersion")
                    val version17 = javaVersionClass.getField("VERSION_17").get(null)
                    compileOptions.javaClass.getMethod("setSourceCompatibility", javaVersionClass).invoke(compileOptions, version17)
                    compileOptions.javaClass.getMethod("setTargetCompatibility", javaVersionClass).invoke(compileOptions, version17)
                    logger.quiet("Auto-injected compileOptions Java 17 for subproject $name")
                } catch (e: Exception) {
                    // Fail silently
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid.execute(this)
    } else {
        afterEvaluate {
            configureAndroid.execute(this)
        }
    }
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    tasks.configureEach {
        if (name.contains("compile") && name.contains("Kotlin")) {
            try {
                val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
                val kotlinOptions = getKotlinOptions.invoke(this)
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "17")
                logger.quiet("Aligned Kotlin JVM Target to 17 for task: $name in project: ${project.name}")
            } catch (e: Exception) {
                // Ignore if not a Kotlin Compile task or reflection fails
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
