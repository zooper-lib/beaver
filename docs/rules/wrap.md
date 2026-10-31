# Wrapping rules

Keys under `wrap:` and the top-level `trailing_commas`. Examples are taken verbatim from the golden tests in `packages/zooper_beaver/test/golden/wrap/` and are formatted at 40 columns.

## Policies

The `policy` field of every list map (see [List maps](#list-maps)) takes one of four values:

| Value | Effect |
|---|---|
| `never` | All items on one line, even past `line_length`. Developer line breaks are removed. |
| `if_long` | As many items per line as fit (paragraph fill). |
| `chop_if_long` | Every item on its own line, only when the construct does not fit. |
| `chop_always` | Every item on its own line, always. |

Preset `dart`: `chop_if_long` everywhere except `wrap.switch_expressions` (`chop_always`).

## List maps

Every wrappable list is a map under `wrap:` with the same fields. The scalar shorthand `wrap.<list>: <policy>` is accepted everywhere and sets only `policy`; the long form sets any field:

```yaml
wrap:
  arguments: chop_if_long        # shorthand for arguments.policy
  parameters:
    policy: chop_if_long
    chop_from: 4
    keep_existing_line_breaks: false
```

Each configuration file is normalised to the long form before it is merged with the files it extends, so a shorthand in a project file replaces only the inherited `policy` and keeps an inherited `chop_from`. Setting the same key through two spellings with different values in one file is a configuration error.

| Field | Values | Preset `dart` | On |
|---|---|---|---|
| `policy` | `never` \| `if_long` \| `chop_if_long` \| `chop_always` | `chop_if_long` | every list |
| `chop_from` | integer, `0` disables | `0` | every list |
| `keep_existing_line_breaks` | `true` \| `false` \| `inherit` | `inherit` | every list |
| `chop_on_trailing_comma` | `true` \| `false` \| `inherit` | `inherit` | every list |
| `align` | `true` \| `false` | `false` | `arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `chained_calls`, `initializer_lists` |
| `indent` | integer \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `chained_calls`, `cascades`, `initializer_lists` |
| `close_bracket` | `own_line` \| `after_last_item` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |
| `trailing_commas` | `preserve` \| `remove` \| `add_when_wrapped` \| `add_when_chopped` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |

The lists are `arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions` and `class_header`. A field a list does not offer is a configuration error. `beaver config --template` prints every list with every field.

`inherit` takes the effective value of the field's fallback, resolved after the whole `extends` chain has merged, so it follows a global key overridden in a nearer file. Omitting the field keeps the value the parent file set; writing `inherit` restores the link. The fallbacks:

| Field | Falls back to |
|---|---|
| `keep_existing_line_breaks` | `wrap.keep_existing_line_breaks` |
| `chop_on_trailing_comma` | `wrap.chop_on_trailing_comma` |
| `close_bracket` | `wrap.close_bracket` |
| `trailing_commas` | `trailing_commas` |
| `indent` | `indent.continuation` for `chained_calls` and `binary_expressions`, `indent.size` for the others |
| every field of `enum_values` | the same field of `collection_literals` |

`policy`, `chop_from` and `align` have no global key and do not accept `inherit`, except on `enum_values`, whose fields all follow `collection_literals` so that a configuration customising collection literals keeps its enum layout. `beaver config --print` shows, for an inherited value, both where `inherit` was set and where the value came from.

Record literals, record patterns and record types use the `arguments` (literals, patterns) or `parameters` (types) policy, but always the global `keep_existing_line_breaks`, `chop_on_trailing_comma`, `close_bracket` and `trailing_commas`, never a per-list override.

Every key added after 0.1.0 has a preset value that reproduces the 0.1.0 output, with two deliberate exceptions: `blank_lines.between_comment_and_declaration` is `preserve` ([blank lines](blank_lines.md)) and `wrap.cascades.keep_existing_line_breaks` is `inherit`, which keeps a break typed before a cascade section. `0` and `false` restore the old output.

Aliases, accepted without deprecation and identical to their canonical key:

| Alias | Canonical key |
|---|---|
| `wrap.<list>: <policy>` | `wrap.<list>.policy` |
| `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls` | `wrap.arguments.align`, `wrap.parameters.align`, `wrap.chained_calls.align` |
| `wrap.chained_calls.min_calls` | `wrap.chained_calls.chop_from` |
| `wrap.before_operator` | `wrap.break_before.binary_operator` |

### `never`

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=never`:

```dart
function(firstArgument, secondArgument, third);
```

### `if_long`

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=if_long trailing_commas=remove`:

```dart
function(
  firstArgument, secondArgument, third
);
```

Under the `dart` preset the broken list also gets a trailing comma (`add_when_wrapped`). Items still share lines, so the comma is not a chop request on the next run (see `chop_on_trailing_comma`):

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=if_long`:

```dart
function(
  firstArgument, secondArgument, third,
);
```

Binary expressions have no trailing comma and always fill:

Before:

```dart
value = operandOne + operandTwo + operandThree + four;
```

After with `wrap.binary_expressions=if_long`:

```dart
value =
    operandOne + operandTwo +
    operandThree + four;
```

### `chop_if_long`

Before:

```dart
foo(alpha, beta, gamma);
```

After with `wrap.arguments=chop_if_long`:

```dart
foo(alpha, beta, gamma);
```

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=chop_if_long`:

```dart
function(
  firstArgument,
  secondArgument,
  third,
);
```

A conditional keeps its condition on the line of the `=` (or `=>`, or named argument) when the condition fits there; the `?` and `:` lines get continuation indent, and a branch's own wrapped lines indent past its `? ` or `: `. A conditional in the else branch continues the same chain. When the condition itself does not fit, the line breaks after the `=` instead:

Before:

```dart
value = condition ? whenTrueResult : whenFalseResult;
```

After with `wrap.conditional_expressions=chop_if_long`:

```dart
value = condition
    ? whenTrueResult
    : whenFalseResult;
```

### `chop_always`

Before:

```dart
void f(int a, int b) {}
```

After with `wrap.parameters=chop_always`:

```dart
void f(
  int a,
  int b,
) {}
```

## `wrap.break_before.binary_operator`

Whether a wrapped binary expression puts the operator at the start of the continuation line (`true`) or the end of the previous one (`false`). Preset `dart`: `false`.

Before:

```dart
value = operandOne + operandTwo + operandThree;
```

After with `wrap.break_before.binary_operator=true`:

```dart
value =
    operandOne
    + operandTwo
    + operandThree;
```

Before:

```dart
value = operandOne + operandTwo + operandThree;
```

After with `wrap.break_before.binary_operator=false`:

```dart
value =
    operandOne +
    operandTwo +
    operandThree;
```

## `wrap.chained_calls`

`policy` applies to method chains (two or more calls after a target). A chain with at least `chop_from` calls is chopped regardless of width, unless the policy is `never`; `0` disables this. `keep_single_line_if_fits` keeps a chain with fewer calls on one line when it fits, even under `chop_always`. Preset `dart`: `chop_if_long`, `chop_from: 0`, `keep_single_line_if_fits: true`.

Before:

```dart
a.b().c().d();
```

After with `wrap.chained_calls.chop_from=3`:

```dart
a
    .b()
    .c()
    .d();
```

Before:

```dart
a.b().c();
```

After with `wrap.chained_calls.chop_from=3`:

```dart
a.b().c();
```

Before:

```dart
a.b().c();
```

After with `wrap.chained_calls.policy=chop_always`:

```dart
a.b().c();
```

## `wrap.keep_existing_line_breaks`

A line break the developer placed between items of a wrappable construct, or right after its opening bracket, is kept. Kept breaks never expand their siblings: the items between two kept breaks stay together while they fit. Only `never` removes them. Newlines between statements and members are not affected by this key; see [blank lines](blank_lines.md). Preset `dart`: `true`.

This is the global value. Each list map has its own `keep_existing_line_breaks`, preset `inherit`, so a team can keep breaks in collections and normalise argument lists:

Before:

```dart
const corners = [
  Offset(0, 0), Offset(1, 0),
  Offset(0, 1), Offset(1, 1),
];
```

After with `wrap.collection_literals.keep_existing_line_breaks=false`:

```dart
const corners = [
  Offset(0, 0),
  Offset(1, 0),
  Offset(0, 1),
  Offset(1, 1),
];
```

Before:

```dart
foo(a,
    b, c);
```

After with `trailing_commas=preserve`:

```dart
foo(
  a,
  b, c
);
```

Before:

```dart
foo(firstArgument,
    secondArgument, thirdArgumentEvenLonger);
```

After with `trailing_commas=preserve`:

```dart
foo(
  firstArgument,
  secondArgument,
  thirdArgumentEvenLonger
);
```

Before:

```dart
foo(a,
    b, c);
```

After with `wrap.arguments=never`:

```dart
foo(a, b, c);
```

Under the `dart` preset the kept break breaks the list, so it gets a trailing comma. Items still share a line, so the comma does not chop the list on the next run (see `chop_on_trailing_comma`):

Before:

```dart
foo(a,
    b, c);
```

After:

```dart
foo(
  a,
  b, c,
);
```

Binary expressions, conditionals and chains have no trailing comma, so their kept breaks stay as typed:

Before:

```dart
x = a +
    b + c;
```

After:

```dart
x =
    a +
    b + c;
```

## `trailing_commas`

`preserve` keeps the source's choice, `remove` never prints an optional trailing comma, `add_when_wrapped` prints one exactly when the last item is followed by a line break, `add_when_chopped` only when the list is chopped (every item starts its own line; a filled list, or one whose kept breaks group several items, gets none). Each of `arguments`, `parameters`, `collection_literals` and `enum_values` has its own `trailing_commas` field, preset `inherit`; records always follow this global key. Required commas, such as a single-field record `(42,)`, are never removed. Preset `dart`: `add_when_wrapped`.

Before:

```dart
var list = [firstElement, secondElement, third];
```

After:

```dart
var list = [
  firstElement,
  secondElement,
  third,
];
```

Before:

```dart
foo(a, b,);
```

After with `wrap.chop_on_trailing_comma=false`:

```dart
foo(a, b);
```

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `trailing_commas=remove`:

```dart
function(
  firstArgument,
  secondArgument,
  third
);
```

Before:

```dart
final r = (42,);
```

After with `trailing_commas=remove`:

```dart
final r = (42,);
```

## `wrap.chop_on_trailing_comma`

A trailing comma in the source chops the construct fully, the Flutter "add a comma, save, the tree expands" idiom. With `trailing_commas: remove` the comma still chops and is then removed. Preset `dart`: `true`; `false` gives dart_style's default behaviour.

The exception is a list the source already splits with some items sharing a line: there the existing breaks decide (`keep_existing_line_breaks`) and the comma chops nothing, so adding a comma to such a list does not expand it. Only the list's own line breaks count (after the opening bracket, between items, before the closing bracket), never those inside an item such as a function body. This keeps Beaver's own wrapped output, which gets a trailing comma, stable on the next run.

This is the global value; each list map has its own `chop_on_trailing_comma`, preset `inherit`.

For any list with an optional trailing comma (and for records, on the global keys), `trailing_commas: remove` with `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` in effect for that list is a configuration error: the chop deletes the comma that requested it, and nothing would keep the chopped layout on the next run. The check runs on the effective values after `inherit` is resolved, so a global value can complete a conflict on one list. A list whose policy is `never` or `chop_always` is exempt. Set one of the three differently for that list.

Before:

```dart
foo(a, b,);
```

After:

```dart
foo(
  a,
  b,
);
```

Before:

```dart
foo(a, b,);
```

After with `trailing_commas=remove`:

```dart
foo(
  a,
  b
);
```

Before:

```dart
foo(a, b,);
```

After with `trailing_commas=preserve wrap.chop_on_trailing_comma=false`:

```dart
foo(a, b,);
```

Before:

```dart
foo(
  a, b,
  c,
);
```

After:

```dart
foo(
  a, b,
  c,
);
```

## `wrap.chop_on_named_arguments`

A list of argument names. An invocation whose own argument list contains a named argument with a listed name is chopped. Nested invocations and collections are judged on their own, and the callee's name and type are ignored, so `process(child: value)` matches too. `wrap.arguments: never` wins. Preset `dart`: `[]`.

Before:

```dart
Padding(padding: p, child: Text('hi'));
```

After with `wrap.chop_on_named_arguments=[child,children]`:

```dart
Padding(
  padding: p,
  child: Text('hi'),
);
```

Before:

```dart
Column(children: [Text('A'), Text('B')]);
```

After with `wrap.chop_on_named_arguments=[child,children]`:

```dart
Column(
  children: [Text('A'), Text('B')],
);
```

Before:

```dart
process(child: value);
```

After with `wrap.chop_on_named_arguments=[child]`:

```dart
process(
  child: value,
);
```

## `wrap.simple_blocks_on_one_line` and `wrap.simple_lambdas_on_one_line`

A block holding one statement prints as `{ statement }` when it fits. `simple_blocks_on_one_line` covers control-flow and nested blocks, `simple_lambdas_on_one_line` the block bodies of function expressions; declaration bodies always span lines. Preset `dart`: both `false`.

Before:

```dart
if (x) {
  return;
}
```

After with `wrap.simple_blocks_on_one_line=true`:

```dart
if (x) { return; }
```

Before:

```dart
list.map((e) {
  return e + 1;
});
```

After with `wrap.simple_lambdas_on_one_line=true`:

```dart
list.map((e) { return e + 1; });
```

## `chop_from`

A field of every list map. With `chop_from: N`, a list of at least N items puts every item on its own line, whatever its width; `0` disables this and is the preset everywhere (except `wrap.cascades`, `2`). Policy `never` suppresses it. Otherwise it defeats filling, kept groups of items sharing a line, block-argument hugging and `keep_single_line_if_fits`. Items are counted syntactically per list: a named argument, a closure, a spread or a collection `if`/`for` counts once, and a nested list is counted on its own. Binary operands are counted within one run of operators of the same precedence; a parenthesized expression or one at another precedence is one operand. `wrap.chained_calls.chop_from` counts calls (alias `min_calls`). Examples at 40 columns.

Before:

```dart
canvas.drawLine(start, end, paint);
```

After with `wrap.arguments.chop_from=3`:

```dart
canvas.drawLine(
  start,
  end,
  paint,
);
```

Before:

```dart
x = [a, if (x) ...more];
```

After with `wrap.collection_literals.chop_from=3`:

```dart
x = [a, if (x) ...more];
```

Before:

```dart
x = a + b * c;
```

After with `wrap.binary_expressions.chop_from=3`:

```dart
x = a + b * c;
```

Before:

```dart
enum Side { left, right }
```

After with `wrap.enum_values.chop_from=2`:

```dart
enum Side {
  left,
  right,
}
```

## `wrap.cascades`

A list map for cascade sections (`..`). Preset `dart`: `policy: chop_if_long`, `chop_from: 2` (two or more sections always chop), `keep_existing_line_breaks: inherit` (so a developer's break before a section stays, like in every other list; Beaver 0.1.0 joined it, which `keep_existing_line_breaks: false` restores), `indent: inherit` (`indent.size`). Only a break before a section counts as a cascade-level break: newlines inside the target or a section do not, so a multi-line collection keeps a single section on its closing line (`]..sort()`). Examples at 80 columns.

Before:

```dart
final p = Paint()..color = Colors.red..strokeWidth = 2;
```

After with the preset:

```dart
final p = Paint()
  ..color = Colors.red
  ..strokeWidth = 2;
```

Before:

```dart
final p = Paint()..color = Colors.red..strokeWidth = 2;
```

After with `wrap.cascades.chop_from=0`:

```dart
final p = Paint()..color = Colors.red..strokeWidth = 2;
```

Before:

```dart
final p = Paint()
  ..color = Colors.red;
```

After with `wrap.cascades.keep_existing_line_breaks=true`:

```dart
final p = Paint()
  ..color = Colors.red;
```

Before:

```dart
final list = [
  firstElementWithLongName,
  secondElementWithLongName,
  thirdElement,
]..sort();
```

After with the preset:

```dart
final list = [
  firstElementWithLongName,
  secondElementWithLongName,
  thirdElement,
]..sort();
```

## `wrap.initializer_lists`

A list map for constructor initializer lists. Preset `dart`: `policy: chop_if_long`, `align: true`, `indent: inherit` (`indent.size`), `keep_existing_line_breaks: false`, `colon: auto`. `indent` is the baseline of the broken list relative to the constructor; `align: true` lines later initializers up under the first, `align: false` indents them by `indent` from that baseline. `colon` is `auto` (on a new line, unless the parameter list split: then it follows `)`), `new_line` or `end_of_header`; an unbroken list stays on the header line under all three. Examples at 80 columns.

Before:

```dart
class Point {
  Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';
}
```

After with `wrap.initializer_lists.policy=chop_always`:

```dart
class Point {
  Point(this.x, this.y)
    : _len = sqrt(x * x + y * y),
      _label = '$x,$y';
}
```

After with `wrap.initializer_lists.policy=chop_always wrap.initializer_lists.colon=end_of_header wrap.initializer_lists.align=false`:

```dart
class Point {
  Point(this.x, this.y) :
      _len = sqrt(x * x + y * y),
      _label = '$x,$y';
}
```

After with `wrap.initializer_lists.policy=chop_always wrap.initializer_lists.colon=end_of_header wrap.initializer_lists.align=true`:

```dart
class Point {
  Point(this.x, this.y) :
    _len = sqrt(x * x + y * y),
    _label = '$x,$y';
}
```

Before:

```dart
class Point {
  Point(this.someVeryLongParameterName, this.anotherVeryLongParameterName, this.third) : first = 1, second = 2;
}
```

After with the preset:

```dart
class Point {
  Point(
    this.someVeryLongParameterName,
    this.anotherVeryLongParameterName,
    this.third,
  ) : first = 1,
      second = 2;
}
```

## `wrap.switch_expressions`

A list map over switch expression arms. Preset `dart`: `policy: chop_always`. Arm commas print exactly as in the source under every policy: none is added or removed. Examples at 80 columns.

Before:

```dart
final label = switch (side) { Side.left => 'L', Side.right => 'R' };
```

After with `wrap.switch_expressions=chop_if_long`:

```dart
final label = switch (side) { Side.left => 'L', Side.right => 'R' };
```

After with the preset:

```dart
final label = switch (side) {
  Side.left => 'L',
  Side.right => 'R'
};
```

## `wrap.class_header`

A list map over the `extends`, `with`, `implements` and `on` clauses of a type declaration, plus `clauses_on_new_line`. Preset `dart`: `policy: chop_if_long`, `keep_existing_line_breaks: false`, `clauses_on_new_line: true`. With `clauses_on_new_line: false`, `extends` stays on the name's line when the header splits. A kept break splits the whole header. Examples at 80 columns.

Before:

```dart
class HomeScreen extends StatefulWidget with RouteAware implements PreferredSizeWidget {}
```

After with the preset:

```dart
class HomeScreen
    extends StatefulWidget
    with RouteAware
    implements PreferredSizeWidget {}
