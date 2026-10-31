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

A list map with an `indent` field uses that field as the offset of its broken items. Its preset `inherit` follows `indent.continuation` for `wrap.chained_calls` and `wrap.binary_expressions`, and `indent.size` for the other lists, so a team that only changes these two keys keeps today's layout everywhere. An integer is never added on top of an alignment column; see [`wrap.<list>.indent`](#wraplistindent) for `first_item`. `wrap.chained_calls.indent_from` and `wrap.binary_expressions.indent_from` choose what that offset is measured from: the line (`line`, the preset) or the column where the chain's target or the first operand starts (`target`), see [wrap](wrap.md).

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

## `wrap.<list>.indent`

The `indent` field of a list map (see [list maps](wrap.md#list-maps)) answers one question: where do the second and later items start. It takes one of three values:

- `inherit` (the preset): the list's fallback, `indent.continuation` for `chained_calls` and `binary_expressions` and `indent.size` for the other lists.
- an integer: that many columns from the base `indent_from` names (the line, for the lists without `indent_from`).
- `first_item`: the column where the first item starts, when the first item shares a line with what precedes it (the opening bracket, or the chain's receiver). When it does not, because `break_after_open_bracket: true` or because the chain's first call broke, there is nothing beside it to align to and `inherit` applies. Not offered on `cascades`, where nothing precedes the first section.

`first_item` never moves the brackets: those are `break_after_open_bracket` and `break_before_close_bracket` ([wrap](wrap.md#wrapbreak_after_open_bracket-and-wrapbreak_before_close_bracket)). On a chain, the first call shares the receiver's line only when the receiver's kind is in `keep_first_call_on_receiver_line`. `indent_from` is a sub-option of an integer or `inherit` and is ignored under `first_item`. Alignment is never dropped because aligned lines are too long. Aliases: `align: true` and `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls` set to `true`; `false` is accepted and dropped. Preset `dart`: `inherit`, except `wrap.initializer_lists` (`first_item`).

The three values side by side, at 40 columns with `break_after_open_bracket=false` and `break_before_close_bracket=false`.

Before:

```dart
print(firstArgument, secondArgument, third);
```

After with `wrap.arguments.indent=inherit`:

```dart
print(firstArgument,
  secondArgument,
  third);
```

After with `wrap.arguments.indent=4`:

```dart
print(firstArgument,
    secondArgument,
    third);
```

After with `wrap.arguments.indent=first_item`:

```dart
print(firstArgument,
      secondArgument,
      third);
```

With the preset bracket fields the first item starts its own line, so `first_item` falls back to `inherit`. After with `wrap.arguments.indent=first_item`:

```dart
print(
  firstArgument,
  secondArgument,
  third,
);
```

Parameters, with both bracket fields `false`:

Before:

```dart
void function(int first, int second, int third) {}
```

After with `wrap.parameters.indent=first_item`:

```dart
void function(int first,
              int second,
              int third) {}
```

Chains, with `keep_first_call_on_receiver_line=true`: the calls align under the first `.` while the target prints on one line.

Before:

```dart
final r = obj.doThis().thenThat().andMore();
```

After with `wrap.chained_calls.indent=first_item`:

```dart
final r = obj.doThis()
             .thenThat()
             .andMore();
```

When the target itself wraps, continuation indent applies. Before:

```dart
final r = target(argumentNumberOne, argumentNumberTwo).doThis().thenThat();
```

After with `wrap.chained_calls.indent=first_item`:

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

After with `wrap.chained_calls.indent=first_item wrap.chained_calls.chop_from=2`:

```dart
final result = someReceiverObject.doSomethingVeryLong()
                                 .thenThat();
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
