# Settings audit: duplicates, dead fields and interferences

Date: 2026-10-31. Branch: `feature/continuation-indent`, after the change `chain-and-binary-continuation-indent`. Every claim below was checked against the formatter's real output on that branch (via `beaver --stdin --config`) or against the code that reads the setting. Nothing was changed as part of this audit.

The trigger was two findings made while working on chained calls: `align: true` already keeps the first call on the receiver's line, so `keep_first_call_on_receiver_line` is ignored under it, and a proposed `keep_first_call_on_receiver_line: type_names` would have duplicated `align: type_names`. This document goes through every key in `docs/beaver.template.yaml` with the same question: does any other setting duplicate, disable or silently override another one?

Findings are grouped by severity. Group A is two spellings for one behavior. Group B is a field that is accepted but never read. Group C is settings that interact correctly but in a way a reader has to learn. The decisions taken on them are in the next section; the findings themselves are kept below as the evidence.

## Decisions (2026-10-31)

Taken in discussion after the audit. Guiding rule: stick to established formatter vocabulary and option structure (Rider/ReSharper, Prettier, `dart format`) instead of inventing our own, and document every term with real before/after output.

### D1. The wrap model stays: `policy` + `chop_from`

`chop_if_long` and `chop_from` are kept as they are; both are clear. `chop_from` remains the only count-based trigger (Rider: "max arguments on a single line"). "Too long" has one meaning everywhere: the construct, printed on one line, would push that line past `line_length`. It is never about the number of items.

### D2. `if_long` is renamed `fill`

"Fill" is the right word for the behavior (items follow one another, as many per line as fit, like words in a paragraph) and the behavior itself is correct. The value name `if_long` only states the condition and hides the shape, so it becomes `fill`. The condition needs no repeating: a list only ever breaks when it is too long or when `chop_from` says so, so `fill` and `chop_if_long` both mean "when too long", and only the shape differs. `if_long` stays accepted as an alias.

### D3. `chop_always` and `keep_single_line_if_fits` are removed

`chop_always` is `chop_from: 1` (A2), and `chop_always` + `keep_single_line_if_fits: false` is `chop_from: 2` (A1). Under the preset `keep_single_line_if_fits: true`, `chop_always` on chains was a synonym for `chop_if_long`, a policy value that needed a second key to mean what it says. `policy: chop_always` and `keep_single_line_if_fits` are refused with the replacement named (see D12). The preset's `switch_expressions: chop_always` becomes `chop_from: 1`, to be verified byte-identical.

`chop_from` under `policy: never` stays ignored, as the spec already says ("Policy `never` SHALL suppress it"). Settled 2026-10-31 with the general rule below; a configuration error was considered and rejected.

### D3a. Sub-options are ignored without their parent; contradicting peers are an error

`chop_from` is a sub-option of the breaking policies `fill` and `chop_if_long`: "when this list chops, do it from N items even when the line fits". Under `never` nothing chops, so the sub-option has no parent and is ignored, which keeps `arguments: never` usable as a kill switch over an inherited configuration:

```yaml
# company/.beaver.yaml
wrap:
  arguments: {policy: chop_if_long, chop_from: 3}

# project/.beaver.yaml
extends: ../company/.beaver.yaml
wrap:
  arguments: never         # wrapping off; the inherited chop_from has no policy to apply to
```
```dart
function(first, second, third, fourth);   // left as written
```

This is different from the trailing-comma check (`remove` + `chop_on_trailing_comma` + no kept breaks → exit 78), where three peer settings are all active and together make the output flip between runs. The rule, to be stated once in the `wrap.md` glossary so it is not re-decided per key: a sub-option without its parent is ignored; peer settings that contradict each other are a configuration error. Sub-options so far: `chop_from` (parent: `fill`, `chop_if_long`), `indent_from` (parent: an integer `indent`), `keep_existing_line_breaks` (irrelevant once `chop_from` is reached). Every sub-option's documentation names its parent.

### D4. Bracket placement is a separate question from wrapping, as in Rider

