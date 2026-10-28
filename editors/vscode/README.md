# Beaver for VS Code

Formats Dart with [Beaver](https://github.com/zooper-lib/beaver), the configurable formatter whose rules live in `.beaver.yaml`. Supports Format Document, Format Selection and format on save; works in remote and container workspaces.

Make it the Dart formatter:

```json
"[dart]": {
  "editor.defaultFormatter": "zooper.beaver",
  "editor.formatOnSave": true
}
```

The extension uses `beaver.executablePath` if set, else `beaver` on your PATH, else the binary bundled for your platform. Run **Beaver: Show Formatter Information** to see which one is in use. See the [documentation](https://github.com/zooper-lib/beaver/blob/main/docs/editors/vscode.md).
