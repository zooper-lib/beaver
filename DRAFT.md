# Beaver — a configurable Dart formatter

Draft 0.2 · 2026-10-28 · status: design settled in review (20 decisions, §12), nothing implemented

## 1. Why

`dart format` is deliberately unconfigurable. `dart_format` (eggnstone) is configurable but only along ten boolean/int knobs (brace newlines, indent width, max empty lines, remove trailing commas) and it never rewraps code against a line width. Neither gives the kind of control ReSharper/Rider users expect: per-construct wrapping policy, chain breaking, alignment, spacing around every token class, blank-line rules.

Beaver is that formatter: a full pretty-printer (line-width aware, like `dart format`) whose every decision is a documented rule in a project-local `.beaver.yaml`.

## 2. Goals (v1)

- Format any valid Dart 3.x source, including Flutter widget trees (opt-in named-argument-triggered expansion, D14). Output must re-parse to the identical AST (whitespace/comments aside) and be idempotent.
- Rules live in `.beaver.yaml`, discovered by walking up from the file (nearest wins, explicit `extends:`). One built-in preset in v1 (`dart`) with per-rule overrides; teams share templates via `extends: <path>`.
- Method chains: join or split with configurable thresholds.
- Indentation: width, tabs vs spaces, continuation indent, alignment.
- Line wrapping: max width + per-construct wrap policy (arguments, parameters, chains, binary expressions, conditionals, collections, strings).
- Whitespace: spaces around operators, commas, brackets, braces, `=>`, `:`, `?`.
- Trailing commas: `preserve` | `remove` | `add_when_wrapped`; a source trailing comma chops the construct (`wrap.chop_on_trailing_comma`).
- CLI: files, directories, globs, stdin→stdout, `--check`, meaningful exit codes.
- Exclusions: globs in config, sensible defaults for generated code.
- Directives: `// beaver-ignore`, `// beaver-ignore-start` / `-end`; also honor the official `// dart format off` / `on`.
- Editor integration: VS Code (format on save, range format), IntelliJ / Android Studio; every other editor via its external-formatter setting running `beaver --stdin` (no LSP in v1, D19).
- Engine is a pure Dart library with no editor or IO assumptions.

## 3. Non-goals (v1)

- Import sorting, lint fixes, and any structural AST transformation (including brace insertion/removal; use `curly_braces_in_flow_control_structures` + `dart fix` for that). Optional-trailing-comma and quote-style changes are the only token-level edits (D13).
- Formatting partial / unparseable files. If the file does not parse, exit 65 and leave it.
- A daemon / HTTP service like dart_format's `--web`. An AOT binary starts in ~30 ms; measure before adding one. `ponytail: AOT binary per call, add daemon if format-on-save > 150 ms`.
- Rider itself (no Dart support there). We copy its *settings model*, not target the IDE.

## 4. Architecture

```
beaver/
  packages/
    zooper_beaver/     # pub package `zooper_beaver`, executable `beaver`. Engine + CLI in one package (lib/ + bin/).
      lib/src/config/  # .beaver.yaml loading, presets, schema, validation
      lib/src/parse/   # package:analyzer wrapper, comment & directive attachment
      lib/src/ir/      # Doc IR (Wadler/Prettier style) + layout algorithm
      lib/src/rules/   # AST visitor -> Doc, one file per syntax area
      lib/src/format.dart   # String format(String source, {BeaverConfig, String? path})
      bin/beaver.dart  # CLI
  editors/
    vscode/            # TypeScript, thin: spawns `beaver --stdin`, registers provider
    intellij/          # Kotlin, thin: AsyncDocumentFormattingService (com.intellij.formattingService) spawning `beaver --stdin`
  test/
    golden/            # <area>/*.stmt|.unit in dart_style's grammar + key=value options (D18); dart_style/tall/ verbatim, scored
```

Dependency direction: `editors/* → CLI → lib`. The library never touches `dart:io` paths beyond what the CLI hands it (source string + config object).

### 4.1 Language choice

