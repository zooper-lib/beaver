# Tasks

All paths are relative to `packages/zooper_beaver/` unless they start with `docs/`, `example/` or `openspec/`. Run tests with `dart test` from `packages/zooper_beaver/`.

## 1. Schema and config model

- [x] 1.1 In `lib/src/config/schema.dart`, change `_policy` to `never | fill | chop_if_long`, add `IndentType` (`inherit | an integer >= 0 | first_item`; two-value form for `cascades`), add `wrap.break_after_open_bracket` / `wrap.break_before_close_bracket` (bool) and the `inherit`-able list fields on the four delimited lists, add `ReceiverKindListType` for `keep_first_call_on_receiver_line`, and remove `align`, `close_bracket`, `keep_single_line_if_fits` and `chop_on_trailing_comma` on non-delimited lists. Verify with new cases in `test/config_schema_test.dart` covering the "Field not offered" and "Dead trailing-comma trigger is refused" scenarios.
- [x] 1.2 In `lib/src/config/config.dart`, drop `WrapPolicy.chopAlways` and `CloseBracket`, make `ListSettings.indent` a sealed `Inherit | Columns(int) | FirstItem`, add `breakAfterOpen` / `breakBeforeClose`, and expose `chainKeepFirstCallKinds` as a `Set<ReceiverKind>` (`true` → all, `false` → empty). Verify `dart analyze` reports every former `align`, `closeBracket`, `chopAlways` and `chainKeepSingleLineIfFits` read site as an error, to be fixed in group 3.
- [x] 1.3 Update `lib/src/config/dart_preset.dart`: `switch_expressions` to `chop_if_long` + `chop_from: 1`, `initializer_lists.indent: first_item`, bracket fields `true` globally and `inherit` per list, `keep_first_call_on_receiver_line: []`, remove `align`, `close_bracket`, `keep_single_line_if_fits` and the dead `chop_on_trailing_comma` lines. Verify the preset resolves (`config_resolve_test.dart` preset case) and every schema key has a preset value.

## 2. Loader: aliases and removal errors

- [x] 2.1 In `lib/src/config/loader.dart`, add a value-rewrite step before schema lookup: `if_long` → `fill`; `close_bracket` keys with `own_line | after_last_item` → `break_before_close_bracket: true | false` (`inherit` kept); `align: true` and `indent.align.*: true` → `indent: first_item`; `align: false` and `indent.align.*: false` dropped. Record the user's spelling so the one-layer conflict check names it. Verify with `test/config_resolve_test.dart` cases for the "Legacy policy value", "Legacy alignment key", "align true on a list" (exit 78), "align false dropped" and "Legacy close bracket" scenarios.
- [x] 2.2 Add the removed-spelling check: `policy: chop_always` (long form and shorthand, any list) and `wrap.chained_calls.keep_single_line_if_fits` fail with exit 78 and the replacement text from the spec, including the `chop_from: 2` note on a chain. Verify with `config_resolve_test.dart` cases for the four "Removed spellings" scenarios.
- [x] 2.3 In `lib/src/config/resolve.dart`, change the trailing-comma conflict check to read `break_before_close_bracket: false` as the suppressing value, exempt `never` or `chop_from == 1`, and update the message text. Verify the existing conflict tests plus new cases for "Suppression by close-bracket placement" (new key) and "Always chopped is exempt".
- [x] 2.4 Regenerate `docs/beaver.template.yaml` with `beaver config --template` and verify `test/config_template_test.dart` passes and the file contains no `align`, `close_bracket`, `chop_always`, `if_long` or `keep_single_line_if_fits` line.

## 3. Rule sites: policy, threshold and preset parity

- [x] 3.1 Replace every `WrapPolicy.chopAlways` read in `lib/src/rules/lists.dart`, `chains.dart`, `expressions.dart` and `declarations.dart` with the existing threshold logic (`reachesThreshold` / `forced`); in `chains.dart` drop the `chainKeepSingleLineIfFits` term. Verify `dart analyze` is clean for these sites.
- [x] 3.2 Rewrite the `>>> (...)` headers of the goldens that use the old spellings (`test/golden/wrap/policies.stmt`, `chop_from.stmt`, `close_bracket_commas.stmt`, `binary_align.stmt`, `breaks_commas.stmt`, `cascades.stmt`, `hug_block_argument.stmt`, `initializer_lists.unit`, `per_construct.stmt`, `prefix_placement.stmt`, `prefix_placement_chains.stmt`, `switch_class_header.unit`, `test/golden/spaces/new_spaces.unit`, `test/golden/regressions/corpus.stmt`): `chop_always` → `chop_from=1`, `if_long` → `fill`, `close_bracket=after_last_item` → `break_before_close_bracket=false`, `align=true` → `indent=first_item` (plus `break_after_open_bracket=false, break_before_close_bracket=false` on bracketed lists). Expected output unchanged. Verify `dart test test/golden_test.dart` passes for every file not blocked on group 4 and the preset corpus (`test/golden/dart_style`) is byte-identical.

