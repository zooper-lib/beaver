package dev.zooper.beaver

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.util.ExecUtil
import com.intellij.notification.NotificationGroupManager
import com.intellij.notification.NotificationType
import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.CommonDataKeys
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.service

/** "Beaver: Show Formatter Information": versions, binary source and path,
 *  platform, and the configuration resolved for the current file. */
class ShowInformationAction : AnAction() {
    override fun getActionUpdateThread() = ActionUpdateThread.BGT

    override fun actionPerformed(event: AnActionEvent) {
        val project = event.project
        val file = event.getData(CommonDataKeys.VIRTUAL_FILE)
        ApplicationManager.getApplication().executeOnPooledThread {
            val text = information(file?.takeIf { it.isInLocalFileSystem }?.path, project?.basePath)
            NotificationGroupManager.getInstance().getNotificationGroup("Beaver")
                .createNotification("Beaver formatter information", text, NotificationType.INFORMATION)
                .notify(project)
        }
    }

    companion object {
        fun information(forFile: String?, workDirectory: String?): String {
            val lines = mutableListOf(
                "Plugin declares formatter ${PluginInfo.bundledFormatterVersion}, protocol ${PluginInfo.protocolVersion}",
                "Platform: ${currentPlatform() ?: "${System.getProperty("os.name")} ${System.getProperty("os.arch")} (unsupported)"}",
            )
            try {
                val binary = service<BeaverBinaries>().get()
                lines += listOf(
                    "Formatter: ${binary.version}",
                    "Protocol: ${binary.protocol}",
                    "Source: ${binary.source.name.lowercase()}",
                    "Path: ${binary.path}",
                )
                val command = GeneralCommandLine(binary.path.toString(), "config", "--print")
                if (forFile != null) command.addParameters("--for", forFile)
                workDirectory?.let { java.io.File(it) }?.takeIf { it.isDirectory }?.let { command.withWorkDirectory(it) }
                val config = ExecUtil.execAndGetOutput(command, 10_000)
                lines += listOf("Resolved configuration:", if (config.exitCode == 0) config.stdout else config.stderr)
            } catch (e: BinaryException) {
                lines += "Formatter: unavailable: ${e.message}"
            }
            return lines.joinToString("\n")
        }
    }
}
