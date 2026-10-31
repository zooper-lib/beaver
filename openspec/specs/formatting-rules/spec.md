# formatting-rules Specification

## Purpose

Defines the observable effect of every `.beaver.yaml` formatting rule on Dart source: wrapping, line-break preservation, trailing commas, indentation and alignment, spacing, blank lines, braces and string quotes.

## Requirements

### Requirement: Wrap policy values

Each wrappable construct (`arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions`, `class_header`) SHALL accept a policy of `never`, `if_long`, `chop_if_long` or `chop_always` in its `policy` field. `never` keeps all items on one line; `if_long` fills as many items per line as fit; `chop_if_long` puts every item on its own line only when the construct exceeds `line_length`; `chop_always` puts every item on its own line regardless of width.

#### Scenario: chop_if_long fits
- **WHEN** `wrap.arguments: chop_if_long` and `foo(a, b, c);` fits in the line width
- **THEN** output is `foo(a, b, c);`

#### Scenario: chop_if_long overflows
- **WHEN** `wrap.arguments: chop_if_long` and the call exceeds the line width
- **THEN** every argument is on its own line, indented one level, with the closing parenthesis on its own line

#### Scenario: if_long overflows
- **WHEN** `wrap.binary_expressions: if_long` and an expression of eight operands exceeds the width
- **THEN** operands are packed as many per line as fit, continuing on the next line

#### Scenario: chop_always fits
- **WHEN** `wrap.parameters: chop_always` and `void f(int a, int b) {}` fits
- **THEN** each parameter is still on its own line

#### Scenario: never overflows
- **WHEN** `wrap.arguments: never` and the call exceeds the width
- **THEN** all arguments stay on one line, overflowing the width

### Requirement: Preserved line breaks are never removed

With `keep_existing_line_breaks: true` in effect for a construct, a newline the developer placed between items of that construct, or directly after its opening bracket, SHALL be preserved in the output. Only a construct whose policy is `never` SHALL remove such a newline. Each list SHALL use its own effective `keep_existing_line_breaks`, which falls back to `wrap.keep_existing_line_breaks`.

#### Scenario: Break kept when the construct fits
- **WHEN** input is `foo(a,\n    b, c);`, the call fits on one line, and `wrap.arguments: chop_if_long`
- **THEN** output keeps `a,` on its own line and `b, c` together on the next line, with the closing parenthesis on its own line

#### Scenario: never removes developer breaks
- **WHEN** the same input is formatted with `wrap.arguments: never`
- **THEN** output is `foo(a, b, c);`

#### Scenario: Collections keep breaks, arguments do not
- **WHEN** `wrap.collection_literals.keep_existing_line_breaks: true`, `wrap.arguments.keep_existing_line_breaks: false`, and input is `const corners = [\n  Offset(0, 0), Offset(1, 0),\n  Offset(0, 1), Offset(1, 1),\n];`
- **THEN** the list keeps two offsets per line and each `Offset(...)` call stays on one line

#### Scenario: Per-construct normalisation
- **WHEN** `wrap.collection_literals.keep_existing_line_breaks: false` and the same input
- **THEN** each offset is on its own line

### Requirement: Preserved breaks do not expand siblings

A preserved newline SHALL NOT by itself cause other items in the same construct to break. Additional breaks between siblings SHALL be added only when the construct exceeds `line_length`, according to its policy.

#### Scenario: Sibling items stay together
- **WHEN** input is `foo(a,\n    b, c);` and the call fits
- **THEN** `b` and `c` remain on the same line

#### Scenario: Overflow still chops everything
- **WHEN** input is `foo(a,\n    b, c);` and the call exceeds the width with `chop_if_long`
- **THEN** `a`, `b` and `c` are each on their own line

#### Scenario: Kept break under the dart preset
- **WHEN** input is `foo(a,\n    b, c);`, the call fits, and the `dart` preset applies (`add_when_wrapped`, `chop_on_trailing_comma: true`)
- **THEN** output is `foo(\n  a,\n  b, c,\n);` and formatting it again changes nothing

### Requirement: Statement and member newlines are not wrap decisions

Newlines between statements and between class members SHALL always be preserved as line breaks and governed by `blank_lines`, independent of `keep_existing_line_breaks`.

#### Scenario: Two statements stay on two lines
- **WHEN** input has `a();\nb();` and `keep_existing_line_breaks: false`
- **THEN** output still has `a();` and `b();` on separate lines

### Requirement: Trailing comma policy

`trailing_commas` SHALL accept `preserve`, `remove`, `add_when_wrapped` or `add_when_chopped`. `add_when_wrapped` adds a trailing comma when the last item is followed by a line break in the output and removes it otherwise; `add_when_chopped` adds one only when the list is chopped; `remove` never emits an optional trailing comma; `preserve` leaves the source comma presence unchanged. A list SHALL use its own effective `trailing_commas`, which falls back to the global key.

#### Scenario: add_when_wrapped on a broken list
- **WHEN** `trailing_commas: add_when_wrapped` and an argument list breaks
- **THEN** the last argument is followed by a comma

#### Scenario: add_when_wrapped on a flat list
- **WHEN** `trailing_commas: add_when_wrapped` and `foo(a, b,)` fits on one line with no preserved breaks and `chop_on_trailing_comma: false`
- **THEN** output is `foo(a, b)`

#### Scenario: remove on a broken list
- **WHEN** `trailing_commas: remove` and an argument list breaks
- **THEN** the last argument has no trailing comma and the closing parenthesis is still on its own line

