# Tasks

Specs: `specs/*/spec.md`. Design: `design.md`. Decisions: `DRAFT.md` §12.

## 1. Package scaffold

- [x] 1.1 Create `packages/zooper_beaver/` with `pubspec.yaml` (name `zooper_beaver`, `executables: {beaver: beaver}`, `analyzer >=14.0.0 <15.0.0`, `yaml`, `glob`, `args`, `path`, `pub_semver`, dev `test`), the `lib/src/{config,parse,comments,directives,ir,rules,emit,verify,range}` directories, `lib/beaver.dart`, `bin/beaver.dart` stub; verify `dart pub get` and `dart analyze` pass
- [x] 1.2 Add CI workflow running `dart test` twice, once with the analyzer pinned to the range lower bound and once at latest; verify both jobs run green on the stub
- [x] 1.3 Add `LICENSE` handling and `README.md` skeleton naming the package, executable and `dart install zooper_beaver@<version>`; verify `dart pub publish --dry-run` reports no errors

## 2. Doc IR and printer (`ir/`)

- [x] 2.1 Implement the sealed Doc hierarchy (`Text`, `Line`, `Group` with `shouldBreak` and id, `Indent`, `Align`, `IfBreak` with `groupId`, `Fill`, `BreakParent`, `LineSuffix`, `Concat`, `Marker`) and a builder helper API; verify unit tests construct every node kind
- [x] 2.2 Implement `propagateBreaks` (hard line / `BreakParent` marks ancestor groups broken); verify unit test: a group containing a hard line reports broken at any width
- [x] 2.3 Implement `fits` measurement and the greedy printer loop producing emit commands (text, newline, marker) with indent and mode tracking; verify unit tests cover the `layout-printer` scenarios: outer group breaks / inner fits, everything fits, direct lines break together
- [x] 2.4 Implement `Fill`, `IfBreak` (nearest group and by `groupId`), `LineSuffix` flushing before newline, nested `Indent`/`Align`; verify unit tests for paragraph fill, trailing-comma-only-when-broken, sibling-group reference, trailing comment stays on its line
- [x] 2.5 Implement `emit/` string builder: spaces vs tabs, alignment always spaces, dominant line ending detection, single trailing newline; verify unit tests for tabs-with-alignment and CRLF input

## 3. Parsing and golden harness

- [x] 3.1 Implement `parse/`: `ParsedSource` wrapping `parseString` at latest language version, structured `ParseFailure`, UTF-16 line/column ↔ offset conversion with CRLF handling and surrogate-pair check; verify unit tests for offset conversion on LF, CRLF and non-BMP input
- [x] 3.2 Implement the golden file parser for `.stmt`/`.unit` (width header, file options, `###`, `>>>`/`<<<`, versioned sections, selection-marker detection) and the option tokenizer (quotes, brackets, `key=value`, legacy `(indent N)`, `(experiment X)`, `(trailing_commas preserve)`); verify it parses every file in dart_style 3.1.x `test/tall/` without error and unit tests cover each option form
- [x] 3.3 Implement the strict runner (`test/golden/<area>/`) and the scored runner (`test/golden/dart_style/tall/`) with per-area report and skipped-case accounting; verify a sample strict file passes/fails as expected and the scored runner prints the report table on an empty engine (0% match, 0 safety failures)
- [x] 3.4 Import dart_style `test/tall/` verbatim with its LICENSE and `UPSTREAM.md` (repo, release, language version, date); verify `test/golden/dart_style/` contains `tall/`, `LICENSE`, `UPSTREAM.md` and no `short/`

## 4. Comment attachment (`comments/`)

- [x] 4.1 Implement enclosing/preceding/following node lookup for every comment token via one offset-indexed traversal; verify unit tests on comments at file start, between members, inside argument lists, inside empty bodies
- [x] 4.2 Implement own-line / end-of-line / remaining classification and leading/trailing/dangling attachment with the spec's fallbacks; verify golden cases under `test/golden/comments/` for each `comment-attachment` scenario (trailing `// about a`, empty body, `foo(/* x */ a)`, doc comment stays with class, inline block comment)
- [x] 4.3 Implement comment printing helpers used by the rules visitor (leading with hard line if own-line, trailing via `LineSuffix`, dangling by owner); verify the comment golden cases produce the expected output once group 5 lands and the comment area of the scored corpus reports a non-zero match