```

After with `wrap.class_header.clauses_on_new_line=false`:

```dart
class HomeScreen extends StatefulWidget
    with RouteAware
    implements PreferredSizeWidget {}
```

After with `wrap.class_header=if_long`:

```dart
class HomeScreen extends StatefulWidget with RouteAware
    implements PreferredSizeWidget {}
```

## `wrap.arguments.hug_block_argument`

Whether one block argument may hug the call's parentheses (`f(a, () {` … `})`). Preset `dart`: `true`; no global key and no `inherit`. Eligible: a block-bodied function literal, a non-empty list, set or map literal, or a record with more than one field when it is the sole argument; a named argument is judged by its expression. An `=>` lambda and an empty collection are not eligible. A source trailing comma prevents hugging. `never`, `chop_always`, alignment, a named-argument or call-name match and a reached `chop_from` take precedence. With `false`, the list is laid out by its ordinary settings and is not forced to chop. Examples at 80 columns.

Before:

```dart
test('adds', () { expect(add(1, 2), 3); });
```

After with the preset:

```dart
test('adds', () {
  expect(add(1, 2), 3);
});
```

After with `wrap.arguments.hug_block_argument=false`:

```dart
test(
  'adds',
  () {
    expect(add(1, 2), 3);
  },
);
```

Before:

```dart
someFunction(firstArgumentName, secondArgumentName, [elementOne, elementTwo, three]);
```

After with `wrap.arguments.hug_block_argument=false wrap.arguments=if_long`:

```dart
someFunction(
  firstArgumentName, secondArgumentName, [elementOne, elementTwo, three],
);
```

## `wrap.chop_on_calls`

A list of callable names, empty by default, matched case-sensitively and without type resolution. An invocation whose callable name matches an entry has its own argument list chopped; nested lists are judged on their own. The name is the dotted name of the invoked expression (type arguments are not segments): a one-segment entry such as `Row` matches the final or penultimate segment (`Row(…)`, `m.Row(…)`, `Row.center(…)`), a longer entry such as `Row.center` matches the complete suffix. A computed target (`callbacks[i](x)`, the outer call of `getBuilder()(x)`) has no name. Entries are identifiers separated by single dots; wildcards are a configuration error. `never` takes precedence; a match defeats hugging and kept groups. Examples at 80 columns.

Before:

```dart
return Row(children: [a, b]);
```

After with `wrap.chop_on_calls=[Row]`:

```dart
return Row(
  children: [a, b],
);
```

Before:

```dart
x = m.Row.center(a);
```

After with `wrap.chop_on_calls=[Row]`:

```dart
x = m.Row.center(
  a,
);
```

Before:

```dart
x = RowFactory(a) + Row.center.extra(b);
```

After with `wrap.chop_on_calls=[Row]`:

```dart
x = RowFactory(a) + Row.center.extra(b);
```

## `wrap.close_bracket`

Where the closing `)`, `]` or `}` of a broken list goes: `own_line` (preset) or `after_last_item`. `after_last_item` also suppresses the optional trailing comma; a required comma (a one-field positional record) is kept. A global key plus a `close_bracket` field, preset `inherit`, on `arguments`, `parameters`, `collection_literals` and `enum_values`; records follow the global key. Because it suppresses the comma, it takes part in the trailing-comma conflict check. Examples at 40 columns.

Before:

```dart
canvas.drawLine(startPoint, endPoint, paint);
```

After with `wrap.arguments.close_bracket=after_last_item`:

```dart
canvas.drawLine(
  startPoint,
  endPoint,
  paint);
