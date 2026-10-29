package dev.zooper.beaver

import java.io.IOException
import java.io.InputStream
import java.io.RandomAccessFile
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.security.MessageDigest

class BinaryException(message: String) : Exception(message)

/** Where the binary came from, for the information action. */
enum class Source { SETTING, PATH, CACHE, DOWNLOAD }

data class Binary(val path: Path, val source: Source, val version: String, val protocol: Int)

/**
 * Finds the beaver executable: setting → PATH → cache → download. Every
 * candidate is probed with `--version`; a configured or PATH binary that is
 * unusable is an error, never a silent fallback to the next source.
 * Downloads are verified against [manifest] before they become executable.
 */
class BinaryResolver(
    private val manifest: Manifest,
    private val protocol: Int,
    private val cacheRoot: Path,
    /** `beaver` on PATH, or null. */
    private val onPath: () -> Path?,
    /** Runs `<path> --version`; returns stdout or throws. */
    private val probe: (Path) -> String,
    /** Opens an HTTPS download. */
    private val fetch: (String) -> InputStream,
    private val platform: String? = currentPlatform(),
) {
    fun resolve(setting: String): Binary {
        if (setting.isNotBlank()) return check(Path.of(setting.trim()), Source.SETTING)
        onPath()?.let { return check(it, Source.PATH) }
        val key = platform ?: throw BinaryException(
            "No beaver binary is published for ${System.getProperty("os.name")} ${System.getProperty("os.arch")}; " +
                "install one on PATH or set its path in Settings | Tools | Beaver.",
        )
        val cached = cachePath(key)
        if (Files.isExecutable(cached)) return check(cached, Source.CACHE)
        download(key, cached)
        return check(cached, Source.DOWNLOAD)
    }

    fun cachePath(platform: String): Path {
        val file = manifest.binaries[platform]?.file ?: "beaver"
        return cacheRoot.resolve(manifest.version).resolve(platform).resolve(file)
    }

    private fun check(path: Path, source: Source): Binary {
        val output = try {
            probe(path)
        } catch (e: Exception) {
            throw BinaryException("beaver from ${source.label} ($path) does not run: ${e.message}")
        }
        val (version, reported) = Protocol.parseVersion(output)
            ?: throw BinaryException("beaver from ${source.label} ($path) printed an unexpected version: ${output.trim()}")
        if (reported != protocol) {
            throw BinaryException(
                "beaver from ${source.label} ($path) speaks protocol $reported; this plugin needs protocol $protocol.",
            )
        }
        return Binary(path, source, version, reported)
    }

    /**
     * Downloads into a temporary file next to [target], checks its SHA-256,
     * then moves it into place atomically. A lock file serializes concurrent
     * attempts (several IDE windows); whoever comes second reuses the result.
     * An interrupted or rejected download never leaves a partial executable.
     */
    private fun download(platform: String, target: Path) {
        val entry = manifest.binaries[platform]
            ?: throw BinaryException("The plugin's binary manifest has no entry for $platform.")
        if (!manifest.baseUrl.startsWith("https://")) {
            throw BinaryException("The plugin's binary manifest has no HTTPS download location.")
        }
        val directory = target.parent
        Files.createDirectories(directory)
        // The file lock serializes IDE processes; the monitor serializes
        // threads of this one (a JVM may hold only one lock per file).
        synchronized(monitors.computeIfAbsent(directory.toAbsolutePath()) { Any() }) {
            RandomAccessFile(directory.resolve(".lock").toFile(), "rw").channel.use { channel ->
                channel.lock().use { downloadLocked(entry, target, directory) }
            }
        }
    }

    private fun downloadLocked(entry: Manifest.Entry, target: Path, directory: Path) {
        if (Files.isExecutable(target)) return
        val temp = Files.createTempFile(directory, "download", ".tmp")
        try {
            val digest = MessageDigest.getInstance("SHA-256")
            fetch(manifest.baseUrl + entry.file).use { input ->
                Files.newOutputStream(temp).use { output ->
                    val buffer = ByteArray(1 shl 16)
                    while (true) {
                        val n = input.read(buffer)
                        if (n < 0) break
                        digest.update(buffer, 0, n)
                        output.write(buffer, 0, n)
                    }
                }
            }
            val actual = digest.digest().joinToString("") { "%02x".format(it) }
            if (!actual.equals(entry.sha256, ignoreCase = true)) {
                throw BinaryException(
                    "Downloaded ${entry.file} does not match the plugin's manifest (SHA-256 $actual); discarded.",
                )
            }
            temp.toFile().setExecutable(true)
            Files.move(temp, target, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
        } catch (e: IOException) {
            throw BinaryException("Could not download ${entry.file}: ${e.message}")
        } finally {
            Files.deleteIfExists(temp)
        }
    }

    private val Source.label get() = name.lowercase()

    private companion object {
        val monitors = java.util.concurrent.ConcurrentHashMap<Path, Any>()
    }
}