### Requirement: Trailing commas outside optional constructs are kept

`trailing_commas` SHALL apply only to the constructs whose trailing comma is optional per structural verification. In every other construct (for example assert arguments, list, map and object patterns, switch-expression cases) the source comma SHALL be kept as written.

#### Scenario: Assert arguments
- **WHEN** `trailing_commas: remove` and input is `assert(x, 'message',);`
- **THEN** the comma after `'message'` is kept

### Requirement: Required trailing commas are never removed

A trailing comma that is syntactically required (single-positional-field record literal, record type, or record pattern) SHALL be emitted unchanged under every `trailing_commas` value.

#### Scenario: Single-field record under remove
- **WHEN** `trailing_commas: remove` and the input contains `final r = (42,);`
- **THEN** output contains `(42,)`

### Requirement: A source trailing comma is a chop request

With `chop_on_trailing_comma: true` in effect for a construct, a trailing comma present in the source SHALL force that construct to put every item on its own line, regardless of width, unless the construct is mixed (see below). The comma's presence in the output is then decided by the construct's effective `trailing_commas`. With `chop_on_trailing_comma: false`, a source comma has no layout effect. Each list SHALL use its own effective value, which falls back to `wrap.chop_on_trailing_comma`.

#### Scenario: Flutter idiom
- **WHEN** input is `Padding(padding: p, child: Text('hi'),)` on one line and `chop_on_trailing_comma: true`
- **THEN** output places `padding: p,` and `child: Text('hi'),` on their own lines

#### Scenario: Chop with remove
- **WHEN** the same input is formatted with `trailing_commas: remove`
- **THEN** the arguments are still chopped and the last one has no comma

#### Scenario: Disabled
- **WHEN** the same input is formatted with `chop_on_trailing_comma: false` and it fits
- **THEN** output is on one line

#### Scenario: Disabled for arguments only
- **WHEN** `wrap.arguments.chop_on_trailing_comma: false`, the global value is `true`, and input contains `f(a, b,)` and `[1, 2,]` fitting on one line
- **THEN** `f(a, b)` stays on one line and the list literal is chopped

### Requirement: A mixed construct ignores the chop request

A construct is mixed when the source has a newline in at least one of its list-level gaps (after the opening delimiter, between two items, before the closing delimiter) and at least two adjacent items share a line. Newlines inside an item SHALL NOT count. In a mixed construct a source trailing comma SHALL have no layout effect; the line-break rules decide.

#### Scenario: Mixed layout is not chopped
- **WHEN** input is `foo(\n  a, b,\n  c,\n);` and `chop_on_trailing_comma: true`
- **THEN** output is unchanged

#### Scenario: Newlines inside an item do not count
- **WHEN** input is `foo(a, () {\n  x();\n},);` and `chop_on_trailing_comma: true`
- **THEN** `a` and the function expression are each on their own line

#### Scenario: Wrapped output is stable
- **WHEN** a construct is formatted under `add_when_wrapped` and `chop_on_trailing_comma: true` and its output wraps with items sharing a line
- **THEN** formatting the output again changes nothing

### Requirement: Named-argument-triggered expansion

`wrap.chop_on_named_arguments` SHALL be a list of argument names, empty by default. An invocation whose direct argument list contains a named argument with a listed name SHALL have that argument list fully chopped. Nested invocations and nested collection literals SHALL be judged on their own; matching ignores the callee's name and type (callee matching is `wrap.chop_on_calls`). `wrap.arguments.policy: never` SHALL take precedence.

#### Scenario: Matching invocation
- **WHEN** the list is `[child, children]` and input is `Padding(padding: p, child: Text('hi'))`
- **THEN** `Padding(` is chopped and `Text('hi')` stays on one line

#### Scenario: Nested list not expanded
- **WHEN** the list is `[child, children]` and input is `Column(children: [Text('A'), Text('B')])`
- **THEN** `Column(` is chopped and the list literal stays on one line

#### Scenario: Documented false positive
- **WHEN** the list is `[child]` and input is `process(child: value)`
- **THEN** the call is chopped

#### Scenario: Empty list
- **WHEN** the list is empty
- **THEN** no invocation is chopped by this rule

### Requirement: Chained call wrapping

`wrap.chained_calls.policy` SHALL apply to method chains. A chain with at least `chop_from` calls (alias `min_calls`) SHALL be chopped (one call per line) regardless of width, unless the policy is `never`; with fewer calls, the policy and width decide. `keep_single_line_if_fits: true` SHALL keep a chain with fewer than `chop_from` calls on one line when it fits.

#### Scenario: Chain reaches min_calls
- **WHEN** `min_calls: 3` and input is `a.b().c().d();` fitting on one line
- **THEN** `.c()` and `.d()` are each on their own line

#### Scenario: Short chain fits
- **WHEN** `min_calls: 3` and input is `a.b().c();` fitting on one line
- **THEN** output is on one line

#### Scenario: Canonical threshold
- **WHEN** `wrap.chained_calls.chop_from: 3` and input is `a.b().c().d();` fitting on one line
- **THEN** `.c()` and `.d()` are each on their own line

### Requirement: Operator position when wrapping

With `wrap.break_before.binary_operator: true` (alias `wrap.before_operator`), a wrapped binary expression SHALL start continuation lines with the operator; with `false`, the operator SHALL end the previous line.

#### Scenario: Before operator
- **WHEN** `before_operator: true` and `a + b` wraps
- **THEN** the second line starts with `+ b`

