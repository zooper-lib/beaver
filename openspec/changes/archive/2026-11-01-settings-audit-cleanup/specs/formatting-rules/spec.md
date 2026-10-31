# Spec Delta

## ADDED Requirements

### Requirement: Opening bracket placement

Each delimiter-owning list (`arguments`, `parameters`, `collection_literals`, `enum_values`) SHALL have a `break_after_open_bracket` field (`true` | `false` | `inherit`, global `wrap.break_after_open_bracket` preset `true`). When the list breaks, `true` SHALL start the first item on a new line after the opening bracket and `false` SHALL keep the first item on the bracket's line. The field SHALL be obeyed whatever the policy and `indent` value.

#### Scenario: First item on a new line
- **WHEN** `wrap.arguments.break_after_open_bracket: true`, line length 40 and input is `print(firstArgument, secondArgument, third);`
- **THEN** output is `print(\n  firstArgument,\n  secondArgument,\n  third,\n);`

#### Scenario: First item stays on the bracket line
- **WHEN** `wrap.arguments.break_after_open_bracket: false`, `break_before_close_bracket: true`, `indent: inherit` and the same input
- **THEN** output is `print(firstArgument,\n  secondArgument,\n  third,\n);`

#### Scenario: Independent of alignment
- **WHEN** `wrap.arguments.break_after_open_bracket: true` and `wrap.arguments.indent: first_item`
- **THEN** the first item starts a new line and, having nothing beside it to align to, the items use the `inherit` indent

### Requirement: Source break next to a bracket follows the bracket fields

A source line break directly after an opening bracket or directly before a closing bracket SHALL follow `break_after_open_bracket` and `break_before_close_bracket` and SHALL NOT be kept by `keep_existing_line_breaks`, which governs only the gaps between items.

#### Scenario: Break after the bracket is not kept
- **WHEN** `wrap.arguments.break_after_open_bracket: false`, `keep_existing_line_breaks: true` and input is `print(\n    first, second, third);` fitting on one line
- **THEN** output is `print(first, second, third);`

#### Scenario: Break between items is kept
- **WHEN** `wrap.arguments.break_after_open_bracket: false`, `break_before_close_bracket: false`, `keep_existing_line_breaks: true` and input is `print(first,\n    second, third);`
- **THEN** output is `print(first,\n  second, third);`

#### Scenario: Preset keeps today's output
- **WHEN** the preset applies (`break_after_open_bracket: true`) and input is `print(\n    first, second, third);`
- **THEN** the break after `(` is kept, as before this change

## MODIFIED Requirements

### Requirement: Wrap policy values

Each wrappable construct (`arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions`, `class_header`) SHALL accept a policy of `never`, `fill` or `chop_if_long` in its `policy` field. A construct is too long when, printed on one line, it would exceed `line_length`; this is the only width condition and is never about the number of items. `never` leaves the construct as written; `fill` puts as many items per line as fit when too long; `chop_if_long` puts every item on its own line when too long. Chopping regardless of width is expressed with `chop_from` only.

#### Scenario: chop_if_long fits
- **WHEN** `wrap.arguments: chop_if_long` and `foo(a, b, c);` fits in the line width
- **THEN** output is `foo(a, b, c);`

#### Scenario: chop_if_long overflows
- **WHEN** `wrap.arguments: chop_if_long` and the call exceeds the line width
- **THEN** every argument is on its own line, indented one level, with the closing parenthesis on its own line

#### Scenario: if_long overflows
- **WHEN** `wrap.binary_expressions: fill` (alias `if_long`) and an expression of eight operands exceeds the width
- **THEN** operands are packed as many per line as fit, continuing on the next line

#### Scenario: fill item that does not fit
- **WHEN** `wrap.arguments: fill` and one argument does not fit on the current line
- **THEN** that argument starts a new line; an argument that is itself too long gets a line of its own and breaks inside if it can

#### Scenario: chop_always fits
- **WHEN** `wrap.parameters: {policy: chop_if_long, chop_from: 1}` and `void f(int a, int b) {}` fits
- **THEN** each parameter is still on its own line

#### Scenario: never overflows
- **WHEN** `wrap.arguments: never` and the call exceeds the width
- **THEN** all arguments stay on one line, overflowing the width

