# Ignore directives

Beaver leaves parts of a file exactly as written when they are marked with these line comments. Matching is exact after trimming whitespace; `// beaver-ignore please` is an ordinary comment.

| Directive | Effect |
|---|---|
| `// beaver-ignore-start` | Starts an ignored region. |
| `// beaver-ignore-end` | Ends it. |
| `// dart format off` / `// dart format on` | Aliases for start and end, as honoured by `dart format`. |
| `// beaver-ignore` | Ignores the node the comment leads: a statement, member, argument, list element, any node. |

Every byte between a start and its end (whitespace, indentation, line endings) is copied to the output unchanged. Regions may begin and end anywhere, also in the middle of an argument list; the code around them is still formatted. The whole file is still parsed, so a syntax error inside a region rejects the file (exit 65). A start without an end runs to the end of the file. A start inside an open region, or an end with no open region, rejects the file with exit 65 naming the lines. The directive comments themselves stay where they are. Examples are taken verbatim from `packages/zooper_beaver/test/golden/directives/`.

Before:

```dart
// beaver-ignore-start
const matrix = [
  1,  0,   0,
  0,  1,   0,
  0,  0,   1,
];
// beaver-ignore-end
var   after=1;
```

After:

```dart
// beaver-ignore-start
const matrix = [
  1,  0,   0,
  0,  1,   0,
  0,  0,   1,
];
// beaver-ignore-end
var after = 1;
```

Before:

```dart
var  a=1;
// dart format off
var  b=2;
// dart format on
var  c=3;
```

After:

```dart
var a = 1;
// dart format off
var  b=2;
// dart format on
var c = 3;
```

Before:

```dart
void f() {
  call(first+1, // beaver-ignore-start
      second  ,   third); // beaver-ignore-end
  other ( );
}
```

After:

```dart
void f() {
  call(
    first + 1, // beaver-ignore-start
      second  ,   third); // beaver-ignore-end
  other();
}
```

Before:

```dart
var  a=1;
// beaver-ignore-start
var  b=2;
var  c   =3;
```

After:

```dart
var a = 1;
// beaver-ignore-start
var  b=2;
var  c   =3;
```

Before:

```dart
// beaver-ignore
final x   =   1;
final y   =   2;
```

After:

```dart
// beaver-ignore
final x   =   1;
final y = 2;
```

Before:

```dart
var list = [
  aaa  +  bbb,
  // beaver-ignore
  ccc  +  ddd,
  eee  +  fff,
];
```

After:

```dart
var list = [
  aaa + bbb,
  // beaver-ignore
  ccc  +  ddd,
  eee + fff,
];
```
