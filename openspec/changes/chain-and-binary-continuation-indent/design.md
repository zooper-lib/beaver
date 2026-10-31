# Design

## Context

Two code paths decide where a wrapped chain or binary expression goes after a prefix:

- `assignmentRhs` (`lib/src/rules/expressions.dart`) handles every prefix: `=` (variables, assignments, pattern declarations and assignments, field initializers, parameter defaults), `=>` (function bodies, switch arms) and a named argument's `:`. A block-like right side (`isBlockLike`, which includes every chain) stays on the prefix line; anything else, binary expressions included, goes into a group that moves it to the next line at continuation indent (`cont`, or `indent` for switch arms) when it does not fit.
- The lists then indent their own continuation lines with `align(settings.indent, ...)`, which is relative to the enclosing indentation, not to a column. `binary` skips that align when `_parentIndents(node)` says the parent already moved it, so the operands share the first operand's column. `chain` always applies it, which produces `date: DateFormat` / `.yMMMMd()` with the dots under the colon.

The IR already has what a column base needs: `Align.toColumn` sets the indentation to the column where its contents start, and `chain`'s `align: true` branch shows the fallback pattern (`IfBreak` on a group id around the target).

## Goals / Non-Goals

**Goals:**
- Both new fields behave the same way on both lists, and the `dart` preset output stays byte-identical (goldens, examples and the self-format check unchanged).

**Non-Goals:**
- Changing which parents count as "already moved" for binary expressions today. `ConstructorFieldInitializer` and `PatternAssignment` go through `assignmentRhs` but are not in `_parentIndents`, so a moved binary there gets one extra indent. That is existing preset output and stays as it is.
- A width key per base. The width is the existing `indent` field.

## Decisions

### Reuse `indent` as the offset under both bases

`wrap.<list>.indent` already is "offset of the broken items from the list's baseline", inheriting `indent.continuation`. `indent_from` only changes the baseline. A separate `rest_indent` would give two width keys whose difference only shows under one base.

Alternative: a single enum with a fixed offset (`line_plus_continuation`, `target_column`, ...). Rejected because it cannot express "one step past the target" with the developer's own step width.

### `line` keeps today's irregularity on purpose

Under `line`, a binary expression moved after a prefix keeps its operands in the first operand's column (offset 0), while one that was not moved gets `indent` from the line. That is the only way the preset can reproduce today's output with a single base value. Chains under `line` follow the same rule once they can move (`break_after_prefix: true`), so both lists read alike: "moved means the move already indented it".

The predicate for "moved" stays `_parentIndents`, extended to chains. Inside a prefix with `break_after_prefix: true`, continuation lines can only exist once the enclosing group broke, because a hard break or an overflowing chain breaks it. So the parent type is a sufficient signal, and no flag has to pass from `assignmentRhs` into the list.

### `target` via `Align.toColumn`

- Binary: `alignToColumn(align(indent, body))`. The first segment prints where the expression starts, and each later line starts at that column plus `indent`. A first operand that itself breaks indents its inner lines from the column too, exactly as `align: true` does today. Binary keeps that without a fallback.
- Chains: `alignToColumn(concat([target, ...head, align(indent, calls)]))`, guarded like the `align: true` branch: when the target group breaks, the `line` layout is used. A target such as `foo(\n  args,\n)` would otherwise indent its arguments from the target's column.
- Under `target` the moved case needs no special handling, because the target starts the line, so its column is the line's indentation.

### `break_after_prefix` lives in `assignmentRhs`

- Chain with `true`: `isChain(rhs)` takes the non-block-like path (the group that moves it when it does not fit), including after `=>`, where the arrow's `ConditionalGroup` for block-like bodies is skipped. A single call (`foo(a)`) is not a chain and stays block-like.
- Binary with `false`: the right side is printed hugged (`op`, space, value), and `_parentIndents` returns false for it, so `binary` applies `indent` from the prefix line. That gives the classic `final total = subtotal` / `+ shipping` layout.
- `wrap.break_before.assignment` / `arrow` keep working: with the operator on the next line the expression has moved, as today.

### Precedence

`align: true` is checked before `indent_from` in both lists, so an alignment column always wins, matching "the numeric indent is never added on top of an alignment column". `keep_first_call_on_receiver_line` composes: the first call joins the target, and the later calls follow the base.

### Placement in config

Both fields are list `extra`s in `listConstructs` (`schema.dart`), like `keep_single_line_if_fits`. Extras without `inheritsFrom` are plain types, so `inherit` is refused automatically and the template generator picks them up. Accessors go on `BeaverConfig` next to `chainKeepSingleLineIfFits`.

## Risks / Trade-offs

- [`target` deepens nesting after long prefixes (`final someLongName = obj` / `.call()` far right)] → It is opt-in, and the docs show the long-prefix case next to `break_after_prefix: true`, which avoids it.
- [`break_after_prefix: false` on binary never moves, so a very long first operand overflows] → Same trade-off as chains under the preset today. Documented on the rule page.
- [`_parentIndents` and the set of `assignmentRhs` callers differ (see Non-Goals)] → A golden case pins today's field-initializer output, so the difference stays visible instead of drifting silently.