### Requirement: Continuation indent

Wrapped continuation lines of an expression SHALL be indented by `indent.continuation` spaces beyond the statement's indentation, except where alignment applies. A list with an `indent` field SHALL use its effective value as the baseline offset of its broken items; `inherit` resolves to `indent.continuation` for chained calls and binary expressions and to `indent.size` for the other lists. The numeric indent SHALL NOT be added on top of an alignment column.

#### Scenario: Continuation of an assignment
- **WHEN** `indent.continuation: 4` and `final x = someLongExpression;` wraps after `=`
- **THEN** the second line is indented 4 spaces more than `final`

#### Scenario: Per-construct chain indent
- **WHEN** `indent.continuation: 4`, `wrap.chained_calls.indent: 2` and a chain chops
- **THEN** each call line is indented 2 spaces more than the statement

### Requirement: Alignment precedence

For each list whose `align` field (aliases `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls`) is `true`, wrapped items SHALL align to the column where the anchor ends when the anchor (the text before the first wrapped item) is on a single line in the output; otherwise they SHALL use continuation indent. The column SHALL be the anchor's resolved output column, including enclosing indentation and alignment. Alignment SHALL NOT be suppressed because aligned lines overflow `line_length`.

#### Scenario: Flat anchor aligns
- **WHEN** `align.chained_calls: true` and input is `final r = obj.doThis().thenThat();` wrapping after `.doThis()`
- **THEN** `.thenThat()` starts in the column of the first `.`

#### Scenario: Broken anchor falls back
- **WHEN** `align.chained_calls: true` and the receiver itself wraps onto multiple lines
- **THEN** subsequent calls are indented by `indent.continuation`

#### Scenario: Overflow does not disable alignment
- **WHEN** `align.chained_calls: true` and aligned calls exceed `line_length`
- **THEN** they are still aligned

#### Scenario: Aligned arguments
- **WHEN** `align.arguments: true` and `print(first, second, third);` wraps
- **THEN** `second` and `third` start in the column of `first`

#### Scenario: Nested alignment
- **WHEN** `align.arguments: true` and an aligned argument list inside a block contains another wrapped argument list
- **THEN** the inner items align to the column where the inner list's first item printed

### Requirement: Switch case indentation

With `indent.switch_cases: true`, `case` and `default` labels SHALL be indented one level inside the switch body; with `false`, they SHALL align with `switch`.

#### Scenario: Indented cases
- **WHEN** `indent.switch_cases: true`
- **THEN** `case 1:` is indented one level under `switch (x) {`

### Requirement: Simple blocks and lambdas on one line

With `simple_blocks_on_one_line: true`, a block containing a single statement SHALL be printed on one line when it fits; with `false`, the body SHALL be on its own line. With `simple_lambdas_on_one_line: true`, a function expression whose body is a single expression or statement SHALL stay on one line when it fits.

#### Scenario: Simple block
- **WHEN** `simple_blocks_on_one_line: true` and input is `if (x) {\n  return;\n}`
- **THEN** output is `if (x) { return; }`

#### Scenario: Simple lambda
- **WHEN** `simple_lambdas_on_one_line: true` and input is `list.map((e) {\n  return e + 1;\n})`
- **THEN** the lambda prints on one line if it fits

### Requirement: Space rules

Each `spaces.*` key SHALL control exactly the whitespace it names: around assignment operators, around binary operators, around `=>`, after and before commas, before and after the colon in named arguments, before and after the colon in map entries, before the colon of an initializer list, before the colon of a switch case, inside parentheses, inside brackets, inside braces, before control-flow parentheses, inside empty braces, after `as`, and before an end-of-line comment.

#### Scenario: Inside braces
- **WHEN** `spaces.inside_braces: true` and input is `{a: 1}`
- **THEN** output is `{ a: 1 }`

#### Scenario: Before control parentheses off
- **WHEN** `spaces.before_control_parentheses: false`
- **THEN** `if (x)` becomes `if(x)`

#### Scenario: Empty braces
- **WHEN** `spaces.in_empty_braces: false` and input is `{ }`
- **THEN** output is `{}`

### Requirement: Blank line rules

`blank_lines.max_consecutive` SHALL cap consecutive blank lines outside function bodies and `max_consecutive_in_code` inside them; `after_imports`, `between_members`, `before_first_member`, `after_last_member`, `at_block_edges` and integer values of `around_class_declarations`, `between_top_level_declarations` and `between_import_groups` SHALL set the number of blank lines at those positions. Blank lines inside a function body up to the cap SHALL be preserved.

#### Scenario: Collapse consecutive blanks
- **WHEN** `max_consecutive: 1` and the input has three blank lines between statements
- **THEN** output has one

#### Scenario: Between members
- **WHEN** `between_members: 1` and two methods are adjacent with no blank line
- **THEN** output has exactly one blank line between them

#### Scenario: Before first member
- **WHEN** `before_first_member: 0` and a class body starts with a blank line
- **THEN** the blank line is removed

### Requirement: Source blank lines kept between grouped members and list items

When `blank_lines.keep_between_non_block_members` is `true`, `between_members` SHALL NOT apply between two adjacent members that both lack a block body (fields, `=>` members, constructors ending in `;`); their source blank lines SHALL be kept up to `max_consecutive`. Blank lines between the items of a list that splits (arguments, parameters, collection elements, enum values) SHALL also be kept up to `max_consecutive`; a list printed on one line drops them.

