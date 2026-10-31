# Beaver

<p align="center">
  <img src="icon.png" alt="Beaver" width="200"/>
</p>

<p align="center">
  <a href="https://pub.dev/packages/zooper_beaver"><img src="https://img.shields.io/pub/v/zooper_beaver.svg" alt="pub package"/></a>
  <a href="https://github.com/zooper-lib/beaver/actions/workflows/ci.yml"><img src="https://github.com/zooper-lib/beaver/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"/></a>
</p>

> *The compiler doesn't care how your code looks. Unfortunately, we do.*
>
> *Because "it compiles" is a disturbingly low standard.*

A configurable, line-width-aware formatter for Dart and Flutter. You describe how your code should look in a `.beaver.yaml` next to your `pubspec.yaml`, and Beaver formats every file accordingly: from the command line, in CI, and on save in your editor.

## Overview

`dart format` is deliberately unconfigurable. That is a fine choice until your team wants 100 columns with aligned parameters, or keeps the line breaks it typed on purpose. Beaver starts from `dart format`'s conventions and lets you change the ones you disagree with, one documented rule at a time.

## Features

- **Rules, not opinions.** About forty settings for wrapping, indentation, spacing, blank lines, braces and quotes. Each one has its own page with before-and-after examples, and [`example/`](example/) shows every value of every setting on real code.
- **Respects your line breaks.** A line break you typed between arguments, list items or operands stays, unless you configure otherwise. A trailing comma still means "one item per line", as Flutter developers expect.
- **Never changes what your code means.** After formatting, Beaver checks that the result is the same program: same tokens, same syntax tree, same comments in the same places. If the check fails, nothing is written. This cannot be switched off.
- **Leaves alone what you mark.** `// beaver-ignore` keeps the next statement, member or expression exactly as written; `// beaver-ignore-start` … `// beaver-ignore-end` (or `// dart format off` … `on`) keeps a whole region.
- **Fast enough for format on save.** About 16 ms for a 500-line file, from process start to verified output.
- **Close to `dart format` out of the box.** With no configuration, the built-in `dart` preset follows `dart format`'s style. It is close, not identical: Beaver keeps your deliberate line breaks, for example.

## Installation

### Command line, with the Dart SDK

```sh
dart install zooper_beaver
beaver --version
```

This compiles Beaver on your machine and puts `beaver` on your PATH. `dart pub global activate zooper_beaver` works too.

### Command line, prebuilt binary

