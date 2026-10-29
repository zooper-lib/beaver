# VS Code

## Install

Install **Beaver Dart Formatter** (`zooper.beaver`) from the Marketplace, or a downloaded `beaver-<platform>.vsix` with **Extensions: Install from VSIX…**. Each platform's extension bundles a `beaver` binary, so nothing else is needed. It is a workspace extension: in a remote, WSL or dev-container workspace it runs where the files are and formats with the binary there.

## Make Beaver the Dart formatter

In your user or workspace `settings.json`:

```json
"[dart]": {
  "editor.defaultFormatter": "zooper.beaver",
  "editor.formatOnSave": true
}
```

**Format Document**, **Format Selection** and format on save then use Beaver. Formatting uses the editor's buffer, including unsaved edits, and the `.beaver.yaml` that applies to the file's path. Files excluded by the configuration (generated code, by default) are left unchanged without an error.

## Coexisting with the Dart extension

The Dart extension (`Dart-Code.dart-code`) also provides a formatter. Keep it for everything else it does; the `editor.defaultFormatter` setting above decides which formatter runs. To be sure the Dart extension never formats, also set `"dart.enableSdkFormatter": false`.

## Which binary is used

1. `beaver.executablePath`, if set.
2. `beaver` on your PATH, for example after `dart install zooper_beaver@<version>`.
3. The binary bundled with the extension.

The chosen binary must report the protocol version the extension speaks; if a configured or PATH binary does not, formatting stops with an error rather than silently using another one. Run **Beaver: Show Formatter Information** to see the formatter version, protocol, source, path, platform and the resolved configuration for the current file. To match CI exactly, install the same version on PATH or point `beaver.executablePath` at it.

## When a file is not formatted

A syntax error, invalid configuration or failed verification leaves the buffer unchanged; the reason is in the status bar and the **Beaver** output channel.
