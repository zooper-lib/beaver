# Proposal

## Why

A chopped method chain after a prefix such as `date:` or `final names =` indents its calls from the start of the line, not from the chain's target. When the prefix is wider than the continuation indent, the calls start left of the target they continue (`date: DateFormat` followed by `.yMMMMd()` under the colon). Binary expressions avoid this only because they always move to their own line after the prefix, and neither the move nor the base of the indentation can be configured. Teams that want the classic `final total = subtotal` / `+ shipping` layout, or the operators one step past the first operand, have no setting for it.

## What Changes

- **`break_after_prefix: true | false`** on `wrap.chained_calls` and `wrap.binary_expressions`. When a wrapped chain or binary expression follows `=`, `=>`, a named argument's `:` or a default value's `=`, `true` moves it to its own line at the continuation indent; `false` keeps its target or first operand on the prefix line. Preset `dart`: `false` for chains and `true` for binary expressions, which is today's output.
- **`indent_from: line | target`** on the same two lists. `line` keeps today's base: continuation lines are indented by the list's `indent` from the line's indentation, and an expression moved after a prefix keeps its continuation lines in its first item's column. `target` measures the list's `indent` from the column where the chain's target or the first operand starts, so a continuation line never starts left of what it continues. Preset `dart`: `line` for both.
- The existing `indent` field of both lists (inherit → `indent.continuation`) stays the width of the offset under both bases. No new width key is added.
- `align: true` keeps precedence over `indent_from`, as it does over `indent` today.
- Every new field has a preset value that reproduces today's output; no formatting changes without a configuration change.

Out of scope: an EditorConfig mapping for continuation indent (JetBrains' `ij_continuation_indent_size`), and the same fields on other lists. Conditional expressions after a prefix keep their current layout.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `formatting-rules`: the continuation-indent requirement gains the base (`indent_from`) and the move after a prefix (`break_after_prefix`) for chained calls and binary expressions.
- `config-resolution`: the two new fields on `wrap.chained_calls` and `wrap.binary_expressions`, their value types and their preset values.

## Impact

- **Code:** `packages/zooper_beaver/lib/src/config` (`schema.dart` list extras, `dart_preset.dart`, `config.dart` accessors), `lib/src/rules/chains.dart` (`chain`), `lib/src/rules/expressions.dart` (`assignmentRhs`, `binary`, `_parentIndents`).
- **Docs:** `docs/rules/wrap.md` (both lists), `docs/rules/indent.md` (continuation indent base), the generated `docs/beaver.template.yaml`.
- **Examples and tests:** `example/` folders for every value of both fields, golden cases for every combination on both lists, config tests for validation and preset values. Existing goldens and the self-format check stay unchanged.
- **Users:** existing configurations format exactly as before.
