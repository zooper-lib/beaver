# Design

## Context

See `proposal.md` for motivation and the specs for the required behaviour. This section covers only the current code that shapes the approach.

- **Configuration is a flat dotted map.** `flatten()` in `config/config.dart` turns YAML into `key → value`. `schema.dart` maps every dotted key to a `ValueType` (`IntType`, `BoolType`, `EnumType`, `StringListType`), and the `dart` preset YAML defines every key. `parseConfigFile` validates each file with `validateValues`. `resolveConfig` in `resolve.dart` then overlays the files on the preset key by key (`exclude` concatenates), records one provenance string per key, and runs the single global trailing-comma conflict check.
- **The golden runner bypasses the resolver.** `test/src/golden_runner.dart` validates file and case options separately, then spreads both into one `BeaverConfig.dart.merge({...})`. That is where the "normalise each layer, then merge" rule breaks today.
- **Rules read typed getters.** `BeaverConfig` exposes getters such as `wrapArguments`, `alignArguments` and `chainMinCalls`. Every bracketed list is laid out by one helper, `DocBuilder.delimited()` in `rules/lists.dart`, which already implements kept breaks, mixed-construct detection, chop on trailing comma, alignment and the trailing-comma `IfBreak`. Chains and cascades live in `chains.dart`, and binary runs in `builder.dart` (`runs`). Enum bodies call `delimited` with `config.wrapCollections`.
- **Line endings** are chosen in `format.dart` by `detectLineEnding(source)` and passed to `emit`.
- **Specs base.** `openspec/specs/` is empty until `initial-implementation` is archived. This change's deltas modify those capabilities.

## Goals / Non-Goals

**Goals:**

- One normalisation and validation path used by `.beaver.yaml` files, `--config`, and the golden harness's file and case options.
- Rules receive fully resolved, typed values. `inherit`, aliases and EditorConfig never reach `lib/src/rules`.
- Add the per-construct plumbing first, with byte-identical golden output, so each new key lands later as an isolated rule change.
- The engine stays free of `dart:io`. EditorConfig files are read through the injected `ReadFile`.

**Non-Goals:**

- No changes to the verifier (`lib/src/verify`). Every new rule stays inside the existing token, fingerprint and comment checks. The only comma change, suppression under `close_bracket: after_last_item`, falls under the optional-comma normalisation that already exists.
- No `cleanup:` keys in the schema or the template.
- No change to `beaver init` output beyond what it already derives from the schema.

## Decisions

### 1. The schema stays flat; list maps are generated from a construct table

`schema.dart` gains a table of list constructs. Each entry gives the construct's name, the optional fields it accepts (`indent`, `close_bracket`, `trailing_commas`, plus construct-specific fields such as `hug_block_argument`, `colon` or `clauses_on_new_line`), and its `indent` fallback. The schema map is built from that table plus the hand-written scalar keys. It remains `Map<String, ValueType>` with only leaf keys, so `flatten()` needs no union types and no special cases.

*Alternative:* writing roughly 90 list-field entries by hand. Rejected because the five common fields would drift between constructs.

*Alternative:* a nested typed schema (`ListSchema`, `ScalarSchema`). Rejected because every consumer (validation, template, provenance, `config --print`) already iterates a flat map.

### 2. `normalizeAndValidateValues` replaces `validateValues`

There is one function, returning `Map<String, Object?>` keyed by canonical key, with a side table from canonical key to the spelling the user wrote. It works in three steps:

1. **Rewrite aliases.** It holds the only alias table. A shorthand `wrap.<list>: <scalar>` becomes `wrap.<list>.policy`. `indent.align.*`, `min_calls` and `before_operator` map one-to-one.
2. **Check conflicts.** Two spellings with different values in one layer raise a `ConfigException` naming both keys.
3. **Validate.** Each value is checked against its `ValueType`. Diagnostics name the user's spelling and the canonical key.

`parseConfigFile` and the golden runner both call it. The runner then folds file options and case options in turn onto the preset with `merge`, so a shorthand in a case keeps a file-level `chop_from`.

*Alternative:* normalising after the merge. Rejected because a shorthand child would then replace the whole inherited map, the exact bug the rule exists to prevent.

### 3. New value types

- `InheritOr(ValueType)` accepts `inherit` or the inner type.
- `IntOrPreserveType` accepts `preserve` or an int ≥ 0.
- `DottedNameListType` validates `chop_on_calls` entries: identifier segments separated by single dots, no wildcards.
- `IntType` gains the `min` the template prints (`spaces.before_trailing_comment` has `min: 1`).

