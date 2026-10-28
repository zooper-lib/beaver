# Spec Delta

## Purpose

Defines the observable effect of every `.beaver.yaml` formatting rule on Dart source: wrapping, line-break preservation, trailing commas, indentation and alignment, spacing, blank lines, braces and string quotes.

## ADDED Requirements

### Requirement: Wrap policy values
Each wrappable construct (`arguments`, `parameters`, `collection_literals`, `binary_expressions`, `conditional_expressions`, `chained_calls`) SHALL accept a policy of `never`, `if_long`, `chop_if_long` or `chop_always`. `never` keeps all items on one line; `if_long` fills as many items per line as fit; `chop_if_long` puts every item on its own line only when the construct exceeds `line_length`; `chop_always` puts every item on its own line regardless of width.

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
With `keep_existing_line_breaks: true`, a newline the developer placed between items of a wrappable construct, or directly after its opening bracket, SHALL be preserved in the output. Only a construct whose policy is `never` SHALL remove such a newline.

#### Scenario: Break kept when the construct fits
- **WHEN** input is `foo(a,\n    b, c);`, the call fits on one line, and `wrap.arguments: chop_if_long`
- **THEN** output keeps `a,` on its own line and `b, c` together on the next line, with the closing parenthesis on its own line

#### Scenario: never removes developer breaks
- **WHEN** the same input is formatted with `wrap.arguments: never`
- **THEN** output is `foo(a, b, c);`

### Requirement: Preserved breaks do not expand siblings
A preserved newline SHALL NOT by itself cause other items in the same construct to break. Additional breaks between siblings SHALL be added only when the construct exceeds `line_length`, according to its policy.

#### Scenario: Sibling items stay together
- **WHEN** input is `foo(a,\n    b, c);` and the call fits
- **THEN** `b` and `c` remain on the same line

#### Scenario: Overflow still chops everything
- **WHEN** input is `foo(a,\n    b, c);` and the call exceeds the width with `chop_if_long`
- **THEN** `a`, `b` and `c` are each on their own line

### Requirement: Statement and member newlines are not wrap decisions
Newlines between statements and between class members SHALL always be preserved as line breaks and governed by `blank_lines`, independent of `keep_existing_line_breaks`.

#### Scenario: Two statements stay on two lines
- **WHEN** input has `a();\nb();` and `keep_existing_line_breaks: false`
- **THEN** output still has `a();` and `b();` on separate lines

### Requirement: Trailing comma policy
`trailing_commas` SHALL accept `preserve`, `remove` or `add_when_wrapped`. `add_when_wrapped` adds a trailing comma when the last item is followed by a line break in the output and removes it otherwise; `remove` never emits an optional trailing comma; `preserve` leaves the source comma presence unchanged.

#### Scenario: add_when_wrapped on a broken list
- **WHEN** `trailing_commas: add_when_wrapped` and an argument list breaks
- **THEN** the last argument is followed by a comma

#### Scenario: add_when_wrapped on a flat list
- **WHEN** `trailing_commas: add_when_wrapped` and `foo(a, b,)` fits on one line with no preserved breaks and `chop_on_trailing_comma: false`
- **THEN** output is `foo(a, b)`

#### Scenario: remove on a broken list
- **WHEN** `trailing_commas: remove` and an argument list breaks
- **THEN** the last argument has no trailing comma and the closing parenthesis is still on its own line

### Requirement: Required trailing commas are never removed
A trailing comma that is syntactically required (single-positional-field record literal, record type, or record pattern) SHALL be emitted unchanged under every `trailing_commas` value.

#### Scenario: Single-field record under remove
- **WHEN** `trailing_commas: remove` and the input contains `final r = (42,);`
- **THEN** output contains `(42,)`

### Requirement: A source trailing comma is a chop request
With `chop_on_trailing_comma: true`, a trailing comma present in the source SHALL force that construct to put every item on its own line, regardless of width. The comma's presence in the output is then decided by `trailing_commas`. With `chop_on_trailing_comma: false`, a source comma has no layout effect.

#### Scenario: Flutter idiom
- **WHEN** input is `Padding(padding: p, child: Text('hi'),)` on one line and `chop_on_trailing_comma: true`
- **THEN** output places `padding: p,` and `child: Text('hi'),` on their own lines

