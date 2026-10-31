# Indentation rules

Keys under `indent:`. Examples are taken verbatim from `packages/zooper_beaver/test/golden/indent/` and are formatted at 40 columns.

## `indent.size` and `indent.style`

`size` is the width of one indentation level; `style` is `spaces` or `tabs`. With tabs, each level is one tab and alignment padding is always spaces. Preset `dart`: `2`, `spaces`. Both can come from EditorConfig (below).

Before:

```dart
void f() { var x = someLongFunctionName + anotherOperand; }
```

After with `indent.style=tabs`:

```dart
void f() {
	var x =
	    someLongFunctionName +
	    anotherOperand;
}
```

## `indent.continuation`

Wrapped continuation lines of an expression are indented by this many spaces beyond the statement. Preset `dart`: `4`.

A list map with an `indent` field uses that field as the offset of its broken items. Its preset `inherit` follows `indent.continuation` for `wrap.chained_calls` and `wrap.binary_expressions`, and `indent.size` for the other lists, so a team that only changes these two keys keeps today's layout everywhere. The numeric indent is never added on top of an alignment column. `wrap.chained_calls.indent_from` and `wrap.binary_expressions.indent_from` choose what that offset is measured from: the line (`line`, the preset) or the column where the chain's target or the first operand starts (`target`), see [wrap](wrap.md).

Before:

```dart
final x = someLongExpressionName + other;
```

After:

```dart
final x =
    someLongExpressionName + other;
```

Before:

```dart
final x = someLongExpressionName + other;
```

After with `indent.continuation=2`:

```dart
final x =
  someLongExpressionName + other;
```

## `indent.switch_cases`

Whether `case` and `default` are indented one level inside the switch body. Preset `dart`: `true`.

Before:

```dart
switch (x) { case 1: a(); default: b(); }
```

After:

```dart
switch (x) {
  case 1:
    a();
  default:
    b();
}
```

Before:

```dart
switch (x) { case 1: a(); default: b(); }
```

After with `indent.switch_cases=false`:

```dart
switch (x) {
case 1:
  a();
default:
  b();
}
```

## `wrap.<list>.align`

The `align` field of a list map (see [list maps](wrap.md#list-maps)); `indent.align.arguments`, `indent.align.parameters` and `indent.align.chained_calls` are aliases of `wrap.arguments.align`, `wrap.parameters.align` and `wrap.chained_calls.align`. When `true`, wrapped items align to the column where the anchor ends (the text before the first wrapped item), as long as the anchor itself printed on one line. If Beaver's own rules wrapped the anchor, continuation indent applies instead. Alignment is never dropped because aligned lines are too long. Preset `dart`: all `false`.

Before:

```dart
final r = obj.doThis().thenThat().andMore();
```

After with `wrap.chained_calls.align=true`:

```dart
final r = obj.doThis()
             .thenThat()
             .andMore();
```

Before:

```dart
final r = target(argumentNumberOne, argumentNumberTwo).doThis().thenThat();
```

After with `wrap.chained_calls.align=true`:

```dart
final r = target(
  argumentNumberOne,
  argumentNumberTwo,
)
    .doThis()
    .thenThat();
```

Before:

```dart
final result = someReceiverObject.doSomethingVeryLong().thenThat();
```

After with `wrap.chained_calls.align=true wrap.chained_calls.chop_from=2`:

```dart
final result = someReceiverObject.doSomethingVeryLong()
                                 .thenThat();
```

Before:

```dart
print(firstArgument, secondArgument, third);
```

After with `wrap.arguments.align=true`:

```dart
print(firstArgument,
      secondArgument,
      third);
```

Before:

```dart
void function(int first, int second, int third) {}
```

After with `wrap.parameters.align=true`:

```dart
void function(int first,
              int second,
              int third) {}
```

## EditorConfig

`editorconfig: true` (top level, preset `false`, inherited through `extends` like any key) makes Beaver read `.editorconfig` files for three properties. Without it, no `.editorconfig` is ever read, so a project without a `.beaver.yaml` never consults EditorConfig.

| EditorConfig | Beaver key | Mapping |
|---|---|---|
| `indent_style` | `indent.style` | `space` → `spaces`, `tab` → `tabs` |
| `indent_size` | `indent.size` | the number; `tab` takes the value of `tab_width` |
| `end_of_line` | `line_ending` | `lf`, `crlf`; `cr` is reported and ignored |

Every other property, `max_line_length` included, is ignored.

Precedence, lowest first: the `dart` preset, EditorConfig, any explicit setting in the Beaver `extends` chain. An explicit Beaver value wins wherever it sits in the chain, even when an `.editorconfig` is nearer the file; preset values never count as explicit. So `line_ending: auto` written in a `.beaver.yaml` selects source-based detection even when EditorConfig says `crlf`. Keys inheriting `indent.size` (such as `wrap.arguments.indent`) follow the EditorConfig value.

Resolution is the full EditorConfig algorithm: `.editorconfig` files from the formatted file's directory upward until one declares `root = true`, sections matched against the file's path with EditorConfig globs (`*`, `**`, `?`, `[...]`, `{a,b}`, `{1..9}`; a pattern without `/` matches the file name at any depth), later sections and nearer files overriding earlier ones, and `unset` removing a value. Because sections match file names, `beaver config --print` needs `--for` and `beaver --stdin` needs `--stdin-name` while integration is enabled.