| Component | Language | Reason |
|---|---|---|
| Engine, CLI | Dart | `package:analyzer` is the only complete, maintained Dart parser. Writing our own (dart_format's apparent route) means chasing every language release. |
| VS Code extension | TypeScript | No choice. Kept to ~200 lines. |
| IntelliJ plugin | Kotlin | No choice. Kept to ~200 lines. |
| Distribution | AOT binaries for 5 targets (GitHub releases, one tag) + `dart install zooper_beaver@<version>` (installs `beaver`; `pub global activate` also works) | Editors never require a Dart SDK (D20). |

### 4.2 Parsing

`package:analyzer`'s `parseString` gives a `CompilationUnit` with full token stream, comments attached to tokens, and precise offsets. Beaver declares an analyzer version range (one major), tests at both ends, and parses with `FeatureSet.latestLanguageVersion()` (D5).

Comments: walked off the token stream before layout and attached to AST nodes as leading, trailing, or dangling using Prettier's three-way classification (D6). This is the one genuinely hard part of any formatter; dart_style's test corpus is the edge-case reference.

### 4.3 Formatting engine

Greedy left-to-right layout over a Wadler-style document tree (Wadler 1997, "A prettier printer"), with Prettier's full instruction set. Settled in D4; dart_style's cost-based solver is ruled out.

```
Doc = Text(s)
    | Line(soft | hard | literal)        # soft: space if flat, newline if broken; hard: always newline
    | Group(doc, {shouldBreak})          # try flat; if it does not fit, break every direct Line
    | Indent(doc) | Align(n | string | toColumn, doc)  # toColumn: align to the output column where doc starts (D10)
    | IfBreak(whenBroken, whenFlat, {groupId})  # trailing comma only when the group broke; groupId reads an earlier group's printed state
    | Fill([..])                         # as many items per line as fit (paragraph wrap)
    | BreakParent                        # force enclosing groups to break (keep_existing_line_breaks)
    | LineSuffix(doc)                    # trailing `// comment` kept at end of its line
    | Concat([..])
```

`rules/` turns AST → Doc using the config. `ir/layout.dart` fits groups against `line_length`. Rules never deal with columns; layout never deals with syntax. That separation is what makes "literally everything configurable" tractable: a rule like `wrap_arguments: chop_if_long` is just a choice of which Doc shape to emit. `conditionalGroup` is deliberately omitted until a golden test needs it.

Keeping user line breaks (`keep_existing_line_breaks`) emits a hard `Line` where the developer broke between items of a wrappable construct; siblings keep soft, individually fit-checked lines and are only broken when the construct exceeds the width (D7). This is the main behaviour dart_format users want and `dart format` refuses.

### 4.4 Safety invariants (tested in CI)

1. **Structural preservation.** `parse(format(x))` and `parse(x)` are the same program: no semantic token is added, removed or reordered; literal values are identical (also when quote style changes). Permitted token-level edits are exactly: adding/removing a *syntactically optional* trailing comma, and changing string quote style/escaping when the literal's value is unchanged. A required trailing comma (single-positional-field record literal `(42,)`, record type `(int,)`, record pattern `(v,)`) is never removed. Checked as specified in D17: normalized token comparison + AST structural fingerprint + positional comment check + D8 byte check; `toSource()` is not an oracle. Runs in tests, on the corpus, and in production before any output is written (failure → exit 70).
2. `format(format(x)) == format(x)`.
3. Every ignored region (D8) is byte-identical in output.
4. Corpus test: format the top N pub packages + Flutter repo under the `dart` preset and a set of non-default configs; all three invariants hold.

## 5. Configuration: `.beaver.yaml`

Discovery: start at the file's directory, walk up to filesystem root, first `.beaver.yaml` wins; no implicit cascading (D11). Inheritance is explicit via `extends:` (preset name or relative path). No file → preset `dart`. `--config path` overrides discovery.

The block below is an example user file showing the catalog, not the `dart` preset: where its values differ from dart_style (e.g. `binary_expressions`, `before_operator`, `inside_braces`, `simple_lambdas_on_one_line`, `min_calls`), the preset follows dart_style per D3. `beaver config --print` shows the preset's values. `min_calls: 0` disables the min-calls rule.

```yaml
# .beaver.yaml
extends: dart           # preset name (v1: only `dart`) or relative path to another .beaver.yaml. Implied `dart` if omitted.

line_length: 100
indent:
  size: 2
  style: spaces         # spaces | tabs
  continuation: 4       # indent for wrapped continuation lines
  switch_cases: true
  align:
    arguments: false    # align wrapped arguments with the first one
    parameters: false
    chained_calls: false # align `.foo()` under the first `.` (all align.* false in preset dart, D10)

wrap:                   # policy values: never | if_long | chop_if_long | chop_always
  arguments: chop_if_long
  parameters: chop_if_long
  collection_literals: chop_if_long
  binary_expressions: if_long
  conditional_expressions: chop_if_long
  before_operator: true
  chained_calls:
    policy: chop_if_long
    min_calls: 3        # chop whole chain when it has >= 3 calls, regardless of width
    keep_single_line_if_fits: true
  keep_existing_line_breaks: true
  chop_on_trailing_comma: true         # a trailing comma in source forces a full chop (Flutter idiom)
  simple_blocks_on_one_line: false     # `if (x) { return; }`
  simple_lambdas_on_one_line: true
  chop_on_named_arguments: []          # e.g. [child, children]: an invocation with such a direct named arg is fully chopped (D14). Empty in preset dart.

trailing_commas: add_when_wrapped       # preserve | remove | add_when_wrapped

spaces:
  around_assignment: true
  around_binary_operators: true
  around_arrow: true            # =>
  after_comma: true
  before_comma: false
  after_colon_in_named_argument: true
  inside_parentheses: false
  inside_brackets: false
  inside_braces: true           # { a: 1 } vs {a: 1}
  before_control_parentheses: true   # if (x)
  in_empty_braces: false
  after_cast: true              # as

blank_lines:
  max_consecutive: 1
  after_imports: 1
  between_members: 1
  before_first_member: 0
  around_class_declarations: 1

braces:                             # whitespace around braces only; never inserts/removes them (D13)
  else_on_new_line: false

strings:
  quotes: preserve                  # preserve | single | double

exclude:                  # concatenates along the extends chain (D16); patterns match against the effective root; package:glob syntax
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.gr.dart"
  - "**/*.mocks.dart"
  - "**/generated/**"
  - "build/**"            # package-root build dir; .dart_tool/ and .git/ are protected and never traversed
```

Rules of the config:

- Unknown keys are an error (exit 78, `EX_CONFIG`), as in dart_format. Silent ignore hides typos.
- Every key has a default; `beaver config --print` dumps the effective merged config.
- Presets are just YAML files shipped in the package; a user file reaches one through its `extends:` chain.
- The rule list above is the v1 catalog. It is deliberately ReSharper-shaped (Tabs/Indents, Wrapping, Spaces, Blank lines, Braces). New rules get added one at a time with a golden test, never speculatively.

## 6. CLI

```
beaver [options] <paths...>        format in place
beaver --check <paths...>          exit 1 if anything would change, print file list
beaver --diff <paths...>           print unified diff, change nothing
beaver --stdin [--stdin-name f.dart] [--range L1:C1-L2:C2]   read stdin, write stdout
beaver --config <file>             explicit config
beaver config --print              effective config for cwd (or --for <file>)
beaver init [--preset p]           write a .beaver.yaml
beaver --version
```

Exit codes (sysexits-style, stable, documented):

| Code | Meaning |
|---|---|
| 0 | OK / nothing to change |
| 1 | `--check`: files need formatting |
| 64 | bad CLI usage (flags, range coordinates) |
| 65 | input could not be parsed (file left untouched) |
| 66 | input file not found |
| 70 | internal error (invariant violated; please report) |
| 78 | invalid `.beaver.yaml` (unknown key, bad value, `extends:` cycle) |

`--stdin` with `--stdin-name` is what editors use: the name selects config discovery and exclusion matching without writing a temp file. Protocol (D15):

- Input is the complete document; on success stdout is always the complete resulting document. Errors go to stderr only; nothing partial is ever written to stdout.
- Excluded `--stdin-name` → input echoed unchanged, exit 0, no parse. Parse failure anywhere in the document → empty stdout, diagnostic on stderr, exit 65.
- `--range L1:C1-L2:C2`: 1-based lines and columns, columns in UTF-16 code units, start inclusive, end exclusive, positions refer to the input document, may not split a surrogate pair; reversed/invalid → exit 64. The whole document is parsed; the selection expands along a fixed ladder to the smallest covering unit: statement → class member → top-level declaration. Beaver never refuses a range. Only the expanded region may change; every other byte (whitespace, line endings, comments, non-conforming formatting) is preserved. An empty selection formats the enclosing unit at the cursor; a cursor in whitespace returns the document unchanged. Ignored regions (D8) take precedence inside the range.
- Editor adapters replace the whole text but first trim the common prefix and suffix so the applied edit is local. No shared diff library.

File selection (D16): directories are searched recursively for `.dart` files, symlinks not followed; explicit files, directories and globs share one exclusion check; files are deduplicated and processed in normalized-path order. Exclusions apply to explicitly named files too; excluded files are skipped silently (listed with `--verbose`), never parsed, never affect the exit code. A missing explicit file → 66. Per-file errors (parse, unreadable, missing, a broken `.beaver.yaml` discovered for some files) are accumulated and reported once each with their path; processing continues. Usage and startup errors stop before processing. Final exit code is the most severe seen: 70, 78, 64, 65, 66, 1, 0.

## 7. Editor integration

| Editor | Mechanism | Format on save |
|---|---|---|
| VS Code | `DocumentFormattingEditProvider` + range provider; spawns `beaver --stdin`. Platform-specific VSIX bundling one AOT binary, workspace extension (runs on the remote host). Binary resolved per D20: setting → PATH → bundled. | Native (`editor.formatOnSave`, `[dart]` default formatter). |
| IntelliJ / Android Studio | Kotlin plugin implementing `AsyncDocumentFormattingService` at `com.intellij.formattingService`; same stdin protocol; current buffer is authoritative (never save-then-read). Must work for single file, range, folder reformat, reformat-on-save, unsaved buffers, excluded files (IDEA-318504 is a known platform risk). | Native "Reformat on save" action. |
| Neovim, Helix, Zed, Emacs, Sublime | Editor's external-formatter setting running `beaver --stdin --stdin-name <path>`; documented per editor, including whether selection formatting is available there (Helix: no; Zed: whole buffer only; Neovim conform.nvim: yes via range args). | Editor-native. |
| CI | `beaver --check .` | — |
| git hook | `git diff --cached --name-only --diff-filter=ACMR -z -- '*.dart' \| xargs -0 beaver --check` | — |

Both IDE plugins are shells around the CLI. All logic, including config discovery and exclusion, stays in Dart so behaviour is identical everywhere.

Binary resolution and distribution: see D20. Both plugins offer a "Show Formatter Information" command (version, protocol, binary source, path, platform, resolved config).

Git-hook caveat: the hook sees staged *paths* but Beaver reads the *working tree*, and reformatting on disk does not restage. Use `--check` in the hook; a staged-content formatter is a separate tool, not the CLI's job.

## 8. Formatting directives

```dart
// beaver-ignore            the next AST node (whatever it is) untouched
// beaver-ignore-start      ...
// beaver-ignore-end
// dart format off / on     honored as aliases
```

Ignored regions are passed through byte-for-byte by splicing raw source at emit time (D8); the whole file is still parsed so the surrounding layout is correct. Unterminated `-start` runs to end of file. Overlapping or nested regions are an error (exit 65).

## 9. Testing strategy

- Golden tests: `test/golden/<area>/<case>.stmt|.unit`, dart_style's file grammar extended with dotted `key=value` config options (D18). Strict pass/fail; every case also runs D17 verification and the idempotence check.
- Reference corpus: `test/golden/dart_style/tall/` is a verbatim copy of dart_style's tall-style tests (with its LICENSE and an `UPSTREAM.md` pinning release, language version, import date). Formatting mismatches are *scored* (D3's match percentage, reported overall and per area); D17 or idempotence failures on it are test failures.
- Invariant tests (§4.4) also run over a corpus of real packages.
- Each editor plugin has smoke tests covering the behaviours D19 requires; each documented external-formatter config is validated against the editor.

## 10. Milestones

1. **Skeleton**: analyzer parse → IR → layout, no config, under the `dart` preset. Exit: idempotent, AST-preserving, and a tracked match percentage against dart_style's `.stmt`/`.unit` corpus (D3). Proves the engine.
2. **Config**: `.beaver.yaml` loading, `extends:`, the `dart` preset, `indent`, `line_length`, `trailing_commas`, `exclude`. CLI with `--check`, `--stdin`, exit codes.
3. **Wrapping rules**: arguments, parameters, chains, collections, binary, conditional, `keep_existing_line_breaks`, `chop_on_trailing_comma`, `chop_on_named_arguments`.
4. **Spaces / blank lines / braces** rule groups. Directives.
5. **VS Code extension** + AOT release pipeline.
6. **IntelliJ plugin**; external-formatter docs for other editors.
7. Corpus hardening, docs site with every rule and its before/after.

Milestone 1 is the risk. If the comment-attachment and layout engine take more than a few weeks, everything after it is cheap; if not, nothing else matters.

## 11. Open questions

None. Every question raised in draft 0.1 is resolved in §12.

## 12. Decisions

Settled in review on 2026-10-28. Each entry: decision, rationale, what it rules out.

### D1. Naming: brand `beaver`, pub package `zooper_beaver`

Pub package is `zooper_beaver` with `executables: { beaver: beaver }`. Everything user-facing stays `beaver`: the binary, `.beaver.yaml`, `// beaver-ignore`, the editor extension ids. Rationale: `beaver` on pub.dev is taken by an abandoned 2020 logger (0.0.4, no executables, so no PATH collision) and pub.dev never releases names; `zooper_` is the existing publisher prefix (`zooper_table`, `zooper_flutter_*`). Package name ≠ executable name is the established pub pattern (`dart_style` → `dart_format`, `very_good_cli` → `very_good`). Rules out: `beaver_format`/`beaver_fmt` variants, and any full rename of config/directive/binary names.

### D2. Engine: own implementation, dart_style as reference only

Beaver writes its own layout engine. No code is vendored or forked from `dart_style`. `dart_style` (BSD-3, ~25k LOC, 992 `.unit`/`.stmt` cases in 3.1.9) is used as a reference: its test corpus for finding edge cases, its source for how it solved them (comment attachment, cascade/chain handling, trailing-comma rules). Rationale: owner's call; a fork ties the rule set to an IR designed for one fixed style and makes every upstream merge a conflict with Beaver's parameterization. Rules out: vendoring `front_end/`, `piece/`, `back_end/`; depending on `package:dart_style` at runtime. Consequence to resolve downstream: `dart format` parity is no longer free, so what the `dart` preset promises (D3) and the layout algorithm must be decided explicitly.

### D3. Preset `dart`: dart_style's rules as defaults, no byte-parity promise

A preset is a complete rule set, a template: every rule in the catalog has a value in it, and the user's `.beaver.yaml` layers overrides on top. `dart` is one such template whose values are dart_style 3.x's conventions (2-space indent, 80 columns, trailing-comma-driven splitting, chain and cascade rules, blank-line rules). It is tested against dart_style's own golden corpus with a tracked match percentage that is published, never a byte-identical guarantee (the Biome-vs-Prettier model). Rationale: byte parity requires reproducing dart_style's cost-based solver and its cost table, which is the coupling D2 rejected; an honest "close" beats a broken "identical" for teams migrating a `dart format`ed repo. Rules out: "zero-diff" wording anywhere; any invariant that compares Beaver output to `dart format` output as pass/fail.

### D4. Layout: greedy Wadler/Prettier printer with Prettier's instruction set

Layout is "Way A": walk left to right, measure each `Group`, keep it flat if it fits, otherwise break it and recurse. The Doc instruction set is Prettier's full set (see §4.3), not the six-node subset the draft first listed, because `trailing_commas: add_when_wrapped` needs `IfBreak`, `wrap.*: if_long` needs `Fill`, and end-of-line comments need `LineSuffix`. Rationale: each config rule maps to exactly one Doc shape with one describable effect, which is the product promise; a cost-based solver (dart_style 3) makes every rule a cost that interacts with every other cost and its output cannot be documented per rule. Established, sourced pattern: Wadler 1997; Prettier, Biome, dprint. Rules out: cost-based/solver layout; any rule implemented as a post-pass over printed text.

### D5. Analyzer coupling: one-major range, CI at both ends, parse at latest language version

`pubspec.yaml` depends on `analyzer: '>=14.0.0 <15.0.0'` (bumped per major); Beaver's SDK constraint equals the lower bound's. CI runs the full suite twice: resolved at the lower bound and at the latest. Every file is parsed with `FeatureSet.latestLanguageVersion()`; Beaver never rejects syntax its analyzer knows. A Beaver patch release follows each Dart stable that adds syntax. Rationale: this is dart_style's practice (`>=13.1.0 <15.0.0`); an exact pin would block `dart pub global activate` for any team whose SDK is one minor behind the pin, while AOT users are unaffected either way. Rules out: exact analyzer pin; per-file language-version detection (a type-checker concern, not a formatter's).

