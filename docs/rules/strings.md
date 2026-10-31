# String rules

## `strings.quotes`

`preserve`, `single` or `double`. `single` and `double` change the delimiters of plain and interpolated string literals only when the value stays the same without new escapes. Raw strings are left as they are, and so are literals that would need an escaped delimiter while `strings.quotes_avoid_escapes` is `true`. Preset `dart`: `preserve`. Examples are taken verbatim from `packages/zooper_beaver/test/golden/strings/quotes.stmt`.

Before:

```dart
x = "hello";
```

After with `strings.quotes=single`:

```dart
x = 'hello';
```

Before:

```dart
x = "it's";
```

After with `strings.quotes=single`:

```dart
x = "it's";
```

Before:

```dart
x = r"raw";
```

After with `strings.quotes=single`:

```dart
x = r"raw";
```

Before:

```dart
x = "a $b ${c + d} e";
```

After with `strings.quotes=single`:

```dart
x = 'a $b ${c + d} e';
```

## `strings.quotes_avoid_escapes`

With `true` (preset `dart`), a literal whose conversion to the configured quote would need the new delimiter escaped keeps its delimiters. With `false`, a one-line literal is converted anyway and the delimiter inside is escaped; the value never changes. Multi-line strings always keep their delimiters in that case. Examples are taken verbatim from `packages/zooper_beaver/test/golden/strings/avoid_escapes.stmt`.

Before:

```dart
final msg = "don't";
```

After with `strings.quotes=single`:

```dart
final msg = "don't";
```

After with `strings.quotes=single strings.quotes_avoid_escapes=false`:

```dart
final msg = 'don\'t';
```