## 5. Core rules under the `dart` preset (`rules/`)

- [x] 5.1 Implement the `AstVisitor<Doc>` skeleton with the shared wrappable-construct helper (runs of items as nested groups joined by hard lines where the source had newlines, `force_chop`, trailing-comma `IfBreak`) and `format()` wiring parse → comments → rules → print → emit (verification added in group 6); verify `format('a=b;')` returns `a = b;\n`
- [x] 5.2 Implement declarations: compilation unit, directives (`import`/`export`/`part`), classes, mixins, enums, extensions, extension types, functions, constructors, fields, getters/setters, type parameters, metadata; verify strict golden cases per declaration kind and the `declaration`/`top_level` areas of the scored corpus report a match percentage
- [x] 5.3 Implement statements: blocks, variable declarations, if/else, loops, switch (statements and expressions), try/catch/finally, return/break/continue/yield, labels, assert; verify strict golden cases per statement kind and the `statement` area is scored
- [x] 5.4 Implement expressions: binary/unary/assignment/conditional/cascade/is/as, invocations and argument lists, named arguments, function expressions, index and property access, await/throw, records, patterns; verify strict golden cases and the `expression`/`invocation`/`pattern` areas are scored
- [x] 5.5 Implement collection literals (list, set, map, spreads, control-flow elements), string literals and interpolation, and method/cascade chains; verify strict golden cases and the `collection`/`string`/`chain` corpus areas are scored
- [x] 5.6 Implement `formatStatement` (synthetic wrapper, body Doc extracted, no wrapper text in output); verify `.stmt` golden files run through it and `a=b=c;` formats to `a = b = c;`
- [x] 5.7 Run the full scored corpus and record the first overall and per-area match percentage in `UPSTREAM.md`; verify zero structural or idempotence failures once group 6 is wired (re-run after 6.4)

## 6. Structural verification (`verify/`)

- [x] 6.1 Implement normalized token comparison with the AST-derived optional-comma set (argument/parameter lists, list/set/map literals, enum constants, multi-field or named record literal/type/pattern) and string comparison by value or lexeme per `strings.quotes`; verify unit tests: optional comma added passes, `(42,)`→`(42)` fails, `(v,)` pattern fails, quote change passes, content change fails
- [x] 6.2 Implement the AST structural fingerprint via `childEntities`; verify unit test: `return;` wrapped in a block fails, identical programs pass
- [x] 6.3 Implement the positional comment check and the ignored-region byte check; verify unit tests: moved doc comment fails, dropped comment fails, altered region byte fails
- [x] 6.4 Wire verification into `format()` and `formatStatement` so unverified text is never returned (`VerificationFailure` with stage); verify an injected defect in a test build raises the failure and the golden runners assert idempotence on every case
- [x] 6.5 Measure engine time with and without verification on representative files and record the numbers in `docs/performance.md`; verify the engine budget from `DRAFT.md` §3 is reported against measured values

## 7. Configuration (`config/`)

- [x] 7.1 Implement the schema table (dotted key, type, allowed values) and `BeaverConfig` model; verify a unit test asserts every key in `DRAFT.md` §5 is present
- [x] 7.2 Add the `dart` preset as a package asset validated against the schema; verify a test asserts it defines every key with the D3 values (80 columns, 2 spaces, all `align.*` false, `chop_on_named_arguments` empty, default exclusions)
- [x] 7.3 Implement YAML loading with unknown-key and bad-value rejection producing path-qualified diagnostics (exit 78 mapping); verify unit tests for `line_lenght` and `wrap.arguments: sometimes`
- [x] 7.4 Implement discovery (nearest `.beaver.yaml`, `--config` override), `extends` chain resolution (preset name or relative path, implicit `dart`, cycle detection, map merge, `exclude` concatenation); verify unit tests with a temp directory tree for shadowing, team-file extension, cycle, unknown preset, exclusion concatenation
- [x] 7.5 Implement effective-root computation and `package:glob` matching (case-sensitive) plus protected directories; verify unit tests: inherited pattern anchors at the project, working directory does not matter, `.dart_tool` never matched as formattable
- [x] 7.6 Implement `beaver config --print [--for <file>]` with per-key provenance and `beaver init` (refuses to overwrite); verify CLI tests for provenance output and the overwrite refusal (exit 64)
- [x] 7.7 Thread `BeaverConfig` through `format()` and the golden harness (preset → file options → case options, per-case isolation, option validation against the schema); verify harness tests for case-level override, list value, invalid option failing the suite, file-option isolation