### D6. Comments: Prettier's three-way attachment

Before layout, every comment gets its enclosing node (smallest containing it), preceding node (last ending before it) and following node (first starting after it), then is classified by position. Own-line → leading of following, else trailing of preceding, else dangling on enclosing. End-of-line → trailing of preceding, else leading of following, else dangling. Remaining (code on both sides) → leading of following, else trailing of preceding, else dangling. Printing: leading comments before the node (hard line if they were own-line), trailing via `LineSuffix`, dangling placed by the owning node's rule (e.g. inside empty braces). Rationale: the draft's "nearest following, else preceding" moves every `a, // about a` comment onto the next item and has no home for a comment in an empty body; Prettier's algorithm (`comments/attach.js`, also used by Biome) handles both and is documented. Rules out: nearest-following attachment; dart_style's inline handling of comments in the token-writing visitor.

### D7. `keep_existing_line_breaks`: preserve, never auto-expand siblings (ReSharper semantics)

1. `keep_existing_line_breaks: true` preserves developer-inserted breaks between items of a wrappable construct (the `wrap:` keys: arguments, parameters, collection literals, binary expressions, conditional expressions, chained calls) and after its opening bracket.
2. A preserved break does **not** cause sibling items to break. `chop_if_long` adds breaks between siblings only when the construct exceeds `line_length`; `if_long` adds them only where a line would overflow.
3. `wrap: <construct>: never` takes precedence and removes optional breaks the developer inserted.
4. Indentation, delimiter placement, trailing commas and spacing apply independently of preservation.
Newlines between statements and members are governed by `blank_lines`, not by this rule. Implementation under D4: preserved breaks are hard `Line`s; the other separators are soft `Line`s that fit-check individually (fill-style) rather than one all-or-nothing `Group`, so the output is stable on re-format. Rationale: this is ReSharper's "Keep existing line breaks" model, which §3 already adopted; Prettier's "any newline expands the whole construct" (reading 2) was rejected because it adds breaks the developer did not type. Rules out: Prettier object-literal expansion semantics; a developer break being discarded by any policy other than `never`.

