# 🦫 Beaver

> *The compiler doesn't care how your code looks. Unfortunately, we do.*
>
> *Because "it compiles" is a disturbingly low standard.*

**Beaver is a configurable, line-width-aware formatter for Dart and Flutter.** You describe how your code should look in a `.beaver.yaml` next to your `pubspec.yaml`, and Beaver formats every file accordingly: from the command line, in CI, and on save in your editor.

`dart format` is deliberately unconfigurable. That is a fine choice until your team wants 100 columns with aligned parameters, or keeps the line breaks it typed on purpose. Beaver starts from `dart format`'s conventions and lets you change the ones you disagree with, one documented rule at a time.

## What it does

- **Rules, not opinions.** About forty settings for wrapping, indentation, spacing, blank lines, braces and quotes. Each one has its own page with before-and-after examples, and [`example/`](example/) shows every value of every setting on real code.
- **Respects your line breaks.** A line break you typed between arguments, list items or operands stays, unless you configure otherwise. A trailing comma still means "one item per line", as Flutter developers expect.
- **Never changes what your code means.** After formatting, Beaver checks that the result is the same program: same tokens, same syntax tree, same comments in the same places. If the check fails, nothing is written. This cannot be switched off.
- **Leaves alone what you mark.** `// beaver-ignore` keeps the next statement, member or expression exactly as written; `// beaver-ignore-start` … `// beaver-ignore-end` (or `// dart format off` … `on`) keeps a whole region.
- **Fast enough for format on save.** About 16 ms for a 500-line file, from process start to verified output.
- **Close to `dart format` out of the box.** With no configuration, the built-in `dart` preset follows `dart format`'s style. It is close, not identical: Beaver keeps your deliberate line breaks, for example.

## A taste

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

## Getting started

```sh
dart install zooper_beaver
```

That puts `beaver` on your PATH (`dart pub global activate zooper_beaver` works too). Without a Dart SDK, download a prebuilt binary for Linux, macOS or Windows from the [GitHub releases](https://github.com/zooper-lib/beaver/releases); see [Installing Beaver](docs/install.md). **The prebuilt binaries are not code-signed**, so macOS and Windows warn before running one downloaded with a browser; the install guide explains how to allow it.

In your project:

```sh
beaver init              # write a starter .beaver.yaml
beaver .                 # format every Dart file in place
beaver --check lib       # list files that would change; exit 1 if any (for CI)
beaver --diff lib        # show what would change, change nothing
beaver config --print    # show the settings in effect, and where each one comes from
```

Generated files (`*.g.dart`, `*.freezed.dart`, `build/`, …) are skipped by default.

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

Every setting, with examples: [wrapping](docs/rules/wrap.md) · [indentation](docs/rules/indent.md) · [spaces](docs/rules/spaces.md) · [blank lines](docs/rules/blank_lines.md) · [braces](docs/rules/braces.md) · [strings](docs/rules/strings.md). Or browse [`example/`](example/): one folder per setting, one subfolder per value, each with its `.beaver.yaml` and the output it produces.

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

## Documentation

- [Command line](docs/cli.md): modes, file selection, exit codes, a git pre-commit hook
- [Ignoring code](docs/directives.md): `// beaver-ignore` and ignored regions
- [Installing](docs/install.md) and [versioning](docs/versioning.md)
- [Performance](docs/performance.md) and the [safety corpus](docs/safety-corpus.md): how Beaver is tested on real code

## Contributing

```sh
cd packages/zooper_beaver
dart test                              # unit, golden and safety tests
dart run bin/beaver.dart --check .     # this repository is formatted by Beaver itself
```

Formatting behaviour is pinned by golden tests in `packages/zooper_beaver/test/golden/`; a change in output comes with a golden case. Please format with Beaver, not `dart format`: CI checks it.

## License

MIT, see [LICENSE](LICENSE).
