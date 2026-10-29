# Indentation rules

Keys under `indent:`. Examples are taken verbatim from `packages/zooper_beaver/test/golden/indent/` and are formatted at 40 columns.

## `indent.size` and `indent.style`

`size` is the width of one indentation level; `style` is `spaces` or `tabs`. With tabs, each level is one tab and alignment padding is always spaces. Preset `dart`: `2`, `spaces`.

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

## `indent.align.*`

`arguments`, `parameters` and `chained_calls`. When `true`, wrapped items align to the column where the anchor ends (the text before the first wrapped item), as long as the anchor itself printed on one line. If Beaver's own rules wrapped the anchor, continuation indent applies instead. Alignment is never dropped because aligned lines are too long. Preset `dart`: all `false`.

Before:

```dart
final r = obj.doThis().thenThat().andMore();
```

After with `indent.align.chained_calls=true`:

```dart
final r = obj.doThis()
             .thenThat()
             .andMore();
```

Before:

```dart
final r = target(argumentNumberOne, argumentNumberTwo).doThis().thenThat();
```

After with `indent.align.chained_calls=true`:

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

After with `indent.align.chained_calls=true wrap.chained_calls.min_calls=2`:

```dart
final result = someReceiverObject.doSomethingVeryLong()
                                 .thenThat();
```

Before:

```dart
print(firstArgument, secondArgument, third);
```

After with `indent.align.arguments=true`:

```dart
print(firstArgument,
      secondArgument,
      third);
```

Before:

```dart
void function(int first, int second, int third) {}
```

After with `indent.align.parameters=true`:

```dart
void function(int first,
              int second,
              int third) {}
```
