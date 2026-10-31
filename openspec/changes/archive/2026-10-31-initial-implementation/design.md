# Design

## Context

Greenfield: the repository holds only `LICENSE` and `DRAFT.md`. The design was settled in review as twenty recorded decisions (`DRAFT.md` §12, D1–D20); this document maps them onto a code structure and a processing pipeline, and records the technical choices the specs leave open. See `proposal.md` for motivation and `specs/*/spec.md` for behaviour.

Constraints that shape the approach:

- `package:analyzer` is the only maintained Dart parser. It provides a token stream with comments attached to tokens and precise offsets, but no structural AST equality and no notion of "optional" trailing comma. Latest is 14.6.0; the local SDK is Dart 3.13.3.
- No code is taken from `dart_style` (D2). Its architecture (cost-based `Piece` solver) is incompatible with per-rule configurability; only its test corpus and its solutions to edge cases are used as reference.
- The engine must be a pure library: no `dart:io`, no editor assumptions. The CLI and the editor adapters are shells around it, and the stdin protocol is the only cross-editor contract (D19).
- Editor latency budget: AOT binary per invocation, no daemon unless format-on-save exceeds 150 ms measured end to end (§3).

## Goals / Non-Goals

**Goals:**

- One pipeline, `source → parse → attach comments → build Doc → print → splice ignored regions → verify → emit`, in which every `.beaver.yaml` rule changes exactly one step (Doc construction) and nothing downstream knows about syntax.
- Every decision in D1–D20 has an owner module and no module needs knowledge outside its layer.
- Verification (D17) is structurally impossible to bypass: the only public formatting entry point runs it.

**Non-Goals:**

- Matching `dart_style` output byte for byte (D3). The reference corpus is scored, not asserted.
- Type resolution of any kind; everything is syntactic (D5, D14).
- A persistent process, an LSP, or any editor logic beyond spawning the CLI (D19).
- Performance work before measurement. The design leaves room (reuse of the parse, single-pass printer) but no caches or parallelism in v1.

## Decisions

### Package layout (one pub package, D1)

```
packages/zooper_beaver/
  lib/beaver.dart                 # public API: format(), formatRange(), BeaverConfig, FormatResult, exceptions
  lib/src/config/                 # schema, defaults (dart preset as a YAML asset), loader, extends-chain resolver, effective root
  lib/src/parse/                  # analyzer wrapper: parse at latest language version, structured diagnostics, line/column ↔ offset (UTF-16, CRLF)
  lib/src/comments/               # D6 attachment: enclosing/preceding/following search, classification, attachment table
  lib/src/directives/             # D8: marker recognition, region table, `// beaver-ignore` → node range desugaring, overlap checks
  lib/src/ir/                     # D4: Doc node types, printer (fits + propagate breaks + emit), width measurement
  lib/src/rules/                  # AST visitor → Doc; one file per syntax area (declarations, statements, expressions, collections, chains, strings, comments-placement)
  lib/src/emit/                   # string builder: indentation style, line endings, raw-source splicing at marker offsets
  lib/src/verify/                 # D17: token normalization, comma allowlist, fingerprint, comment position check, region byte check
  lib/src/range/                  # D15: ladder expansion, region replacement with byte preservation
  lib/src/format.dart             # orchestrates the pipeline; the only place verify is invoked
  bin/beaver.dart                 # CLI: args, file selection (D16), modes, exit-code aggregation, stdin protocol
  test/golden/                    # D18 harness + Beaver suites + dart_style/tall verbatim corpus
