# Proposal

## Why

`dart format` is deliberately unconfigurable and `dart_format` (eggnstone) exposes ten knobs and never rewraps against a line width, so Dart and Flutter teams who want ReSharper-style control over wrapping, chains, alignment, spacing and blank lines have no formatter at all. Beaver is that formatter: a line-width-aware pretty-printer whose every decision is a documented rule in a project-local `.beaver.yaml`. The design is settled (`DRAFT.md` 0.2, decisions D1–D20) and nothing is implemented; this change is the initial implementation of the whole of it.

## What Changes

- New pub package `zooper_beaver` (executable `beaver`): a pure-Dart formatting engine plus CLI in one package, parsing with `package:analyzer` (one-major version range, latest language version), with no `dart:io` in the engine.
- Layout engine: a Wadler/Prettier document tree with Prettier's full instruction set and a greedy left-to-right printer. No cost-based solver.
- Comment handling: Prettier's three-way leading/trailing/dangling attachment, computed before layout.
- Rule catalog driven by `.beaver.yaml`: indentation and alignment, per-construct wrap policies (`never | if_long | chop_if_long | chop_always`), `keep_existing_line_breaks` with ReSharper semantics (preserved breaks never auto-expand siblings), trailing commas (`preserve | remove | add_when_wrapped`) with a source trailing comma acting as a chop request, opt-in named-argument-triggered expansion (`chop_on_named_arguments`), spaces, blank lines, brace whitespace, string quotes.
- Configuration resolution: nearest `.beaver.yaml` wins, explicit `extends:` (preset name or path), one built-in preset `dart` holding dart_style's conventions, unknown keys rejected, exclusion lists concatenating along the chain and matched against an effective root.
- Ignore directives: `// beaver-ignore`, `// beaver-ignore-start`/`-end`, and `// dart format off`/`on` as aliases, implemented by emit-time raw-source splicing so ignored regions are byte-identical.
- Structural-preservation verification run in production before any output is written: normalized token comparison, AST fingerprint, positional comment check, ignored-region byte check, idempotence. Failure leaves the file untouched and exits 70.
- CLI: files, directories and globs with recursive discovery and exclusion; `--check`, `--diff`, `--stdin --stdin-name --range`, `--config`, `config --print`, `init`, `--version` (reporting formatter and protocol version); sysexits-style codes 0/1/64/65/66/70/78 with documented aggregation across files.
- Range formatting over stdin: fixed expansion ladder (statement → member → top-level declaration), whole document in and out, bytes outside the range preserved, 1-based UTF-16 coordinates.
- Golden test harness in dart_style's `.stmt`/`.unit` grammar extended with `key=value` config options; a verbatim copy of dart_style's tall-style corpus scored for a published match percentage, never pass/fail.
- Editor integration: a VS Code extension (platform-specific VSIX bundling one AOT binary, workspace extension) and an IntelliJ/Android Studio plugin (`AsyncDocumentFormattingService`, platform-independent, verified on-demand binary download). No LSP. Other editors documented via their external-formatter settings.
- Distribution: AOT binaries for five targets from one tag, `dart install zooper_beaver@<version>`, plugin versions independent of the formatter version, binary resolution setting → PATH → bundled/cached with `--version` validation and no silent fallback.

Explicitly out of scope (v1 non-goals): import sorting, lint fixes, brace insertion/removal or any other structural AST change, formatting unparseable files, a daemon, presets other than `dart`, an LSP server, a `version:` key in `.beaver.yaml`.

No breaking changes: this is a greenfield implementation.

## Capabilities

### New Capabilities

- `config-resolution`: discovery of `.beaver.yaml`, the `extends:` chain and the `dart` preset, schema validation with unknown-key rejection, effective-root computation, exclusion-pattern semantics (D3, D11, D12, D16).
- `layout-printer`: the Doc instruction set (`Text`, `Line`, `Group`, `Indent`, `Align`, `IfBreak` with group ids, `Fill`, `BreakParent`, `LineSuffix`, `Concat`) and the greedy printer that fits groups to `line_length` (D4, D10 mechanism).
- `formatting-rules`: AST-to-Doc rules for every `.beaver.yaml` key: indentation and alignment precedence, wrap policies, `keep_existing_line_breaks`, trailing commas and `chop_on_trailing_comma`, `chop_on_named_arguments`, spaces, blank lines, brace whitespace, string quotes (D7, D9, D10, D13, D14).
- `comment-attachment`: three-way classification and placement of comments relative to AST nodes before layout (D6).
- `ignore-directives`: marker comments, `// beaver-ignore` as node-range sugar, emit-time raw-source splicing, overlap and termination rules (D8).
- `structural-verification`: the production and test-time check that formatted output is the same program as the input, including the optional-comma allowlist, string-value comparison, AST fingerprint, positional comment check and idempotence (D13, D17).
- `cli`: command surface, path and glob selection, exclusion application, per-file error accumulation, exit-code aggregation, `config --print`, `init`, `--version` (D15 exit codes, D16, D20 version/protocol reporting).
- `stdin-protocol`: whole-document stdin/stdout contract, `--stdin-name` semantics (config, exclusion echo, never a file read), `--range` coordinates and expansion ladder, error behaviour (D15, D19).
- `golden-test-harness`: the `.stmt`/`.unit` grammar with extended options, legacy option semantics, versioned-output selection, the `formatStatement` test entry point, strict Beaver suites and the scored dart_style corpus (D3, D18).
- `vscode-extension`: formatting and range providers, binary resolution and validation, platform-specific packaging as a workspace extension, diagnostics command (D19, D20).
- `intellij-plugin`: `AsyncDocumentFormattingService` integration, buffer-authoritative formatting, manifest-verified binary download and cache, diagnostics command, required workflows including folder reformat and reformat-on-save (D19, D20).
- `release-distribution`: release targets, `dart install` path, `--version` protocol reporting, plugin-to-formatter version declaration, binary manifest and checksums (D1, D5, D20).

### Modified Capabilities

None. `openspec/specs/` is empty; every capability above is new.

## Impact

- New code: `packages/zooper_beaver/` (engine `lib/`, CLI `bin/`), `editors/vscode/` (TypeScript), `editors/intellij/` (Kotlin), `test/golden/` including the imported dart_style corpus with its BSD license.
- Dependencies: `analyzer` (`>=14.0.0 <15.0.0`), `yaml`, `glob`, `args`, `path`, `pub_semver`; CI resolves the suite twice, at the analyzer lower bound and at latest.
- Public surfaces created: the `beaver` CLI and its exit codes, the stdin/range protocol (the editor contract, protocol-versioned), the `.beaver.yaml` schema, the pub package `zooper_beaver`, the VS Code extension and IntelliJ plugin, GitHub release artifacts for five targets.
- External references: dart_style 3.1.x as reference implementation and test corpus (no code vendored); Prettier's printer and comment-attachment algorithms as the documented patterns followed.
- Documentation: per-editor configuration pages for Helix, Zed, Neovim, Emacs, Sublime; the rule catalog with before/after examples.
