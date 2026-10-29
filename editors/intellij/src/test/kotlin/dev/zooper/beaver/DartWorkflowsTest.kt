package dev.zooper.beaver

import com.intellij.openapi.command.WriteCommandAction
import com.intellij.testFramework.fixtures.BasePlatformTestCase

/**
 * Folder reformat and Reformat on Save. The platform skips files of a type
 * without a formatter on these paths, so `.dart` files must be Dart files:
 * these run only with the Dart plugin in the test IDE (`-PwithDart=true`,
 * done in CI against IntelliJ IDEA Community).
 */
class DartWorkflowsTest : BasePlatformTestCase() {
    override fun createTempDirTestFixture() =
        com.intellij.testFramework.fixtures.impl.TempDirTestFixtureImpl()

    private lateinit var root: com.intellij.openapi.vfs.VirtualFile

    override fun setUp() {
        super.setUp()
        BeaverSettings.instance.executablePath = System.getenv("BEAVER_BINARY")!!
        // Folder reformat and actions on save only touch project content.
        root = myFixture.tempDirFixture.findOrCreateDir(".")
        com.intellij.testFramework.PsiTestUtil.addContentRoot(module, root)
    }

    override fun tearDown() {
        try {
            com.intellij.testFramework.PsiTestUtil.removeContentEntry(module, root)
        } finally {
            super.tearDown()
        }
    }

    private fun assumeDart(file: com.intellij.psi.PsiFile) =
        assertEquals("these tests need the Dart plugin", "Dart", file.language.id)

    /** Async formatting finishes off the UI thread; pump events until [done]. */
    private fun waitFor(done: () -> Boolean) {
        val deadline = System.currentTimeMillis() + 15_000
        while (!done() && System.currentTimeMillis() < deadline) {
            com.intellij.testFramework.PlatformTestUtil.dispatchAllEventsInIdeEventQueue()
            Thread.sleep(20)
        }
    }

    fun `test folder reformat`() {
        val a = myFixture.addFileToProject("lib/a.dart", "var  a=1;\n")
        val b = myFixture.addFileToProject("lib/src/b.dart", "var  b=2;\n")
        assumeDart(a)
        val directory = a.containingDirectory.parentDirectory!!.findSubdirectory("lib")!!
        com.intellij.codeInsight.actions.ReformatCodeProcessor(project, directory, true, false).run()
        waitFor { b.viewProvider.document!!.text == "var b = 2;\n" }
        assertEquals("var a = 1;\n", a.viewProvider.document!!.text)
        assertEquals("var b = 2;\n", b.viewProvider.document!!.text)
    }

    fun `test Reformat on Save`() {
        val options = com.intellij.codeInsight.actions.onSave.FormatOnSaveOptions.getInstance(project)
        options.isRunOnSaveEnabled = true
        try {
            val file = myFixture.addFileToProject("save.dart", "var a = 1;\n")
            assumeDart(file)
            val document = file.viewProvider.document!!
            WriteCommandAction.runWriteCommandAction(project) { document.setText("var  saved=1;\n") }
            // Actions on save run on an explicit save (Save All, Ctrl+S), not on
            // every programmatic save.
            com.intellij.testFramework.PlatformTestUtil.invokeNamedAction("SaveAll")
            waitFor { String(file.virtualFile.contentsToByteArray()) == "var saved = 1;\n" }
            assertEquals("var saved = 1;\n", String(file.virtualFile.contentsToByteArray()))
        } finally {
            options.isRunOnSaveEnabled = false
        }
    }

    /**
     * Task 17.3: end-to-end Reformat on Save on a representative file (541
     * lines), process start included. Reported, not asserted: machines vary;
     * docs/performance.md records the numbers.
     */
    fun `test Reformat on Save latency`() {
        val source = java.io.File("../../packages/zooper_beaver/lib/src/cli/cli.dart").readText()
        val options = com.intellij.codeInsight.actions.onSave.FormatOnSaveOptions.getInstance(project)
        options.isRunOnSaveEnabled = true
        try {
            val file = myFixture.addFileToProject("latency.dart", source)
            assumeDart(file)
            val document = file.viewProvider.document!!
            val times = (1..7).map {
                WriteCommandAction.runWriteCommandAction(project) {
                    document.setText(source.replaceFirst("import ", "import  "))
                }
                val start = System.nanoTime()
                com.intellij.testFramework.PlatformTestUtil.invokeNamedAction("SaveAll")
                waitFor { String(file.virtualFile.contentsToByteArray()) == source }
                assertEquals(source, String(file.virtualFile.contentsToByteArray()))
                (System.nanoTime() - start) / 1e6
            }
            // The first save also locates and probes the binary.
            val sorted = times.drop(1).sorted()
            println(
                "BEAVER_LATENCY intellij first=%.1fms median=%.1fms max=%.1fms runs=%s"
                    .format(times[0], sorted[sorted.size / 2], sorted.last(), times.map { "%.0f".format(it) }),
            )
        } finally {
            options.isRunOnSaveEnabled = false
        }
    }
}
