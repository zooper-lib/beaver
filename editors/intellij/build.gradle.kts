import org.jetbrains.intellij.platform.gradle.TestFrameworkType

plugins {
    kotlin("jvm") version "2.3.21"
    id("org.jetbrains.intellij.platform") version "2.10.4"
}

group = "dev.zooper.beaver"
version = providers.gradleProperty("pluginVersion").get()

kotlin { jvmToolchain(21) }

repositories {
    mavenCentral()
    intellijPlatform { defaultRepositories() }
}

dependencies {
    intellijPlatform {
        val local = providers.gradleProperty("localPlatformPath").get()
        if (local.isNotBlank()) {
            local(local)
        } else {
            create(
                providers.gradleProperty("platformType"),
                providers.gradleProperty("platformVersion"),
            )
        }
        testFramework(TestFrameworkType.Platform)
        // Real Dart files for DartWorkflowsTest; not a runtime dependency.
        if (providers.gradleProperty("withDart").orNull == "true") compatiblePlugin("Dart")
    }
    testImplementation("junit:junit:4.13.2")
}

intellijPlatform {
    pluginConfiguration {
        version = providers.gradleProperty("pluginVersion")
        ideaVersion {
            sinceBuild = providers.gradleProperty("sinceBuild")
            untilBuild = providers.gradleProperty("untilBuild")
        }
    }
    // Plugin Verifier: the supported range, checked in CI.
    pluginVerification { ides { recommended() } }
}

// The binary manifest from the release and the declared versions are
// embedded at build time. Without a release manifest (local builds), a
// placeholder with no binaries is used, so downloads are disabled.
val generateResources by tasks.registering {
    val manifest = providers.environmentVariable("BEAVER_MANIFEST")
    val output = layout.buildDirectory.dir("generated/resources")
    val formatter = providers.gradleProperty("bundledFormatterVersion")
    val protocol = providers.gradleProperty("protocolVersion")
    inputs.property("formatter", formatter)
    inputs.property("protocol", protocol)
    inputs.property("manifest", manifest.orElse(""))
    outputs.dir(output)
    doLast {
        val dir = output.get().asFile.resolve("beaver").apply { mkdirs() }
        dir.resolve("plugin.properties").writeText(
            "bundledFormatterVersion=${formatter.get()}\nprotocolVersion=${protocol.get()}\n",
        )
        val source = manifest.orNull
        dir.resolve("beaver-manifest.json").writeText(
            if (source.isNullOrBlank()) {
                """{"version": "${formatter.get()}", "protocol": ${protocol.get()}, "baseUrl": "", "binaries": {}}"""
            } else {
                file(source).readText()
            },
        )
    }
}
sourceSets.main { resources.srcDir(generateResources) }

tasks.test {
    if (providers.gradleProperty("withDart").orNull != "true") exclude("**/DartWorkflowsTest*")
    systemProperty("beaver.expectedFormatterVersion", providers.gradleProperty("bundledFormatterVersion").get())
    environment("BEAVER_BINARY", providers.environmentVariable("BEAVER_BINARY").getOrElse(""))
}
