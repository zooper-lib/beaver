package dev.zooper.beaver

import com.intellij.openapi.components.BaseState
import com.intellij.openapi.components.Service
import com.intellij.openapi.components.SimplePersistentStateComponent
import com.intellij.openapi.components.State
import com.intellij.openapi.components.Storage
import com.intellij.openapi.components.service
import com.intellij.openapi.options.BoundConfigurable
import com.intellij.openapi.ui.DialogPanel
import com.intellij.ui.dsl.builder.bindText
import com.intellij.ui.dsl.builder.panel

/** Application-level setting: an explicit beaver executable. */
@Service
@State(name = "Beaver", storages = [Storage("beaver.xml")])
class BeaverSettings : SimplePersistentStateComponent<BeaverSettings.Options>(Options()) {
    class Options : BaseState() {
        var executablePath by string("")
    }

    var executablePath: String
        get() = state.executablePath ?: ""
        set(value) {
            state.executablePath = value
            service<BeaverBinaries>().reset()
        }

    companion object {
        val instance get() = service<BeaverSettings>()
    }
}

class BeaverConfigurable : BoundConfigurable("Beaver") {
    override fun createPanel(): DialogPanel = panel {
        row("Beaver executable:") {
            textField()
                .bindText(BeaverSettings.instance::executablePath)
                .comment("Empty: beaver on PATH, else the plugin's verified download.")
        }
    }
}