### D8. Ignore directives: emit-time raw-source splicing by marker offset

Region markers (`// beaver-ignore-start`/`-end`, aliases `// dart format off`/`on`) are ordinary comments attached per D6 and printed as text, each carrying its source offset. The final string builder emits formatted output until it reaches a start marker, then copies raw source bytes from just past the marker to just before the matching end marker, then resumes. `// beaver-ignore` desugars to a region covering the source range of the node it is a leading comment of (the "following node" D6 already computes), so it works on any node, not only statements or members. Overlapping or nested regions → exit 65 (input data error) naming both markers. Unterminated start → end of file. Rationale: this is how dart_style implements `dart format off` (`EnableFormattingCommentPiece` + `setFormattingEnabled(offset)` in its code writer); it is the only mechanism that satisfies all three §8 promises at once: byte identity, full parse, arbitrary marker placement including mid-construct. Rules out: printing an ignored node as a `Text` leaf (cannot express a mid-node cut); restricting markers to statement boundaries; silently resolving overlaps.

### D9. Trailing commas: three values, and a source comma is a chop request

`trailing_commas: preserve | remove | add_when_wrapped`. `add` is dropped: "always add" on a one-line construct yields `foo(a, b,)`, which no formatter ships; Prettier's `trailingComma: all` is already `add_when_wrapped`. "Wrapped" = the last item is followed by a line break in the output. `wrap.chop_on_trailing_comma: true` (default in `dart`): a trailing comma present in the source forces the construct to chop fully, as if the developer had broken after every item. This is the one deliberate exception to D7's no-sibling-expansion rule, because the comma is an explicit request (the Flutter "type comma, save, tree expands" idiom, dart_style `preserve` mode, every `dart format` before 3.7). With `trailing_commas: remove` the comma still triggers the chop and is then deleted. Removal (and `add_when_wrapped` collapsing) applies only to syntactically optional commas; a required comma such as the single-field record `(42,)` is never touched (D13). `chop_on_trailing_comma: false` gives dart_style `automate` behaviour. Exception, so D7 and D9 hold together and output stays idempotent: in a *mixed* construct (the source has a newline in at least one list-level gap — after the opening delimiter, between items, before the closing delimiter — and at least two adjacent items share a line; newlines inside an item do not count) the comma is not a chop request and the existing breaks decide. Without it, the comma `add_when_wrapped` adds to a kept-break or `if_long` layout would chop that layout on the next run. Known limitation, accepted: adding a comma to an already partially wrapped construct does not expand it. `trailing_commas: remove` with `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` is rejected as a configuration error (exit 78): the chop removes the comma that requested it, and nothing keeps the chop on the next run. Invariant §4.4 #1 remains "modulo trailing commas". Rules out: an `add` value; a trailing comma being layout-neutral under the default preset.