Settled in the grill session, 2026-10-31. Whether a list breaks (and in what shape) and where the brackets sit relative to the items are two different options. Rider has three independent yes/no options per bracket pair ([ReSharper C# line breaks](https://www.jetbrains.com/help/resharper/2017.1/EditorConfig_CSHARP_LineBreaksPageSchema.html)):

| Rider option | Meaning | Beaver |
|---|---|---|
| `wrap_before_invocation_lpar` | line break before `(`: the bracket itself starts a new line | not offered; no Dart style uses it |
| `wrap_after_invocation_lpar` | line break after `(`: the first item starts a new line | new field `break_after_open_bracket: true | false` |
| `wrap_before_invocation_rpar` | line break before `)`: the closing bracket starts a new line | `break_before_close_bracket: true | false`; `close_bracket` stays as alias (`own_line` → true, `after_last_item` → false) |

Both fields are always obeyed; nothing overrides them. Preset `dart`: both `true`, today's output. Today `align: true` on a bracketed list silently did all three things at once (first item on the `(` line, items aligned, `)` after the last item; `lib/src/rules/lists.dart:188`); that coupling goes. Expected output at 40 columns for `print(firstArgument, secondArgument, third);`:

```dart
// break_after_open_bracket: true, break_before_close_bracket: true (preset)
print(
  firstArgument,
  secondArgument,
  third,
);

// break_after_open_bracket: false, break_before_close_bracket: true, indent: inherit
print(firstArgument,
  secondArgument,
  third
);

// break_after_open_bracket: false, break_before_close_bracket: false, indent: first_item  (today's align: true)
print(firstArgument,
      secondArgument,
      third);
```

A configuration that today says only `align: true` gets the preset brackets after this change and has to add the two bracket fields to keep its look. An earlier draft named the field `open_bracket: own_line | same_line`; rejected because "own line" is Rider's *first* row (the bracket on its own line), not the second.

### D8. `indent: inherit | <integer> | first_item` replaces `align`

Settled 2026-10-31. "Where do items 2 and following start" had two keys: `align: true` (the first item's column) and `indent` (N columns from the line), with `align` silently winning (`align: true, indent: 4` ignores the 4). They become one key, `indent`, with a third value:

- `inherit`: the list's documented fallback (`indent.size` or `indent.continuation`), which under `editorconfig: true` comes from the IDE's `.editorconfig`.
- an integer: that many columns from the base `indent_from` names.
- `first_item`: the first item's column, when the first item shares a line with what precedes it (the `(`, or the chain's receiver). When it does not, because `break_after_open_bracket: true` or because the first call broke, there is nothing beside it to align to and `inherit` applies.

`align: true` becomes an alias of `indent: first_item`; `align: false` is dropped (it only ever meant "use `indent`"). `indent_from` applies to the integer values only. The key is `indent`, not `align`: `indent: 3` reads naturally, `align: 3` does not, and `inherit` and the integer are `indent`'s values already. Expected output at 40 columns, `break_after_open_bracket: false`:

```dart
// indent: inherit (2)       // indent: 4                // indent: first_item
print(firstArgument,         print(firstArgument,        print(firstArgument,
  secondArgument,                secondArgument,               secondArgument,
  third);                        third);                       third);
```

Removes: the `align` field on every list, the `BoolOrWord` type and `chainAlignTypeNames` added on 2026-10-31, the spec requirements "Alignment precedence", "Binary expression alignment", "Type-name chain alignment" and "Chained-call alignment value" (rewritten around `indent: first_item`), the `wrap.<list>.align` section of `indent.md`, the `example/wrap.*.align` folders, the goldens `binary_align.stmt`, `align_type_names.stmt` and the align cases in `prefix_placement_chains.stmt`, and the `indent.align.*` aliases (they become aliases of `indent: first_item`).

### D9. `keep_first_call_on_receiver_line` becomes a list of receiver kinds

Settled 2026-10-31. The setting decides one thing: when a method chain breaks, does the first `.call()` stay on the receiver's line. Arguments are never involved; they belong to `wrap.arguments`.

```dart
// input
final names = users.where((u) => u.active).map((u) => u.name).toList();

// first call breaks
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();

// first call stays
final names = users.where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

Whether it should stay depends on what the receiver is: `DateFormat` is a type, and `.yMMMMd()` is how the value is obtained, so `DateFormat` alone on a line is a type name posing as an object; `users` is a value and `.where(...)` a method on it. `dart format` keeps the first call for type-name receivers only; Prettier keeps it for capitalized identifiers, `this` and short identifiers; IntelliJ keeps `ClassName.staticCall()` together by default. A single extra enum value (`type_names`, implemented today as `align: type_names`) bakes one such condition into the key and cannot express its inverse or a third condition. The setting becomes a list of receiver kinds, the same shape as `chop_on_calls` and `chop_on_named_arguments`:

```yaml
wrap:
  chained_calls:
    keep_first_call_on_receiver_line: [type_names]   # a list of kinds, or true | false
```

| Kind | Receiver looks like | Example |
|---|---|---|
| `type_names` | UpperCamelCase identifier, possibly import-prefixed | `DateFormat.yMMMMd().format(x)`, `intl.DateFormat.yMMMMd()` |
| `identifiers` | any other plain identifier | `users.where(f).toList()` |
| `this` | `this` or `super` | `this.copyWith(a: 1).save()` |
| `calls` | a call result | `fetch().then(f).catchError(g)` |
| `properties` | a property path | `theme.textTheme.labelMedium.copyWith(c).merge(o)` |

`true` is an alias of every kind, `false` of `[]`. Preset `dart`: `[]`. A new kind is one list element, never a new combination. Expected output at 60 columns:

```dart
// input
final d = DateFormat.yMMMMd().format(invitation.invitedAt.toLocal());
final names = users.where((u) => u.active).map((u) => u.name).toList();

// []                       // [type_names]  (dart format)    // [identifiers]
final d = DateFormat        final d = DateFormat.yMMMMd()     final d = DateFormat
    .yMMMMd()                   .format(invitation...);           .yMMMMd()
    .format(invitation...);  final names = users                  .format(invitation...);
final names = users             .where((u) => u.active)      final names = users.where((u) => u.active)
    .where((u) => u.active)     .map((u) => u.name)              .map((u) => u.name)
    .map((u) => u.name)         .toList();                       .toList();
    .toList();
```

With `indent: first_item` on top, the calls after a kept first call align under its `.`; a chain whose first call broke has nothing beside it and uses `inherit`, so `[type_names]` + `first_item` gives `DateFormat.yMMMMd()` / `.format(...)` aligned and `users` / `.where(...)` at the continuation indent. Removes `align: type_names` from the open change `chain-and-binary-continuation-indent` (schema, `chainAlignTypeNames`, `_isTypeName` stays and gains the other kinds, `align_type_names.stmt` rewritten, `indent.md` section, example folder, both delta specs).

### D5. `keep_existing_line_breaks` stays

It is an established feature (Rider: "Keep existing line breaks"; Prettier keeps the first-line break of object literals; `dart format`'s trailing comma is a weaker form). Its description changes to what it does: the formatter adds line breaks where a line is too long but never removes a break the developer typed between items. The trade-off is documented next to it: `true` lets two developers get different, equally stable layouts from the same code; `false` makes the formatter own the layout and rewrites hand-chosen breaks.

### D6. A glossary with examples goes at the top of `wrap.md`

Every rule page uses only these words. Each term carries real formatter output; the draft below was produced by Beaver at 40 columns (arguments) and 60 columns (chains), input always the single-line form.

**Too long.** The construct on one line would exceed `line_length`.

```dart
function(first, second, third);          // 33 chars: fits, untouched
function(                                // 65 chars on one line: too long, so it breaks
  firstArgument,
  secondArgument,
  thirdArgument,
  fourth,
);
```

**`never`.** Ignore "too long"; the line stays as written, 65 characters wide.

```dart
function(firstArgument, secondArgument, thirdArgument, fourth);
```

**Fill (`fill`).** When too long, items follow one another, as many per line as fit. An item that does not fit starts a new line; an item that is itself too long gets a line of its own and breaks inside if it can, or overflows if it is atomic.

```dart
function(
  firstArgument, secondArgument,
  thirdArgument, fourth,
);
```

**Chop (`chop_if_long`).** When too long, one item per line.

```dart
function(
  firstArgument,
  secondArgument,
  thirdArgument,
  fourth,
);
```

**`chop_from: N`.** One item per line from N items, even when the line fits. The only count-based trigger.

```dart
function(a, b);         // 2 items: untouched
function(               // 3 items, 18 chars: chopped because of the count
  a,
  b,
  c,
);
```

**Kept line break (`keep_existing_line_breaks: true`, the preset).** A break the developer typed between items makes the list break; it is not a chop request, items still share lines where they fit.

```dart
// typed; fits in 40 columns
function(first,
    second, third);

// chop_if_long keeps the grouping
function(
  first,
  second, third,
);

// fill flows in runs
function(
  first, second,
  third, fourth, fifth,
);

// keep_existing_line_breaks: false
function(first, second, third);
```

**Bracket placement.** Independent of all of the above: `break_after_open_bracket` (does the first item start a new line) and `break_before_close_bracket` (does the closing bracket start a new line). See D4.

**The same on chains** (60 columns; the "items" are the calls):

```dart
// chop_if_long
final a = x.b().c();
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();

// fill
final a = x.b().c();
final names = users.where((u) => u.active)
    .map((u) => u.name).toList();

// chop_from: 2 (today's chop_always + keep_single_line_if_fits: false)
final a = x
    .b()
    .c();
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

### D7. Dead `chop_on_trailing_comma` fields are removed (B1)

Offered only on the four bracketed lists that read it (`arguments`, `parameters`, `collection_literals`, `enum_values`). Setting it elsewhere becomes exit 78, as `align` on `cascades` already is. Settled 2026-10-31 that this includes `switch_expressions`: switch arms do have commas, but Beaver prints them exactly as in the source because arm commas are not on the structural verifier's optional-comma list (`expressions.dart:935`), so the field has nothing to act on there.

Observed, not decided: Beaver differs from `dart format` on switch-arm commas. `dart format` always adds a comma after the last arm; Beaver keeps whatever the source has. Making switch commas configurable (`trailing_commas` on the list, arm commas on the verifier's optional list, preset decision) is a feature of its own, not part of this cleanup.

```dart
// input: final x = switch (y) { 1 => alpha, 2 => beta };
// Beaver preset                 // dart format
final x = switch (y) {           final x = switch (y) {
  1 => alpha,                      1 => alpha,
  2 => beta                        2 => beta,
};                               };
```

### D10. `trailing_commas` is a sub-option of `break_before_close_bracket: true`

Settled 2026-10-31, closing C1 by D3a. A trailing comma is only meaningful when the closing bracket starts its own line; no established formatter prints `ccc,)`. With `break_before_close_bracket: false` no comma is added and a source comma is dropped, also under `preserve`, which is today's behavior (`lists.dart:138`). No behavior change; `wrap.md` names the parent in both the `trailing_commas` and the `break_before_close_bracket` sections ("including one in the source"). The oscillation check keeps counting the suppressed comma as a removing policy.

```yaml
wrap:
  arguments: {break_before_close_bracket: false}
trailing_commas: add_when_wrapped        # has no parent here: ignored
```
```dart
g(
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,
  ccccccccccccccc);
```

### D11. Bracket fields win over a source break next to the bracket

Settled 2026-10-31. `keep_existing_line_breaks` is about the gaps between items. A source line break directly after the opening bracket or directly before the closing bracket follows `break_after_open_bracket` / `break_before_close_bracket` instead of being kept; otherwise `break_after_open_bracket: false` would mean "unless someone once typed a break there". Today the gap after `(` counts like a gap between items (`lists.dart:60`, `gaps[0]`); under the preset (`true`) nothing changes. Expected output with `break_after_open_bracket: false`:

```dart
// input                      // output
print(                        print(first, second, third);       // the break after ( is not kept
    first, second, third);
print(first,                  print(first,                       // the break between items is kept
    second, third);             second, third);
```

`wrap.md`, `keep_existing_line_breaks` section: "between items; a break directly after the opening or before the closing bracket follows the bracket fields".

### D12. Renames are aliases; removals are errors that name the replacement

Settled 2026-10-31. The recorded alias pattern (`wrap.md`: "accepted without deprecation and identical to their canonical key", `loader.dart` one-to-one table) covers every one-to-one rename: `if_long` → `fill`, `close_bracket: own_line | after_last_item` → `break_before_close_bracket: true | false`, `indent.align.*` and `align: true` → `indent: first_item`. `align: false` only ever meant "use `indent`" and is accepted and dropped. The two spellings that are not one-to-one are refused with exit 78 and the replacement in the message, like an unknown key:

```
.beaver.yaml: `wrap.chained_calls.policy: chop_always` was replaced by `chop_from`; write `chop_from: 1`
              (with `keep_single_line_if_fits: false` on a chain: `chop_from: 2`).
.beaver.yaml: `wrap.chained_calls.keep_single_line_if_fits` was removed; see `chop_from`.
```

Rejected: a value-alias mechanism that expands `chop_always` into two keys and drops `keep_single_line_if_fits` depending on its neighbour. Aliases are for spellings that mean exactly the same thing; `chop_always` meant different things depending on a second key, which is why it goes. An explicit `chop_from` next to `chop_always` in one file needs no special case once `chop_always` is an error. Preset: `switch_expressions.policy: chop_if_long` + `chop_from: 1` (to be verified byte-identical to today).

### Nothing left open

Every finding has a decision (table below). Observed but deliberately not decided here: switch-arm commas differ from `dart format` (D7).

### What the decisions change, by area

- **Schema** (`schema.dart`): `policy` values `never | fill | chop_if_long` (D2, D3); `chop_on_trailing_comma` only on the four delimited lists (D7); `align` removed, `indent` gains `first_item` (D8); `BoolOrWord` removed (D8); `keep_first_call_on_receiver_line` becomes a list of kinds with `true`/`false` accepted (D9); `break_after_open_bracket` and `break_before_close_bracket` on the delimited lists, `close_bracket` kept as alias (D4); `keep_single_line_if_fits` and `chop_always` removed (D3).
- **Loader** (`loader.dart`): aliases for the one-to-one renames; `align: false` dropped; errors with replacement text for `chop_always` and `keep_single_line_if_fits` (D12).
- **Preset** (`dart_preset.dart`): `switch_expressions` to `chop_if_long` + `chop_from: 1`; `close_bracket: inherit` becomes `break_before_close_bracket: inherit`; output byte-identical.
- **Layout**: `lists.dart` obeys both bracket fields independently of alignment (D4) and ignores a source break next to a bracket under `false` (D11); `chains.dart` drops the `keep_single_line_if_fits` branch (D3), takes the receiver-kind list (D9) and `indent: first_item` (D8); `expressions.dart` binary alignment via `indent: first_item` (D8).
- **Specs**: `formatting-rules` requirements "Chained call wrapping", "Alignment precedence", "Binary expression alignment", "First chained call on the receiver line", "Type-name chain alignment", "Item threshold forces chopping" (`never` wording stays, D3a); `config-resolution` requirements "Canonical long-form keys", "Aliases map one-to-one", "Chained-call alignment value", the list-field inventory (D7), new requirements for the removal errors (D12) and the sub-option rule (D3a).
- **Docs**: `wrap.md` glossary (D6) with the sub-option rule (D3a), `keep_existing_line_breaks` rewritten (D5, D11), `trailing_commas` and bracket sections naming the parent relationship (D10); `indent.md` `wrap.<list>.align` section replaced by `indent: first_item`; the template regenerated.
- **Examples and goldens**: folders for `align`, `chop_always`, `keep_single_line_if_fits`, `close_bracket` replaced by `indent`, `break_after_open_bracket`, `break_before_close_bracket`, `keep_first_call_on_receiver_line` kinds; goldens mentioning `align=`, `chop_always`, `if_long`, `close_bracket=` rewritten; `align_type_names.stmt` becomes a `keep_first_call_on_receiver_line` file.
- **The open change `chain-and-binary-continuation-indent`**: its `align: type_names` part (schema, `chainAlignTypeNames`, `_isTypeName` call site, goldens, docs, example, both delta specs) is superseded by D8/D9 before it is archived.

## Mapping of findings to decisions

| Finding | Decision |
|---|---|
| A1 `keep_single_line_if_fits` | removed, error naming `chop_from` (D3, D12) |
| A2 `chop_always` | removed, error naming `chop_from: 1` (D3, D12) |
| A3 `align` ⊃ `keep_first_call_on_receiver_line` | dissolved: `align` removed (D8), `type_names` moves to a list on `keep_first_call_on_receiver_line` (D9) |
| B1 dead `chop_on_trailing_comma` | removed from seven lists (D7) |
| B2 `quotes_avoid_escapes` | no action, documented as conditional |
| C1 `after_last_item` suppresses commas | sub-option, no change (D10) |
| C2 three deferral words in `blank_lines` | no action |
| C3 `break_before` outside the list maps | no action |
| C4 `indent_from: line` special case | no action, documented |
| (new) opening bracket coupled to `align` | `break_after_open_bracket` / `break_before_close_bracket` (D4) |
| (new) `align` and `indent` answer one question | `indent: inherit | <integer> | first_item` (D8) |
| (new) `align: type_names` bakes a condition into an enum | list of receiver kinds (D9) |
| (new) `if_long` hides its shape | renamed `fill` (D2) |
| (new) terms undefined | glossary with examples (D6) |