## 8. Configurable wrapping, breaks, commas, alignment

- [x] 8.1 Implement the four wrap policies for `arguments`, `parameters`, `collection_literals`, `binary_expressions`, `conditional_expressions`, `chained_calls` (with `min_calls`, `keep_single_line_if_fits`) and `before_operator`; verify strict golden files under `test/golden/wrap/` with one case per policy per construct, including the `formatting-rules` scenarios
- [x] 8.2 Implement `keep_existing_line_breaks` per D7 (preserved breaks, no sibling expansion, `never` removes); verify golden cases: `foo(a,\n b, c);` fits → `b, c` together; overflow → all chopped; `never` → one line; statements unaffected by the flag
- [x] 8.3 Implement `trailing_commas` (`preserve`, `remove`, `add_when_wrapped`), `chop_on_trailing_comma`, and required-comma protection; verify golden cases: broken list gets comma, flat list loses it, `remove` on broken list, `(42,)` under `remove`, Flutter idiom chop, chop with `remove`, disabled flag
- [x] 8.4 Implement `chop_on_named_arguments` (direct named arguments only, `force_chop`, `never` precedence); verify golden cases: `Padding(... child:)` chopped with `Text` flat, `Column(children: [...])` list stays flat, `process(child:)` false positive, empty list no effect
- [x] 8.5 Implement `indent.continuation`, `indent.align.{arguments,parameters,chained_calls}` with the group-id `IfBreak` mechanism, `indent.switch_cases`, `indent.style: tabs`; verify golden cases: flat anchor aligns, broken anchor falls back, overflow keeps alignment, aligned arguments, switch cases both ways, tabs output
- [x] 8.6 Implement `simple_blocks_on_one_line` and `simple_lambdas_on_one_line`; verify golden cases for `if (x) { return; }` and a one-statement lambda, both values
- [x] 8.7 Document every rule in this group in `docs/rules/wrap.md` and `docs/rules/indent.md` with a before/after example taken from the golden files; verify each example appears verbatim in a golden case

## 9. Spaces, blank lines, braces, strings

- [x] 9.1 Implement all `spaces.*` keys; verify strict golden files under `test/golden/spaces/` with both values for each key, including `inside_braces`, `before_control_parentheses`, `in_empty_braces`
- [x] 9.2 Implement `blank_lines.*` (`max_consecutive`, `after_imports`, `between_members`, `before_first_member`, `around_class_declarations`) and blank-line preservation around own-line comments; verify golden cases for collapsing, between members, before first member, comment separated by a blank line
- [x] 9.3 Implement `braces.else_on_new_line` (also `catch`/`finally`) with no brace insertion or removal; verify golden cases for both values and that `if (x) return;` stays braceless, and the verification suite rejects a block/statement swap
- [x] 9.4 Implement `strings.quotes` (`preserve`/`single`/`double`, value-preserving only, raw strings untouched, skip when escapes would be needed); verify golden cases: `"hello"`→`'hello'`, `"it's"` unchanged, raw string unchanged, interpolated string converted, and verification passes under value comparison
- [x] 9.5 Document this group's rules in `docs/rules/spaces.md`, `docs/rules/blank_lines.md`, `docs/rules/braces.md`, `docs/rules/strings.md` with golden-derived examples; verify each example matches a golden case

## 10. Ignore directives (`directives/`)

- [x] 10.1 Implement directive recognition (exact match of the five forms), region table, overlap/stray-end detection (exit 65 with line numbers), unterminated start to EOF; verify unit tests for alias, near-miss comment, nested start, stray end, unterminated start
- [x] 10.2 Implement `Marker` emission by the rules visitor and raw-source splicing in `emit/`; verify golden cases: hand-aligned matrix byte-identical, region cutting through an argument list, syntax error inside a region still rejected, directive text preserved
- [x] 10.3 Implement `// beaver-ignore` desugaring to the following node's source range; verify golden cases for an ignored statement and an ignored list element
- [x] 10.4 Document directives in `docs/directives.md`; verify the examples are golden cases

