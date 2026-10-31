# Wrapping rules

Keys under `wrap:` and the top-level `trailing_commas`. Examples are taken verbatim from the golden tests in `packages/zooper_beaver/test/golden/wrap/` and are formatted at 40 columns.

## Glossary

Every section below uses these terms. Examples are formatted at 40 columns (arguments) and 60 columns (chains); the input is always the single-line form unless shown otherwise.

**Too long.** The construct printed on one line would exceed `line_length`. This is the only width condition, and it is never about the number of items.

Before:

```dart
function(first, second, third);
```

After (fits, untouched):

```dart
function(first, second, third);
```

Before:

```dart
function(firstArgument, secondArgument, thirdArgument, fourth);
```

After (too long, so it breaks):

```dart
function(
  firstArgument,
  secondArgument,
  thirdArgument,
  fourth,
);
```

**`never`.** Ignore "too long"; the construct stays as written, past the width.

After with `wrap.arguments=never`:

```dart
function(firstArgument, secondArgument, thirdArgument, fourth);
```

**Fill (`fill`).** When too long, items follow one another, as many per line as fit. An item that does not fit starts a new line; an item that is itself too long gets a line of its own and breaks inside if it can. Alias: `if_long`.

After with `wrap.arguments=fill`:

```dart
function(
  firstArgument, secondArgument,
  thirdArgument, fourth,
);
```

**Chop (`chop_if_long`).** When too long, one item per line. This is the output above under "too long", since `chop_if_long` is the preset.

**`chop_from: N`.** One item per line from N items, even when the line fits. It is the only count-based trigger; `0` disables it.

After with `wrap.arguments.chop_from=3`:

```dart
function(a, b);
```

```dart
function(
  a,
  b,
  c,
);
```

**Kept line break (`keep_existing_line_breaks: true`, the preset).** The formatter adds line breaks where a line is too long but never removes a break the developer typed between items. A kept break makes the list break; it is not a chop request, and items still share lines where they fit.

Before:

```dart
function(first,
    second, third);
```

After (the preset, `chop_if_long` keeps the grouping):

```dart
function(
  first,
  second, third,
);
```

After with `wrap.keep_existing_line_breaks=false`:

```dart
function(first, second, third);
```

Under `fill` the items flow in runs between kept breaks:

Before:

```dart
function(first,
    second, third, fourth, fifth);
```

After with `wrap.arguments=fill`:

```dart
function(
  first,
  second, third, fourth, fifth,
);
```

