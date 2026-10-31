# Space rules

Keys under `spaces:`, each `true` or `false` (except `before_trailing_comment`, an integer), each controlling exactly the whitespace it names. Examples are taken verbatim from `packages/zooper_beaver/test/golden/spaces/spaces.stmt` and `new_spaces.stmt`.

| Key | Preset `dart` |
|---|---|
| `around_assignment` | `true` |
| `around_binary_operators` | `true` |
| `around_arrow` | `true` |
| `after_comma` | `true` |
| `before_comma` | `false` |
| `before_colon_in_named_argument` | `false` |
| `after_colon_in_named_argument` | `true` |
| `before_colon_in_map_entry` | `false` |
| `after_colon_in_map_entry` | `true` |
| `before_colon_in_initializer_list` | `true` |
| `before_colon_in_switch_case` | `false` |
| `inside_parentheses` | `false` |
| `inside_brackets` | `false` |
| `inside_braces` | `false` |
| `before_control_parentheses` | `true` |
| `in_empty_braces` | `false` |
| `after_cast` | `true` |
| `before_trailing_comment` | `1` (an integer, minimum 1) |

Spaces that keep two tokens apart are never removed: `after_cast: false` only drops the space before a parenthesized (record) type, and a space is kept between `-` and a following `-`.

Before:

```dart
x = a; y += 1;
```

After with `spaces.around_assignment=false`:

```dart
x=a;
y+=1;
```

Before:

```dart
x = a + b * c;
```

After with `spaces.around_binary_operators=false`:

```dart
x = a+b*c;
```

Before:

```dart
var f = (x) => x;
```

After with `spaces.around_arrow=false`:

```dart
var f = (x)=>x;
```

Before:

```dart
f(a, b, c);
```

After with `spaces.after_comma=false`:

```dart
f(a,b,c);
```

Before:

```dart
f(a, b, c);
```

After with `spaces.before_comma=true`:

```dart
f(a , b , c);
```

Before:

```dart
f(a: 1, b: 2);
```

After with `spaces.after_colon_in_named_argument=false`:

```dart
f(a:1, b:2);
```

Before:

```dart
if (x) f(a, b);
```

After with `spaces.inside_parentheses=true`:

```dart
if ( x ) f( a, b );
```

Before:

```dart
var l = [1, 2];
```

After with `spaces.inside_brackets=true`:

```dart
var l = [ 1, 2 ];
```

Before:

```dart
var m = {a: 1};
```

After with `spaces.inside_braces=true`:

```dart
var m = { a: 1 };
```

Before:

```dart
if (x) { while (y) {} }
```

After with `spaces.before_control_parentheses=false`:

```dart
if(x) {
  while(y) {}
}
```

Before:

```dart
var m = { };
```

After with `spaces.in_empty_braces=true`:

```dart
var m = { };
```

Before:

```dart
var r = x as (int, int);
```

After with `spaces.after_cast=false`:

```dart
var r = x as(int, int);
```

## `spaces.before_trailing_comment`

The number of spaces between code and a `//` comment that ends the line. Preset `dart`: `1`; minimum `1`.

Before:

```dart
final retries = 3;// never more than three
```

After with `spaces.before_trailing_comment=2`:

```dart
final retries = 3;  // never more than three
```

## Colon spacing

Each colon position has its own key: `before_colon_in_named_argument` and `after_colon_in_named_argument` (also record fields), `before_colon_in_map_entry` and `after_colon_in_map_entry` (also map patterns), `before_colon_in_initializer_list` and `before_colon_in_switch_case` (also `default:`).

Before:

```dart
final m = {'a' : 1, 'b' : 2};
```

After with the preset:

```dart
final m = {'a': 1, 'b': 2};
```

Before:

```dart
class Point {
  Point(this.x) : y = 0;
}
```

After with `spaces.before_colon_in_initializer_list=false`:

```dart
class Point {
  Point(this.x): y = 0;
}
```

Before:

```dart
switch (x) {
  case 1:
    a();
  default:
    b();
}
```

After with `spaces.before_colon_in_switch_case=true`:

```dart
switch (x) {
  case 1 :
    a();
  default :
    b();
}
```
