# Helix

Add to `languages.toml` (global `~/.config/helix/languages.toml` or the project's `.helix/languages.toml`):

```toml
[[language]]
name = "dart"
auto-format = true
formatter = { command = "beaver", args = ["--stdin", "--stdin-name", "%{buffer_name}"] }
```

`:format` (or saving, with `auto-format`) formats the whole buffer. `%{buffer_name}` passes the file's path so `.beaver.yaml` and exclusions apply; it needs Helix 25.01 or later. On older versions drop the last two arguments, and the configuration is then discovered from Helix's working directory.

Selection formatting: not available. Helix runs external formatters on the whole document only.
