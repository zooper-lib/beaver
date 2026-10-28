package dev.zooper.beaver

/** The plugin side of the stdin protocol (docs/stdin-protocol.md); IDE-independent. */
object Protocol {
    private val versionLine = Regex("""^beaver (\S+) \(protocol (\d+)\)\s*$""")

    /** Parses `beaver <version> (protocol <n>)`. */
    fun parseVersion(output: String): Pair<String, Int>? =
        versionLine.find(output.trim())?.let { it.groupValues[1] to it.groupValues[2].toInt() }

    /** `--range` value (1-based line:column, end exclusive) for [start, end)
     *  offsets in [text], columns in UTF-16 units like Java strings. */
    fun range(text: CharSequence, start: Int, end: Int): String {
        fun position(offset: Int): String {
            var line = 1
            var lineStart = 0
            for (i in 0 until offset) {
                if (text[i] == '\n') {
                    line++
                    lineStart = i + 1
                }
            }
            return "$line:${offset - lineStart + 1}"
        }
        return "${position(start)}-${position(end)}"
    }

    val exitMeaning = mapOf(
        64 to "usage error",
        65 to "the file does not parse or has invalid ignore directives",
        66 to "input not found",
        70 to "internal error: the formatted output failed verification",
        78 to "invalid configuration",
    )
}