`describe()` on each type feeds both diagnostics and the template's trailing comment.

### 4. Resolution pipeline: layers → merge → EditorConfig → inherit → checks

`resolveConfig` keeps its discovery and `extends` walk and then:

1. **Overlay.** Overlay the normalised file layers on the preset exactly as today. `inherit` is just a stored value at this point.
2. **EditorConfig.** If the merged `editorconfig` is `true`, resolve EditorConfig for the target path. Write its three mapped keys only where provenance is still the preset. This is how "above the preset, below any explicit Beaver value" is implemented without a separate precedence system.
3. **Inherit.** Replace each remaining `inherit` with the effective value of its fallback key. Fallbacks come from a fixed table: per-list flags to the global flag, per-list `indent` to the construct's documented key, `braces.*_on_new_line` to `else_on_new_line`, `max_consecutive_in_code` to `max_consecutive`, `enum_values.*` to `collection_literals.*`, and `around_class_declarations: inherit` to `between_top_level_declarations`. Chains are at most two deep (`enum_values.trailing_commas` → `collection_literals.trailing_commas` → `trailing_commas`), so resolution recurses through the table, which has no cycles by construction. A test asserts that.
4. **Checks.** Run the per-construct trailing-comma check on the resolved values.

Provenance becomes `Map<String, Source>`, where `Source` holds the setting's origin and, for an inherited key, the origin of the fallback value. EditorConfig origins carry path, section and property (plus `tab_width` when derived). `config --print` prints both. Today's string field becomes the `origin` of the record, so `exclude`'s concatenated provenance is unchanged.

*Alternative:* resolving `inherit` per layer. Rejected because the spec requires `inherit` to follow a global override made in a nearer file.

### 5. `BeaverConfig` exposes one resolved settings object per list

A `ListSettings` value (policy, chopFrom, keepExistingLineBreaks, chopOnTrailingComma, align, indent, closeBracket, trailingCommas) is built once per construct and exposed as `config.arguments`, `config.parameters`, and so on. `delimited()` takes a `ListSettings` in place of its separate `policy` and `align` parameters, and reads the per-list flags from it instead of global getters. The old getters (`wrapArguments`, `alignArguments`, `chainMinCalls`, `breakBeforeOperator`) are removed in the same step, so no rule can read a global value where a per-construct one exists.

Records are the trap noted in the specs. Record literals and patterns currently reuse the arguments policy, and record types the parameters policy. They receive a `ListSettings` derived from that construct's policy but with the **global** `trailing_commas`, `chop_on_trailing_comma` and `keep_existing_line_breaks`. One golden case per record form pins this.

### 6. Threshold, hugging and call matching live in `delimited()` and its callers

- **`chop_from`.** The threshold becomes one more input to the existing `forceChop`: `settings.chopFrom > 0 && items.length >= settings.chopFrom && policy != never`. Callers already pass syntactic items (named arguments, spreads and `if` elements are single nodes), so counting needs no new logic. Binary runs count operands in the flattened run `runs()` already builds. Chains keep their count, now read from `chop_from`.
- **`hug_block_argument: false`.** This skips the existing hugging branch and falls through to the ordinary layout. The eligibility rules already in the helper are unchanged.
- **`chop_on_calls`.** The parent invocation's callable name (from `MethodInvocation`, `InstanceCreationExpression` and `FunctionExpressionInvocation` with a dotted `Identifier`/`PropertyAccess` target) is matched in the argument-list caller and passed as `forceChop`, exactly like a named-argument match.

### 7. `add_when_chopped` and `after_last_item` reuse the group machinery

`delimited()` already distinguishes the chop layout (a `Group` whose separators are `hardline`/`line`) from the fill layout (`Fill`).

- **`add_when_chopped`** emits the trailing-comma `IfBreak` only in the chop layout. In the fill layout it emits no optional comma.
- **`close_bracket: after_last_item`** drops the `softline` before the closing delimiter and suppresses the optional comma. A required comma (single-field record) is still emitted.

The verifier already normalises optional trailing commas, so both pass verification unchanged.

### 8. Cascades get a list map without moving their code

`chains.dart`'s `cascade()` keeps its layout code. It reads `config.cascades` for policy, `chop_from` (preset 2, replacing today's hard-coded "two or more sections always chop"), `indent` (replacing the fixed `indent.size` use) and `keep_existing_line_breaks`. Cascade-level gaps are measured between the receiver's end and each `..`. `attach.dart` already treats cascade sections as line starts and needs no change.