#### Scenario: Adjacent fields keep their grouping
- **WHEN** `between_members: 1` and two field declarations are adjacent with no blank line
- **THEN** output keeps them adjacent

#### Scenario: Adjacent one-line members keep their grouping
- **WHEN** `between_members: 1` and a constructor ending in `;`, a field and two `=>` getters are adjacent with no blank lines
- **THEN** output keeps them adjacent, and a following method with a block body gets exactly one blank line before it

#### Scenario: Blank lines between items of a split list
- **WHEN** `max_consecutive: 1` and a split list literal has three blank lines between two elements
- **THEN** output has one blank line between them

### Requirement: Brace placement is whitespace only

`braces.else_on_new_line` SHALL control whether `else` starts a new line after the closing brace. `braces.catch_on_new_line`, `braces.finally_on_new_line` and `braces.while_on_new_line` SHALL control the start of a `catch` or `on` handler clause, a `finally` clause and the trailing `while` of a `do` loop, each falling back to `else_on_new_line`. A handler's `on` type SHALL never be split from its `catch`. Beaver SHALL never insert or remove braces.

#### Scenario: else on new line
- **WHEN** `else_on_new_line: true`
- **THEN** `} else {` becomes `}\nelse {`

#### Scenario: Braceless if untouched
- **WHEN** input is `if (x) return;`
- **THEN** output remains a braceless statement

#### Scenario: Finally overrides the fallback
- **WHEN** `else_on_new_line: true`, `finally_on_new_line: false` and input is `try { a(); } catch (e) { b(); } finally { c(); }`
- **THEN** output has `}\ncatch (e) {` and `} finally {`

#### Scenario: On clause moves as a whole
- **WHEN** `catch_on_new_line: true` and input contains `} on FormatException catch (e) {`
- **THEN** output has `}\non FormatException catch (e) {`

#### Scenario: Ordinary while unaffected
- **WHEN** `while_on_new_line: true` and input contains a `while (x) { ... }` statement
- **THEN** its layout is unchanged

### Requirement: String quote style

`strings.quotes` SHALL accept `preserve`, `single` or `double`. `single` and `double` SHALL change the delimiters of simple and interpolated string literals only when the literal's value is unchanged, adjusting escapes as needed; raw strings SHALL be left unchanged, and literals whose conversion would require escaping the new delimiter inside the value SHALL be left unchanged while `strings.quotes_avoid_escapes` is `true`.

#### Scenario: Convert to single
- **WHEN** `strings.quotes: single` and input is `"hello"`
- **THEN** output is `'hello'`

#### Scenario: Conversion would need escapes
- **WHEN** `strings.quotes: single` and input is `"it's"`
- **THEN** output is `"it's"`

#### Scenario: Preserve
- **WHEN** `strings.quotes: preserve`
- **THEN** every string literal keeps its original delimiters

### Requirement: Unformatted-length statements overflow gracefully

When no permitted break can bring a line within `line_length` (for example a single long string literal), the line SHALL overflow rather than be split in a way that changes tokens.

#### Scenario: Long string
- **WHEN** a string literal is longer than `line_length`
- **THEN** it is emitted unchanged on an overflowing line

### Requirement: Item threshold forces chopping

`chop_from: N` on a wrappable list SHALL put every item on its own line when the construct contains at least N syntactic items. `0` SHALL disable the trigger and is the preset everywhere. Policy `never` SHALL suppress it. Otherwise, reaching the threshold SHALL defeat filling, kept groups of items sharing a line, block-argument hugging and `keep_single_line_if_fits`.

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

#### Scenario: Threshold defeats kept groups
- **WHEN** `wrap.arguments.chop_from: 3`, `keep_existing_line_breaks: true` and input is `foo(a,\n    b, c);`
- **THEN** `a`, `b` and `c` are each on their own line

### Requirement: Item counting for the threshold

Items SHALL be counted syntactically per list: a named argument or trailing closure is one argument; a spread or a collection `if` or `for` element is one element; a nested list is counted on its own, even when it fits on one line. Binary operands SHALL be counted within one flattened run of operators of the same precedence, where a parenthesized expression or an expression at another precedence counts as one operand. Chains SHALL count calls as `min_calls` did.

#### Scenario: Collection if counts once
- **WHEN** `wrap.collection_literals.chop_from: 3` and input is `[a, if (x) ...more]`
- **THEN** the list has two elements and is not forced to chop

#### Scenario: Nested list judged on its own
- **WHEN** `wrap.arguments.chop_from: 3` and input is `f(a, g(b, c, d))` fitting on one line
- **THEN** `g(b, c, d)` is chopped and `f(` is not forced to chop by the threshold

#### Scenario: Mixed precedence
- **WHEN** `wrap.binary_expressions.chop_from: 3` and input is `a + b * c`
- **THEN** the `+` run has two operands and is not forced to chop

### Requirement: Threshold interaction with each policy

Below the threshold, or with `chop_from: 0`, every other setting SHALL operate as usual and being below the threshold SHALL never force a list onto one line. At or above it, `if_long`, `chop_if_long` and `chop_always` SHALL chop regardless of width. Chopping SHALL govern only the separators between items; an item may itself span lines.

#### Scenario: if_long at the threshold
- **WHEN** `wrap.arguments.policy: if_long`, `chop_from: 3` and `foo(a, b, c);` fits
- **THEN** every argument is on its own line

### Requirement: Cascade wrapping