#### Scenario: Chop with remove
- **WHEN** the same input is formatted with `trailing_commas: remove`
- **THEN** the arguments are still chopped and the last one has no comma

#### Scenario: Disabled
- **WHEN** the same input is formatted with `chop_on_trailing_comma: false` and it fits
- **THEN** output is on one line

### Requirement: Named-argument-triggered expansion
`wrap.chop_on_named_arguments` SHALL be a list of argument names, empty by default. An invocation whose direct argument list contains a named argument with a listed name SHALL have that argument list fully chopped. Nested invocations and nested collection literals SHALL be judged on their own; matching ignores the callee's name and type. `wrap.arguments: never` SHALL take precedence.

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
`wrap.chained_calls.policy` SHALL apply to method chains. A chain with at least `min_calls` calls SHALL be chopped (one call per line) regardless of width; with fewer calls, the policy and width decide. `keep_single_line_if_fits: true` SHALL keep a chain with fewer than `min_calls` calls on one line when it fits.

#### Scenario: Chain reaches min_calls
- **WHEN** `min_calls: 3` and input is `a.b().c().d();` fitting on one line
- **THEN** `.c()` and `.d()` are each on their own line

#### Scenario: Short chain fits
- **WHEN** `min_calls: 3` and input is `a.b().c();` fitting on one line
- **THEN** output is on one line

### Requirement: Operator position when wrapping
With `wrap.before_operator: true`, a wrapped binary expression SHALL start continuation lines with the operator; with `false`, the operator SHALL end the previous line.

#### Scenario: Before operator
- **WHEN** `before_operator: true` and `a + b` wraps
- **THEN** the second line starts with `+ b`

### Requirement: Continuation indent
Wrapped continuation lines of an expression SHALL be indented by `indent.continuation` spaces beyond the statement's indentation, except where alignment applies.

#### Scenario: Continuation of an assignment
- **WHEN** `indent.continuation: 4` and `final x = someLongExpression;` wraps after `=`
- **THEN** the second line is indented 4 spaces more than `final`

### Requirement: Alignment precedence
For each `indent.align.*` rule that is `true`, wrapped items SHALL align to the column where the anchor ends when the anchor (the text before the first wrapped item) is on a single line in the output; otherwise they SHALL use continuation indent. Alignment SHALL NOT be suppressed because aligned lines overflow `line_length`.

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
Each `spaces.*` key SHALL control exactly the whitespace it names: around assignment operators, around binary operators, around `=>`, after and before commas, after the colon in named arguments, inside parentheses, inside brackets, inside braces, before control-flow parentheses, inside empty braces, and after `as`.

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
`blank_lines.max_consecutive` SHALL cap consecutive blank lines; `after_imports`, `between_members`, `before_first_member` and `around_class_declarations` SHALL set the exact number of blank lines at those positions. Blank lines inside a function body up to the cap SHALL be preserved.

#### Scenario: Collapse consecutive blanks
- **WHEN** `max_consecutive: 1` and the input has three blank lines between statements
- **THEN** output has one

#### Scenario: Between members
- **WHEN** `between_members: 1` and two methods are adjacent with no blank line
- **THEN** output has exactly one blank line between them

#### Scenario: Before first member
- **WHEN** `before_first_member: 0` and a class body starts with a blank line
- **THEN** the blank line is removed

### Requirement: Brace placement is whitespace only
`braces.else_on_new_line` SHALL control whether `else` (and `catch`/`finally`) starts a new line after the closing brace. Beaver SHALL never insert or remove braces.

#### Scenario: else on new line
- **WHEN** `else_on_new_line: true`
- **THEN** `} else {` becomes `}\nelse {`

#### Scenario: Braceless if untouched
- **WHEN** input is `if (x) return;`
- **THEN** output remains a braceless statement

### Requirement: String quote style
`strings.quotes` SHALL accept `preserve`, `single` or `double`. `single` and `double` SHALL change the delimiters of simple and interpolated string literals only when the literal's value is unchanged, adjusting escapes as needed; raw strings and literals whose conversion would require escaping the new delimiter inside the value SHALL be left unchanged.

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
