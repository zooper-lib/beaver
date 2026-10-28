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

    override fun setUp() {
        super.setUp()
        BeaverSettings.instance.executablePath = System.getenv("BEAVER_BINARY")!!
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
            com.intellij.openapi.fileEditor.FileDocumentManager.getInstance().saveDocument(document)
            waitFor { String(file.virtualFile.contentsToByteArray()) == "var saved = 1;\n" }
            assertEquals("var saved = 1;\n", String(file.virtualFile.contentsToByteArray()))
        } finally {
            options.isRunOnSaveEnabled = false
        }
    }

}