## 11. CLI (`bin/beaver.dart`)

- [x] 11.1 Implement argument parsing (`--check`, `--diff`, `--stdin`, `--stdin-name`, `--range`, `--config`, `--verbose`, `--version`, `config --print`, `init`, `--help`) with usage errors as exit 64 before processing; verify CLI tests: `--help` lists every mode, unknown flag exits 64 without formatting, `--version` prints `beaver <semver> (protocol 1)`
- [x] 11.2 Implement file selection: files, directories (recursive `.dart`, no symlink following), globs, deduplication, deterministic order, exclusion applied to every selection method, silent skip with `--verbose` listing; verify CLI tests with a temp tree for overlap dedupe, symlinked directory, explicit `.g.dart` unchanged with exit 0, verbose skip report, non-Dart files ignored
- [x] 11.3 Implement format-in-place with atomic write only when content changed, `--check` (list all, exit 1), `--diff` (unified diff); verify CLI tests: already formatted file not rewritten (mtime unchanged), three unformatted files all listed, diff output shape
- [x] 11.4 Implement per-file error accumulation (parse, unreadable, missing, config error reported once) and exit-code aggregation in the order 70, 78, 64, 65, 66, 1, 0, with all diagnostics on stderr; verify CLI tests: one unparseable among many → others formatted, exit 65; broken shared config reported once; missing file → 66; mixed check → 65; stdout clean in check mode
- [x] 11.5 Implement `--stdin` protocol: whole document in/out, `--stdin-name` for config/exclusion only (never read from disk), excluded name echoed with exit 0, errors leave stdout empty; verify CLI tests for successful format, unsaved-buffer semantics, excluded echo, syntax error → empty stdout exit 65
- [x] 11.6 Write `docs/cli.md` covering modes, exit codes and the git-hook recipe with the staging caveat; verify the documented hook command runs against a temp repository

## 12. Range formatting (`range/`)

- [x] 12.1 Implement `--range` parsing (1-based, UTF-16 columns, inclusive/exclusive, bounds, surrogate check, reversed → 64, requires `--stdin`); verify unit tests for valid range, reversed range, CRLF document positions
- [x] 12.2 Implement the expansion ladder (statement → class member → top-level declaration), empty-selection handling, whitespace position → unchanged; verify unit tests for selection inside a method body, inside an argument, spanning two members, cursor inside statement, cursor on blank line
- [x] 12.3 Implement `formatRange()`: whole-document parse and verification, unit-only formatting with AST-depth indentation, byte-exact replacement of the expanded range; verify golden-style tests that an unformatted neighbour is untouched, a syntax error outside the range still exits 65, and an ignored region inside the range is unchanged
- [x] 12.4 Document range formatting and the protocol version policy in `docs/stdin-protocol.md`; verify the documented coordinate examples match the tests

## 13. Release pipeline

- [ ] 13.1 Add a release workflow building `dart compile exe` binaries for Windows x64, Linux x64, Linux arm64, macOS x64, macOS arm64 from one tag (cross-compile where it works, native runners otherwise), producing `checksums.txt` and the platform→file→SHA-256 manifest JSON; verify a dry run on a test tag uploads five binaries, the checksum file and the manifest
- [ ] 13.2 Add signing/notarization steps for macOS and Windows binaries where required; verify the macOS binary runs on a clean machine without a Gatekeeper block
- [ ] 13.3 Add `pub publish` to the release workflow and verify `dart install zooper_beaver@<version>` from a test publish yields a working `beaver` on PATH
- [ ] 13.4 Write `docs/install.md` (dart install, pub global activate, binary download, checksums) and `docs/versioning.md` (formatter vs protocol vs plugin versions, no `version:` key); verify the install commands run as written

## 14. VS Code extension (`editors/vscode/`)

