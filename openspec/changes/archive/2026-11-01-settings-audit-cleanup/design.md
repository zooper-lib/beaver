# Design

## Context

See `proposal.md` for the motivation and the delta specs for the required behavior. What shapes the approach:

- The schema (`packages/zooper_beaver/lib/src/config/schema.dart`) is a flat map of dotted key to `ValueType`; every list is a `ListConstruct` that generates its fields from flags (`align`, `indent`, `delimited`, `extra`). `chop_on_trailing_comma` is generated for every list unconditionally.
- The alias table in `loader.dart` maps key to key only (`_aliases`, `_shorthands`); there is no value-level alias today. Normalisation runs per layer, so two spellings of one key in one file are already an error.
- `config.dart` exposes `ListSettings` with `align: bool`, `indent: int`, `closeBracket: CloseBracket`, and a `WrapPolicy` enum with four members. `chopAlways` is read in `lists.dart`, `chains.dart`, `expressions.dart` and `declarations.dart`.
- In `lists.dart` the `align` branch is a separate layout that does three things at once: first item on the bracket line, aligned items, closer after the last item. The non-aligned layout honours `closeBracket` and always breaks after the opening bracket. The source newline after the opening bracket is `gaps[0]`, treated like any gap between items.
- In `chains.dart` the `forced` condition reads `chopAlways && !chainKeepSingleLineIfFits`; `keep_first_call_on_receiver_line` is a bool read via `config.flag`; `settings.align` selects a separate `IfBreak(continued, aligned)` layout.
- Goldens carry their settings in a `>>> (key=value)` header; examples are folders named after a key with one subfolder per value.
- The preset is byte-identical before and after by requirement (`config-resolution`: "Preset output unchanged by this change"), which the golden corpus already enforces.

## Goals / Non-Goals

**Goals:**

- Every renamed spelling is a pure alias resolved during normalisation, so the rest of the code sees only canonical keys and values.
- The layout code has one code path per list, parameterised by the bracket fields and the `indent` value, instead of a parallel aligned layout.
- A configuration that only used canonical, surviving keys produces identical output.

**Non-Goals:**

- Switch-arm trailing commas (proposal, out of scope).
- Rewriting the `wrap.md` rule pages beyond the glossary and the sections the specs touch.
- A general value-alias mechanism beyond what the three renames need.

## Decisions

### D1. Value aliases are rewritten in the normaliser, next to key aliases

`if_long` → `fill`, `close_bracket: own_line | after_last_item` → `break_before_close_bracket: true | false`, and `align: true` → `indent: first_item` all change the key or the value or both. `normalizeAndValidateValues` gains a small rewrite step before schema lookup: a table from `(canonical key pattern, value)` to `(key, value)`. `close_bracket` and `align` entries rewrite the key; the policy entry rewrites the value only. `align: false` and `indent.align.*: false` rewrite to nothing (dropped). The existing "two spellings in one layer" check then catches `align: true` next to `indent: 4` for free, since both land on `wrap.<list>.indent`.

Alternative considered: keep `align` in the schema and merge it with `indent` at `ListSettings` construction. Rejected: the schema would still offer a field the specs say does not exist, the template would print it, and the conflict check would not see the overlap.

### D2. Removed spellings are a dedicated check before the unknown-key error

`policy: chop_always` (any list, long form or shorthand) and `wrap.chained_calls.keep_single_line_if_fits` get a small table of key or value to message, consulted in the normaliser before the schema lookup. The message quotes the key as written and the replacement text from the spec. Without this step they would already fail, but as a bare "unknown key" or "invalid value" error that does not name `chop_from`.

### D3. `WrapPolicy` loses `chopAlways`; the threshold carries "always"

The enum becomes `never | fill | chopIfLong`. Every `chopAlways` read in the rules is replaced by the existing `reachesThreshold` / `forced` logic, which already handles `chop_from`. The preset's `switch_expressions: chop_from: 1` makes "always" a threshold of one, so the switch-arm code needs no special case. `chains.dart` drops the `chainKeepSingleLineIfFits` term from `forced`.

Risk to check per site: `chopAlways` also disabled block-argument hugging and the conflict-check exemption. Hugging is already disabled at the threshold (`reachesThreshold`), so `chop_from: 1` keeps that behavior. The conflict check's exemption becomes `chop_from == 1` (spec: "Always chopped is exempt").

### D4. `indent` becomes a three-way value in `ListSettings`

`ListSettings.indent` becomes a sealed value: `Inherit` (resolved to the fallback integer as today), `Columns(int)`, or `FirstItem`. The schema type is a new `IndentType` accepting `inherit`, an integer ≥ 0, or `first_item`; lists that today have `align: false` (`cascades`) get the two-value form. `settings.align` is replaced by `settings.indent is FirstItem` at its call sites in `lists.dart`, `chains.dart` and `expressions.dart`. `indent_from` is consulted only when the value is an integer or `inherit`.

Alternative considered: keep `indent: int` and a separate `alignFirstItem: bool` derived from the value. Rejected: that recreates the two-field state the change removes, one layer down.

### D5. One list layout, parameterised by the bracket fields

The `align` branch in `lists.dart` is deleted. The remaining layout takes two booleans from `ListSettings`, `breakAfterOpen` and `breakBeforeClose`, and the `indent` value:

- `breakAfterOpen: true`: hardline-or-softline after the opening bracket, items at the indent (today's layout).
- `breakAfterOpen: false`: no separator after the bracket; the first item follows it on the same line. Later items go at the indent, or, with `FirstItem`, inside `alignToColumn` anchored at the first item.
- `breakBeforeClose` replaces `closeBracket == afterLastItem` in the trailing-comma and closer logic, unchanged otherwise.

Today's `align: true` output equals `breakAfterOpen: false, breakBeforeClose: false, indent: first_item`, which is what the alias produces, so the `align` goldens become bracket-field goldens with the same expected output. The line-comment guard that forces the closer onto its own line stays.

`gaps[0]` (source newline after the opening bracket) is replaced by `breakAfterOpen` when computing kept breaks; the gap before the closer is already governed by `closeBracket` today. Under the preset both are `true`, so the kept-break behavior is unchanged there.

### D6. Receiver kinds are a classifier on the chain target

`keep_first_call_on_receiver_line` gets a `ReceiverKindListType` accepting a list of the five words or a bool, normalised to a `Set<ReceiverKind>` in `BeaverConfig` (`true` → all, `false` → empty). `chains.dart` classifies `target` once: `SimpleIdentifier` starting with an uppercase letter, or a `PrefixedIdentifier` whose identifier does, is `type_names`; other `SimpleIdentifier` is `identifiers`; `ThisExpression`/`SuperExpression` is `this`; `MethodInvocation`/`FunctionExpressionInvocation` is `calls`; a `PrefixedIdentifier` or `PropertyAccess` chain is `properties`. The first call stays on the receiver line when the kind is in the set. With `FirstItem`, the aligned layout anchors at the kept first call's `.`; when the first call broke, the `IfBreak` fallback already yields the continuation indent.

Alternative considered: resolving the receiver via the analyzer's element model to tell a class from a variable. Rejected: Beaver formats without resolution; the capitalisation rule matches `dart format` and the spec.

### D7. Template and docs are regenerated, not hand-edited

`docs/beaver.template.yaml` is produced by `beaver config --template` and checked by `config_template_test.dart`, so it follows the schema. The `wrap.md` glossary examples are produced by running Beaver at 40 and 60 columns on the inputs in the audit and pasted in; each example folder's `after` files are regenerated by the existing example runner so docs and goldens cannot drift from the code.

### D8. Goldens and examples are renamed to the surviving spellings

Golden headers that say `align=true` become `break_after_open_bracket=false, break_before_close_bracket=false, indent=first_item` (or just `indent=first_item` for chains and binary expressions); `chop_always` becomes `chop_from=1`; `if_long` becomes `fill`; `close_bracket=after_last_item` becomes `break_before_close_bracket=false`. Expected output does not change in any of these, which is the regression check for D3 to D5. The example folders `wrap.*.align`, `wrap.close_bracket`, `wrap.chained_calls.keep_single_line_if_fits` and `wrap.chop_on_trailing_comma` are replaced by `wrap.<list>.indent` (values `inherit`, `4`, `first_item`), `wrap.break_after_open_bracket`, `wrap.break_before_close_bracket`, `wrap.chained_calls.keep_first_call_on_receiver_line` (values `[]`, `[type_names]`, `[identifiers]`, `true`) and `wrap.arguments.chop_on_trailing_comma`.

## Risks / Trade-offs

- [Alias rewriting hides the user's spelling in later diagnostics] → the normaliser already records `spelling[canonical]`; the rewrite step stores the original key and value there so the conflict message names what the user wrote.
- [`first_item` plus `break_after_open_bracket: false` on a list whose first item is itself multi-line] → `alignToColumn` anchors at the first item's start column, as the nested-alignment scenario requires; verified by the existing nested-alignment golden rewritten to the new keys.
- [Dropping `chopAlways` from a rule site that relied on it for something other than chopping] → each of the five files is grepped and every site mapped to `reachesThreshold`; the golden corpus run with the preset must stay byte-identical, which covers switch expressions directly.
- [`gaps[0]` no longer kept under `break_after_open_bracket: false` changes output for users who had `align: true` and a source break after `(`] → accepted; the spec says the bracket fields win, and `align: true` already dropped that break by hugging the first item.
- [Users on `chop_always` or `keep_single_line_if_fits` are broken on upgrade] → exit 78 with the replacement in the message; changelog entry and a minor version bump.
- [Receiver classification by capitalisation misfiles a constant like `MAX.toString()`] → matches `dart format`'s rule and is listed under `type_names` in the docs; a user who disagrees picks a different kind set.

## Migration Plan

1. Schema, config and loader first (D1 to D4, D6): the test suite fails on the goldens and the template.
2. Regenerate the template; rewrite golden headers (D8); run the suite with the preset to confirm byte-identical output before touching layout.
3. Layout changes (D5, chains, binary): new goldens for `break_after_open_bracket: false` with `inherit` and integer `indent`, for the receiver kinds, and for the source break next to a bracket.
4. Docs: glossary, rewritten sections, `indent.md`, example folders (D7, D8).
5. Changelog and version bump. No data migration; a user's `.beaver.yaml` either resolves through aliases or fails with the replacement named.

Rollback: revert the commit; no persisted state changes.
