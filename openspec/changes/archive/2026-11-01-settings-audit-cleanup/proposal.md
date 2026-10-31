# Proposal

## Why

The settings audit of 2026-10-31 found that several `wrap` keys are two spellings for one behavior (`chop_always` is `chop_from: 1`; `align: true` silently overrides `indent` and also moves both brackets), that `chop_on_trailing_comma` is accepted on seven lists that never read it, and that the vocabulary (`if_long`, `close_bracket`, `align`) hides what the formatter does. Every finding has a recorded decision; this change applies them before the settings surface grows further, so that each layout question has exactly one key and every term is defined with real output.

## What Changes

- Rename the wrap policy value `if_long` to `fill`; `if_long` stays as an alias (D2).
- **BREAKING** Remove `policy: chop_always` and `wrap.chained_calls.keep_single_line_if_fits`. Both are refused with exit 78 and a message naming the replacement (`chop_from: 1`, or `chop_from: 2` on a chain with `keep_single_line_if_fits: false`). The preset's `switch_expressions` becomes `chop_if_long` + `chop_from: 1`, byte-identical output (D3, D12).
- State the sub-option rule once: a sub-option without its parent is ignored (`chop_from` under `never`, `indent_from` without an integer `indent`, `trailing_commas` under `break_before_close_bracket: false`); peer settings that contradict each other are a configuration error (D3a, D10).
- Split bracket placement from wrapping on the delimited lists: new fields `break_after_open_bracket` and `break_before_close_bracket` (both `true` in the preset). `close_bracket: own_line | after_last_item` becomes an alias of `break_before_close_bracket: true | false`. A source line break directly next to a bracket follows these fields instead of `keep_existing_line_breaks` (D4, D11).
- **BREAKING** Replace `align` with a third value of `indent`: `indent: inherit | <integer> | first_item`. `align: true` is an alias of `indent: first_item`; `align: false` is accepted and dropped. A configuration that relied on `align: true` to put the first item on the bracket line and the closing bracket after the last item now needs the two bracket fields to keep its look (D8).
- Turn `wrap.chained_calls.keep_first_call_on_receiver_line` into a list of receiver kinds (`type_names`, `identifiers`, `this`, `calls`, `properties`), with `true` meaning every kind and `false` meaning `[]`. Preset: `[]` (D9).
- **BREAKING** Remove `chop_on_trailing_comma` from the lists that never read it; it stays on `arguments`, `parameters`, `collection_literals` and `enum_values` only. Elsewhere it is an unknown key (D7).
- Rewrite the `keep_existing_line_breaks` description to what it does, with the trade-off next to it (D5).
- Add a glossary with real before/after output at the top of `docs/rules/wrap.md`: too long, `never`, fill, chop, `chop_from`, kept line break, bracket placement, and the same on chains (D6).
- Regenerate `docs/beaver.template.yaml`; replace the example folders and goldens that use the removed spellings.

Not in scope: switch-arm trailing commas, which differ from `dart format` and are a feature of their own (observed in D7).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `formatting-rules`: "Wrap policy values" (`fill`, no `chop_always`); "Chained call wrapping" (no `keep_single_line_if_fits`); "Alignment precedence", "Binary expression alignment" and "Continuation indent" (rewritten around `indent: first_item`); "First chained call on the receiver line" (list of receiver kinds); "Closing delimiter placement" (the two bracket fields, independent of wrapping); "Preserved line breaks are never removed" (a break next to a bracket follows the bracket fields); "Item threshold forces chopping" and "Threshold interaction with each policy" (`chop_from` as the only count-based trigger, ignored under `never`); "Trailing comma when chopped" (sub-option of `break_before_close_bracket: true`).
- `config-resolution`: "Canonical long-form keys" and "Aliases map one-to-one onto canonical keys" (the new aliases; `align: false` dropped); "Unknown keys and invalid values are configuration errors" (`chop_on_trailing_comma` only on the four delimited lists); new requirements for the removal errors that name the replacement and for the sub-option rule; "Single built-in preset `dart`" (`switch_expressions` preset, bracket fields); "Reference template" (the regenerated template).

## Impact

- **Config**: `packages/zooper_beaver/lib/src/config/schema.dart` (policy enum, `align` removed, `indent` gains `first_item`, bracket fields, receiver-kind list, `chop_on_trailing_comma` inventory), `resolve.dart` (aliases, removal errors, `align: false` drop), `dart_preset.dart`, `config.dart`.
- **Rules**: `packages/zooper_beaver/lib/src/rules/lists.dart` (bracket fields independent of alignment; source break next to a bracket), `chains.dart` (drop the `keep_single_line_if_fits` branch, receiver kinds, `first_item`), `expressions.dart` (binary alignment via `first_item`).
- **Tests**: `test/config_resolve_test.dart`, `test/config_template_test.dart`; goldens under `test/golden/wrap/` that mention `align=`, `chop_always`, `if_long`, `close_bracket=` or `keep_single_line_if_fits` (`policies.stmt`, `chop_from.stmt`, `binary_align.stmt`, `close_bracket_commas.stmt`, `prefix_placement_chains.stmt`, `initializer_lists.unit`, `switch_class_header.unit`, among others).
- **Docs**: `docs/rules/wrap.md` (glossary, rewritten sections), `docs/rules/indent.md` (`wrap.<list>.align` section replaced), `docs/beaver.template.yaml` regenerated.
- **Examples**: `example/wrap.*.align`, `wrap.chained_calls.keep_single_line_if_fits`, `wrap.close_bracket`, `wrap.chop_on_trailing_comma` replaced by folders for `indent`, the two bracket fields and the receiver kinds.
- **Users**: three breaking spellings (`chop_always`, `keep_single_line_if_fits`, `chop_on_trailing_comma` on the seven lists) fail with a message naming the fix; `align: true` on bracketed lists changes output unless the bracket fields are added. Needs a minor version bump and a changelog entry.