### Requirement: Preserved line breaks are never removed

With `keep_existing_line_breaks: true` in effect for a construct, a newline the developer placed between items of that construct SHALL be preserved in the output; the formatter adds breaks where a line is too long but never removes a break typed between items. A newline directly after the opening bracket or before the closing bracket follows the bracket fields instead. Only a construct whose policy is `never` SHALL remove a break between items. Each list SHALL use its own effective `keep_existing_line_breaks`, which falls back to `wrap.keep_existing_line_breaks`.

#### Scenario: Break kept when the construct fits
- **WHEN** input is `foo(a,\n    b, c);`, the call fits on one line, and `wrap.arguments: chop_if_long`
- **THEN** output keeps `a,` on its own line and `b, c` together on the next line, with the closing parenthesis on its own line

#### Scenario: never removes developer breaks
- **WHEN** the same input is formatted with `wrap.arguments: never`
- **THEN** output is `foo(a, b, c);`

#### Scenario: fill flows in runs after a kept break
- **WHEN** input is `function(first,\n    second, third, fourth, fifth);`, `wrap.arguments: fill` and the call fits in 40 columns
- **THEN** output is `function(\n  first,\n  second, third, fourth, fifth,\n);`

#### Scenario: Collections keep breaks, arguments do not
- **WHEN** `wrap.collection_literals.keep_existing_line_breaks: true`, `wrap.arguments.keep_existing_line_breaks: false`, and input is `const corners = [\n  Offset(0, 0), Offset(1, 0),\n  Offset(0, 1), Offset(1, 1),\n];`
- **THEN** the list keeps two offsets per line and each `Offset(...)` call stays on one line

#### Scenario: Per-construct normalisation
- **WHEN** `wrap.collection_literals.keep_existing_line_breaks: false` and the same input
- **THEN** each offset is on its own line

### Requirement: Chained call wrapping

`wrap.chained_calls.policy` SHALL apply to method chains. A chain with at least `chop_from` calls (alias `min_calls`) SHALL be chopped (one call per line) regardless of width, unless the policy is `never`; with fewer calls, the policy and width decide. There SHALL be no separate key for keeping a short chain on one line: a chain below the threshold that fits stays on one line under `fill` and `chop_if_long`; `chop_from: 2` chops every chain of two or more calls.

#### Scenario: Chain reaches min_calls
- **WHEN** `min_calls: 3` and input is `a.b().c().d();` fitting on one line
- **THEN** `.c()` and `.d()` are each on their own line

#### Scenario: Short chain fits
- **WHEN** `min_calls: 3` and input is `a.b().c();` fitting on one line
- **THEN** output is on one line

#### Scenario: Canonical threshold
- **WHEN** `wrap.chained_calls.chop_from: 3` and input is `a.b().c().d();` fitting on one line
- **THEN** `.c()` and `.d()` are each on their own line

#### Scenario: Every chain chopped
- **WHEN** `wrap.chained_calls.chop_from: 2` and input is `final a = x.b().c();` fitting on one line
- **THEN** output is `final a = x\n    .b()\n    .c();`

#### Scenario: fill on a chain
- **WHEN** `wrap.chained_calls: fill`, line length 60 and input is `final names = users.where((u) => u.active).map((u) => u.name).toList();`
- **THEN** output is `final names = users.where((u) => u.active)\n    .map((u) => u.name).toList();`

### Requirement: Continuation indent

Wrapped continuation lines of an expression SHALL be indented by `indent.continuation` spaces beyond the statement's indentation, except where a list's `indent` says otherwise. A list's `indent` field SHALL accept `inherit`, an integer, or `first_item` where offered. `inherit` resolves to `indent.continuation` for chained calls and binary expressions and to `indent.size` for the other lists. An integer is that many columns from the base `indent_from` names. `first_item` aligns the items under the first item's column when the first item shares a line with what precedes it; otherwise `inherit` applies. `indent_from` applies to the integer values only.

#### Scenario: Continuation of an assignment
- **WHEN** `indent.continuation: 4` and `final x = someLongExpression;` wraps after `=`
- **THEN** the second line is indented 4 spaces more than `final`