## 4. Layout: brackets, first_item, receiver kinds

- [x] 4.1 In `lib/src/rules/lists.dart`, delete the `settings.align` branch and parameterise the remaining layout by `breakAfterOpen`, `breakBeforeClose` and the `indent` value (`FirstItem` anchors `alignToColumn` at the first item when `breakAfterOpen` is false, falls back to the inherit indent otherwise); replace `gaps[0]` with `breakAfterOpen` for the kept-break computation; keep the line-comment guard. Verify the renamed `align` goldens from 3.2 pass unchanged and add `test/golden/wrap/bracket_placement.stmt` covering the "Opening bracket placement", "Source break next to a bracket", "Three values side by side", "Alignment does not move the brackets" and "Source comma dropped under preserve" scenarios.
- [x] 4.2 In `lib/src/rules/chains.dart`, add the receiver classifier (`type_names`, `identifiers`, `this`, `calls`, `properties`) on the chain target, keep the first call on the receiver line when its kind is in `chainKeepFirstCallKinds`, and select the aligned layout from `indent is FirstItem` with `indent_from` ignored under `FirstItem`. Verify with `test/golden/wrap/keep_first_call_kinds.stmt` covering the six "First chained call on the receiver line" scenarios and the "indent_from ignored under first_item" scenario at 60 columns.
- [x] 4.3 In `lib/src/rules/expressions.dart`, read binary alignment from `indent is FirstItem` and the hug-block guard from the same value. Verify `binary_align.stmt` (renamed header) passes unchanged and `hug_block_argument.stmt` still passes.
- [x] 4.4 Run the full suite (`dart test`) and the preset corpus and verify byte-identical preset output end to end, including every switch expression.

## 5. Docs and examples

- [x] 5.1 Add the glossary to the top of `docs/rules/wrap.md` (too long, `never`, fill, chop, `chop_from`, kept line break, bracket placement, the same on chains) with the sub-option rule stated once; generate each example by running Beaver at 40 columns (arguments) and 60 columns (chains) on the audit's inputs. Verify `dart test test/docs_test.dart` passes and each example in the glossary matches `beaver --stdin --config` output for its stated settings.
- [x] 5.2 Rewrite the `wrap.md` sections for `policy`, `chop_from`, `keep_existing_line_breaks` (what it does, the trade-off, breaks next to a bracket), `break_after_open_bracket`, `break_before_close_bracket` (naming `trailing_commas` as its sub-option), `trailing_commas`, `keep_first_call_on_receiver_line` (kinds table), `chop_on_trailing_comma` (four lists), and the alias list; remove `chop_always`, `keep_single_line_if_fits`, `close_bracket`. Verify `grep -n "chop_always\|keep_single_line_if_fits\|close_bracket\|if_long" docs/rules/wrap.md` returns only the alias and migration lines.
- [x] 5.3 In `docs/rules/indent.md`, replace the `wrap.<list>.align` section with `indent: inherit | <integer> | first_item` and the three-way example from the spec. Verify `docs_test.dart` passes and `grep -n "align" docs/rules/indent.md` returns only the alias mention.
- [x] 5.4 Replace the example folders: remove `example/wrap.arguments.align`, `wrap.parameters.align`, `wrap.binary_expressions.align`, `wrap.chained_calls.align`, `wrap.chained_calls.keep_single_line_if_fits`, `wrap.close_bracket`, `wrap.chop_on_trailing_comma`; add `wrap.arguments.indent` (`inherit`, `4`, `first_item`), `wrap.break_after_open_bracket`, `wrap.break_before_close_bracket`, `wrap.chained_calls.keep_first_call_on_receiver_line` (`[]`, `[type_names]`, `[identifiers]`, `true`), `wrap.arguments.chop_on_trailing_comma`. Verify `dart test test/example_test.dart` passes.
- [x] 5.5 Add a `CHANGELOG.md` entry under `## Unreleased` listing the renames (aliases), the three breaking removals with their replacements, and the `align: true` bracket note. The version bump (minor) is left to the release commit, which bumps every version file together. Verify `dart test test/cli_test.dart` passes.

## 6. Integration

- [x] 6.1 Run `dart analyze` and `dart test` from `packages/zooper_beaver/` and verify both are clean.
- [x] 6.2 Run `openspec validate settings-audit-cleanup --strict` and walk every scenario in the two delta specs against a golden or a config test; verify each has one.
- [x] 6.3 Delete `SETTINGS_AUDIT.md` from the repository root once every decision in it is reflected in the specs and docs; verify no file references it.

## Workflow follow-up

- Archive the change with `/opsx:archive` after review.