`wrap.cascades` SHALL be a list map, preset `policy: chop_if_long`, `chop_from: 2`, `keep_existing_line_breaks: inherit`, `indent: inherit`. Cascade sections SHALL be indented by `wrap.cascades.indent`. Only breaks between the receiver and the first section and between sections SHALL count as cascade-level breaks; newlines inside the receiver or a section SHALL NOT.

#### Scenario: Two sections chop under the preset
- **WHEN** input is `final p = Paint()..color = Colors.red..strokeWidth = 2;`
- **THEN** output is `final p = Paint()\n  ..color = Colors.red\n  ..strokeWidth = 2;`

#### Scenario: Threshold disabled
- **WHEN** `wrap.cascades.chop_from: 0` and the same input fits
- **THEN** output is `final p = Paint()..color = Colors.red..strokeWidth = 2;`

#### Scenario: Developer break kept in a one-section cascade
- **WHEN** the preset applies and input is `final p = Paint()\n  ..color = Colors.red;`
- **THEN** output keeps `..color = Colors.red;` on its own line

#### Scenario: Normalisation restored
- **WHEN** `wrap.cascades.keep_existing_line_breaks: false` and the same input fits
- **THEN** output is `final p = Paint()..color = Colors.red;`

#### Scenario: Multi-line collection receiver
- **WHEN** input is a multi-line list literal followed by `..sort();`
- **THEN** `..sort()` stays on the closing bracket's line as `]..sort();`

### Requirement: Initializer list wrapping

`wrap.initializer_lists` SHALL be a list map with `policy` (preset `chop_if_long`), `chop_from`, `keep_existing_line_breaks`, `align` (preset `true`), `indent` (preset `inherit`, fallback `indent.size`) and `colon`. `indent` SHALL set the broken list's baseline relative to the constructor declaration; `align: true` SHALL align later initializers under the first; `align: false` SHALL indent them by the indentation from that baseline.

#### Scenario: Chop always with the preset
- **WHEN** `wrap.initializer_lists.policy: chop_always` and input is `Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';`
- **THEN** output is `Point(this.x, this.y)\n  : _len = sqrt(x * x + y * y),\n    _label = '$x,$y';`

#### Scenario: Short list stays inline
- **WHEN** the preset applies and `Point(this.x) : y = 0;` fits
- **THEN** output is unchanged

### Requirement: Initializer list colon placement

`wrap.initializer_lists.colon` SHALL accept `auto`, `new_line` or `end_of_header`, preset `auto`. `auto` SHALL place the colon on a new line unless the parameter list split, in which case it follows the closing parenthesis. `new_line` and `end_of_header` SHALL select their position whenever the list breaks. An unbroken list SHALL stay inline under all three.

#### Scenario: End of header without alignment
- **WHEN** `policy: chop_always`, `colon: end_of_header`, `align: false` and input is `Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';`
- **THEN** output is `Point(this.x, this.y) :\n    _len = sqrt(x * x + y * y),\n    _label = '$x,$y';`

#### Scenario: Auto after a split parameter list
- **WHEN** `colon: auto` and the constructor's parameter list split
- **THEN** the colon follows the closing parenthesis as `) : first = value,` and later initializers align under `first`

### Requirement: Annotation placement

`wrap.annotations` SHALL accept `own_line`, `same_line` or `preserve`, preset `own_line`, and SHALL govern annotations on declarations. Parameter annotations SHALL keep their current placement under every value.

#### Scenario: Own line
- **WHEN** `wrap.annotations: own_line` and input is `@override void dispose() { super.dispose(); }`
- **THEN** `@override` is on its own line above `void dispose() {`

#### Scenario: Same line
- **WHEN** `wrap.annotations: same_line` and the same input
- **THEN** output starts `@override void dispose() {`

#### Scenario: Preserve
- **WHEN** `wrap.annotations: preserve` and a declaration annotation is on its own line in the source
- **THEN** it stays on its own line

### Requirement: Block-argument hugging

`wrap.arguments.hug_block_argument` SHALL be a boolean, preset `true`, with no global and no `inherit`. When `true`, Beaver MAY hug exactly one eligible block argument at any position. When `false`, the argument list SHALL use its ordinary policy, break preservation, alignment and chop settings, and SHALL NOT be forced to chop.

#### Scenario: Hugging enabled
- **WHEN** `hug_block_argument: true` and input is `test('adds', () { expect(add(1, 2), 3); });`
- **THEN** output is `test('adds', () {\n  expect(add(1, 2), 3);\n});`

#### Scenario: Hugging disabled
- **WHEN** `hug_block_argument: false` and the same input
- **THEN** `'adds'` and the function expression are each on their own line, the closure body indented one level further

#### Scenario: Disabled under if_long
- **WHEN** `hug_block_argument: false`, `wrap.arguments.policy: if_long` and a call with a block argument does not fit
- **THEN** the arguments are filled, not chopped

### Requirement: Block-argument eligibility and precedence

An eligible block argument SHALL be a block-bodied function literal, a non-empty list, set or map literal, or a record with more than one field when it is the sole argument; a named argument SHALL be judged by its expression. An `=>` lambda and an empty collection SHALL NOT be eligible. A source trailing comma SHALL prevent hugging. Policy `never` or `chop_always`, alignment, a named-argument or call-name match and a reached threshold SHALL take precedence.

#### Scenario: Arrow lambda not hugged
- **WHEN** `hug_block_argument: true` and the only block-like argument is `(x) => x + 1`
- **THEN** it is laid out like any other argument