Every [release](https://github.com/zooper-lib/beaver/releases) carries a self-contained binary per platform; no Dart SDK needed.

| Platform | File |
|---|---|
| macOS, Apple silicon | `beaver-macos-arm64` |
| macOS, Intel | `beaver-macos-x64` |
| Linux x64 | `beaver-linux-x64` |
| Linux arm64 | `beaver-linux-arm64` |
| Windows x64 | `beaver-windows-x64.exe` |

On macOS and Linux, download it with its checksum, check it, and put it on your PATH:

```sh
file=beaver-macos-arm64   # your platform's file from the table
base=https://github.com/zooper-lib/beaver/releases/latest/download
curl -fLO "$base/$file" -O "$base/checksums.txt"
grep " $file\$" checksums.txt | shasum -a 256 -c -   # on Linux: sha256sum -c -
chmod +x "$file" && sudo mv "$file" /usr/local/bin/beaver
beaver --version
```

On Windows, in PowerShell:

```powershell
$base = "https://github.com/zooper-lib/beaver/releases/latest/download"
Invoke-WebRequest "$base/beaver-windows-x64.exe" -OutFile beaver.exe
Invoke-WebRequest "$base/checksums.txt" -OutFile checksums.txt
(Get-FileHash beaver.exe).Hash   # must match the beaver-windows-x64.exe line in checksums.txt
```

Then move `beaver.exe` to a folder on your PATH.

**The prebuilt binaries are not code-signed.** Downloaded with a browser, macOS refuses to open them ("the developer cannot be verified") and Windows SmartScreen warns. After checking the checksum, allow the binary: on macOS run `xattr -d com.apple.quarantine beaver` (or choose System Settings → Privacy & Security → Open Anyway), on Windows choose More info → Run anyway (or run `Unblock-File beaver.exe`). Downloads with `curl` as above are not affected. More in [Installing Beaver](docs/install.md).

### VS Code

Install **Beaver Dart Formatter** (`zooper.beaver`) from the Marketplace. It bundles the `beaver` binary for your platform, so nothing else is needed. Then make it the Dart formatter in your `settings.json`:

```json
"[dart]": {
  "editor.defaultFormatter": "zooper.beaver",
  "editor.formatOnSave": true
}
```

Format Document, Format Selection and format on save now use Beaver. Details: [VS Code](docs/editors/vscode.md).

### IntelliJ IDEA and Android Studio

Install **Beaver Dart Formatter** from the JetBrains Marketplace (Settings | Plugins). The plugin uses `beaver` from your PATH if it is there, and otherwise downloads the matching binary and checks its checksum. Reformat Code, Reformat Selection and folder reformat then use Beaver; for format on save, enable Settings | Tools | Actions on Save | Reformat code. Supported: IntelliJ IDEA and Android Studio 2024.3 to 2025.3. Details: [IntelliJ](docs/editors/intellij.md).

### Other editors

Neovim, Helix, Emacs, Zed and Sublime Text run `beaver` as an external formatter; see [Editors](#editors) for a ready-to-paste configuration each.

## Quick Start

1. Install Beaver (see [Installation](#installation)).
2. In your project, write a starter configuration:

   ```sh
   beaver init
   ```

3. Format every Dart file in place:

   ```sh
   beaver .
   ```

4. Check formatting in CI, without changing anything:

   ```sh
   beaver --check lib       # lists files that would change; exit 1 if any
   beaver --diff lib        # shows what would change
   ```

`beaver config --print` shows the settings in effect and where each one comes from. Generated files (`*.g.dart`, `*.freezed.dart`, `build/`, …) are skipped by default. Everything about the command line, including a git pre-commit hook: [Command line](docs/cli.md).

## Configuration

A `.beaver.yaml` only lists what differs from the `dart` preset:

```yaml
extends: dart

line_length: 100
indent:
  align:
    parameters: true
wrap:
  arguments: if_long
spaces:
  inside_braces: true   # { a: 1 } instead of {a: 1}
strings:
  quotes: single
exclude:
  - "lib/legacy/**"
```

Beaver uses the nearest `.beaver.yaml` above each file. A file can build on another one with `extends:`, so a monorepo can share one base. Unknown keys and invalid values are errors, never silently ignored.

Every setting with its preset value and alternatives, ready to copy as a starting point: [`docs/beaver.template.yaml`](docs/beaver.template.yaml) (or `beaver config --template`). Every setting, with examples: [wrapping](docs/rules/wrap.md) · [indentation](docs/rules/indent.md) · [spaces](docs/rules/spaces.md) · [blank lines](docs/rules/blank_lines.md) · [braces](docs/rules/braces.md) · [strings](docs/rules/strings.md). Or browse [`example/`](example/): one folder per setting, one subfolder per value, each with its `.beaver.yaml` and the output it produces.

## Editors

All editors use the same `beaver` executable and the same `.beaver.yaml`.

| Editor | Integration | Format selection |
|---|---|---|
| VS Code | [Extension](docs/editors/vscode.md) with the binary bundled | Yes |
| IntelliJ IDEA, Android Studio | [Plugin](docs/editors/intellij.md); downloads and verifies the binary | Yes |
| Neovim | [conform.nvim configuration](docs/editors/neovim.md) | Yes |
| Helix | [`languages.toml` entry](docs/editors/helix.md) | No |
| Emacs | [apheleia configuration](docs/editors/emacs.md) | No |
| Zed | [settings entry](docs/editors/zed.md) | No |
| Sublime Text | [Fmt configuration](docs/editors/sublime.md) | No |

Any other editor can call `beaver --stdin`; [the stdin protocol](docs/stdin-protocol.md) describes the contract.

## Examples

One long call:

```dart
final result = computeTheAnswer(firstArgument, secondArgument, thirdArgument, fourth);
```

With the default `wrap.arguments: chop_if_long`, an argument list that does not fit puts every argument on its own line:

```dart
final result = computeTheAnswer(
  firstArgument,
  secondArgument,
  thirdArgument,
  fourth,
);
```

With `wrap.arguments: if_long`, it fills lines instead, like a paragraph:

```dart
final result = computeTheAnswer(
  firstArgument, secondArgument, thirdArgument, fourth,
);
```

For every setting and every value, see [`example/`](example/).

## Documentation

- [Command line](docs/cli.md): modes, file selection, exit codes, a git pre-commit hook
- [Ignoring code](docs/directives.md): `// beaver-ignore` and ignored regions
- [Installing](docs/install.md) and [versioning](docs/versioning.md)
- [Performance](docs/performance.md) and the [safety corpus](docs/safety-corpus.md): how Beaver is tested on real code

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

```sh
cd packages/zooper_beaver
dart test                              # unit, golden and safety tests
dart run bin/beaver.dart --check .     # this repository is formatted by Beaver itself
```

Formatting behaviour is pinned by golden tests in `packages/zooper_beaver/test/golden/`; a change in output comes with a golden case. Please format with Beaver, not `dart format`: CI checks it.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by the Zooper team
