# Blank line rules

Keys under `blank_lines:`. `max_consecutive` caps blank lines anywhere; inside function bodies blank lines up to the cap are kept. `after_imports`, `between_members`, `before_first_member` and `around_class_declarations` set the exact number at those positions. `between_members` applies around members with a `{ }` body; between two members without one (fields, `=>` getters and methods, constructors ending in `;`), the source's blank lines are kept up to the cap, so related members can stay grouped. Blank lines between the items of a list that splits (arguments, parameters, collection elements, enum values) are kept up to the cap; a list that fits on one line drops them. Examples are taken verbatim from `packages/zooper_beaver/test/golden/blank_lines/blank_lines.unit`.

| Key | Preset `dart` |
|---|---|
| `max_consecutive` | `1` |
| `after_imports` | `1` |
| `between_members` | `1` |
| `before_first_member` | `0` |
| `around_class_declarations` | `1` |

Before:

```dart
void f() {
  a();



  b();
}
```

After:

```dart
void f() {
  a();

  b();
}
```

Before:

```dart
class A {
  void a() {}
  void b() {}


  void c() {}
}
```

After:

```dart
class A {
  void a() {}

  void b() {}

  void c() {}
}
```

Before:

```dart
class A {
  int a = 0;
  int b = 0;

  int c = 0;
}
```

After:

```dart
class A {
  int a = 0;
  int b = 0;

  int c = 0;
}
```

Before:

```dart
class A {

  int a = 0;
}
```

After:

```dart
class A {
  int a = 0;
}
```

Before:

```dart
import 'a.dart';
class A {}
class B {}
void f() {}
```

After:

```dart
import 'a.dart';

class A {}

class B {}

void f() {}
```

A blank line before an own-line comment is kept; the comment is followed directly by the code it describes:

Before:

```dart
void f() {
  a();

  // about b

  b();
}
```

After:

```dart
void f() {
  a();

  // about b
  b();
}
```
