# Brace rules

Beaver formats whitespace around braces only. It never adds or removes braces, so a braceless `if` stays braceless; use the `curly_braces_in_flow_control_structures` lint with `dart fix` for that. Examples are taken verbatim from `packages/zooper_beaver/test/golden/braces/braces.stmt` and `handlers.stmt`.

## `braces.else_on_new_line`

Whether `else` starts a new line after the closing brace. It is also the fallback of the three keys below. Preset `dart`: `false`.

Before:

```dart
if (x) { a(); } else { b(); }
```

After with `braces.else_on_new_line=true`:

```dart
if (x) {
  a();
}
else {
  b();
}
```

Before:

```dart
try { a(); } catch (e) { b(); } finally { c(); }
```

After with `braces.else_on_new_line=true`:

```dart
try {
  a();
}
catch (e) {
  b();
}
finally {
  c();
}
```

Before:

```dart
if (x) return;
```

After:

```dart
if (x) return;
```

## `braces.catch_on_new_line`, `braces.finally_on_new_line` and `braces.while_on_new_line`

Whether an `on`/`catch` handler clause, a `finally` clause and the trailing `while` of a `do` loop start a new line after the closing brace. Each accepts `true`, `false` or `inherit`, preset `inherit`: it follows `braces.else_on_new_line`. A handler moves as a whole, so its `on` type never separates from its `catch`; an ordinary `while` loop is not affected.

Before:

```dart
try { a(); } catch (e) { b(); } finally { c(); }
```

After with `braces.else_on_new_line=true braces.finally_on_new_line=false`:

```dart
try {
  a();
}
catch (e) {
  b();
} finally {
  c();
}
```

After with `braces.catch_on_new_line=true`:

```dart
try {
  a();
}
on FormatException catch (e) {
  b();
}
```

Before:

```dart
do { a(); } while (x);
```

After with `braces.while_on_new_line=true`:

```dart
do {
  a();
}
while (x);
```