- [x] 14.1 Scaffold the TypeScript extension with `extensionKind: ["workspace"]`, document and range formatting providers for `dart`, buffer-authoritative `--stdin --stdin-name` invocation, 0-based → 1-based range conversion, prefix/suffix trim to a single edit, cancellation killing the process, stale-result discard; verify the extension's integration tests: Format Document, Format Selection, unsaved edits, change near the end yields a local edit, typing during format discards the result
- [x] 14.2 Implement binary resolution (setting → PATH → bundled) with `--version` probe and protocol check, explicit/PATH incompatibility as an error with no fallback, excluded-file and non-zero-exit handling with no buffer change; verify tests: PATH preferred over bundled, incompatible explicit path errors, exit 65 leaves buffer unchanged, `.g.dart` save shows no error
- [ ] 14.3 Add the "Beaver: Show Formatter Information" command; verify it displays version, protocol, source, path, platform and resolved config
- [ ] 14.4 Add platform-specific VSIX packaging (one bundled binary each) to the release workflow; verify five VSIX files are produced and the Linux VSIX installs and formats inside a dev container while the UI runs on another OS
- [x] 14.5 Write `docs/editors/vscode.md` (install, default formatter for `[dart]`, format on save, coexistence with the Dart extension); verify the documented settings produce format-on-save in a test workspace

## 15. IntelliJ / Android Studio plugin (`editors/intellij/`)

- [x] 15.1 Scaffold the Kotlin plugin with `AsyncDocumentFormattingService` registered at `com.intellij.formattingService`, buffer-authoritative stdin invocation, `--range` for selections, off-UI-thread execution with cancellation, prefix/suffix local edit, no document change on failure; verify plugin tests: Reformat Code, Reformat Selection, folder reformat, Reformat on Save, unsaved document, syntax error leaves document unchanged, excluded file no error
- [x] 15.2 Implement binary resolution (setting → PATH → cache → download) with `--version` probe and protocol check and no silent fallback; verify tests: PATH binary used without download, incompatible explicit path errors
- [x] 15.3 Implement manifest-verified download (HTTPS, SHA-256 against the manifest embedded at build time, discard on mismatch, unsupported-platform error) and the version/platform-keyed cache with atomic install, lock file, offline reuse; verify tests: checksum mismatch rejected, interrupted download leaves no partial executable, offline reuse works, concurrent attempts leave one valid binary
- [x] 15.4 Declare `bundledFormatterVersion` and `protocolVersion` in plugin metadata, add the "Show Formatter Information" action; verify the action displays all fields and a plugin-only version bump leaves the declared formatter version unchanged
- [ ] 15.5 Add plugin packaging (manifest copied into resources from the release artifacts) to the release workflow and record the supported IDE version range; verify the packaged plugin installs in the oldest and newest declared IDE versions and the group 15.1 workflows pass on both
- [x] 15.6 Write `docs/editors/intellij.md`; verify the documented setup produces Reformat on Save in a test project

## 16. Other editors

- [ ] 16.1 Write `docs/editors/{helix,zed,neovim,emacs,sublime}.md` with a valid, copy-paste external-formatter configuration each and an explicit statement of whether selection formatting is available in that editor; verify each configuration file parses (TOML/JSON/Lua) and formats a file in the respective editor
- [ ] 16.2 Add a CI job that runs each documented configuration headlessly where the editor supports it (Helix, Neovim) and verifies the formatted output equals the CLI's

## 17. Integration checks

- [x] 17.1 Run the full scored corpus and the strict suites at both analyzer bounds; verify zero structural or idempotence failures, and record the match percentage overall and per area in `UPSTREAM.md`
- [x] 17.2 Run the §4.4 corpus test over a set of real packages (top pub packages and a Flutter checkout) under the `dart` preset and three non-default configurations; verify all three invariants hold on every file and failures, if any, are reduced to golden cases
- [ ] 17.3 Measure end-to-end format-on-save latency (process start, config, parse, format, verify) in VS Code and IntelliJ on a representative file and record it in `docs/performance.md`; verify the number is compared against the 150 ms threshold from `DRAFT.md` §3 and the result is stated

## Workflow follow-up

- Archive the change once implementation is complete and the specs are synced to `openspec/specs/`.
- Re-baseline the match percentage whenever the dart_style corpus is refreshed.