#### Scenario: Trailing comma prevents hugging
- **WHEN** `hug_block_argument: true`, `chop_on_trailing_comma: false` and input is `test('adds', () { x(); },);`
- **THEN** the closure is not hugged

### Requirement: Braceless body placement

`wrap.braceless_bodies` SHALL accept `same_line_if_fits`, `new_line` or `preserve`, preset `same_line_if_fits`, and SHALL govern the single statement of a braceless `if`, `else`, `for` or `while`. `new_line` SHALL put the statement on its own line, indented one level.

#### Scenario: New line
- **WHEN** `wrap.braceless_bodies: new_line` and input is `if (items.isEmpty) return null;`
- **THEN** output is `if (items.isEmpty)\n  return null;`

#### Scenario: Same line if fits
- **WHEN** the preset applies and input is `if (items.isEmpty)\n  return null;`
- **THEN** output is `if (items.isEmpty) return null;`

### Requirement: Simple case bodies on one line

With `wrap.simple_case_bodies_on_one_line: true`, preset `false`, a `case` or `default` whose body is a single statement SHALL be printed on the label's line when it fits.

#### Scenario: Two short cases
- **WHEN** `simple_case_bodies_on_one_line: true` and a switch has `case 200:\n    return ok;` and `case 404:\n    return missing;`
- **THEN** output has `case 200: return ok;` and `case 404: return missing;`

### Requirement: Simple methods on one line

With `wrap.simple_methods_on_one_line: true`, preset `false`, a method or function whose block body holds one statement SHALL keep `{ statement; }` on the declaration line when it fits.

#### Scenario: One-statement method
- **WHEN** `simple_methods_on_one_line: true` and input is `void close() { _controller.close(); }`
- **THEN** output is unchanged

#### Scenario: Disabled
- **WHEN** the preset applies and the same input
- **THEN** output is `void close() {\n  _controller.close();\n}`

### Requirement: Switch expression wrapping

`wrap.switch_expressions` SHALL be a list map over switch expression arms, preset `policy: chop_always`. Switch expression commas SHALL be preserved exactly as today under every policy.

#### Scenario: Short switch on one line
- **WHEN** `wrap.switch_expressions: chop_if_long` and `final label = switch (side) { Side.left => 'L', Side.right => 'R' };` fits
- **THEN** output is unchanged

#### Scenario: Preset chops
- **WHEN** the preset applies and the same input
- **THEN** each arm is on its own line

### Requirement: Control condition layout

`wrap.control_conditions` SHALL accept `continuation` or `block`, preset `continuation`, for a condition that does not fit inside `if`, `while` or `for` parentheses. `continuation` SHALL continue on the next line with continuation indent and keep `)` on the last operand's line. `block` SHALL end the line after `(`, indent the condition one level and put `)` on its own line.

#### Scenario: Block layout
- **WHEN** `wrap.control_conditions: block` and `if (user.isActive && user.hasVerifiedEmail && !user.isSuspended) { grant(); }` does not fit
- **THEN** output is `if (\n  user.isActive &&\n  user.hasVerifiedEmail &&\n  !user.isSuspended\n) {\n  grant();\n}`

#### Scenario: Continuation layout
- **WHEN** the preset applies and the same input does not fit
- **THEN** output is `if (user.isActive &&\n    user.hasVerifiedEmail &&\n    !user.isSuspended) {\n  grant();\n}`

### Requirement: Class header wrapping

`wrap.class_header` SHALL be a list map over the `extends`, `with` and `implements` clauses, preset `policy: chop_if_long`, with a boolean `clauses_on_new_line`, preset `true`. When the header splits and `clauses_on_new_line` is `false`, `extends` SHALL stay on the class name's line.

#### Scenario: Preset at 80 columns
- **WHEN** the preset applies and input is `class HomeScreen extends StatefulWidget with RouteAware implements PreferredSizeWidget {}`
- **THEN** output is `class HomeScreen\n    extends StatefulWidget\n    with RouteAware\n    implements PreferredSizeWidget {}`

#### Scenario: Extends stays with the name
- **WHEN** `wrap.class_header.clauses_on_new_line: false` and the same input
- **THEN** output is `class HomeScreen extends StatefulWidget\n    with RouteAware\n    implements PreferredSizeWidget {}`

### Requirement: Closing delimiter placement

`wrap.close_bracket` SHALL accept `own_line` or `after_last_item`, preset `own_line`, and each delimiter-owning list map SHALL have a `close_bracket` field accepting the same values or `inherit`. `after_last_item` SHALL place the closing delimiter after the final item of a chopped list and SHALL suppress an optional trailing comma. A required comma SHALL be kept.

#### Scenario: After last item
- **WHEN** `wrap.arguments.close_bracket: after_last_item` and `canvas.drawLine(start, end, paint);` chops
- **THEN** output is `canvas.drawLine(\n  start,\n  end,\n  paint);`

#### Scenario: Collections keep their own line
- **WHEN** `wrap.arguments.close_bracket: after_last_item` and `wrap.collection_literals.close_bracket: inherit` with the global preset
- **THEN** a chopped list literal has `]` on its own line

#### Scenario: Required comma kept
- **WHEN** `close_bracket: after_last_item` applies to a single positional field record that breaks
- **THEN** output keeps `value,)` with the comma and closer on one line

### Requirement: Operator break side

`wrap.break_before` SHALL hold four booleans that choose the side of an operator receiving a break when wrapping occurs: `binary_operator` (preset `false`), `conditional_operator` (`true`), `arrow` (`false`) and `assignment` (`false`). They SHALL NOT force wrapping.