### D10. Alignment wins over continuation indent when enabled and the anchor printed flat

For each `indent.align.*` that is `true`: if the anchor (the text from the start of the line up to the alignment point, e.g. `print(` or `receiver.first()`) ends up on a single line in the **resolved output layout**, wrapped items align to that column. If Beaver's own rules made the anchor wrap, the construct falls back to `indent.continuation`. Flatness is read from the printed layout, never from the source. Alignment is never suppressed for width: overflowing aligned lines are what the user configured (ReSharper semantics, §3). The `dart` preset sets every `align.*` to `false`, as dart_style never aligns. Mechanism under D4: the anchor is a `Group` with an id; the wrapped items are `IfBreak(Indent(continuation), Align.toColumn(items), groupId: anchor)`, which Prettier's printer resolves against the anchor group's actual mode. `Align.toColumn` is a mode of `Align`, not a new instruction: the printer sets the alignment to the column where the aligned contents start in the output, so enclosing indentation and nested alignment are accounted for. Rationale: alignment to a column that does not exist in the output is undefined; width-based fallback would make a rename change the chain's style unpredictably. Known cost, accepted: renaming the anchor re-indents every aligned line (diff noise), which is why alignment is off by default. Rules out: continuation-wins precedence; width-triggered automatic fallback; computing flatness from source newlines.

