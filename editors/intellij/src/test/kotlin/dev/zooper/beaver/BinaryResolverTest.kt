package dev.zooper.beaver

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream
import java.nio.file.Files
import java.nio.file.Path
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

class BinaryResolverTest {
    private val payload = "#!/bin/sh\necho 'beaver 0.1.0 (protocol 1)'\n".toByteArray()
    private val sha = MessageDigest.getInstance("SHA-256").digest(payload).joinToString("") { "%02x".format(it) }
    private val cache: Path = Files.createTempDirectory("beaver-cache")

    private fun manifest(sum: String = sha) = Manifest(
        "0.1.0", 1, "https://example.invalid/v0.1.0/",
        mapOf("linux-x64" to Manifest.Entry("beaver-linux-x64", sum)),
    )

    private fun resolver(
        manifest: Manifest = manifest(),
        onPath: Path? = null,
        versions: Map<Path, String> = emptyMap(),
        fetch: (String) -> InputStream = { ByteArrayInputStream(payload) },
    ) = BinaryResolver(
        manifest = manifest,
        protocol = 1,
        cacheRoot = cache,
        onPath = { onPath },
        probe = { path -> versions[path] ?: if (Files.exists(path)) "beaver 0.1.0 (protocol 1)" else throw IOException("missing") },
        fetch = fetch,
        platform = "linux-x64",
    )

    @Test
    fun `PATH binary is used without download`() {
        val onPath = Path.of("/usr/bin/beaver")
        val binary = resolver(
            onPath = onPath,
            versions = mapOf(onPath to "beaver 0.2.0 (protocol 1)"),
            fetch = { fail("downloaded"); throw IOException() },
        ).resolve("")
        assertEquals(Source.PATH, binary.source)
        assertEquals("0.2.0", binary.version)
    }

    @Test
    fun `incompatible explicit path is an error with no fallback`() {
        val explicit = Path.of("/opt/beaver")
        try {
            resolver(versions = mapOf(explicit to "beaver 9.0.0 (protocol 2)")).resolve("/opt/beaver")
            fail("resolved")
        } catch (e: BinaryException) {
            assertTrue(e.message!!.contains("protocol 2"))
        }
    }

    @Test
    fun `download is verified and cached`() {
        val binary = resolver().resolve("")
        assertEquals(Source.DOWNLOAD, binary.source)
        assertTrue(Files.isExecutable(binary.path))
        assertEquals(sha, MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(binary.path)).joinToString("") { "%02x".format(it) })
    }

    @Test
    fun `checksum mismatch is rejected and nothing is left behind`() {
        val resolver = resolver(manifest = manifest(sum = "0".repeat(64)))
        try {
            resolver.resolve("")
            fail("resolved")
        } catch (e: BinaryException) {
            assertTrue(e.message!!.contains("does not match"))
        }
        val dir = resolver.cachePath("linux-x64").parent
        assertFalse(Files.exists(resolver.cachePath("linux-x64")))
        assertTrue(Files.list(dir).use { files -> files.allMatch { it.fileName.toString() == ".lock" } })
    }

    @Test
    fun `interrupted download leaves no partial executable`() {
        val resolver = resolver(fetch = {
            object : InputStream() {
                var sent = 0
                override fun read(): Int = if (sent++ < 10) 'x'.code else throw IOException("connection reset")
            }
        })
        try {
            resolver.resolve("")
            fail("resolved")
        } catch (e: BinaryException) {
            assertTrue(e.message!!.contains("connection reset"))
        }
        assertFalse(Files.exists(resolver.cachePath("linux-x64")))
    }

    @Test
    fun `cached binary is reused offline`() {
        resolver().resolve("")
        val offline = resolver(fetch = { throw IOException("offline") }).resolve("")
        assertEquals(Source.CACHE, offline.source)
    }

    @Test
    fun `concurrent attempts leave one valid binary`() {
        val downloads = AtomicInteger()
        val start = CountDownLatch(1)
        val results = List(4) {
            val resolver = resolver(fetch = {
                downloads.incrementAndGet()
                Thread.sleep(50)
                ByteArrayInputStream(payload)
            })
            var binary: Binary? = null
            thread { start.await(); binary = resolver.resolve("") } to { binary }
        }
        start.countDown()
        results.forEach { it.first.join() }
        assertEquals(1, downloads.get())
        assertTrue(results.all { it.second()!!.path == results[0].second()!!.path })
        assertTrue(Files.isExecutable(results[0].second()!!.path))
    }

    @Test
    fun `unsupported platform is an error`() {
        val resolver = BinaryResolver(manifest(), 1, cache, { null }, { "" }, { throw IOException() }, platform = null)
        try {
            resolver.resolve("")
            fail("resolved")
        } catch (e: BinaryException) {
            assertTrue(e.message!!.contains("No beaver binary is published"))
        }
    }

    @Test
    fun `platform keys`() {
        assertEquals("macos-arm64", currentPlatform("Mac OS X", "aarch64"))
        assertEquals("linux-x64", currentPlatform("Linux", "amd64"))
        assertEquals("windows-x64", currentPlatform("Windows 11", "amd64"))
        assertEquals(null, currentPlatform("FreeBSD", "amd64"))
    }

    @Test
    fun `range coordinates are 1-based UTF-16`() {
        assertEquals("2:1-2:4", Protocol.range("var  a=1;\nvar  b=2;\n", 10, 13))
    }

    @Test
    fun `manifest parses the release format`() {
        val m = Manifest.parse(
            """{"version": "0.1.0", "protocol": 1, "baseUrl": "https://x/", "binaries": {
              "linux-x64": {"file": "beaver-linux-x64", "sha256": "ab"}}}""",
        )
        assertEquals(Manifest.Entry("beaver-linux-x64", "ab"), m.binaries["linux-x64"])
    }
}