#### Scenario: Per-construct chain indent
- **WHEN** `indent.continuation: 4`, `wrap.chained_calls.indent: 2` and a chain chops
- **THEN** each call line is indented 2 spaces more than the statement

#### Scenario: Three values side by side
- **WHEN** `wrap.arguments.break_after_open_bracket: false`, `break_before_close_bracket: false`, line length 40 and input is `print(firstArgument, secondArgument, third);`
- **THEN** with `indent: inherit` the later items are indented 2 from the line, with `indent: 4` they are indented 4, and with `indent: first_item` they start in the column of `firstArgument`

#### Scenario: indent_from ignored under first_item
- **WHEN** `wrap.chained_calls.indent: first_item` and `wrap.chained_calls.indent_from: target`
- **THEN** `indent_from` has no parent and is ignored; the calls align under the first call or use `inherit`

### Requirement: Alignment precedence

Alignment SHALL be requested only through `indent: first_item` (aliases `align: true`, `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls`); there SHALL be no separate `align` field that overrides `indent`. With `first_item`, wrapped items SHALL align to the column where the first item starts when the first item shares a line with what precedes it (the opening bracket, or the chain's receiver) in the output; otherwise they SHALL use the `inherit` indent. The column SHALL be the first item's resolved output column, including enclosing indentation and alignment. Alignment SHALL NOT be suppressed because aligned lines overflow `line_length`, and SHALL NOT move the brackets.

#### Scenario: Flat anchor aligns
- **WHEN** `wrap.chained_calls.indent: first_item`, `keep_first_call_on_receiver_line: true` and input is `final r = obj.doThis().thenThat();` wrapping after `.doThis()`
- **THEN** `.thenThat()` starts in the column of the first `.`

#### Scenario: Broken anchor falls back
- **WHEN** `wrap.chained_calls.indent: first_item` and the first call breaks onto its own line
- **THEN** subsequent calls are indented by `indent.continuation`

#### Scenario: Overflow does not disable alignment
- **WHEN** `wrap.chained_calls.indent: first_item` and aligned calls exceed `line_length`
- **THEN** they are still aligned

#### Scenario: Aligned arguments
- **WHEN** `wrap.arguments.indent: first_item`, `break_after_open_bracket: false`, `break_before_close_bracket: false` and `print(first, second, third);` wraps
- **THEN** output is `print(first,\n      second,\n      third);`

#### Scenario: Alignment does not move the brackets
- **WHEN** `wrap.arguments.indent: first_item` with the preset bracket fields (both `true`) and `print(first, second, third);` wraps
- **THEN** `first` starts a new line after `(`, the items use the `inherit` indent and `)` is on its own line

#### Scenario: Nested alignment
- **WHEN** `wrap.arguments.indent: first_item`, `break_after_open_bracket: false` and an aligned argument list inside a block contains another wrapped argument list
- **THEN** the inner items align to the column where the inner list's first item printed

### Requirement: Item threshold forces chopping

`chop_from: N` on a wrappable list SHALL put every item on its own line when the construct contains at least N syntactic items, even when the line fits. It is the only count-based trigger. `0` SHALL disable the trigger and is the preset on every list except `cascades` (2) and `switch_expressions` (1). Policy `never` SHALL suppress it: `chop_from` is a sub-option of `fill` and `chop_if_long` and has no parent under `never`. Otherwise, reaching the threshold SHALL defeat filling, kept groups of items sharing a line and block-argument hugging.

#### Scenario: Short call reaches the threshold
- **WHEN** `wrap.arguments.chop_from: 3` and input is `canvas.drawLine(start, end, paint);` fitting on one line
- **THEN** `start`, `end` and `paint` are each on their own line

#### Scenario: Enum values
- **WHEN** `wrap.enum_values.chop_from: 2` and input is `enum Side { left, right }`
- **THEN** `left` and `right` are each on their own line

#### Scenario: Below the threshold
- **WHEN** `wrap.arguments.chop_from: 4` and `foo(a, b, c);` fits
- **THEN** output is `foo(a, b, c);`

#### Scenario: never suppresses the threshold
- **WHEN** `wrap.arguments.policy: never` and `wrap.arguments.chop_from: 2`
- **THEN** `foo(a, b, c);` stays on one line

#### Scenario: never as a kill switch over an inherited threshold
- **WHEN** a parent file sets `wrap.arguments: {policy: chop_if_long, chop_from: 3}` and the project file sets `wrap.arguments: never`
- **THEN** resolution succeeds and `function(first, second, third, fourth);` is left as written

#### Scenario: Threshold defeats kept groups
- **WHEN** `wrap.arguments.chop_from: 3`, `keep_existing_line_breaks: true` and input is `foo(a,\n    b, c);`
- **THEN** `a`, `b` and `c` are each on their own line

### Requirement: Threshold interaction with each policy

Below the threshold, or with `chop_from: 0`, every other setting SHALL operate as usual and being below the threshold SHALL never force a list onto one line. At or above it, `fill` and `chop_if_long` SHALL chop regardless of width. Chopping SHALL govern only the separators between items; an item may itself span lines.

#### Scenario: if_long at the threshold
- **WHEN** `wrap.arguments.policy: fill`, `chop_from: 3` and `foo(a, b, c);` fits
- **THEN** every argument is on its own line

### Requirement: Closing delimiter placement

`wrap.break_before_close_bracket` SHALL accept `true` or `false`, preset `true`, and each delimiter-owning list map SHALL have a `break_before_close_bracket` field accepting the same values or `inherit`. `true` SHALL put the closing delimiter of a broken list on its own line; `false` SHALL place it after the final item. `trailing_commas` is a sub-option of `break_before_close_bracket: true`: with `false` no optional trailing comma SHALL be added and one in the source SHALL be dropped, under every `trailing_commas` value including `preserve`. A required comma SHALL be kept. With both `break_after_open_bracket: false` and `break_before_close_bracket: false`, a source trailing comma SHALL NOT be a chop request: chopping would leave only breaks next to the brackets, which neither field keeps, so the next run would undo it. The field SHALL be obeyed whatever the policy and `indent` value.

#### Scenario: After last item
- **WHEN** `wrap.arguments.break_before_close_bracket: false` and `canvas.drawLine(start, end, paint);` chops
- **THEN** output is `canvas.drawLine(\n  start,\n  end,\n  paint);`

#### Scenario: Collections keep their own line
- **WHEN** `wrap.arguments.break_before_close_bracket: false` and `wrap.collection_literals.break_before_close_bracket: inherit` with the global preset
- **THEN** a chopped list literal has `]` on its own line

#### Scenario: Source comma dropped under preserve
- **WHEN** `wrap.arguments.break_before_close_bracket: false`, `trailing_commas: preserve` and input is `g(\n  aaa,\n  bbb,\n  ccc,\n);` which does not fit on one line
- **THEN** output is `g(\n  aaa,\n  bbb,\n  ccc);`

#### Scenario: Dropped comma is not a chop request
- **WHEN** `wrap.arguments.break_after_open_bracket: false`, `break_before_close_bracket: false` and input is `f(\n  value,\n);`
- **THEN** output is `f(value);`, and formatting it again gives the same output

#### Scenario: Required comma kept
- **WHEN** `break_before_close_bracket: false` applies to a single positional field record that breaks
- **THEN** output keeps `value,)` with the comma and closer on one line

### Requirement: First chained call on the receiver line

`wrap.chained_calls.keep_first_call_on_receiver_line` SHALL be a list of receiver kinds, preset `[]`; `true` SHALL mean every kind and `false` SHALL mean `[]`. When a chain breaks and the receiver's kind is listed, the first call SHALL stay on the receiver's line and the chain SHALL break before each later call; otherwise the first call SHALL break too. Kinds: `type_names` (an UpperCamelCase identifier, possibly import-prefixed), `identifiers` (any other plain identifier), `this` (`this` or `super`), `calls` (a call result), `properties` (a property path). A receiver of none of these kinds, such as a literal or a parenthesized expression, SHALL break before its first call under every value, including `true`. Arguments are never involved.

#### Scenario: First call kept
- **WHEN** `keep_first_call_on_receiver_line: true` and `final names = users.where((u) => u.active).map((u) => u.name).toList();` chops
- **THEN** output is `final names = users.where((u) => u.active)\n    .map((u) => u.name)\n    .toList();`

#### Scenario: Preset breaks the first call
- **WHEN** the preset applies, line length 60 and input is `final d = DateFormat.yMMMMd().format(invitation.invitedAt.toLocal());`
- **THEN** output is `final d = DateFormat\n    .yMMMMd()\n    .format(invitation.invitedAt.toLocal());`

#### Scenario: Type names only
- **WHEN** `keep_first_call_on_receiver_line: [type_names]`, line length 60 and the inputs are the `DateFormat` chain above and `final names = users.where((u) => u.active).map((u) => u.name).toList();`
- **THEN** output is `final d = DateFormat.yMMMMd()\n    .format(invitation.invitedAt.toLocal());` and `final names = users\n    .where((u) => u.active)\n    .map((u) => u.name)\n    .toList();`

#### Scenario: Import-prefixed type name
- **WHEN** `keep_first_call_on_receiver_line: [type_names]` and the receiver is `intl.DateFormat`
- **THEN** `.yMMMMd()` stays on the receiver's line

#### Scenario: Identifiers only
- **WHEN** `keep_first_call_on_receiver_line: [identifiers]`, line length 60 and the same two inputs
- **THEN** `DateFormat` breaks before `.yMMMMd()` and `users.where((u) => u.active)` stays together

#### Scenario: Kept first call with first_item alignment
- **WHEN** `keep_first_call_on_receiver_line: [type_names]`, `indent: first_item`, line length 60 and the same two inputs
- **THEN** `.format(...)` starts in the column of the `.` of `.yMMMMd()`, and the `users` chain, whose first call broke, uses the continuation indent

### Requirement: Binary expression alignment

With `wrap.binary_expressions.indent: first_item`, continuation lines of a wrapped binary expression SHALL align under its first operand wherever the expression occurs; with `inherit` or an integer they SHALL be offset by that value from the base `indent_from` names. The preset is `inherit`. The column is wherever the first operand landed: with `break_after_prefix: true` (the preset), the right-hand side of `=` moves to its own line before the operands wrap, so the aligned and the `line`-based layouts coincide there.

#### Scenario: Aligned operands
- **WHEN** `wrap.binary_expressions.indent: first_item`, line length 30, and input is `return subtotal + shipping + tax;`
- **THEN** `shipping +` and `tax;` start in the column of `subtotal`

#### Scenario: After an assignment
- **WHEN** `wrap.binary_expressions.indent: first_item`, line length 30, and input is `final total = subtotal + shipping + tax - discount;`
- **THEN** the right-hand side starts on its own line at the continuation indent and every operand starts in that column, the same output as with `inherit`

### Requirement: Trailing comma when chopped

`trailing_commas: add_when_chopped` SHALL add a trailing comma when the list is chopped and remove an optional one otherwise. A list SHALL count as chopped when each of its own items starts a line, whatever caused it; a filled list, or a multi-line item inside a filled list, SHALL NOT count.

#### Scenario: Filled list loses its comma
- **WHEN** `trailing_commas: add_when_chopped`, `wrap.arguments.policy: fill` and an argument list fills across two lines
- **THEN** the last argument has no trailing comma

#### Scenario: Chopped list gets a comma
- **WHEN** `trailing_commas: add_when_chopped` and an argument list chops
- **THEN** the last argument is followed by a comma

### Requirement: Switch expression wrapping

`wrap.switch_expressions` SHALL be a list map over switch expression arms, preset `policy: chop_if_long` with `chop_from: 1`, which chops every switch expression and reproduces the output from before this change byte for byte. Switch expression commas SHALL be preserved exactly as today under every policy.

#### Scenario: Short switch on one line
- **WHEN** `wrap.switch_expressions: {policy: chop_if_long, chop_from: 0}` and `final label = switch (side) { Side.left => 'L', Side.right => 'R' };` fits
- **THEN** output is unchanged

#### Scenario: Preset chops
- **WHEN** the preset applies and the same input
- **THEN** each arm is on its own line

#### Scenario: Preset output unchanged
- **WHEN** the golden corpus is formatted with the preset before and after this change
- **THEN** every switch expression is formatted identically

### Requirement: Initializer list wrapping

`wrap.initializer_lists` SHALL be a list map with `policy` (preset `chop_if_long`), `chop_from`, `keep_existing_line_breaks`, `indent` (preset `first_item`; `inherit` falls back to `indent.size`) and `colon`. The offset of `indent` (under `first_item`, its `inherit` value) SHALL set the broken list's baseline relative to the constructor declaration; `first_item` SHALL align later initializers under the first; `inherit` or an integer SHALL indent them by that offset from the baseline.

#### Scenario: Chop always with the preset
- **WHEN** `wrap.initializer_lists.chop_from: 1` and input is `Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';`
- **THEN** output is `Point(this.x, this.y)\n  : _len = sqrt(x * x + y * y),\n    _label = '$x,$y';`

#### Scenario: Short list stays inline
- **WHEN** the preset applies and `Point(this.x) : y = 0;` fits
- **THEN** output is unchanged

### Requirement: Initializer list colon placement

`wrap.initializer_lists.colon` SHALL accept `auto`, `new_line` or `end_of_header`, preset `auto`. `auto` SHALL place the colon on a new line unless the parameter list split, in which case it follows the closing parenthesis. `new_line` and `end_of_header` SHALL select their position whenever the list breaks. An unbroken list SHALL stay inline under all three.

#### Scenario: End of header without alignment
- **WHEN** `chop_from: 1`, `colon: end_of_header`, `indent: inherit` and input is `Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';`
- **THEN** output is `Point(this.x, this.y) :\n    _len = sqrt(x * x + y * y),\n    _label = '$x,$y';`

#### Scenario: Auto after a split parameter list
- **WHEN** `colon: auto` and the constructor's parameter list split
- **THEN** the colon follows the closing parenthesis as `) : first = value,` and later initializers align under `first`

### Requirement: Block-argument hugging

`wrap.arguments.hug_block_argument` SHALL be a boolean, preset `true`, with no global and no `inherit`. When `true`, Beaver MAY hug exactly one eligible block argument at any position. When `false`, the argument list SHALL use its ordinary policy, break preservation, alignment and chop settings, and SHALL NOT be forced to chop.

#### Scenario: Hugging enabled
- **WHEN** `hug_block_argument: true` and input is `test('adds', () { expect(add(1, 2), 3); });`
- **THEN** output is `test('adds', () {\n  expect(add(1, 2), 3);\n});`

#### Scenario: Hugging disabled
- **WHEN** `hug_block_argument: false` and the same input
- **THEN** `'adds'` and the function expression are each on their own line, the closure body indented one level further

#### Scenario: Disabled under if_long
- **WHEN** `hug_block_argument: false`, `wrap.arguments.policy: fill` and a call with a block argument does not fit
- **THEN** the arguments are filled, not chopped

### Requirement: Block-argument eligibility and precedence

An eligible block argument SHALL be a block-bodied function literal, a non-empty list, set or map literal, or a record with more than one field when it is the sole argument; a named argument SHALL be judged by its expression. An `=>` lambda and an empty collection SHALL NOT be eligible. A source trailing comma SHALL prevent hugging. Policy `never`, `indent: first_item`, a named-argument or call-name match and a reached threshold (including `chop_from: 1`) SHALL take precedence.

#### Scenario: Arrow lambda not hugged
- **WHEN** `hug_block_argument: true` and the only block-like argument is `(x) => x + 1`
- **THEN** it is laid out like any other argument

#### Scenario: Trailing comma prevents hugging
- **WHEN** `hug_block_argument: true`, `chop_on_trailing_comma: false` and input is `test('adds', () { x(); },);`
- **THEN** the closure is not hugged

### Requirement: Continuation base

A wrapped chain's or binary expression's continuation lines SHALL be offset by its list's `indent` from the base its `indent_from` names. `line`: the indentation of the line the expression starts on, except that an expression moved after a prefix keeps its continuation lines in its first item's column. `target`: the column where the chain's target or the first operand starts. `indent_from` is a sub-option of an integer or `inherit` value of `indent` and SHALL have no effect under `first_item`. Preset `dart`: `line` on both lists.

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
- **WHEN** a list has `indent: first_item` and `indent_from: target`
- **THEN** its continuation lines use the alignment column, or the `inherit` offset from the line when nothing precedes the first item, and `indent_from` has no effect