```

Before:

```dart
f([firstElement, secondElement, thirdOne]);
```

After with `wrap.arguments.close_bracket=after_last_item`:

```dart
f([
  firstElement,
  secondElement,
  thirdOne,
]);
```

Before:

```dart
final r = (someVeryLongValueThatBreaksHere,);
```

After with `wrap.close_bracket=after_last_item`:

```dart
final r = (
  someVeryLongValueThatBreaksHere,);
```

## `wrap.break_before`

Which side of an operator receives the break when a line wraps there. They never force wrapping. `binary_operator` (preset `false`; alias `wrap.before_operator`, see above), `conditional_operator` (`true`: `?` and `:` start their lines), `arrow` (`false`) and `assignment` (`false`). Examples at 60 columns.

Before:

```dart
final decoded = jsonDecode(response.body) as Map<String, dynamic>;
```

After with `wrap.break_before.arrow=true wrap.break_before.assignment=true`:

```dart
final decoded
    = jsonDecode(response.body) as Map<String, dynamic>;
```

Before:

```dart
String describe(Order order) => '${order.id}: ${order.items.length} items';
```

After with `wrap.break_before.arrow=true`:

```dart
String describe(Order order)
    => '${order.id}: ${order.items.length} items';
```

Before:

```dart
final value = someCondition ? firstAlternativeValue : secondAlternative;
```

After with `wrap.break_before.conditional_operator=false`:

```dart
final value = someCondition ?
    firstAlternativeValue :
    secondAlternative;
