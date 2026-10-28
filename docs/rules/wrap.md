# Wrapping rules

Keys under `wrap:` and the top-level `trailing_commas`. Examples are taken verbatim from the golden tests in `packages/zooper_beaver/test/golden/wrap/` and are formatted at 40 columns.

## Policies

`wrap.arguments`, `wrap.parameters`, `wrap.collection_literals`, `wrap.binary_expressions`, `wrap.conditional_expressions` and `wrap.chained_calls.policy` each take one of four values:

| Value | Effect |
|---|---|
| `never` | All items on one line, even past `line_length`. Developer line breaks are removed. |
| `if_long` | As many items per line as fit (paragraph fill). |
| `chop_if_long` | Every item on its own line, only when the construct does not fit. |
| `chop_always` | Every item on its own line, always. |

Preset `dart`: `chop_if_long` everywhere.

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

## `wrap.before_operator`

Whether a wrapped binary expression puts the operator at the start of the continuation line (`true`) or the end of the previous one (`false`). Preset `dart`: `false`.

Before:

```dart
value = operandOne + operandTwo + operandThree;
```

After with `wrap.before_operator=true`:

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

After with `wrap.before_operator=false`:

```dart
value =
    operandOne +
    operandTwo +
    operandThree;
```

## `wrap.chained_calls`

`policy` applies to method chains (two or more calls after a target). A chain with at least `min_calls` calls is chopped regardless of width; `0` disables this. `keep_single_line_if_fits` keeps a chain with fewer calls on one line when it fits, even under `chop_always`. Preset `dart`: `chop_if_long`, `min_calls: 0`, `keep_single_line_if_fits: true`.

Before:

```dart
a.b().c().d();
```

After with `wrap.chained_calls.min_calls=3`:

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

After with `wrap.chained_calls.min_calls=3`:

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

`preserve` keeps the source's choice, `remove` never prints an optional trailing comma, `add_when_wrapped` prints one exactly when the last item is followed by a line break. Required commas, such as a single-field record `(42,)`, are never removed. Preset `dart`: `add_when_wrapped`.

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

`trailing_commas: remove` with `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` is a configuration error: the chop deletes the comma that requested it, and nothing would keep the chopped layout on the next run. Set one of the three differently.

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
