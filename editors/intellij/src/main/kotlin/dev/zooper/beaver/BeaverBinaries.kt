package dev.zooper.beaver

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.configurations.PathEnvironmentVariableUtil
import com.intellij.execution.util.ExecUtil
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.components.Service
import com.intellij.util.io.HttpRequests
import java.nio.file.Path
import java.util.Properties

/** The plugin's declared versions and embedded manifest. */
object PluginInfo {
    private val properties = Properties().apply {
        PluginInfo::class.java.getResourceAsStream("/beaver/plugin.properties")?.use(::load)
    }
    val bundledFormatterVersion: String = properties.getProperty("bundledFormatterVersion", "?")
    val protocolVersion: Int = properties.getProperty("protocolVersion", "1").toInt()
    val manifest: Manifest = Manifest.parse(
        PluginInfo::class.java.getResource("/beaver/beaver-manifest.json")!!.readText(),
    )
}

/** Resolves the executable once per settings change. */
@Service
class BeaverBinaries {
    @Volatile
    private var cached: Binary? = null

    fun reset() {
        cached = null
    }

    @Synchronized
    fun get(): Binary = cached ?: resolver().resolve(BeaverSettings.instance.executablePath).also { cached = it }

    fun resolver() = BinaryResolver(
        manifest = PluginInfo.manifest,
        protocol = PluginInfo.protocolVersion,
        cacheRoot = Path.of(PathManager.getSystemPath(), "beaver"),
        onPath = { PathEnvironmentVariableUtil.findInPath("beaver")?.toPath() },
        probe = { path ->
            val output = ExecUtil.execAndGetOutput(GeneralCommandLine(path.toString(), "--version"), 10_000)
            if (output.exitCode != 0) throw IllegalStateException(output.stderr.ifBlank { "exit ${output.exitCode}" })
            output.stdout
        },
        fetch = { url -> HttpRequests.request(url).connect { it.inputStream.readAllBytes() }.inputStream() },
    )
}