```

## `wrap.chained_calls.keep_first_call_on_receiver_line`

When a chain chops, keep its first call on the receiver's line and break before each later call. Preset `dart`: `false`. Example at 50 columns.

Before:

```dart
final names = users.where((u) => u.active).map((u) => u.name).toList();
```

After with `wrap.chained_calls.keep_first_call_on_receiver_line=true`:

```dart
final names = users.where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

## `wrap.binary_expressions.align`

Continuation lines of a wrapped binary expression align under its first operand, wherever the expression occurs, instead of being indented by `wrap.binary_expressions.indent` (`inherit`: `indent.continuation`). Preset `dart`: `false`. The column is wherever the first operand landed: after `=` the whole right-hand side moves to its own line first, so there the operands line up at the continuation indent and the output is the same as with `false`; the difference shows in a `return`, a condition or an argument, where the first operand shares a line with what precedes it. Examples at 30 columns.

Before:

```dart
return subtotal + shipping + tax;
```

After with `wrap.binary_expressions.align=true`:

```dart
return subtotal +
       shipping +
       tax;
```

## `wrap.annotations`

Whether a declaration's annotations share its line: `own_line` (preset), `same_line` or `preserve`. Parameter annotations stay on the parameter's line under every value. Examples at 80 columns.

Before:

```dart
@override void dispose() { super.dispose(); }
```

After with `wrap.annotations=same_line`:

```dart
@override void dispose() {
  super.dispose();
}
```

## `wrap.braceless_bodies`

Where the single statement of a braceless `if`, `else`, `for` or `while` goes: `same_line_if_fits` (preset), `new_line` (on its own line, indented one level) or `preserve`. Beaver never adds or removes braces. Examples at 40 columns.

Before:

```dart
if (items.isEmpty) return null;
```

After with `wrap.braceless_bodies=new_line`:

```dart
if (items.isEmpty)
  return null;
```

Before:

```dart
if (items.isEmpty)
  return null;
```

After with the preset:

```dart
if (items.isEmpty) return null;
```

## `wrap.control_conditions`

How a condition that does not fit inside `if (…)`, `while (…)` or `for (…)` is laid out: `continuation` (preset: continuation indent, `)` on the last operand's line) or `block` (`(` ends the line, the condition is indented one level, `)` on its own line). Examples at 40 columns.

Before:

```dart
if (user.isActive && user.hasVerifiedEmail && !user.isSuspended) { grant(); }
```

After with `wrap.control_conditions=block`:

```dart
if (
  user.isActive &&
  user.hasVerifiedEmail &&
  !user.isSuspended
) {
  grant();
}
```

## `wrap.simple_case_bodies_on_one_line` and `wrap.simple_methods_on_one_line`

With `simple_case_bodies_on_one_line: true`, a `case` or `default` whose body is one statement is printed on the label's line when it fits. With `simple_methods_on_one_line: true`, a method or function whose block body holds one statement keeps `{ statement; }` on the declaration line when it fits. Preset `dart`: both `false`. Examples at 40 and 80 columns.

Before:

```dart
switch (code) {
  case 200:
    return ok;
  case 404:
    return missing;
}
```

After with `wrap.simple_case_bodies_on_one_line=true`:

```dart
switch (code) {
  case 200: return ok;
  case 404: return missing;
}
```

Before:

```dart
class A {
  void close() { _controller.close(); }
}
```

After with `wrap.simple_methods_on_one_line=true`:

```dart
class A {
  void close() { _controller.close(); }
}
```