**Bracket placement.** Independent of all of the above: `break_after_open_bracket` (does the first item start a new line) and `break_before_close_bracket` (does the closing bracket start a new line). See [`wrap.break_after_open_bracket` and `wrap.break_before_close_bracket`](#wrapbreak_after_open_bracket-and-wrapbreak_before_close_bracket).

**The same on chains.** The items are the calls. Before:

```dart
final a = x.b().c();
```

```dart
final names = users.where((u) => u.active).map((u) => u.name).toList();
```

After (the preset, `chop_if_long`): the short chain fits and stays, the long one chops:

```dart
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

After with `wrap.chained_calls=fill`:

```dart
final names = users.where((u) => u.active)
    .map((u) => u.name).toList();
```

After with `wrap.chained_calls.chop_from=2`, every chain of two or more calls chops:

```dart
final a = x
    .b()
    .c();
```

**Sub-options.** Some fields only refine another setting, their parent: `chop_from` (parent: policy `fill` or `chop_if_long`), `indent_from` (parent: an integer or `inherit` `indent`) and `trailing_commas` (parent: `break_before_close_bracket: true`). A sub-option whose parent is not in effect is ignored without a diagnostic, so a child file can switch off an inherited behavior with one key: `wrap.arguments: never` disables an inherited `chop_from: 3`. Peer settings that contradict each other are a configuration error instead (see the trailing-comma check under [`wrap.chop_on_trailing_comma`](#wrapchop_on_trailing_comma)).

## Policies

The `policy` field of every list map (see [List maps](#list-maps)) takes one of three values:

| Value | Effect |
|---|---|
| `never` | All items on one line, even past `line_length`. Developer line breaks are removed. |
| `fill` | When too long, as many items per line as fit (paragraph fill). Alias: `if_long`. |
| `chop_if_long` | When too long, every item on its own line. |

Chopping regardless of width is `chop_from: 1` (see [`chop_from`](#chop_from)). Preset `dart`: `chop_if_long` everywhere; `wrap.switch_expressions` adds `chop_from: 1`.

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
| `policy` | `never` \| `fill` \| `chop_if_long` | `chop_if_long` | every list |
| `chop_from` | integer, `0` disables | `0` (`cascades` 2, `switch_expressions` 1) | every list |
| `keep_existing_line_breaks` | `true` \| `false` \| `inherit` | `inherit` | every list |
| `chop_on_trailing_comma` | `true` \| `false` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |
| `indent` | `inherit` \| integer \| `first_item` | `inherit` (`initializer_lists`: `first_item`) | `arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `chained_calls`, `initializer_lists`; `cascades` without `first_item` |
| `break_after_open_bracket` | `true` \| `false` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |
| `break_before_close_bracket` | `true` \| `false` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |
| `trailing_commas` | `preserve` \| `remove` \| `add_when_wrapped` \| `add_when_chopped` \| `inherit` | `inherit` | `arguments`, `parameters`, `collection_literals`, `enum_values` |

The lists are `arguments`, `parameters`, `collection_literals`, `enum_values`, `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions` and `class_header`. A field a list does not offer is a configuration error. `beaver config --template` prints every list with every field.

`inherit` takes the effective value of the field's fallback, resolved after the whole `extends` chain has merged, so it follows a global key overridden in a nearer file. Omitting the field keeps the value the parent file set; writing `inherit` restores the link. The fallbacks:

| Field | Falls back to |
|---|---|
| `keep_existing_line_breaks` | `wrap.keep_existing_line_breaks` |
| `chop_on_trailing_comma` | `wrap.chop_on_trailing_comma` |
| `break_after_open_bracket` | `wrap.break_after_open_bracket` |
| `break_before_close_bracket` | `wrap.break_before_close_bracket` |
| `trailing_commas` | `trailing_commas` |
| `indent` | `indent.continuation` for `chained_calls` and `binary_expressions`, `indent.size` for the others |
| every field of `enum_values` | the same field of `collection_literals` |

`policy` and `chop_from` have no global key and do not accept `inherit`, except on `enum_values`, whose fields all follow `collection_literals` so that a configuration customising collection literals keeps its enum layout. `beaver config --print` shows, for an inherited value, both where `inherit` was set and where the value came from.

Record literals, record patterns and record types use the `arguments` (literals, patterns) or `parameters` (types) policy, but always the global `keep_existing_line_breaks`, `chop_on_trailing_comma`, `break_after_open_bracket`, `break_before_close_bracket` and `trailing_commas`, never a per-list override.

Every key added after 0.1.0 has a preset value that reproduces the 0.1.0 output, with two deliberate exceptions: `blank_lines.between_comment_and_declaration` is `preserve` ([blank lines](blank_lines.md)) and `wrap.cascades.keep_existing_line_breaks` is `inherit`, which keeps a break typed before a cascade section. `0` and `false` restore the old output.

Aliases, accepted without deprecation and identical to their canonical key:

| Alias | Canonical key |
|---|---|
| `wrap.<list>: <policy>` | `wrap.<list>.policy` |
| policy value `if_long` | `fill` |
| `wrap.<list>.align: true`, `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls` set to `true` | `wrap.<list>.indent: first_item` |
| `wrap.close_bracket`, `wrap.<list>.close_bracket`: `own_line` \| `after_last_item` | `break_before_close_bracket`: `true` \| `false` (`inherit` unchanged) |
| `wrap.chained_calls.min_calls` | `wrap.chained_calls.chop_from` |
| `wrap.before_operator` | `wrap.break_before.binary_operator` |

`align: false` and `indent.align.*: false` are accepted and dropped: they only ever meant "use `indent`". `align: true` next to an `indent` value in one file sets `indent` twice and is a configuration error.

Removed spellings fail with exit code 78 and a message naming the replacement:

| Removed | Replacement |
|---|---|
| `policy: chop_always` | `policy: chop_if_long` with `chop_from: 1`; on a chain, `chop_always` with `keep_single_line_if_fits: false` is `chop_from: 2` |
| `wrap.chained_calls.keep_single_line_if_fits` | `chop_from`: a chain below the threshold that fits stays on one line under `fill` and `chop_if_long` |
| `chop_on_trailing_comma` on `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions`, `class_header` | none: those lists never read it; it is an unknown key there |

A configuration that used `align: true` on `arguments`, `parameters` or `collection_literals` to put the first item on the bracket line and the closing bracket after the last item needs `break_after_open_bracket: false` and `break_before_close_bracket: false` to keep that look; on a chain, alignment needs `keep_first_call_on_receiver_line` too.

### `never`

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=never`:

```dart
function(firstArgument, secondArgument, third);
```

### `fill`

Before:

```dart
function(firstArgument, secondArgument, third);
```

After with `wrap.arguments=fill trailing_commas=remove`:

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

After with `wrap.arguments=fill`:

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

After with `wrap.binary_expressions=fill`:

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

`policy` applies to method chains (two or more calls after a target). A chain with at least `chop_from` calls is chopped regardless of width, unless the policy is `never`; `0` disables this. Below the threshold, a chain that fits stays on one line under `fill` and `chop_if_long`; `chop_from: 2` chops every chain. Preset `dart`: `chop_if_long`, `chop_from: 0`.

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
final a = x.b().c();
```

After with `wrap.chained_calls.chop_from=2`:

```dart
final a = x
    .b()
    .c();
```

## `wrap.keep_existing_line_breaks`

The formatter adds line breaks where a line is too long but never removes a break the developer typed between items of a wrappable construct. Kept breaks never expand their siblings: the items between two kept breaks stay together while they fit. Only `never` removes them. A break directly after the opening bracket or before the closing bracket is not an item gap: it follows [`break_after_open_bracket` and `break_before_close_bracket`](#wrapbreak_after_open_bracket-and-wrapbreak_before_close_bracket), so under the preset (`true`) a break typed after `(` stays, and under `false` it is removed. Newlines between statements and members are not affected by this key; see [blank lines](blank_lines.md). Preset `dart`: `true`.

The trade-off: `true` lets two developers get different, equally stable layouts from the same code, because each keeps the breaks they typed; `false` makes the formatter own the layout and rewrites hand-chosen breaks, so the same code always formats the same way.

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

`preserve` keeps the source's choice, `remove` never prints an optional trailing comma, `add_when_wrapped` prints one exactly when the last item is followed by a line break, `add_when_chopped` only when the list is chopped (every item starts its own line; a filled list, or one whose kept breaks group several items, gets none). Each of `arguments`, `parameters`, `collection_literals` and `enum_values` has its own `trailing_commas` field, preset `inherit`; records always follow this global key. Required commas, such as a single-field record `(42,)`, are never removed. `trailing_commas` is a sub-option of `break_before_close_bracket: true`: with `false`, no optional comma is added and one in the source is dropped, under every value including `preserve`. Preset `dart`: `add_when_wrapped`.

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

This is the global value; `arguments`, `parameters`, `collection_literals` and `enum_values` each have their own `chop_on_trailing_comma`, preset `inherit`. Records follow the global key. No other list has a trailing comma to act on, so the field is an unknown key there. With both `break_after_open_bracket: false` and `break_before_close_bracket: false`, a source comma is dropped and is not a chop request: nothing would keep the chop on the next run.

For any list with an optional trailing comma (and for records, on the global keys), `trailing_commas: remove` (or a comma suppressed by `break_before_close_bracket: false`) with `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` in effect for that list is a configuration error: the chop deletes the comma that requested it, and nothing would keep the chopped layout on the next run. The check runs on the effective values after `inherit` is resolved, so a global value can complete a conflict on one list. A list whose policy is `never` or whose `chop_from` is 1 is exempt; a larger threshold alone is not. Set one of the three differently for that list.

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

A field of every list map. With `chop_from: N`, a list of at least N items puts every item on its own line, whatever its width; `0` disables this and is the preset everywhere except `wrap.cascades` (`2`) and `wrap.switch_expressions` (`1`). It is the only count-based trigger, and `chop_from: 1` is how "always chop" is written. It is a sub-option of `fill` and `chop_if_long`: under `never` it is ignored. Otherwise it defeats filling, kept groups of items sharing a line and block-argument hugging. Items are counted syntactically per list: a named argument, a closure, a spread or a collection `if`/`for` counts once, and a nested list is counted on its own. Binary operands are counted within one run of operators of the same precedence; a parenthesized expression or one at another precedence is one operand. `wrap.chained_calls.chop_from` counts calls (alias `min_calls`). Examples at 40 columns.

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

After with `wrap.initializer_lists.chop_from=1`:

```dart
class Point {
  Point(this.x, this.y)
    : _len = sqrt(x * x + y * y),
      _label = '$x,$y';
}
```

After with `wrap.initializer_lists.chop_from=1 wrap.initializer_lists.colon=end_of_header wrap.initializer_lists.indent=inherit`:

```dart
class Point {
  Point(this.x, this.y) :
      _len = sqrt(x * x + y * y),
      _label = '$x,$y';
}
```

After with `wrap.initializer_lists.chop_from=1 wrap.initializer_lists.colon=end_of_header wrap.initializer_lists.indent=first_item`:

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

A list map over switch expression arms. Preset `dart`: `policy: chop_if_long` with `chop_from: 1`, which chops every switch expression. Arm commas print exactly as in the source under every policy: none is added or removed. Examples at 80 columns.

Before:

```dart
final label = switch (side) { Side.left => 'L', Side.right => 'R' };
```

After with `wrap.switch_expressions=chop_if_long wrap.switch_expressions.chop_from=0`:

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

After with `wrap.class_header=fill`:

```dart
class HomeScreen extends StatefulWidget with RouteAware
    implements PreferredSizeWidget {}
```

## `wrap.arguments.hug_block_argument`

Whether one block argument may hug the call's parentheses (`f(a, () {` … `})`). Preset `dart`: `true`; no global key and no `inherit`. Eligible: a block-bodied function literal, a non-empty list, set or map literal, or a record with more than one field when it is the sole argument; a named argument is judged by its expression. An `=>` lambda and an empty collection are not eligible. A source trailing comma prevents hugging. `never`, `indent: first_item`, a named-argument or call-name match and a reached `chop_from` take precedence. With `false`, the list is laid out by its ordinary settings and is not forced to chop. Examples at 80 columns.

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

After with `wrap.arguments.hug_block_argument=false wrap.arguments=fill`:

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

## `wrap.break_after_open_bracket` and `wrap.break_before_close_bracket`

Where the brackets of a broken list sit relative to its items, independent of the policy and of `indent`. `break_after_open_bracket`: `true` starts the first item on a new line after `(`, `[` or `{`; `false` keeps it on the bracket's line. `break_before_close_bracket`: `true` puts the closing bracket on a line of its own; `false` places it after the last item. Each is a global key, preset `true`, plus a field, preset `inherit`, on `arguments`, `parameters`, `collection_literals` and `enum_values`; records follow the global keys. Alias: `close_bracket: own_line | after_last_item` for `break_before_close_bracket: true | false`.

[`trailing_commas`](#trailing_commas) is a sub-option of `break_before_close_bracket: true`: with `false` no optional trailing comma is added and one in the source is dropped, under every `trailing_commas` value including `preserve`. A required comma (a one-field positional record) is kept. Because it suppresses the comma, `break_before_close_bracket: false` takes part in the trailing-comma conflict check. A line comment after the last item still puts the closer on its own line.

A source line break directly after the opening bracket or before the closing bracket follows these fields; [`keep_existing_line_breaks`](#wrapkeep_existing_line_breaks) governs only the gaps between items. Examples at 40 columns.

Before:

```dart
print(firstArgument, secondArgument, third);
```

After (the preset):

```dart
print(
  firstArgument,
  secondArgument,
  third,
);
```

After with `wrap.arguments.break_after_open_bracket=false`:

```dart
print(firstArgument,
  secondArgument,
  third,
);
```

After with `wrap.arguments.break_after_open_bracket=false wrap.arguments.break_before_close_bracket=false`:

```dart
print(firstArgument,
  secondArgument,
  third);
```

Before:

```dart
canvas.drawLine(startPoint, endPoint, paint);
```

After with `wrap.arguments.break_before_close_bracket=false`:

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

After with `wrap.arguments.break_before_close_bracket=false` (the list literal keeps the preset):

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

After with `wrap.break_before_close_bracket=false`:

```dart
final r = (
  someVeryLongValueThatBreaksHere,);
```

Before:

```dart
g(
  aaaaaaaaaaaa,
  bbbbbbbbbbbb,
  cccccccccccc,
);
```

After with `trailing_commas=preserve wrap.arguments.break_before_close_bracket=false`:

```dart
g(
  aaaaaaaaaaaa,
  bbbbbbbbbbbb,
  cccccccccccc);
```

A source break next to a bracket. Before:

```dart
print(
    first, second, third);
```

After (the preset keeps it):

```dart
print(
  first, second, third,
);
```

After with `wrap.arguments.break_after_open_bracket=false`:

```dart
print(first, second, third);
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

When a chain breaks, whether its first call stays on the receiver's line, decided by what the receiver is. A list of receiver kinds; `true` means every kind and `false` means `[]`. When the receiver's kind is listed, the first call stays and the chain breaks before each later call; otherwise the first call breaks too. Arguments are never involved. Preset `dart`: `[]`.

| Kind | Receiver looks like | Example |
|---|---|---|
| `type_names` | an UpperCamelCase identifier, possibly import-prefixed | `DateFormat.yMMMMd().format(x)`, `intl.DateFormat.yMMMMd()` |
| `identifiers` | any other plain identifier | `users.where(f).toList()` |
| `this` | `this` or `super` | `this.copyWith(a: 1).save()` |
| `calls` | a call result | `fetch().then(f).catchError(g)` |
| `properties` | a property path | `theme.textTheme.labelMedium.copyWith(c).merge(o)` |

Beaver formats without type information, so a type name is recognised by its capital letter: a constant such as `MAX.toString()` counts as `type_names`. A receiver of no listed kind, such as a literal, always breaks before its first call. With [`indent: first_item`](indent.md#wraplistindent), the calls after a kept first call align under its `.`; a chain whose first call broke has nothing beside it and uses the continuation indent. Examples at 60 columns.

Before:

```dart
final d = DateFormat.yMMMMd().format(invitation.invitedAt.toLocal());
```

After (the preset):

```dart
final d = DateFormat
    .yMMMMd()
    .format(invitation.invitedAt.toLocal());
```

After with `wrap.chained_calls.keep_first_call_on_receiver_line=[type_names]`:

```dart
final d = DateFormat.yMMMMd()
    .format(invitation.invitedAt.toLocal());
```

After with `wrap.chained_calls.keep_first_call_on_receiver_line=[type_names] wrap.chained_calls.indent=first_item`:

```dart
final d = DateFormat.yMMMMd()
                    .format(invitation.invitedAt.toLocal());
```

Before:

```dart
final names = users.where((u) => u.active).map((u) => u.name).toList();
```

After with `wrap.chained_calls.keep_first_call_on_receiver_line=[type_names]` (an identifier, so the first call breaks):

```dart
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

After with `wrap.chained_calls.keep_first_call_on_receiver_line=[identifiers]`:

```dart
final names = users.where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

## `wrap.chained_calls.break_after_prefix`

Where a wrapped chain starts when it follows a prefix: `=`, `=>`, a named argument's `:` or a parameter default's `=`. With `false`, the target stays on the prefix line and the calls are offset from there. With `true`, a chain that does not fit on the prefix line moves to its own line at the continuation indent, like a binary expression does, and then chops only if it still does not fit. A chain that fits on the prefix line stays there either way. Preset `dart`: `false`. Examples at 40 columns.

Before:

```dart
call(date: formatterFactory.create().format(value.toLocal()));
```

After (the preset):

```dart
call(
  date: formatterFactory
      .create()
      .format(value.toLocal()),
);
```

After with `wrap.chained_calls.break_after_prefix=true`:

```dart
call(
  date:
      formatterFactory
      .create()
      .format(value.toLocal()),
);
```

## `wrap.chained_calls.indent_from`

What the calls of a chopped chain are offset from. `line`: the indentation of the line the chain starts on, so after a prefix wider than the offset (`date: `, `final names = `) the calls can start left of the target; a chain moved by `break_after_prefix` keeps its calls in the target's column. `target`: the column where the target starts, so a call never starts left of what it continues. While the target itself does not fit on one line, `line` applies. The offset is `wrap.chained_calls.indent` under both (`inherit`: `indent.continuation`). `indent: first_item` ignores it: `indent_from` is a sub-option of an integer or `inherit` `indent`. Preset `dart`: `line`. After a long prefix, `target` nests deeply; combined with `break_after_prefix: true` the target starts its own line and the calls sit one step past it. Examples at 40 columns.

Before:

```dart
call(date: formatterFactory.create().format(value.toLocal()));
```

After with `wrap.chained_calls.indent_from=target`:

```dart
call(
  date: formatterFactory
            .create()
            .format(value.toLocal()),
);
```

After with `wrap.chained_calls.break_after_prefix=true wrap.chained_calls.indent_from=target`:

```dart
call(
  date:
      formatterFactory
          .create()
          .format(value.toLocal()),
);
```

Before:

```dart
call(date: Factory(firstArgument, secondArgument).create().format(value));
```

After with `wrap.chained_calls.indent_from=target` (the target breaks, so `line` applies):

```dart
call(
  date: Factory(
    firstArgument,
    secondArgument,
  )
      .create()
      .format(value),
);
```

## `wrap.binary_expressions.indent`

With `first_item`, continuation lines of a wrapped binary expression align under its first operand, wherever the expression occurs; with `inherit` (`indent.continuation`) or an integer they are offset by that many columns from the base `indent_from` names. Preset `dart`: `inherit`. The column is wherever the first operand landed: after `=` the whole right-hand side moves to its own line first (under the preset `break_after_prefix: true`), so there the operands line up at the continuation indent and the output is the same as with `inherit`; the difference shows in a `return`, a condition or an argument, where the first operand shares a line with what precedes it. Alias: `wrap.binary_expressions.align: true`. Examples at 30 columns.

Before:

```dart
return subtotal + shipping + tax;
```

After with `wrap.binary_expressions.indent=first_item`:

```dart
return subtotal +
       shipping +
       tax;
```

## `wrap.binary_expressions.break_after_prefix`

Where a wrapped binary expression starts when it follows a prefix: `=`, `=>`, a named argument's `:` or a parameter default's `=`. With `true`, an expression that does not fit on the prefix line moves to its own line at the continuation indent, and its operands then share that column. With `false`, the first operand stays on the prefix line and the later lines are offset by `wrap.binary_expressions.indent` from the line's indentation (or from the first operand, see `indent_from`). An expression that fits on the prefix line stays there either way. Preset `dart`: `true`. A very long first operand is not moved under `false`, so it can overflow. Examples at 30 columns.

Before:

```dart
final total = subtotal + shipping + tax - discount;
```

After with `wrap.break_before.binary_operator=true`, `break_after_prefix` at its preset:

```dart
final total =
    subtotal
    + shipping
    + tax
    - discount;
```

After with `wrap.break_before.binary_operator=true wrap.binary_expressions.break_after_prefix=false`:

```dart
final total = subtotal
    + shipping
    + tax
    - discount;
```

## `wrap.binary_expressions.indent_from`

What the continuation lines of a wrapped binary expression are offset from. `line`: the indentation of the line the expression starts on; an expression moved after a prefix keeps its operands in the first operand's column, because the move already indented it. `target`: the column where the first operand starts, so a continuation line never starts left of it. The offset is `wrap.binary_expressions.indent` under both (`inherit`: `indent.continuation`). `indent: first_item` ignores it: `indent_from` is a sub-option of an integer or `inherit` `indent`. Preset `dart`: `line`. Examples at 30 columns.

Before:

```dart
final total = subtotal + shipping + tax - discount;
```

After with `wrap.break_before.binary_operator=true wrap.binary_expressions.indent_from=target`:

```dart
final total =
    subtotal
        + shipping
        + tax
        - discount;
```

Before:

```dart
return subtotal + shipping + tax;
```

After with `wrap.break_before.binary_operator=true wrap.binary_expressions.indent_from=target`:

```dart
return subtotal
           + shipping
           + tax;
```

After with `wrap.break_before.binary_operator=true wrap.binary_expressions.indent_from=target wrap.binary_expressions.indent=2`:

```dart
return subtotal
         + shipping
         + tax;
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