editors/vscode/, editors/intellij/
```

Why one package: the CLI is ~hundreds of lines and has no independent consumers; `dart install zooper_beaver` needs engine and executable together (D20). Alternative considered: `beaver_core` + `beaver_cli` split, rejected in D19 as premature.

### Pipeline and data flow

1. **Parse** (`parse/`): `parseString(featureSet: latestLanguageVersion)`. Diagnostics become a `ParseFailure` (exit 65). The `CompilationUnit`, its token stream and the source string are passed down together as one immutable `ParsedSource`.
2. **Directives** (`directives/`): scan comment tokens for the five directive forms; build the ordered region table; validate nesting (exit 65 on overlap); desugar single-node ignores to node ranges using the D6 "following node" lookup. Output: a list of `(startOffset, endOffset)` ignored byte ranges.
3. **Comments** (`comments/`): for every comment token compute enclosing, preceding and following node in one post-order traversal keyed by offset, classify own-line / end-of-line / remaining, and attach as leading / trailing / dangling. Output: a map `AstNode → {leading, trailing, dangling}`. Directive comments are attached like any other so they print in place.
4. **Rules** (`rules/`): a single `AstVisitor<Doc>` dispatching to per-area builders. Each builder reads `BeaverConfig` and the comment map and returns a Doc. Comments are printed by a shared helper the visitor calls around every node it visits. Directive markers are printed as `Text` carrying their source offset (a `Marker` Doc leaf, the one Doc addition beyond Prettier's set, invisible to layout).
5. **Print** (`ir/`): Prettier's algorithm: a work stack of `(indent, mode, doc)` triples; `fits()` measures the rest of the line in flat mode with a width budget; `propagateBreaks()` runs first so any hard line or `BreakParent` marks its ancestor groups broken; `IfBreak` with a `groupId` consults the recorded mode of that group. Output: a list of emitted `Text` / newline / `Marker` commands, not a string.
6. **Emit** (`emit/`): turns commands into the final string, expanding indentation per `indent.style`, choosing the line ending, and, on reaching a start `Marker`, copying raw source from the marker's offset to the matching end marker's offset instead of the formatted commands in between.
7. **Verify** (`verify/`): see below. On failure `format()` throws `VerificationFailure` (exit 70); callers never see unverified text.

`formatRange()` runs steps 1–3 on the whole document, computes the expanded ladder range, runs 4–7 for the enclosing unit(s) only, then replaces exactly the bytes of that range in the original string. Indentation for the unit is computed from AST depth × `indent.size`, so a statement is self-contained (D15).

### Doc IR and printer (D4, D10)

Doc is a sealed class hierarchy: `Text`, `Line(kind)`, `Group(doc, shouldBreak, id)`, `Indent`, `Align(n|string|toColumn)`, `IfBreak(broken, flat, groupId)`, `Fill(parts)`, `BreakParent`, `LineSuffix`, `Concat`, plus `Marker(offset, isStart)`. Group ids are allocated by the rule builder from a per-format counter. Alignment (D10) is `IfBreak(Indent(continuation), Align.toColumn(items), groupId: anchorGroup)`; `toColumn` aligns to the output column where the contents start, read by the printer at print time, so nested and indented anchors align correctly. Alternative considered: a cost-based solver (dart_style). Rejected in D4 because rules would become interacting costs.

### Keep-existing-line-breaks and chop (D7, D9, D14)

A wrappable construct is emitted as `Group([open, Indent([Line, item, sep, Line, item, ...]), Line, close])` where each separator `Line` is soft unless the source had a newline there, in which case it is hard. With plain group semantics a hard line would break the outer group and therefore every soft separator too, which is Prettier's "expand all" behaviour that D7 rejects. So the items are emitted as runs: consecutive items with no source newline between them form one nested `Group` with soft separators, and runs are joined by hard lines. The outer group breaks (opening and closing brackets on their own lines) while each run stays flat if it fits and chops only if it does not, which is exactly D7. Under `if_long` the run contents go into `Fill` instead of a `Group`. `force_chop` (a source trailing comma under `chop_on_trailing_comma`, or a `chop_on_named_arguments` match) sets `shouldBreak` on the outer group and makes all separators hard. `never` emits spaces and no `Line`s at all, discarding source newlines.

### Comment attachment (D6)

Prettier's `attach` algorithm: for each comment, binary-search the sorted child list of the enclosing node to find preceding and following siblings; classify; attach with the fallbacks in the spec. Printing: leading comments print before the node with a hard line if own-line; trailing comments print as `LineSuffix` for `//` and inline for `/* */`; dangling comments are printed by the node builder that owns the empty construct. Doc comments are leading comments with "no blank line after" enforced by the declaration builder.

### Verification (D17)

Runs on `ParsedSource` of input and of output (one extra parse). Token normalization: walk both token lists skipping comments; when the next token is a `,` immediately before a closing token, consult an `optionalCommaOffsets` set built from the AST (last separator of `ArgumentList`, `FormalParameterList`, `ListLiteral`, `SetOrMapLiteral`, enum constants, multi-field or named record literal/type/pattern) and skip it on either side if present; otherwise compare. `STRING` tokens: if `strings.quotes != preserve`, compare `SimpleStringLiteral.value` / interpolation string parts by value, else lexeme. Fingerprint: pre-order list of `runtimeType` names via `childEntities`, compared as lists. Comments: for each comment token record `(lexeme, indexOfPrecedingNonCommentToken, indexOfFollowingNonCommentToken)` in the normalized stream and compare lists. Regions: direct byte comparison per ignored range. Any mismatch → `VerificationFailure(stage, detail)`. Idempotence is asserted by the test harness, not in production.

### Configuration (D3, D11, D12, D16)

