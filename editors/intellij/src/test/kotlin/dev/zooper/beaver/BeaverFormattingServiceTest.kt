package dev.zooper.beaver

import com.intellij.openapi.command.WriteCommandAction
import com.intellij.psi.codeStyle.CodeStyleManager
import com.intellij.testFramework.fixtures.BasePlatformTestCase

/** Runs the platform's reformat entry points against a real beaver
 *  executable given by BEAVER_BINARY. */
class BeaverFormattingServiceTest : BasePlatformTestCase() {
    // Real files on disk, so `--stdin-name` (and with it exclusions) applies.
    override fun createTempDirTestFixture() =
        com.intellij.testFramework.fixtures.impl.TempDirTestFixtureImpl()

    override fun setUp() {
        super.setUp()
        val binary = System.getenv("BEAVER_BINARY")
        assumeTrue(!binary.isNullOrBlank())
        BeaverSettings.instance.executablePath = binary!!
    }

    private fun assumeTrue(condition: Boolean) = org.junit.Assume.assumeTrue("BEAVER_BINARY not set", condition)

    private fun reformat(range: IntRange? = null) = WriteCommandAction.runWriteCommandAction(project) {
        val manager = CodeStyleManager.getInstance(project)
        if (range == null) {
            manager.reformat(myFixture.file)
        } else {
            manager.reformatText(myFixture.file, range.first, range.last + 1)
        }
    }

    fun `test Reformat Code`() {
        myFixture.configureByText("a.dart", "var  a=1;\n")
        reformat()
        assertEquals("var a = 1;\n", myFixture.editor.document.text)
    }

    fun `test Reformat Selection formats the covering statement only`() {
        myFixture.configureByText("b.dart", "var  a=1;\nvar  b=2;\n")
        reformat(10 until 13)
        assertEquals("var  a=1;\nvar b = 2;\n", myFixture.editor.document.text)
    }

    fun `test unsaved document text is what gets formatted`() {
        myFixture.configureByText("c.dart", "var  disk=1;\n")
        WriteCommandAction.runWriteCommandAction(project) {
            myFixture.editor.document.setText("var  buffer=2;\n")
        }
        reformat()
        assertEquals("var buffer = 2;\n", myFixture.editor.document.text)
    }

    fun `test syntax error leaves the document unchanged`() {
        myFixture.configureByText("d.dart", "var = ;\n")
        reformat()
        assertEquals("var = ;\n", myFixture.editor.document.text)
    }

    fun `test excluded file is unchanged without error`() {
        myFixture.addFileToProject("pubspec.yaml", "name: x\n")
        myFixture.configureByText("e.g.dart", "var  generated=1;\n")
        reformat()
        assertEquals("var  generated=1;\n", myFixture.editor.document.text)
    }

    fun `test information lists versions, source, path, platform and configuration`() {
        val text = ShowInformationAction.information(null, null)
        for (field in listOf("Plugin declares formatter", "Platform:", "Formatter:", "Protocol: 1", "Source: setting", "Path:", "Resolved configuration:", "line_length:")) {
            assertTrue(text, text.contains(field))
        }
    }

    fun `test plugin version and declared formatter version are independent`() {
        assertEquals(System.getProperty("beaver.expectedFormatterVersion"), PluginInfo.bundledFormatterVersion)
        assertEquals(1, PluginInfo.protocolVersion)
    }
}
