package dev.zooper.beaver

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.CapturingProcessHandler
import com.intellij.formatting.service.AsyncDocumentFormattingService
import com.intellij.formatting.service.AsyncFormattingRequest
import com.intellij.formatting.service.FormattingService
import com.intellij.openapi.components.service
import com.intellij.psi.PsiFile
import java.nio.charset.StandardCharsets

/**
 * Formats Dart files through `beaver --stdin`. Runs off the UI thread,
 * formats the document's current text (not the file on disk), passes
 * selections as `--range`, and on any failure leaves the document untouched.
 */
class BeaverFormattingService : AsyncDocumentFormattingService() {
    override fun getFeatures(): Set<FormattingService.Feature> = setOf(FormattingService.Feature.FORMAT_FRAGMENTS)

    override fun canFormat(file: PsiFile): Boolean = file.name.endsWith(".dart")

    override fun getNotificationGroupId(): String = "Beaver"

    override fun getName(): String = "Beaver"

    override fun createFormattingTask(request: AsyncFormattingRequest): FormattingTask? {
        val binary = try {
            service<BeaverBinaries>().get()
        } catch (e: BinaryException) {
            request.onError("Beaver", e.message ?: "No beaver executable.")
            return null
        }
        val text = request.documentText
        val file = request.context.virtualFile
        val command = GeneralCommandLine(binary.path.toString(), "--stdin").withCharset(StandardCharsets.UTF_8)
        if (file != null && file.isInLocalFileSystem) command.addParameters("--stdin-name", file.path)
        val ranges = request.formattingRanges
        val whole = ranges.size == 1 && ranges[0].startOffset == 0 && ranges[0].endOffset == text.length
        if (!whole && ranges.isNotEmpty()) {
            // The protocol takes one range: the span covering every fragment.
            val start = ranges.minOf { it.startOffset }
            val end = ranges.maxOf { it.endOffset }
            command.addParameters("--range", Protocol.range(text, start, end))
        }
        // Configuration discovery without --stdin-name starts here.
        val workDirectory = file?.takeIf { it.isInLocalFileSystem }?.parent?.path ?: request.context.project.basePath
        workDirectory?.let { java.io.File(it) }?.takeIf { it.isDirectory }?.let { command.withWorkDirectory(it) }

        return object : FormattingTask {
            private var handler: CapturingProcessHandler? = null

            override fun run() {
                val process = CapturingProcessHandler(command).also { handler = it }
                process.processInput.use { it.write(text.toByteArray(StandardCharsets.UTF_8)) }
                val result = process.runProcess()
                when {
                    result.isCancelled -> request.onTextReady(null)
                    result.exitCode == 0 -> request.onTextReady(result.stdout)
                    else -> request.onError(
                        "Beaver",
                        "Not formatted: ${Protocol.exitMeaning[result.exitCode] ?: "exit ${result.exitCode}"}. ${result.stderr.trim()}",
                    )
                }
            }

            override fun cancel(): Boolean {
                handler?.destroyProcess()
                return true
            }

            override fun isRunUnderProgress(): Boolean = true
        }
    }
}
