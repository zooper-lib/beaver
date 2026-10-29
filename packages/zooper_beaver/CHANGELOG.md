## 0.1.0

First release.

- `beaver` command: format files in place, `--check` and `--diff` for CI, `--stdin` for editors (with `--range` for selections), `config --print` and `init`.
- `.beaver.yaml` configuration with the built-in `dart` preset, `extends:` inheritance and `exclude:` patterns; generated files are skipped by default.
- Rules for wrapping (arguments, parameters, collections, binary and conditional expressions, method chains), trailing commas, indentation and alignment, spaces, blank lines, braces and string quotes.
- Line breaks you typed are kept; a trailing comma puts every item on its own line.
- `// beaver-ignore`, `// beaver-ignore-start` / `-end` and `// dart format off` / `on`.
- Every result is verified to be the same program before it is written.
- Prebuilt, unsigned binaries for Linux, macOS and Windows; extensions for VS Code and IntelliJ IDEA / Android Studio.