### D11. Config resolution: nearest file wins, explicit `extends:`, one key

Discovery walks up from the formatted file to the filesystem root and stops at the first `.beaver.yaml`; nothing above it is read unless that file says so. Inheritance is a single key, `extends`, which takes a preset name (v1: `dart`, see D12) or a relative path to another `.beaver.yaml`; the separate `preset:` key is dropped because a preset is already a complete rule file (D3). A chain must terminate in a preset so every key has a value; a chain whose last file has no `extends` implies `dart`. Cycles → exit 78. `beaver config --print --for <file>` shows the chain and which file set each value. Two path bases (D16): relative `extends:` paths resolve against the file that declares them; exclusion patterns resolve against the *effective root*, the directory of the discovered project `.beaver.yaml` (fallback: nearest `pubspec.yaml` directory, else the file's own directory; never the working directory). Rationale: this is the Dart-ecosystem pattern (`analysis_options.yaml` `include:`) and `tsconfig` `extends`; implicit cascading (`.gitignore`, EditorConfig, legacy ESLint) was rejected because the origin of a value cannot be read from the file, which is why ESLint's flat config removed it. Rules out: implicit cascading; a `preset:` key beside `extends:`.

### D12. One built-in preset in v1: `dart`

`compact` and `expanded` are dropped. Only `dart` has an authoritative definition (dart_style's behaviour and corpus, D3); any definition of the other two today would be a taste guess, and a preset name is a stable promise used across many repos, so a wrong one is a breaking change later. Teams share full templates with `extends: <path>` (D11). A new built-in preset is added only by promoting a template that real projects have used, without changing any value. Rules out: speculative preset definitions; preset names appearing anywhere in v1 docs other than `dart`.

### D13. Braces: whitespace only, no structural edits; invariant tightened

`braces.single_statement_if` is removed entirely (not kept as `preserve`-only: an option that cannot change behaviour has no value). `braces.else_on_new_line` stays; Beaver may format whitespace around braces (indentation, breaks, placement relative to `else`/`catch`/`finally`) and must never turn a statement into a block or a block into a statement. Structural fixes are out of scope for the formatter and no `beaver fix` command is added in v1; Dart already provides `curly_braces_in_flow_control_structures` + `dart fix --apply`, and any future refactoring support would be a separate subsystem with its own guarantees. §4.4 invariant 1 is strengthened (see text): no semantic token added/removed/reordered, literal values identical, permitted edits limited to optional trailing commas and quote style, required trailing commas (single-field records) never removed. Rationale: the invariant is what lets a team format a million lines without reading the diff; every carve-out weakens it, and brace insertion is a lint fix (dart_style and Prettier have none; ReSharper does it in Code Cleanup, not its formatter). Rules out: any formatter rule that changes the AST beyond the two permitted edits; a `beaver fix` command in v1.

### D14. Named-argument-triggered expansion, syntactic and opt-in

`wrap.chop_on_named_arguments: [..]` (default `[]`; no `flutter:` namespace because the mechanism is language-agnostic). An invocation matches when its **direct** argument list contains a `NamedExpression` whose name is in the list; nested invocations are judged on their own. A match forces that invocation's argument list into fully chopped layout via the same internal `force_chop` instruction D9's trailing comma uses, without synthesizing a comma; actual comma emission stays governed by `trailing_commas`. Only the matching argument list expands; nested collections and nested invocations keep their own wrapping decisions (consistent with D7). `wrap.arguments: never` still wins. Matching is deterministic and ignores callee name, capitalisation, constructor syntax and types, so `MyWrapper(child: foo)` is a documented false positive and `Text('hi')` stays flat. No type resolution, Flutter SDK or package context is required, so it works identically for files and `--stdin`. The `dart` preset ships `[]` because dart_style never does this and D3's match percentage would otherwise drop. `expand_when_nested_depth` is dropped (depth semantics undefined, no demonstrated need). Known consequence for docs: with `[child, children]`, `Column(children: [Text('A'), Text('B')])` chops `Column(` but keeps the list flat; the list expands via trailing comma or a kept break as usual. Rules out: type-resolution-based widget detection; callee-name heuristics; recursive expansion of descendants; the rule being on in `dart`.

### D15. Range formatting and the stdin protocol

Range expansion follows a fixed ladder, never refusal: the selection grows to the smallest covering unit among statement → class member → top-level declaration. Sub-statement pieces (an argument, a chain segment) are not independently formattable because their layout depends on whether the enclosing construct chops, so they expand to their statement; a statement's indentation is computed from AST depth × `indent.size`, so statements are. Whole document in, whole document out; the range only limits what may change, and everything outside it is preserved byte-for-byte (not reconstructed from the Doc tree). Excluded stdin → echo, exit 0. Parse failure → empty stdout, stderr, 65. Coordinates: 1-based, UTF-16 code-unit columns, inclusive start, exclusive end, no surrogate splitting, CRLF-aware. Empty selection → enclosing unit at cursor; whitespace → unchanged. D8 wins inside a range. Exit codes: 64 usage, 65 input, 66 missing file, 70 internal, 78 config (`EX_CONFIG`; was wrongly 64 in the draft, which also moves `extends:` cycles to 78 and overlapping ignore regions to 65). Adapters/LSP replace whole text after trimming common prefix/suffix; VS Code additionally minimizes edits itself (`computeMoreMinimalEdits`), so this is insurance for verbatim-applying LSP clients, not a requirement. Rationale: Prettier `--range-*` and IntelliJ both widen rather than refuse; refusing makes "Format Selection" fail intermittently in editors; a whole-document protocol keeps adapters thin and editor-independent. Rules out: top-level-member expansion; refusing a range; per-plugin general diffing or a shared diff library; non-zero exit for excluded files; partial output on any error.

### D16. CLI file selection and exclusion

Exclusions always apply, whether a file was named explicitly, found by directory walk, or given via `--stdin-name` (D15); this is what makes git hooks safe without a `--force-exclude` flag (Prettier's model; Black's explicit-path override was rejected). Skips are silent; `--verbose` lists each skipped file with the matching pattern. Patterns use `package:glob` syntax, case-sensitive, matched against the effective root (see D11 addendum), so a shared config reached via `extends:` works for every project that extends it. `exclude:` lists **concatenate** along the `extends` chain, the one documented exception to D11's replace semantics, so adding `**/*.pb.dart` can never silently re-enable `.g.dart` formatting; inherited exclusions cannot be removed in v1 (a `--force-excluded` for explicit paths is deferred, not ruled out). Protected, never traversed: `.dart_tool/`, `.git/`. Default-excluded in the `dart` preset, configurable: package-root `build/`, `**/*.g.dart`, `**/*.freezed.dart`, `**/*.gr.dart`, `**/*.mocks.dart`, `**/generated/**`. Discovery: recursive `.dart` search, no symlink following, dedupe, deterministic order. Recoverable per-file errors accumulate and are reported once each; fatal usage/startup errors stop before processing; exit priority 70 > 78 > 64 > 65 > 66 > 1 > 0, so `--check` reports every offending file in one run. §7's hook was unsafe (whitespace splitting; index vs working tree) and is replaced. Rules out: `exclude_add` as a second key; cwd-relative or declaring-file-relative glob matching; fail-fast on the first bad file; `build/` as an un-overridable protected directory; subcommand syntax (`beaver format`, `beaver check`) in place of §6's flags.

### D17. Structural-equivalence verification

Primary oracle: parse the formatted output and compare both token streams (comments excluded) token-for-token on type, lexeme and order. Normalizations are limited to the two permitted edits. (a) A trailing comma is skipped only if it is the last separator of an enclosing node where it is optional: `ArgumentList`, `FormalParameterList`, `ListLiteral`, `SetOrMapLiteral`, enum constants, and record literal/type/pattern with ≥2 positional fields or any named field. Single-positional-field record literals, record types and record patterns are required commas and must match. This is a hand-maintained list: the analyzer does not mark optionality. (b) String literal parts are compared by interpreted value when `strings.quotes` ≠ `preserve`; lexeme-exact under `preserve` (the `dart` preset). Interpolation expressions are ordinary tokens and need no special handling; raw strings keep their lexeme; value equality never authorizes rewrites beyond delimiter/escape changes. Cross-check: a structural fingerprint of both ASTs (ordered node types via `childEntities`) must match; in theory redundant with identical tokens, in practice the guard on the hand-written comma list and on future Dart syntax. Comment check, independent of D6: every comment keeps its exact lexeme, its order, and the indices of its preceding and following non-comment token in the normalized stream (catches a doc comment migrating to another declaration; does not reuse the attacher to verify itself). D8 regions are compared byte-for-byte. `CompilationUnit.toSource()` is rejected as an oracle: tested, it prints `(42,)` as `(42)`. Pipeline: reuse the formatting parse, format in memory, parse output, run all checks, then write; stdin output is buffered; a failure leaves the file untouched, reports file + failed stage on stderr, exit 70 as a recoverable per-file error under D16. Verification cost is inside the §3 performance budget and is never disabled to meet it. Rules out: `toSource()` comparison; a hand-written per-node structural comparer; trusting D6 attachment as the comment oracle; writing output before verification.

### D18. Golden test format: dart_style's grammar, extended options

Files are `.stmt` (each case a statement) or `.unit` (each case a compilation unit) using dart_style's grammar unchanged: `N columns |` width header, optional parenthesized file-level options line, `###` comments, `>>> (options) description`, input, `<<< [version] [description]`, output. Options are extended with dotted config paths, `key=value`, values being YAML scalars, quoted strings, or `[a,b]` lists, parsed properly (not whitespace-split) and validated against the real config schema. Precedence per case: `dart` preset → file-level options → case options; cases are isolated. Legacy options keep their upstream meaning: `(indent N)` is *leading* indentation applied by the harness (not `indent.size`), `(experiment x)` a parser flag, `(trailing_commas preserve)` maps to `trailing_commas=preserve chop_on_trailing_comma=true`. Malformed options fail the suite with file and case. Versioned outputs: each `<<< X` is the minimum version where that output applies and there is no "unsupported" marker; since Beaver formats at the latest language version (D5), the newest section is the expectation. Cases using `‹›` selection markers are reported as skipped. The engine exposes a test-only `formatStatement` entry point for `.stmt` input; the wrapper never appears in output and D17 runs on the statement. Layout: `test/golden/<area>/` strict Beaver tests, one case per rule value; `test/golden/dart_style/tall/` verbatim upstream copy with LICENSE and `UPSTREAM.md`, scored not pass/fail, refreshed by copying; `short/` is not imported (a style Beaver does not implement). Rules out: a `.beaver` extension or YAML case format; rewriting imported files; mapping `(indent N)` to config; counting skipped cases as matches; importing `short/`.

### D19. Editor scope v1: VS Code + IntelliJ, no LSP; the stdin protocol is the contract

v1 ships the CLI, a VS Code extension and an IntelliJ/Android Studio plugin. `beaver_lsp` is removed: Helix, Zed, Neovim (conform.nvim), Emacs (apheleia) and Sublime all run stdin formatters natively, so an LSP exposing `textDocument/formatting` would duplicate the CLI while adding protocol, lifecycle, packaging and release costs. Each of those editors gets a documented, valid, tested configuration (`beaver --stdin --stdin-name <path>`), and the docs state per editor whether selection formatting is available: external-command integrations do not generally support it (Helix has no such action; Zed sends the whole buffer), conform.nvim does via range args. `--range` is therefore an available capability, not a universal promise. IntelliJ uses the documented external-formatter API, `AsyncDocumentFormattingService` registered at `com.intellij.formattingService` (the draft's `ExternalFormatProcessor` was wrong); because of IDEA-318504 the plugin is required to work for folder reformat and reformat-on-save, not merely to register. In all adapters the current editor buffer is authoritative and `--stdin-name` provides context only, never a file read. The D15 stdin protocol is the sole cross-editor contract; adapters contain no formatting logic. End-to-end editor latency (process start + config + parse + verify) is measured separately from engine time, per §3's existing rule. An LSP is reconsidered only when an editor supports LSP formatting but no external command, or when §3's latency threshold demands a persistent process. Package layout stays as D1 (one pub package `zooper_beaver`); no `beaver_core`/`beaver_cli` split, no `editors/`→`extensions/` rename. Rules out: `beaver_lsp` in v1; `ExternalFormatProcessor`; save-then-read-from-disk; promising selection formatting in editors that can't pass a range.

### D20. Binary distribution and editor resolution

Release targets: Windows x64, Linux x64, Linux arm64, macOS x64, macOS arm64, all built with `dart compile exe` from one tagged revision (3.13's `--target-os`/`--target-arch` list all five OSes; the pipeline proves which combinations cross-compile). Recommended CLI install is `dart install zooper_beaver@<version>` (produces `beaver` via D1's `executables`); `pub global activate` remains documented. Resolution order in both plugins: explicit path setting → `beaver` on PATH → bundled (VS Code) or cached/downloaded (IntelliJ). Every candidate is validated by running `beaver --version`, which reports formatter version and CLI protocol version; an explicit or PATH binary that is missing or protocol-incompatible is an actionable error, never a silent fallback to another version. PATH-first respects installed binaries but is **not** version pinning and v1 claims no editor/CI parity; teams pin by what they install, and the plugins' "Show Formatter Information" command exposes version, protocol, source, path, platform and resolved config. VS Code: platform-specific VSIX with exactly one binary, declared as a workspace extension so it runs on the remote host (SSH, containers, WSL), no runtime download. IntelliJ: platform-independent plugin; when nothing is on PATH it downloads over HTTPS the binary named in a manifest embedded in the plugin at build time and verifies SHA-256 against *that* manifest (a `checksums.txt` beside the binary on the same release is not a trust anchor; it stays for manual installs), installs atomically into a user cache keyed by version and platform, never executes a partial or unverified file, and works offline from cache. Plugin versions are independent of formatter versions; each plugin release declares `bundledFormatterVersion` and `protocolVersion`. macOS notarization/Windows signing where required. No `version:` key in `.beaver.yaml`. Rules out: bundled-before-PATH; five binaries inside the IntelliJ plugin; same-origin checksum verification; lock-step plugin/formatter versioning; silent version substitution.
