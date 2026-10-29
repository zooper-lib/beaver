# Beaver

<p align="center">
  <img src="https://raw.githubusercontent.com/zooper-lib/beaver/main/icon.png" alt="Beaver" width="200"/>
</p>

<p align="center">
  <a href="https://pub.dev/packages/zooper_beaver"><img src="https://img.shields.io/pub/v/zooper_beaver.svg" alt="pub package"/></a>
  <a href="https://github.com/zooper-lib/beaver/actions/workflows/ci.yml"><img src="https://github.com/zooper-lib/beaver/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <a href="https://github.com/zooper-lib/beaver/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"/></a>
</p>

> *The compiler doesn't care how your code looks. Unfortunately, we do.*
>
> *Because "it compiles" is a disturbingly low standard.*

A configurable, line-width-aware formatter for Dart and Flutter. You describe how your code should look in a `.beaver.yaml` next to your `pubspec.yaml`, and Beaver formats every file accordingly: from the command line, in CI, and on save in your editor.

The package is `zooper_beaver`; the executable it installs is `beaver`.

## Features

- **Rules, not opinions.** About forty documented settings for wrapping, indentation, spacing, blank lines, braces and quotes.
- **Respects your line breaks.** A line break you typed stays; a trailing comma means "one item per line".
- **Never changes what your code means.** Every result is verified to be the same program before it is written.
- **Close to `dart format` out of the box,** with the built-in `dart` preset.
- **Editor support** for VS Code, IntelliJ IDEA / Android Studio, Neovim, Helix, Emacs, Zed and Sublime Text.

## Installation

```sh
dart install zooper_beaver
```

`dart pub global activate zooper_beaver` works too. Prebuilt binaries for Linux, macOS and Windows are attached to every [GitHub release](https://github.com/zooper-lib/beaver/releases).

**Prebuilt binaries are not signed.** The binaries attached to the GitHub releases are not code-signed: no Apple Developer ID or notarization on macOS, no code-signing certificate on Windows. Downloaded with a browser, macOS blocks them ("the developer cannot be verified") and Windows SmartScreen warns before running them. Check the SHA-256 against the release's `checksums.txt`, then allow the binary: on macOS with `xattr -d com.apple.quarantine beaver` (or System Settings → Privacy & Security → Open Anyway), on Windows with More info → Run anyway (or `Unblock-File` in PowerShell). `dart install` is not affected: it compiles on your machine. See [Installing Beaver](https://github.com/zooper-lib/beaver/blob/main/docs/install.md).

## Quick Start

```sh
beaver init              # write a starter .beaver.yaml
beaver .                 # format in place
beaver --check lib       # list unformatted files, exit 1 if any
beaver --stdin --stdin-name lib/a.dart < lib/a.dart
```

A `.beaver.yaml` lists what differs from the `dart` preset:

```yaml
extends: dart
line_length: 100
wrap:
  arguments: if_long
```

## Using it from Dart

```dart
import 'package:zooper_beaver/zooper_beaver.dart';

final formatted = format(
  source,
  config: BeaverConfig.dart.merge({'line_length': 100}),
);
```

`format` throws `ParseFailure` for code that does not parse, and `VerificationFailure` if the result would not be the same program.

## Documentation

Every setting with examples, the command line, editor setup and more: [github.com/zooper-lib/beaver](https://github.com/zooper-lib/beaver#readme). Every configuration key and value, with the output it produces: [`example/`](https://github.com/zooper-lib/beaver/tree/main/example).

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/zooper-lib/beaver/blob/main/LICENSE) file for details.

---

Made with ❤️ by the Zooper team
