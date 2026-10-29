# IntelliJ IDEA and Android Studio

## Install

Install **Beaver Dart Formatter** from the JetBrains Marketplace, or a downloaded `beaver-intellij-<version>.zip` with **Settings | Plugins | ⚙ | Install Plugin from Disk…**. Supported IDEs: IntelliJ IDEA and Android Studio based on IntelliJ Platform 2024.3 to 2025.3 (builds 243 to 253.*).

## Use

Once installed, Beaver formats every `.dart` file: **Code | Reformat Code** (whole file or selection), **Reformat Code** on a folder, and **Reformat on Save** (Settings | Tools | Actions on Save | Reformat code). It formats the editor's current text, including unsaved changes, with the `.beaver.yaml` that applies to the file. Formatting runs in the background and can be cancelled; if it fails (a syntax error, invalid configuration, failed verification) the document is left unchanged and the reason is shown in a notification. Generated files excluded by the configuration are left as they are, without an error.

To reformat on save:

1. Settings | Tools | Actions on Save.
2. Tick **Reformat code** and make sure Dart files are included.

## Which binary is used

1. **Settings | Tools | Beaver | Beaver executable**, if set.
2. `beaver` on your PATH, for example after `dart install zooper_beaver@<version>`.
3. A binary the plugin downloads from the matching GitHub release on first use, into the IDE's system directory. The download is accepted only if its SHA-256 matches the manifest built into the plugin; an interrupted or mismatching download is discarded and never run. Once downloaded it is reused offline, and several IDE windows share it safely.

The binary must report the protocol version the plugin speaks; a configured or PATH binary that does not is an error, never a silent switch to another binary. **Beaver: Show Formatter Information** (Find Action) shows the formatter version, protocol, source, path, platform and the configuration resolved for the current file.
