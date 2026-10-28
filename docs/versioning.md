# Versions

Beaver has three independent version numbers.

| Version | Where | Changes when |
|---|---|---|
| Formatter version | `beaver --version` (`beaver 0.1.0 …`), the pub package, the release tag `v0.1.0` | Any release of the formatter, including formatting changes. |
| Protocol version | `beaver --version` (`… (protocol 1)`) | Only a breaking change to the [stdin protocol](stdin-protocol.md): its flags, coordinate rules, output or exit-code rules. Never for formatting changes. |
| Plugin version | The VS Code extension and the IntelliJ plugin | Any release of that plugin. Plugin releases do not have to follow formatter releases. |

Each plugin declares the formatter version it bundles or downloads and the protocol version it speaks. A plugin works with any formatter that reports the same protocol version, so it keeps working across formatter releases until the protocol changes, and a plugin-only fix does not change its declared formatter version.

There is no `version:` key in `.beaver.yaml`. Formatting is reproducible by pinning the formatter itself: `dart install zooper_beaver@<version>` on every machine and in CI, or a fixed binary path in the editor settings. The editors' "Show Formatter Information" command shows which binary and version a project actually uses, so a mismatch between an editor and CI is visible.
