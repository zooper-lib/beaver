# Sublime Text

With the [Fmt](https://packagecontrol.io/packages/Fmt) package, in **Preferences | Package Settings | Fmt | Settings**:

```json
{
  "rules": [
    {
      "selector": "source.dart",
      "cmd": ["beaver", "--stdin", "--stdin-name", "$file"],
      "format_on_save": true
    }
  ]
}
```

**Fmt: Format Buffer** and saving format the whole file with the configuration that applies to it.

Selection formatting: not available. Fmt sends the whole buffer to the formatter.
