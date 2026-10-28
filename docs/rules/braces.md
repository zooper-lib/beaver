# Brace rules

Beaver formats whitespace around braces only. It never adds or removes braces, so a braceless `if` stays braceless; use the `curly_braces_in_flow_control_structures` lint with `dart fix` for that. Examples are taken verbatim from `packages/zooper_beaver/test/golden/braces/braces.stmt`.

## `braces.else_on_new_line`

Whether `else`, `catch` and `finally` start a new line after the closing brace. Preset `dart`: `false`.

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