#### Scenario: Break before arrow and assignment
- **WHEN** `break_before.arrow: true`, `break_before.assignment: true`, line length 60, and input is `final decoded = jsonDecode(response.body) as Map<String, dynamic>;`
- **THEN** output is `final decoded\n    = jsonDecode(response.body) as Map<String, dynamic>;`

#### Scenario: Preset arrow placement
- **WHEN** the preset applies and an `=>` body does not fit
- **THEN** `=>` ends the declaration line and the body starts the next line

### Requirement: First chained call on the receiver line

With `wrap.chained_calls.keep_first_call_on_receiver_line: true`, preset `false`, a chopped chain SHALL keep its first call on the receiver's line and break before each later call.

#### Scenario: First call kept
- **WHEN** `keep_first_call_on_receiver_line: true` and `final names = users.where((u) => u.active).map((u) => u.name).toList();` chops
- **THEN** output is `final names = users.where((u) => u.active)\n    .map((u) => u.name)\n    .toList();`

### Requirement: Call-name-triggered expansion

`wrap.chop_on_calls` SHALL chop the argument list of any invocation whose callable name matches an entry, case-sensitively and without type resolution. A one-segment entry SHALL match the final or penultimate segment; a longer entry SHALL match the complete suffix. Only the matched invocation's own list SHALL chop; `never` SHALL suppress the trigger.

#### Scenario: Matching callee
- **WHEN** `wrap.chop_on_calls: [Row]` and input is `return Row(children: [a, b]);`
- **THEN** output is `return Row(\n  children: [a, b],\n);`

#### Scenario: Named constructor and prefix
- **WHEN** `wrap.chop_on_calls: [Row]` and input contains `m.Row.center(a)`
- **THEN** that argument list is chopped

#### Scenario: Different identifier
- **WHEN** `wrap.chop_on_calls: [Row]` and input contains `RowFactory(a)` or `Row.center.extra(a)`
- **THEN** neither argument list is chopped by this rule

#### Scenario: Multi-segment entry
- **WHEN** `wrap.chop_on_calls: ['Row.center']` and input contains `Row(a)` and `Other.center(b)`
- **THEN** neither is chopped by this rule

### Requirement: Call name comes from the callable expression

The callable name SHALL be the dotted name of the invoked expression; type arguments SHALL NOT be segments. A computed target such as `callbacks[index](x)` SHALL have no name, and the outer call in `getBuilder()(x)` SHALL NOT borrow the inner call's name. A match SHALL defeat block-argument hugging and kept groups of arguments.

#### Scenario: Computed target
- **WHEN** `wrap.chop_on_calls: [getBuilder]` and input is `getBuilder()(x)`
- **THEN** the outer argument list `(x)` is not chopped by this rule

### Requirement: Binary expression alignment

With `wrap.binary_expressions.align: true`, preset `false`, continuation lines of a wrapped binary expression SHALL align under its first operand wherever the expression occurs; with `false` they SHALL be indented by `wrap.binary_expressions.indent`. The column is wherever the first operand landed: after `=` the right-hand side moves to its own line before the operands wrap, so the aligned and indented layouts coincide there.

#### Scenario: Aligned operands
- **WHEN** `wrap.binary_expressions.align: true`, line length 30, and input is `return subtotal + shipping + tax;`
- **THEN** `shipping +` and `tax;` start in the column of `subtotal`

#### Scenario: After an assignment
- **WHEN** `wrap.binary_expressions.align: true`, line length 30, and input is `final total = subtotal + shipping + tax - discount;`
- **THEN** the right-hand side starts on its own line at the continuation indent and every operand starts in that column, the same output as with `false`

### Requirement: Space before a trailing comment

`spaces.before_trailing_comment` SHALL be an integer, minimum 1, preset 1, setting the number of spaces between code and an end-of-line comment on the same line.

#### Scenario: Two spaces
- **WHEN** `spaces.before_trailing_comment: 2` and input is `final retries = 3;// never more than three`
- **THEN** output is `final retries = 3;  // never more than three`

### Requirement: Colon spacing positions

Each colon position SHALL have its own boolean: `spaces.before_colon_in_named_argument` (preset `false`), `spaces.before_colon_in_map_entry` (`false`), `spaces.after_colon_in_map_entry` (`true`), `spaces.before_colon_in_initializer_list` (`true`) and `spaces.before_colon_in_switch_case` (`false`), alongside the existing `after_colon_in_named_argument`.

#### Scenario: Map entries under the preset
- **WHEN** the preset applies and input is `final m = {'a' : 1, 'b' : 2};`
- **THEN** output is `final m = {'a': 1, 'b': 2};`

#### Scenario: Initializer colon without a space
- **WHEN** `spaces.before_colon_in_initializer_list: false` and input is `Point(this.x) : y = 0;`
- **THEN** output is `Point(this.x): y = 0;`

### Requirement: Blank lines at block edges

`blank_lines.at_block_edges` SHALL be an integer, preset 0, capping the source blank lines kept directly after `{` and before `}` of a function or block body.

#### Scenario: Removed under the preset
- **WHEN** the preset applies and a function body starts and ends with a blank line
- **THEN** both blank lines are removed

#### Scenario: One kept
- **WHEN** `blank_lines.at_block_edges: 1` and the same input
- **THEN** output is unchanged

### Requirement: Blank lines after the last member

`blank_lines.after_last_member` SHALL be an integer, preset 0, setting the exact number of blank lines before a class-like body's closing brace.

