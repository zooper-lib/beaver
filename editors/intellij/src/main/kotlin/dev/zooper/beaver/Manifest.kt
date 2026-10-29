package dev.zooper.beaver

import com.google.gson.JsonParser

/** The release's platform → file → SHA-256 table, embedded at build time. */
data class Manifest(
    val version: String,
    val protocol: Int,
    val baseUrl: String,
    val binaries: Map<String, Entry>,
) {
    data class Entry(val file: String, val sha256: String)

    companion object {
        /** Parses the manifest JSON written by tool/release/manifest.sh. */
        fun parse(json: String): Manifest {
            val root = JsonParser.parseString(json).asJsonObject
            val binaries = root.getAsJsonObject("binaries").entrySet().associate { (platform, value) ->
                val entry = value.asJsonObject
                platform to Entry(entry["file"].asString, entry["sha256"].asString)
            }
            return Manifest(
                root["version"].asString,
                root["protocol"].asInt,
                root["baseUrl"].asString,
                binaries,
            )
        }
    }
}

/** The running platform's key in the manifest, or null if unsupported. */
fun currentPlatform(
    os: String = System.getProperty("os.name"),
    arch: String = System.getProperty("os.arch"),
): String? {
    val system = when {
        os.startsWith("Mac") -> "macos"
        os.startsWith("Linux") -> "linux"
        os.startsWith("Windows") -> "windows"
        else -> return null
    }
    val cpu = when (arch) {
        "aarch64", "arm64" -> "arm64"
        "x86_64", "amd64" -> "x64"
        else -> return null
    }
    return "$system-$cpu".takeIf { it != "windows-arm64" }
}
