# Installing Beaver

## With the Dart SDK

```sh
dart install zooper_beaver@<version>
```

This installs the `beaver` executable on your PATH. `dart pub global activate zooper_beaver` works too.

To run an unreleased checkout:

```sh
dart pub global activate --source path packages/zooper_beaver
```

## Prebuilt binary

Each release on GitHub (`https://github.com/zooper-lib/beaver/releases`) carries one self-contained binary per platform; no Dart SDK is needed:

| Platform | File |
|---|---|
| Linux x64 | `beaver-linux-x64` |
| Linux arm64 | `beaver-linux-arm64` |
| macOS Intel | `beaver-macos-x64` |
| macOS Apple silicon | `beaver-macos-arm64` |
| Windows x64 | `beaver-windows-x64.exe` |

Download the binary and `checksums.txt` from the same release, check the SHA-256, then put the binary on your PATH as `beaver`:

```sh
version=0.1.0
file=beaver-macos-arm64
base=https://github.com/zooper-lib/beaver/releases/download/v$version
curl -fLO "$base/$file" -O "$base/checksums.txt"
grep " $file\$" checksums.txt | shasum -a 256 -c -
chmod +x "$file" && mv "$file" /usr/local/bin/beaver
beaver --version
```

On Linux use `sha256sum -c -` instead of `shasum -a 256 -c -`. On Windows, compare `(Get-FileHash beaver-windows-x64.exe).Hash` with the line in `checksums.txt`.

The release also carries `beaver-manifest.json`, the platform → file → SHA-256 table the IntelliJ plugin uses to verify its downloads.

### The binaries are not signed

The release binaries are not code-signed: no Apple Developer ID or notarization on macOS, no code-signing certificate on Windows. The checksums above are what proves a binary is the released one.

- **macOS:** a binary downloaded with a browser is quarantined, and Gatekeeper refuses to run it ("cannot be opened because the developer cannot be verified"). After checking its SHA-256, remove the quarantine with `xattr -d com.apple.quarantine beaver`, or open it once and choose System Settings → Privacy & Security → Open Anyway. A download with `curl`, as above, is not quarantined.
- **Windows:** SmartScreen shows "Windows protected your PC" for a downloaded `.exe`; choose More info → Run anyway, or run `Unblock-File beaver-windows-x64.exe` in PowerShell. Some managed machines block unsigned executables entirely; use `dart install` there.

`dart install zooper_beaver` compiles Beaver on your machine and is not affected. The IntelliJ plugin downloads the binary itself, without quarantine, and checks it against `beaver-manifest.json`.

## Editors

See [VS Code](editors/vscode.md), [IntelliJ / Android Studio](editors/intellij.md), and the external-formatter setups for [Helix](editors/helix.md), [Zed](editors/zed.md), [Neovim](editors/neovim.md), [Emacs](editors/emacs.md) and [Sublime Text](editors/sublime.md).