### 9. Comment gap is decided in the declaration sequence, not in comment attachment

Attachment (which node a comment leads) is unchanged. The blank-line count between a leading comment group and its declaration is emitted where declarations are sequenced (`declarations.dart`, the class-member and top-level paths). There, the source gap after the last ordinary own-line comment is capped (`preserve`) or replaced (integer). Doc comments and line-sensitive directives (`// ignore:`, `// ignore_for_file:`, `// coverage:ignore-line`) are excluded before the count is applied. Statement and list-item paths keep today's behaviour.

### 10. EditorConfig resolver is a small self-contained module

`config/editorconfig.dart` provides:

- an INI parser covering sections, `key = value`, `;`/`#` comments and `root`;
- a glob-to-RegExp translator implementing the EditorConfig rules (`*`, `**`, `?`, `[...]`, `{a,b}`, `{n1..n2}`, and a pattern without `/` matching the basename at any depth);
- the upward walk via `ReadFile`.

*Alternative:* reusing `package:glob`. Rejected because its semantics differ: no numeric ranges, and different handling of slash-less patterns. Getting this wrong silently changes which section applies. It is kept as a separate module so it can be tested against the EditorConfig core test cases on its own.

### 11. Template is generated from schema + preset + construct table

`config/template.dart` walks the schema in a fixed order (top-level keys, then each section in its documentation order, list maps in long form). It prints the preset's raw value (`inherit` where the preset says so) and `describe()` as the trailing comment. `beaver config --template` prints it. `test/docs_test.dart` compares it to `docs/beaver.template.yaml`, the same way `example/` is kept honest. A second test parses the template as a `.beaver.yaml` and checks that it resolves to the preset.

### 12. Sequencing keeps every step reviewable

1. Foundation: types, construct table, normalisation, inherit resolution, provenance, `ListSettings`, golden runner. All goldens are byte-identical.
2. Template and `config --template`.
3. New keys, each with its golden cases, `example/` folder and rule-page entry. Per-key preset values keep goldens identical.
4. The two preset changes, each in its own commit with reviewed golden diffs (`self_format` included) and a second-pass stability run.
5. EditorConfig.

Renamed `example/` folders (`indent.align.*` to `wrap.<list>.align`, `wrap.before_operator` to `wrap.break_before.binary_operator`) move in step 1, and the rule pages list the aliases once.

## Risks / Trade-offs

- **[Risk]** `delimited()` grows more interacting switches (threshold, hugging, call match, close bracket, comma mode). → All of them feed two existing decisions, `forceChop` and the trailing `IfBreak`. Golden cases are added for each pairwise precedence the specs name (`never` against each trigger, threshold against kept groups, trailing comma against hugging).
- **[Risk]** Records accidentally inherit argument or parameter comma overrides. → Decision 5, plus one golden case per record form with a conflicting per-list override.
- **[Risk]** The `inherit` fallback table could form a cycle as keys are added later. → The table is a const map. A unit test walks every chain and asserts it ends at a non-inheriting key.
- **[Risk]** EditorConfig glob semantics differ subtly from editors' implementations. → Port the relevant cases from the EditorConfig core test suite into `test/`. Integration is opt-in, so a mismatch only affects users who enabled it.
- **[Risk]** The two preset changes alter output for existing projects. → Disclosed as BREAKING in the proposal and the changelog. Each lands in a separate commit with reviewed golden diffs. `wrap.cascades.keep_existing_line_breaks: false` and `between_comment_and_declaration: 0` restore the old output.
- **[Trade-off]** `wrap.enum_values` is the one list whose `policy`, `chop_from` and `align` accept `inherit` (falling back to `collection_literals`). This keeps the no-output-change promise for configurations that customised collections. The cost is one exception to "policy never inherits", stated once in the rule page.
- **[Trade-off]** `config --print` output changes shape (two sources per inherited key). Its consumers are humans. The editor plugins do not parse it, so the stdin protocol version is unaffected.

## Migration Plan

- **Prerequisite:** archive `initial-implementation` so `openspec/specs/` holds the base specs these deltas modify.
- **Existing configuration files:** they keep working unchanged, because every old spelling is an alias.
- **Users who want the old output:** they set the two keys named under Risks. The changelog for the release states both.
- **Rollback:** each sequencing step is a separate commit, so reverting the step 4 commits restores the old defaults without touching the new keys.
