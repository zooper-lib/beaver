# Blank line rules

Keys under `blank_lines:`. `max_consecutive` caps blank lines outside function bodies and `max_consecutive_in_code` (preset `inherit`: the same value) inside them; blank lines up to the cap are kept. `after_imports`, `between_members`, `before_first_member` and `around_class_declarations` set the exact number at those positions. `between_members` applies around members with a `{ }` body; between two members without one (fields, `=>` getters and methods, constructors ending in `;`), the source's blank lines are kept up to the cap while `keep_between_non_block_members` is `true` (the preset), so related members can stay grouped. Whether a member has a block body is syntactic, never based on how many lines it prints. Blank lines between the items of a list that splits (arguments, parameters, collection elements, enum values) are kept up to the cap; a list that fits on one line drops them. Examples are taken verbatim from `packages/zooper_beaver/test/golden/blank_lines/blank_lines.unit` and `new_keys.unit`, and `test/golden/comments/declaration_gap.unit`.

| Key | Preset `dart` |
|---|---|
| `max_consecutive` | `1` |
| `max_consecutive_in_code` | `inherit` (`max_consecutive`) |
| `at_block_edges` | `0` |
| `after_imports` | `1` |
| `between_members` | `1` |
| `before_first_member` | `0` |
| `after_last_member` | `0` |
| `keep_between_non_block_members` | `true` |
| `between_top_level_declarations` | `preserve` |
| `around_class_declarations` | `1` |
| `keep_between_non_block_top_level_declarations` | `true` |
| `between_import_groups` | `preserve` |
| `between_comment_and_declaration` | `preserve` |

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

## `blank_lines.at_block_edges` and `blank_lines.after_last_member`

`at_block_edges` caps the source blank lines kept right after `{` and before `}` of a function or block body. `after_last_member` sets the exact number of blank lines before the closing brace of a class, mixin, enum or extension body. Preset `dart`: both `0`.

Before:

```dart
void f() {

  a();

}
```

After with `blank_lines.at_block_edges=1`:

```dart
void f() {

  a();

}
```

Before:

```dart
class A {
  int a = 0;
}
```

After with `blank_lines.after_last_member=1`:

```dart
class A {
  int a = 0;

}
```

## `blank_lines.between_top_level_declarations` and `blank_lines.keep_between_non_block_top_level_declarations`

`between_top_level_declarations` is `preserve` (the preset: source blank lines up to the cap) or an exact count at each boundary between two top-level declarations. Directives follow their own keys. Next to a class-like declaration, an integer `around_class_declarations` wins; `around_class_declarations: inherit` hands those boundaries to this key and its grouping rule. With `keep_between_non_block_top_level_declarations: true` (the preset), two adjacent declarations without a block body of their own (variables, typedefs, `=>` functions) keep their source blank lines up to the cap; a variable initialised with a block-bodied closure has no block body of its own.

Before:

```dart
int counter = 0;
void increment() {
  counter++;
}
typedef Callback = void Function();
```

After with `blank_lines.between_top_level_declarations=1 blank_lines.keep_between_non_block_top_level_declarations=false`:

```dart
int counter = 0;

void increment() {
  counter++;
}

typedef Callback = void Function();
```

Before:

```dart
class A {}
void f() {}
void g() {}
```

After with `blank_lines.around_class_declarations=2 blank_lines.between_top_level_declarations=1`:

```dart
class A {}


void f() {}

void g() {}
```

## `blank_lines.between_import_groups`

`preserve` (the preset) or an exact count of blank lines between the `dart:`, `package:` and relative import groups and before `export` and `part` directives. Directives are never reordered, so a group boundary is wherever two adjacent directives belong to different groups.

Before:

```dart
import 'dart:io';
import 'package:path/path.dart';
import 'src/a.dart';
export 'src/b.dart';
```

After with `blank_lines.between_import_groups=1`:

```dart
import 'dart:io';

import 'package:path/path.dart';

import 'src/a.dart';

export 'src/b.dart';
```

## `blank_lines.between_comment_and_declaration`

The blank lines between an ordinary own-line comment and the declaration it leads (its first annotation, or its first token): `preserve` keeps the source gap up to the cap and never inserts one; an integer sets an exact count. Only the last comment of a group counts. Doc comments and line-sensitive directives (`// ignore:`, `// ignore_for_file:`, `// coverage:ignore-line`) always stay next to their declaration, and comments leading statements or list items are unaffected. Preset `dart`: `preserve`; `0` restores the layout of Beaver 0.1.0, which always removed the gap.

Before:

```dart
// --- Lifecycle ---

@override
void initState() {}
```

After with the preset (`preserve`):

```dart
// --- Lifecycle ---

@override
void initState() {}
```

After with `blank_lines.between_comment_and_declaration=0`:

```dart
// --- Lifecycle ---
@override
void initState() {}
```

