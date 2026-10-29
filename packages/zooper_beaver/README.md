# zooper_beaver

A configurable, line-width-aware formatter for Dart. Every formatting decision is a documented rule in a project-local `.beaver.yaml`.

The package is `zooper_beaver`; the executable it installs is `beaver`.

## Install

```sh
dart install zooper_beaver@<version>
```

`dart pub global activate zooper_beaver` also works.

**Prebuilt binaries are not signed.** The binaries attached to the GitHub releases are not code-signed: no Apple Developer ID or notarization on macOS, no code-signing certificate on Windows. Downloaded with a browser, macOS blocks them ("the developer cannot be verified") and Windows SmartScreen warns before running them. Check the SHA-256 against the release's `checksums.txt`, then allow the binary: on macOS with `xattr -d com.apple.quarantine beaver` (or System Settings → Privacy & Security → Open Anyway), on Windows with More info → Run anyway (or `Unblock-File` in PowerShell). `dart install` is not affected: it compiles on your machine. See [Installing Beaver](https://github.com/zooper-lib/beaver/blob/main/docs/install.md).

## Use

```sh
beaver .                 # format in place
beaver --check lib       # list unformatted files, exit 1 if any
beaver --stdin --stdin-name lib/a.dart < lib/a.dart
```

Every configuration key and value, with the output it produces: [`example/`](https://github.com/zooper-lib/beaver/tree/main/example).

## License

MIT, see `LICENSE`.
