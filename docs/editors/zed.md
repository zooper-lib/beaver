# Zed

Add to Zed's `settings.json` (user, or the project's `.zed/settings.json`):

```json
{
  "languages": {
    "Dart": {
      "format_on_save": "on",
      "formatter": {
        "external": {
          "command": "beaver",
          "arguments": ["--stdin", "--stdin-name", "{buffer_path}"]
        }
      }
    }
  }
}
```

**Format** and format on save then run Beaver on the whole buffer; `{buffer_path}` makes `.beaver.yaml` and exclusions apply to the file.

Selection formatting: not available. Zed formats selections only through language servers, and Beaver has none.
