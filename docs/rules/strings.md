# String rules

## `strings.quotes`

`preserve`, `single` or `double`. `single` and `double` change the delimiters of plain and interpolated string literals only when the value stays the same without new escapes. Raw strings and literals that would need an escaped delimiter are left as they are. Preset `dart`: `preserve`. Examples are taken verbatim from `packages/zooper_beaver/test/golden/strings/quotes.stmt`.

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
