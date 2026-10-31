## ADDED Requirements

### Requirement: Move after a prefix

A wrapped chain or binary expression that follows a prefix (`=`, `=>`, a named argument's `:`, a parameter default's `=`) SHALL be placed by its list's `break_after_prefix`. With `true`, an expression that does not fit on the prefix line SHALL move to its own line at the continuation indent. With `false`, its target or first operand SHALL stay on the prefix line. Preset `dart`: `false` on `wrap.chained_calls`, `true` on `wrap.binary_expressions`.

#### Scenario: Chain moved after the prefix
- **WHEN** `wrap.chained_calls.break_after_prefix: true`, line length 40, and input is `final names = users.where((u) => u.active).map((u) => u.name).toList();`
- **THEN** output is `final names =\n    users\n    .where((u) => u.active)\n    .map((u) => u.name)\n    .toList();`

#### Scenario: Moved chain that fits on its own line
- **WHEN** `wrap.chained_calls.break_after_prefix: true`, policy `chop_if_long`, and a chain after `=` does not fit on the prefix line but fits on the next line
- **THEN** the chain moves to the next line and stays on one line there

#### Scenario: Binary expression kept on the prefix line
- **WHEN** `wrap.binary_expressions.break_after_prefix: false`, `wrap.break_before.binary_operator: true`, line length 30, and input is `final total = subtotal + shipping + tax - discount;`
- **THEN** output is `final total = subtotal\n    + shipping\n    + tax\n    - discount;`

#### Scenario: Preset placement
- **WHEN** the `dart` preset formats `call(date: formatterFactory.create().format(value.toLocal()));` and `final total = subtotal + shipping + tax - discount;` at line length 30
- **THEN** `formatterFactory` stays on the `date:` line and `subtotal` moves to the line after `=`, as before this change

#### Scenario: Short expression is not moved
- **WHEN** `break_after_prefix: true` on either list and the expression fits on the prefix line
- **THEN** it stays on the prefix line

### Requirement: Continuation base

A wrapped chain's or binary expression's continuation lines SHALL be offset by its list's `indent` from the base its `indent_from` names. `line`: the indentation of the line the expression starts on, except that an expression moved after a prefix keeps its continuation lines in its first item's column. `target`: the column where the chain's target or the first operand starts. Preset `dart`: `line` on both lists.

#### Scenario: Chain after a named argument, target base
- **WHEN** `wrap.chained_calls.indent_from: target`, `indent` resolves to 4, and the chain in `date: formatterFactory.create().format(value.toLocal())` chops
- **THEN** `.create()` and `.format(` start 4 columns right of the column where `formatterFactory` starts

#### Scenario: Chain after a named argument, line base
- **WHEN** `wrap.chained_calls.indent_from: line`, `indent` resolves to 4, and the same chain chops
- **THEN** `.create()` and `.format(` start 4 columns right of the indentation of the `date:` line, as before this change

#### Scenario: Moved chain, line base
- **WHEN** `wrap.chained_calls.break_after_prefix: true`, `indent_from: line`, and a chain after `date:` moves and chops
- **THEN** the target starts at the continuation indent and every call starts in the target's column

#### Scenario: Moved chain, target base
- **WHEN** `wrap.chained_calls.break_after_prefix: true`, `indent_from: target`, `indent: 2`, and a chain after `date:` moves and chops
- **THEN** the target starts at the continuation indent and every call starts 2 columns right of the target

#### Scenario: Moved binary expression, target base
- **WHEN** `wrap.binary_expressions.indent_from: target`, `indent` resolves to 4, `wrap.break_before.binary_operator: true`, line length 30, and input is `final total = subtotal + shipping + tax - discount;`
- **THEN** output is `final total =\n    subtotal\n        + shipping\n        + tax\n        - discount;`

#### Scenario: Binary expression after `return`, target base
- **WHEN** `wrap.binary_expressions.indent_from: target`, `indent` resolves to 4, `wrap.break_before.binary_operator: true`, line length 30, and input is `return subtotal + shipping + tax;`
- **THEN** `+ shipping` and `+ tax` start 4 columns right of the column where `subtotal` starts

#### Scenario: Broken chain target falls back to the line base
- **WHEN** `wrap.chained_calls.indent_from: target` and the chain's target itself prints on more than one line
- **THEN** the calls are offset from the line's indentation, as with `line`

#### Scenario: Alignment takes precedence
- **WHEN** a list has `align: true` and `indent_from: target`
- **THEN** its continuation lines use the alignment column and `indent_from` has no effect

## MODIFIED Requirements

### Requirement: Continuation indent

Wrapped continuation lines of an expression SHALL be indented by `indent.continuation` spaces beyond the statement's indentation, except where alignment applies or a list's `indent_from: target` measures from its target instead. A list with an `indent` field SHALL use its effective value as the baseline offset of its broken items; `inherit` resolves to `indent.continuation` for chained calls and binary expressions and to `indent.size` for the other lists. The numeric indent SHALL NOT be added on top of an alignment column.

#### Scenario: Continuation of an assignment
- **WHEN** `indent.continuation: 4` and `final x = someLongExpression;` wraps after `=`
- **THEN** the second line is indented 4 spaces more than `final`

#### Scenario: Per-construct chain indent
- **WHEN** `indent.continuation: 4`, `wrap.chained_calls.indent: 2` and a chain chops
- **THEN** each call line is indented 2 spaces more than the statement

### Requirement: Binary expression alignment

With `wrap.binary_expressions.align: true`, preset `false`, continuation lines of a wrapped binary expression SHALL align under its first operand wherever the expression occurs; with `false` they SHALL be offset by `wrap.binary_expressions.indent` from the base `indent_from` names. The column is wherever the first operand landed: with `break_after_prefix: true` (the preset), the right-hand side of `=` moves to its own line before the operands wrap, so the aligned and the `line`-based layouts coincide there.

#### Scenario: Aligned operands
- **WHEN** `wrap.binary_expressions.align: true`, line length 30, and input is `return subtotal + shipping + tax;`
- **THEN** `shipping +` and `tax;` start in the column of `subtotal`

#### Scenario: After an assignment
- **WHEN** `wrap.binary_expressions.align: true`, line length 30, and input is `final total = subtotal + shipping + tax - discount;`
- **THEN** the right-hand side starts on its own line at the continuation indent and every operand starts in that column, the same output as with `false`