#### Scenario: Removed under the preset
- **WHEN** the preset applies and a class body ends with a blank line before `}`
- **THEN** the blank line is removed

### Requirement: Blank lines between import groups

`blank_lines.between_import_groups` SHALL accept `preserve` (preset) or an integer, applied between the `dart:`, `package:` and relative import groups and before `export` and `part` directives. An integer SHALL insert missing blank lines and collapse extra ones to that count. Directives SHALL NOT be reordered.

#### Scenario: One blank line between groups
- **WHEN** `between_import_groups: 1` and input has a `dart:`, a `package:` and a relative import with no blank lines
- **THEN** output has one blank line between each pair of groups

### Requirement: Blank lines between top-level declarations

`blank_lines.between_top_level_declarations` SHALL accept `preserve` (preset) or an integer. At a boundary between two top-level declarations, directive spacing SHALL use its own rules; when either side is class-like and `around_class_declarations` is an integer, that count SHALL apply; otherwise this key SHALL apply, subject to the non-block grouping rule.

#### Scenario: Exact count
- **WHEN** `between_top_level_declarations: 1`, `keep_between_non_block_top_level_declarations: false`, and input is `int counter = 0;\nvoid increment() {\n  counter++;\n}\ntypedef Callback = void Function();`
- **THEN** output has exactly one blank line at each boundary

#### Scenario: Specific beats general
- **WHEN** `around_class_declarations: 2` and `between_top_level_declarations: 1`
- **THEN** two blank lines separate a class from an adjacent function and one separates two functions

#### Scenario: Preserve under the preset
- **WHEN** the preset applies and two block-bodied top-level functions have no blank line between them
- **THEN** output keeps them adjacent

### Requirement: Non-block declarations keep their grouping

`blank_lines.keep_between_non_block_members` and `blank_lines.keep_between_non_block_top_level_declarations` SHALL be booleans, preset `true`. When `true` and both adjacent declarations lack their own block body, their source blank lines SHALL be kept up to the cap. When `false`, the corresponding spacing rule SHALL apply. Lacking a block body SHALL be syntactic, not based on printed line count.

#### Scenario: Uniform member spacing
- **WHEN** `keep_between_non_block_members: false`, `between_members: 1`, and a class has three adjacent field declarations with one blank line before the third
- **THEN** output has exactly one blank line between each pair of fields

#### Scenario: Closure initialiser is not a block body
- **WHEN** `keep_between_non_block_top_level_declarations: true` and a top-level variable initialised with a block-bodied closure is adjacent to another variable
- **THEN** their source blank-line separation is kept

### Requirement: Blank-line cap inside code

`blank_lines.max_consecutive_in_code` SHALL be an integer or `inherit`, preset `inherit` (fallback `blank_lines.max_consecutive`), and SHALL cap consecutive blank lines inside function bodies. `blank_lines.max_consecutive` SHALL continue to cap blank lines elsewhere.

#### Scenario: Different caps
- **WHEN** `max_consecutive: 2`, `max_consecutive_in_code: 1`, and a class has two fields separated by two blank lines and a method body with two blank lines between statements
- **THEN** output keeps two blank lines between the fields (non-block members keep their source spacing up to the cap) and one between the statements

### Requirement: Trailing comma when chopped

`trailing_commas: add_when_chopped` SHALL add a trailing comma when the list is chopped and remove an optional one otherwise. A list SHALL count as chopped when each of its own items starts a line, whatever caused it; a filled list, or a multi-line item inside a filled list, SHALL NOT count.

#### Scenario: Filled list loses its comma
- **WHEN** `trailing_commas: add_when_chopped`, `wrap.arguments.policy: if_long` and an argument list fills across two lines
- **THEN** the last argument has no trailing comma

#### Scenario: Chopped list gets a comma
- **WHEN** `trailing_commas: add_when_chopped` and an argument list chops
- **THEN** the last argument is followed by a comma

### Requirement: Per-construct trailing comma policy

`arguments`, `parameters`, `collection_literals` and `enum_values` SHALL each have a `trailing_commas` field accepting the four global values or `inherit`, preset `inherit`. Records (literals, types and patterns) SHALL follow the global key, and SHALL NOT pick up an argument or parameter override.

#### Scenario: Collections remove, arguments inherit
- **WHEN** `wrap.collection_literals.trailing_commas: remove`, `wrap.collection_literals.chop_on_trailing_comma: false`, `wrap.collection_literals.keep_existing_line_breaks: false`, and input is `const sizes = [\n  8,\n  16,\n  24,\n];`
- **THEN** output is `const sizes = [8, 16, 24];`

#### Scenario: Record follows the global key
- **WHEN** `trailing_commas: add_when_wrapped` and `wrap.arguments.trailing_commas: remove`, and a two-field record literal chops
- **THEN** the last record field is followed by a comma

### Requirement: Quote conversion that would need escapes

`strings.quotes_avoid_escapes` SHALL be a boolean, preset `true`. With `true`, a literal whose conversion to the configured quote would require escaping the new delimiter SHALL keep its delimiters. With `false`, it SHALL be converted, escaping the delimiter inside the value.

#### Scenario: Escapes avoided
- **WHEN** `strings.quotes: single`, `quotes_avoid_escapes: true` and input is `final msg = "don't";`
- **THEN** output is unchanged

#### Scenario: Escapes added
- **WHEN** `strings.quotes: single`, `quotes_avoid_escapes: false` and the same input
- **THEN** output is `final msg = 'don\'t';`