Schema is a static table of `(dottedKey, type, allowedValues, default)`; the `dart` preset is a YAML file in the package assets validated against the same table at startup (a test asserts it defines every key). Loading: parse YAML, reject unknown keys and bad values with path-qualified diagnostics (exit 78), follow `extends` recursively with a visited set (cycle → 78), merge maps key by key, concatenate `exclude`. Effective root is computed once per discovered config file. Globs via `package:glob` with `caseSensitive: true`, matched against paths relative to the effective root.

### CLI (D15, D16)

`package:args`. File selection builds a deduplicated, sorted list; each file resolves its config (cached per directory), is checked against exclusions, read, formatted, verified, and written atomically (write temp, rename) only when content changed. Errors are collected as `(path, exitCode, message)`; the final code is the maximum by the D16 severity order. `--stdin` reads all of stdin, buffers the verified output, and writes it in one call. `--version` prints `beaver <semver> (protocol 1)`.

### Golden harness (D18)

A parser for the `.stmt`/`.unit` grammar producing `TestCase{options, input, expectedByVersion, hasSelectionMarkers}`; option parsing is a small tokenizer (quotes, brackets) producing `key=value` pairs validated through the config schema; legacy `(indent N)`, `(experiment X)`, `(trailing_commas preserve)` mapped as the spec states. `formatStatement` wraps the statement in a synthetic function for parsing and extracts the body's Doc, so no wrapper text is printed. Two runners: strict (Beaver suites) and scored (reference corpus, prints a per-area table).

### Editor adapters (D19, D20)

VS Code: TypeScript, `DocumentFormattingEditProvider` + `DocumentRangeFormattingEditProvider`, `extensionKind: ["workspace"]`, platform-specific VSIX via `vsce --target`, binary resolution and `--version` probe, prefix/suffix trim, cancellation token kills the process. IntelliJ: Kotlin, `AsyncDocumentFormattingService` registered at `com.intellij.formattingService`, same resolution order plus manifest-verified download into the IDE's cache directory with a lock file; the manifest JSON is generated by the release workflow and copied into plugin resources at build time.

### Dependencies

`analyzer >=14.0.0 <15.0.0`, `yaml`, `glob`, `args`, `path`, `pub_semver`; dev: `test`. No `dart_style`, no diff library.

## Risks / Trade-offs

- [Comment attachment edge cases are the hard part of any formatter] → Prettier's algorithm is documented and battle-tested; dart_style's `tall/` corpus (992 cases) is imported from day one and the comment-related areas are the first scored, so regressions are visible per area.
- [Greedy printer produces worse layouts than a solver on deeply nested calls] → accepted by D3/D4; the match percentage makes the gap measurable, and Prettier-style heuristics (last-argument hugging) can be added as rules later without changing the IR.
- [D7's "siblings stay together" requires nested groups per separator, which is unusual Doc shape] → it is a local pattern in one helper used by every wrappable construct; golden tests for `keep_existing_line_breaks` × every policy pin it down.
- [Verification doubles parse cost] → the output parse is the only extra work; token and fingerprint walks are linear. Measured against the 30 ms engine budget before any optimisation; verification is never disabled (D17).
- [The optional-comma allowlist is hand-maintained and a new Dart construct could make a comma significant] → the AST fingerprint catches it (a misclassified comma changes node kinds), and the corpus refresh per Dart release exercises new syntax.
- [Analyzer major bump breaks the build] → one-major range with CI at both ends; a release follows each Dart stable (D5).
- [IntelliJ `AsyncDocumentFormattingService` not invoked on folder reformat / save in some IDE versions (IDEA-318504)] → the plugin's required behaviours include both workflows; unsupported IDE versions are excluded from the compatibility range rather than worked around.
- [Cross-compiling macOS/Windows binaries from Linux may not work for every target] → `--target-os` exists in 3.13; if a combination fails, that target builds on a native runner. No design impact.
- [Editor/CI version skew] → not solved in v1 (D20); made visible through the information command and `--version`.
- [Match percentage may be low at first] → it is a published number, not a gate; areas are prioritised by their share of mismatches.

## Migration Plan

Greenfield, nothing to migrate. Publication order per release: tag → build five binaries + checksums + manifest → GitHub release → `pub publish zooper_beaver` → VSIX per platform → IntelliJ plugin with embedded manifest. Rollback is re-pinning the previous version; plugins keep working across formatter patches while the protocol version is unchanged.

## Open Questions

- The initial match-percentage figure and whether to publish a per-area floor in CI; decided once the first full corpus run exists. Does not change specs or approach.
- Whether `Fill` needs Prettier's `conditionalGroup` for chained-call layout under `if_long`; D4 defers it until a golden test demands it.
