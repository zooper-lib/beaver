# Proposed settings

Candidates for the next round of `.beaver.yaml` keys. The first section proposes a common value vocabulary and per-construct shape, borrowed from Rider and IntelliJ. The middle sections list new keys grouped like the existing rule pages. After that, every existing key gets the smallest addition that would round it out, then come transformations deferred to a future `beaver cleanup` command, ideas considered and parked, and ideas rejected. Each entry gives the proposed type and default, the tool it comes from where there is one, and a before/after pair. Every "today" output was checked against the current formatter.

The default of every new key reproduces today's output, so adding a key never changes a formatted project, with two deliberate preset changes recorded where they are decided: `blank_lines.between_comment_and_declaration` defaults to `preserve`, and `wrap.cascades.keep_existing_line_breaks` resolves to `true`. Everything up to the deferred-cleanup section stays inside the safety check: same tokens, same syntax tree, same comments.

## Suggested first batch

What to build first if the whole list is too much. Chosen for demand in Dart and Flutter code and for bounded implementation cost. Everything else can wait for someone to ask.

| Key | Why first |
|---|---|
| Canonical per-construct maps, with policy, count threshold, break preservation, comma behaviour, delimiter placement, indentation and alignment where applicable | The one structural change; every later list key is defined in terms of it |
| `wrap.cascades` (preset `chop_if_long`, `chop_from: 2`), `wrap.switch_expressions` | Constructs with no knob at all today |
| `wrap.arguments.hug_block_argument` | The most visible `dart format` opinion people want to turn off |
| `wrap.chop_on_calls` | Flutter widget trees without relying on trailing commas |
| `blank_lines.between_comment_and_declaration` | Answers the open dogfooding question; default `preserve` is a deliberate preset change |
| `blank_lines.between_top_level_declarations`, with `around_class_declarations: inherit` and `keep_between_non_block_top_level_declarations` | Today only class-like declarations get an exact count; the three keys together are the settled behaviour |
| `trailing_commas: add_when_chopped` | Removes the surprise comma after a filled list |
| `spaces.before_trailing_comment` | Two-space trailing comments are common and cost one integer |

Per-layer normalisation and validation, canonical-key merging, and post-merge fallback resolution with provenance underpin the per-construct settings; not every independent scalar needs fallback resolution, but the shared configuration foundation must support those operations. The generated reference template (next section) is a companion deliverable of this batch: the interactions above make discoverability essential.

## Reference template

Whatever subset ships, Beaver needs one file that shows every key with every allowed value and its preset default, so nobody has to assemble the configuration surface from the rule pages. Rider and IntelliJ have the settings dialog for this; a YAML-driven tool has the template file.

- Generated from the schema, not written by hand: `beaver config --template` prints it, and a test fails when the output and the committed copy at `docs/beaver.template.yaml` differ, the same way `example/` is kept honest.
- One line per key, set to the `dart` preset value, with the alternatives in a trailing comment: `arguments: chop_if_long  # never | if_long | chop_if_long | chop_always`. Integers state the minimum. Lists show an example entry.
- Map-shaped keys appear in their long form with every field, and a comment states that the scalar shorthand is accepted.
- The README and `docs/install.md` point to it as the starting point for a new `.beaver.yaml`: copy, delete the lines you do not care about.

## Value vocabulary and per-construct shape

Rider and IntelliJ give every wrappable construct the same five-way choice plus a count threshold, and let "keep existing arrangement" be chosen per construct. Beaver has the four policies but keeps the other two choices global (`wrap.keep_existing_line_breaks`, `wrap.chop_on_trailing_comma`) or special-cased (`wrap.chained_calls.min_calls`). The single change with the most leverage is to give every list the same shape.

| Rider | IntelliJ | Beaver today | Proposed |
|---|---|---|---|
| Do not wrap | Do not wrap | `never` | `never` |
| Simple wrap | Wrap if long | `if_long` | `if_long` |
| Chop if long | Chop down if long | `chop_if_long` | `chop_if_long` |
| Chop always | Wrap always | `chop_always` | `chop_always` |
| Keep existing arrangement | Keep line breaks | `keep_existing_line_breaks: true`, global | the same flag, per construct |
| Max N on a single line | (none) | `chained_calls.min_calls` only | `chop_from: N` on every list |

### Keeping the existing arrangement

Rider's "keep existing arrangement" is already Beaver's default: with `keep_existing_line_breaks: true`, items that shared a line keep sharing it and breaks stay where they were, so coordinate pairs and matrices survive. No new policy value is needed. What is missing is choosing it per construct: a team that wants developer breaks honoured in collections but normalised in argument lists has no way to say so today.

Before:

```dart
const corners = [
  Offset(0, 0), Offset(1, 0),
  Offset(0, 1), Offset(1, 1),
];
```

After (today, and after with `wrap.collection_literals.keep_existing_line_breaks=true`): unchanged.

After with `wrap.collection_literals.keep_existing_line_breaks=false`:

```dart
const corners = [
  Offset(0, 0),
  Offset(1, 0),
  Offset(0, 1),
  Offset(1, 1),
];
```

### Decided: canonical long form, shorthand as an alias

The schema holds only long-form leaves: `wrap.arguments.policy`, `wrap.arguments.chop_from`, `wrap.arguments.keep_existing_line_breaks`, `wrap.arguments.chop_on_trailing_comma`, `wrap.arguments.align`, and the same five under every list. `wrap.chained_calls` is already shaped this way, so this generalises the project's own precedent. Both spellings below stay valid, without deprecation; the first is an alias of `wrap.arguments.policy`.

```yaml
wrap:
  arguments: chop_if_long

wrap:
  arguments:
    policy: chop_if_long
    chop_from: 4
    keep_existing_line_breaks: false
```

Rules that go with it, settled in review:

- **Normalise each layer, then merge.** Every configuration source (a `.beaver.yaml`, the golden harness's file options, its case options) is rewritten to canonical keys on its own before the inheritance merge in `resolve.dart`. So `arguments: never` in a child overrides only `arguments.policy` and keeps an inherited `chop_from`; shorthand and its long form behave identically. The runner currently spreads file and case options into one merge; each must be normalised first.
- **One operation at every entry point.** `validateValues` becomes `normalizeAndValidateValues` and returns the canonical map; every caller consumes the result. No second alias table.
- **Conflicting spellings in one layer are an error.** `indent.align.arguments: true` next to `wrap.arguments.align: false` in the same file fails with the existing configuration-error exit code and names both keys; identical duplicate values are accepted. Across layers the nearer file wins per canonical key, whatever the spelling.
- **Diagnostics use the user's spelling.** `wrap: {arguments: sometimes}` still reports `wrap.arguments` with the four policies, plus the canonical name. The existing spec scenario stays as the alias test; a canonical-form scenario is added.
- **Aliases:** `wrap.<list>` to `wrap.<list>.policy`; `indent.align.arguments`, `indent.align.parameters`, `indent.align.chained_calls` to `wrap.<list>.align`; `wrap.chained_calls.min_calls` to `wrap.chained_calls.chop_from`; `wrap.before_operator` to `wrap.break_before` (see that entry).

**Inheriting the global flags.** The per-construct `keep_existing_line_breaks` and `chop_on_trailing_comma` accept `true | false | inherit`. The preset supplies `inherit`. Omitting the key keeps the parent layer's value; writing `inherit` restores the link to the global key, which an absence-only design cannot express. `inherit` is resolved after the entire chain has merged, so it follows the final effective global value, including a global override in the child. The formatter receives concrete booleans only; inheritance never reaches the rules. `config --print` keeps its contract of fully resolved values: it prints the effective boolean and states in its comment both where `inherit` was configured and which file supplied the global value, which means provenance tracks two sources for such a key rather than one. The generated template prints `inherit`, because a template documents the intended fallback, not a snapshot. `policy`, `chop_from` and `align` inherit through `extends` like every key and have plain preset defaults; there is no global policy or alignment to fall back to.

This rules out a union "scalar or map" value type, special cases in `flatten()`, and any key that is both a leaf and a prefix. It changes the config-resolution spec ("every key has a value" now distinguishes the configured `inherit` from the resolved boolean), `docs/rules/wrap.md` and `docs/rules/indent.md` (canonical names, aliases listed once), and the `example/` folder names for the renamed keys.

### `chop_from` in practice

Rider's "Max formal parameters on a single line" and "Max enum members on a single line", generalised. Flutter widget trees are the common case: `child:` lists are already handled by `chop_on_named_arguments`, this covers positional-heavy APIs and long parameter lists. Default `0` everywhere, which is today's behaviour.

Decided rule, settled in review:

> `chop_from: N` forces one item per line when the construct contains at least N syntactic items. `0` disables this trigger. `policy: never` suppresses it. Otherwise, reaching the threshold defeats filling, kept groups, trailing-argument hugging, and `keep_single_line_if_fits`. Nested constructs are evaluated independently. Binary operands are counted within one flattened run of operators at the same precedence; parenthesized expressions and expressions at another precedence each count as one operand of the enclosing run.

| Policy | Below threshold, or `chop_from: 0` | At or above threshold |
|---|---|---|
| `never` | No discretionary wrapping between items | Same; threshold suppressed |
| `if_long` | Fill when wrapping is needed | Chop |
| `chop_if_long` | Chop when wrapping is needed | Chop regardless of width |
| `chop_always` | Chop | Chop |

"One item per line" governs the separators between items; an item may itself span lines, and operator placement stays with `wrap.break_before`. Counting is syntactic and per list: a named argument or trailing closure is one argument; a spread or a collection `if`/`for` element is one element whatever it produces at runtime; a nested list is counted on its own, even when it fits on one line, because the threshold can itself force the nested list to wrap; chains keep today's `min_calls` counting. `never` suppressing the threshold follows the precedence the code already applies to `min_calls` (`chains.dart` returns the flat chain under `never` before reading the count), to source trailing commas and to `chop_on_named_arguments`, whose rule page says `never` wins. It is not a configuration error, unlike the trailing-comma conflict: that combination changes output between runs, this one is stable, and an inheriting file can say `arguments: never` without having to discover and clear an inherited threshold. Below the threshold every other setting operates as usual; being below it never forces a list onto one line.

Before:

```dart
canvas.drawLine(start, end, paint);
```

After with `wrap.arguments.chop_from=3`:

```dart
canvas.drawLine(
  start,
  end,
  paint,
);
```

Before:

```dart
enum Side { left, right }
```

After with `wrap.enum_values.chop_from=2`:

```dart
enum Side {
  left,
  right,
}
```

## Wrapping

### `wrap.cascades`

Policy map for cascade sections (`..`). IntelliJ (Dart) has "Cascade: wrap". Today, checked against the formatter: a one-section cascade stays inline when it fits and breaks when it does not; two or more sections always chop; a multi-line collection target keeps a single section on its closing line (`]..add(3)`); a source break inside a one-section cascade is removed. Decided in review: the count-and-width rule is represented by the settled vocabulary, not by a `chop_always` default with a hidden one-section exception.

```yaml
wrap:
  cascades:
    policy: chop_if_long
    chop_from: 2
    keep_existing_line_breaks: inherit   # deliberate preset change, see below
    indent: inherit                      # inherits indent.size
```

**Deliberate preset change.** `keep_existing_line_breaks: inherit` resolves to `true` under the preset, so a developer's break inside a one-section cascade now stays where today it is joined back. Cascades thereby honour the same global preference as every other wrappable construct; a team wanting today's normalisation sets `wrap.cascades.keep_existing_line_breaks: false`. The relevant breaks are cascade-level only: the gap between the receiver and the first section, and the gaps between sections. Newlines inside the receiver or inside a section do not count, so a multi-line collection ending in `]..sort()` has no source break between receiver and section and preservation does not force one. `never` suppresses discretionary break preservation and a reached threshold forces chopping independently, as settled. The existing behaviour is recorded as an inconsistency with the global preference, not as a judgement of its intent; the decision stands on consistent preservation, an explicit normalisation option, and disclosure of the changed default output. The rest of the map reproduces today's output.

Before:

```dart
final p = Paint()..color = Colors.red..strokeWidth = 2;
```

After with the preset (two sections reach `chop_from`):

```dart
final p = Paint()
  ..color = Colors.red
  ..strokeWidth = 2;
```

After with `wrap.cascades.chop_from=0`:

```dart
final p = Paint()..color = Colors.red..strokeWidth = 2;
```

### `wrap.initializer_lists`

Constructor initializer lists. ReSharper: "Wrap constructor initializer", "Place ':' on new line", "Indent constructor initializer". Today a short list stays on the header line; a long one breaks with `:` two columns in (`indent.size`) and later initializers aligned under the first, except that when the parameter list itself split, the colon follows the closing parenthesis (`) : first = value,` with the rest aligned under `first`). Decided in review: one map holds policy, indentation, alignment and colon placement, and its preset reproduces today's output exactly. Colon spacing stays under `spaces`.

```yaml
wrap:
  initializer_lists:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    align: true          # later initializers align under the first
    indent: inherit      # baseline of the broken list; inherits indent.size
    colon: auto          # today's header-sensitive placement
```

- **`indent` and `align` control different things.** `indent` is the baseline offset of the broken list relative to the constructor declaration; `align: true` lines later initializers up under the first; `align: false` indents them by the configured indentation from that baseline. The numeric indent is never added on top of the alignment column, and the field never becomes the indentation policy for expressions nested inside an initializer.
- **`colon: auto | new_line | end_of_header`.** `auto` is the current header-sensitive behaviour; the explicit values select their position whenever the list breaks. A short, unbroken list stays inline under all three. A two-value key could not describe today's output without a misleading exception.
- **Per-construct `indent` is general, with construct-specific fallbacks.** The field is `inherit | integer` on every list that owns a defined list-level baseline (arguments, parameters, collections, chains, cascades, binary expressions, initializer lists, and the rest as they gain maps); constructs where it would have no effect do not accept it. `inherit` has one documented fallback per construct, resolved after the chain merges and shown in provenance: chained calls and binary expressions inherit `indent.continuation`; cascades, initializer lists, arguments, parameters and collections inherit `indent.size`. Cascades are not fixed at two columns, they follow `indent.size`, so a literal preset of `2` would have changed configurations with another indent size. The standalone `indent.<construct>` keys from the first draft are withdrawn.

Examples should show both `align` values under both explicit colon positions so the anchors are unambiguous; the two below fix the shape.

Before:

```dart
Point(this.x, this.y) : _len = sqrt(x * x + y * y), _label = '$x,$y';
```

After with `wrap.initializer_lists.policy=chop_always` (other fields preset):

```dart
Point(this.x, this.y)
  : _len = sqrt(x * x + y * y),
    _label = '$x,$y';
```

After with `wrap.initializer_lists.policy=chop_always wrap.initializer_lists.colon=end_of_header wrap.initializer_lists.align=false`:

```dart
Point(this.x, this.y) :
    _len = sqrt(x * x + y * y),
    _label = '$x,$y';
```

### `wrap.annotations`

Whether an annotation shares the line with the declaration it decorates. `dart format` puts declaration annotations on their own line and parameter annotations on the parameter's line. ReSharper: "Place attribute on same line"; IntelliJ: "Annotations: wrap". Type: `own_line | same_line | preserve`, default `own_line`. Parameter annotations keep today's behaviour under all values.

Before:

```dart
@override void dispose() { super.dispose(); }
```

After with `wrap.annotations=own_line` (today):

```dart
@override
void dispose() {
  super.dispose();
}
```

After with `wrap.annotations=same_line`:

```dart
@override void dispose() {
  super.dispose();
}
```

### `wrap.arguments.hug_block_argument`

Whether one block argument may hug the call's parentheses (`f(a, () {` … `})`, `f(a, [` … `], b)`) instead of being laid out like any other item. `dart format` and Prettier hug. Decided in review: a plain boolean field on the arguments map, preset `true`, no global and no `inherit`; the first draft's global `hug_trailing_argument` misnamed the mechanism, which is neither limited to the last position nor to function literals.

> When `true`, Beaver may use its special hugging layout for exactly one eligible block argument, wherever that argument occurs. When `false`, Beaver formats the argument list using its ordinary policy, break-preservation, alignment, and chop settings.

"May" matters: `true` permits hugging, it does not override eligibility, comments or width. `false` does not force a chop: under `if_long` the list can still fill, and kept source groups can remain; chopping stays with the policy and its triggers.

- Eligible: a block-bodied function literal, a non-empty list, set or map literal, or a record with more than one field when it is the sole argument. A named argument is judged by its underlying expression. Not eligible: an `=>` lambda, an empty collection.
- A source trailing comma prevents hugging even when `chop_on_trailing_comma` is `false`, as the helper does today. Kept surrounding breaks and comments can prevent it, and the other arguments must meet the helper's simplicity and fit conditions.
- `never`, `chop_always`, alignment, a named-argument match, a `chop_on_calls` match and a reached threshold take precedence.
- The field never controls wrapping inside the block argument; nested contents keep their own settings.

Before:

```dart
test('adds', () { expect(add(1, 2), 3); });
```

After with `wrap.arguments.hug_block_argument=true` (today):

```dart
test('adds', () {
  expect(add(1, 2), 3);
});
```

After with `wrap.arguments.hug_block_argument=false` (the list no longer fits, so `chop_if_long` chops it):

```dart
test(
  'adds',
  () {
    expect(add(1, 2), 3);
  },
);
```

### `wrap.braceless_bodies`

Where the single statement of a braceless `if`, `else`, `for` or `while` goes. `dart format` keeps it on the same line when it fits. ReSharper: "Place simple embedded statement on same line". Type: `same_line_if_fits | new_line | preserve`, default `same_line_if_fits`.

Before:

```dart
if (items.isEmpty) return null;
```

After with `wrap.braceless_bodies=new_line`:

```dart
if (items.isEmpty)
  return null;
```

### `wrap.simple_case_bodies_on_one_line`

Keep a `case` whose body is one short statement on the case line. ReSharper: "Place simple case statement on same line". Same family as `simple_blocks_on_one_line`. Type: bool, default `false`.

Before:

```dart
switch (code) {
  case 200:
    return ok;
  case 404:
    return missing;
}
```

After with `wrap.simple_case_bodies_on_one_line=true`:

```dart
switch (code) {
  case 200: return ok;
  case 404: return missing;
}
```

### `wrap.switch_expressions`

Policy for switch expression arms. `dart format` puts every arm on its own line, which makes two-arm switches tall. Type: policy, default `chop_always`.

Before:

```dart
final label = switch (side) { Side.left => 'L', Side.right => 'R' };
```

After with `wrap.switch_expressions=chop_if_long`:

```dart
final label = switch (side) { Side.left => 'L', Side.right => 'R' };
```

### `wrap.control_conditions`

How a condition that does not fit inside `if (...)`, `while (...)` or `for (...)` is laid out. `dart format` continues on the next line with extra indent and keeps `)` on the last operand's line; Prettier and ktfmt move it into a block (`(` at the end of the line, `)` on its own line), which reads like an argument list. Type: `continuation | block`, default `continuation`.

Before:

```dart
if (user.isActive && user.hasVerifiedEmail && !user.isSuspended) { grant(); }
```

After with `wrap.control_conditions=continuation` (today):

```dart
if (user.isActive &&
    user.hasVerifiedEmail &&
    !user.isSuspended) {
  grant();
}
```

After with `wrap.control_conditions=block`:

```dart
if (
  user.isActive &&
  user.hasVerifiedEmail &&
  !user.isSuspended
) {
  grant();
}
```

### `wrap.class_header`

Policy for `extends`, `with` and `implements` clauses, plus whether `extends` may stay on the `class` line when the header splits. ReSharper: "Wrap extends/implements list", "Place extends/implements on new line". Today every clause, `extends` included, moves to its own line. Type: policy, default `chop_if_long`. Companion field `wrap.class_header.clauses_on_new_line: bool`, preset `true`; `false` keeps `extends` with the class name, which is how most Flutter code reads when written by hand.

Before:

```dart
class HomeScreen extends StatefulWidget with RouteAware implements PreferredSizeWidget {}
```

After with the defaults (today, at 80 columns):

```dart
class HomeScreen
    extends StatefulWidget
    with RouteAware
    implements PreferredSizeWidget {}
```

After with `wrap.class_header.clauses_on_new_line=false`:

```dart
class HomeScreen extends StatefulWidget
    with RouteAware
    implements PreferredSizeWidget {}
```

### `wrap.close_bracket`

Where `)`, `]` and `}` of a chopped list go. IntelliJ: "Place ')' on new line". `dart format` puts the closer on its own line; `after_last_item` is the pre-2.0 Dart look (`paint);`) and the Java default. The matching opener choice (IntelliJ "New line after '('", first item on the opener's line, the rest aligned under it) already exists as the per-list `align` field, so there is no `open_bracket` key.

Decided in review:

> `after_last_item` places the closing delimiter after the final item and suppresses an optional trailing comma. Required commas are preserved. Comma suppression participates in the per-construct stability check.

- **Scope.** A global `wrap.close_bracket: own_line | after_last_item`, default `own_line`, plus a `close_bracket` field on every delimiter-owning list (`arguments`, `parameters`, `collection_literals`, `enum_values`, and the other bracketed lists as they gain maps) accepting the same two values and `inherit`, preset `inherit`, resolved after the chain merges like the other inheriting fields. Binary expressions, chains and cascades own no delimiter and do not accept the field. Wanting `)` after the last argument while collection closers keep their own line is a coherent preference, so a global-only key was rejected.
- **Suppression is of optional commas only.** A single positional field record still prints `(value,)`; the comma and closer then share a line because the syntax requires it. "Whatever `trailing_commas` says" never means deleting a required comma.
- **Stability.** The per-construct oscillation check uses actual emission behaviour, so suppression by delimiter placement counts as effective removal for that list, with the configured comma policy and the suppressing key both kept for the diagnostic: "arguments inherit `add_when_wrapped`, but `wrap.close_bracket: after_last_item` suppresses optional trailing commas; combined with comma-triggered chopping and disabled break preservation this can produce different output on successive runs." The policy exemptions apply as settled: `never` has no comma trigger to undo, `chop_always` supplies a persistent chop, and a reached threshold supplies a persistent chop for that list instance only, so a non-zero `chop_from` alone does not make a configuration stable.
- **Why not emit the comma anyway.** `paint,);` is not incorrect, it is simply not what this option means; documented suppression is chosen as part of the option's meaning and must stay explicit and observable.

```yaml
wrap:
  close_bracket: own_line
  arguments:
    close_bracket: after_last_item
  collection_literals:
    close_bracket: inherit
```

Before:

```dart
canvas.drawLine(start, end, paint);
```

After with the default (chopped):

```dart
canvas.drawLine(
  start,
  end,
  paint,
);
```

After with `wrap.arguments.close_bracket=after_last_item`:

```dart
canvas.drawLine(
  start,
  end,
  paint);
```

### `wrap.break_before`

Rider has one "Prefer wrap before" checkbox per operator kind; Beaver has only `wrap.before_operator`. Decided in review: four independently inherited booleans under one prefix, not a list, so a child configuration can override one choice and keep the other three. `wrap.before_operator` is a one-to-one alias of `wrap.break_before.binary_operator`, both values passing through unchanged, under the normalisation, conflict and diagnostic rules settled for aliases. No list shorthand: it adds no formatting capability and would need a rule for what an omitted entry means.

```yaml
wrap:
  break_before:
    binary_operator: false      # today's output
    conditional_operator: true  # `?` and `:` already lead their lines
    arrow: false
    assignment: false
```

These settings choose which side of the operator receives a break when wrapping occurs. They do not themselves force wrapping; policies and `chop_from` decide that.

Before:

```dart
String describe(Order order) => '${order.id}: ${order.items.length} items, ${order.total}';
final decoded = jsonDecode(response.body) as Map<String, dynamic>;
```

After with the default (at 60 columns):

```dart
String describe(Order order) =>
    '${order.id}: ${order.items.length} items, ${order.total}';
final decoded =
    jsonDecode(response.body) as Map<String, dynamic>;
```

After with `wrap.break_before.arrow=true wrap.break_before.assignment=true`:

```dart
String describe(Order order)
    => '${order.id}: ${order.items.length} items, ${order.total}';
final decoded
    = jsonDecode(response.body) as Map<String, dynamic>;
```

### `wrap.chained_calls.keep_first_call_on_receiver_line`

When a chain chops, keep the first call on the receiver's line (`list.where(...)` then `.map(...)` below) instead of breaking before every call. IntelliJ Kotlin: "Chained method calls: wrap first call". Type: bool, default `false`.

Before:

```dart
final names = users.where((u) => u.active).map((u) => u.name).toList();
```

After with `keep_first_call_on_receiver_line=false` (today, at 50 columns):

```dart
final names = users
    .where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

After with `keep_first_call_on_receiver_line=true`:

```dart
final names = users.where((u) => u.active)
    .map((u) => u.name)
    .toList();
```

## Indentation

### `wrap.binary_expressions.align`

Align continuation lines of a binary expression under the first operand instead of indenting by `indent.continuation`. IntelliJ: "Binary expressions: align when multiline". Type: bool, default `false`. The key is global for the construct kind: it applies wherever a binary expression wraps (after `=`, inside an argument, in a `return`, in an `if` condition), and the alignment column follows from wherever the first operand landed. Under the per-construct shape it is `wrap.binary_expressions.align`; a per-context split (conditions versus the rest) is not proposed, IntelliJ does not have one either. Its `indent` sibling inherits `indent.continuation`.

Before:

```dart
final total = subtotal + shipping + tax - discount;
```

After with `wrap.binary_expressions.align=false` (today, at 30 columns):

```dart
final total = subtotal +
    shipping +
    tax -
    discount;
```

After with `wrap.binary_expressions.align=true`:

```dart
final total = subtotal +
              shipping +
              tax -
              discount;
```

## Spaces

### `spaces.before_trailing_comment`

Number of spaces between code and an end-of-line comment. `dart format` normalises to one; clang-format (`SpacesBeforeTrailingComments`) and many Dart codebases use two. Type: integer, default `1`.

Before:

```dart
final retries = 3;// never more than three
```

After with `spaces.before_trailing_comment=2`:

```dart
final retries = 3;  // never more than three
```

### Colon spacing

`after_colon_in_named_argument` is the only colon key today. Add its siblings so each position is independent. All bool. Defaults: `before_colon_in_named_argument: false`, `before_colon_in_map_entry: false`, `after_colon_in_map_entry: true`, `before_colon_in_initializer_list: true`, `before_colon_in_switch_case: false`.

Before:

```dart
final m = {'a' : 1, 'b' : 2};
```

After with `spaces.before_colon_in_map_entry=false` (today):

```dart
final m = {'a': 1, 'b': 2};
```

Before:

```dart
Point(this.x) : y = 0;
```

After with `spaces.before_colon_in_initializer_list=false`:

```dart
Point(this.x): y = 0;
```

## Blank lines

### `blank_lines.at_block_edges`

Blank lines allowed directly after `{` and before `}` of a function or block body. Today they are always removed. Some teams want one blank line after a long function header or `class` line as breathing room, and ReSharper exposes the choice ("Remove blank lines after '{' and before '}'"). Type: integer, default `0`; the source's blank lines are kept up to this value.

Before:

```dart
void f() {

  a();

}
```

After with `blank_lines.at_block_edges=0` (today):

```dart
void f() {
  a();
}
```

After with `blank_lines.at_block_edges=1`: unchanged.

### `blank_lines.keep_between_non_block_members`

Today, blank lines between members without a `{ }` body (fields, `=>` members, constructors ending in `;`) are kept up to the cap so related fields stay grouped. `false` applies `between_members` to every pair of members. ReSharper: "Blank lines around single line field / property". Type: bool, default `true`. Decided in review, together with its top-level sibling below:

> When both adjacent declarations lack their own block body, preserve their existing blank-line separation up to the applicable cap. When `false`, apply the corresponding spacing rule instead.

"Own block body" is syntactic: a variable initialised with a closure does not become block-bodied because its initialiser contains `{}`, and a wrapped `=>` function is still expression-bodied. Fields, variables, typedefs, expression-bodied functions and getters, and semicolon-bodied declarations are the non-block category, whatever their printed line count. Members and top-level declarations get separate switches because a team may preserve groups of top-level constants while requiring uniform separation between class fields, or the reverse.

Before:

```dart
class Config {
  final int retries;
  final Duration timeout;

  final String host;
}
```

After with `blank_lines.keep_between_non_block_members=false` and `between_members=1`:

```dart
class Config {
  final int retries;

  final Duration timeout;

  final String host;
}
```

### `blank_lines.between_import_groups`

Blank lines between the `dart:`, `package:` and relative import groups, and before `export` and `part` directives. `dart format` leaves them as written; `directives_ordering` only lints. Type: `preserve` or an integer, default `preserve` (today: the source's blank lines, up to the cap). `1` inserts a missing blank line and collapses extra ones. The schema needs a small int-or-enum type for this; `between_comment_and_declaration` below would share it.

Before:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/button.dart';
```

After with `blank_lines.between_import_groups=1`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/button.dart';
```

### `blank_lines.after_last_member`

Blank lines before a class's closing brace. Sibling of `before_first_member`. Type: integer, default `0`.

Before:

```dart
class A {
  void a() {}

}
```

After with `blank_lines.after_last_member=0` (today):

```dart
class A {
  void a() {}
}
```

### `blank_lines.between_top_level_declarations`

Today only class-like declarations get an exact blank-line count (`around_class_declarations`, applied when either neighbour is a class, mixin, enum, extension or extension type, which is what `_isClassLike` in `declarations.dart` already covers); top-level variables, functions and typedefs keep their source spacing up to the cap, including two block-bodied functions with no blank line between them. Decided in review: two settings with specific-over-general precedence, defaults that reproduce today's output, and no renaming, because a key that also separated block-bodied functions would not be an alias of the class key.

```yaml
blank_lines:
  between_top_level_declarations: preserve   # or a non-negative integer
  around_class_declarations: 1               # or inherit
  keep_between_non_block_top_level_declarations: true
```

At each boundary between two top-level declarations: directive spacing uses its existing rules; if either declaration is class-like and `around_class_declarations` is an integer, that exact count applies; otherwise the general rule applies, including its grouping behaviour. `around_class_declarations: inherit` hands classes to the general rule. A specific setting overrides its general fallback, as the per-construct settings do elsewhere; there is no "larger count wins". Different counts are a real preference (two blank lines around classes, one between functions, constants grouped), so the distinction is kept. `keep_between_non_block_top_level_declarations` is the top-level sibling of `keep_between_non_block_members`, same definition.

Before:

```dart
int counter = 0;
void increment() {
  counter++;
}
typedef Callback = void Function();
```

After with `blank_lines.between_top_level_declarations=1`:

```dart
int counter = 0;

void increment() {
  counter++;
}

typedef Callback = void Function();
```

### `blank_lines.between_comment_and_declaration`

Whether a blank line between an ordinary own-line comment and the declaration below it survives. Today the comment is glued to the declaration, which resolves the open dogfooding question by imposing one interpretation: a comment followed by a gap may be a section heading, a note on the code above, or an introduction to what follows, and removing the gap guesses. `dart format` keeps the gap (checked against the installed SDK for an annotated method and for a block comment). Decided in review: type `preserve` or a non-negative integer, **default `preserve`**, recorded as a deliberate preset change and explicitly exempt from this document's "new defaults reproduce today's output" promise.

Spec requirement replacing the "followed directly by the node it leads" sentence for declarations:

> For ordinary own-line comments leading a declaration, the gap between the final comment and the declaration's first annotation or code token SHALL follow `blank_lines.between_comment_and_declaration`. `preserve` retains the source gap up to the applicable cap; an integer specifies an exact count. Documentation-comment attachment and line-sensitive directive targeting take precedence.

- `preserve` keeps the source gap up to the cap; a gap of zero stays zero, nothing is inserted. An integer sets the exact count like the other explicit spacing keys.
- The setting applies once, between the last ordinary comment of a leading group and the declaration; it does not space the comments within the group apart. For an annotated declaration the boundary is before the first annotation; annotations and declaration are never separated.
- `///` and `/** */` doc comments keep their separate attachment rule and are unaffected.
- A line-sensitive directive such as `// ignore:` governs the next line; an integer setting never separates it from its target.
- Scope is declarations only. The existing requirement still covers comments before statements and list items; it is not replaced wholesale.
- This changes whitespace, not comment ownership: text, order and token anchors are unchanged, so the verifier needs no new tolerance. Affected goldens (`self_format` among them) are updated with reviewed diffs and second-pass stability is verified; regeneration alone is not validation.

Before:

```dart
// --- Lifecycle ---

@override
void initState() {}
```

After with the default `preserve`: unchanged.

After with `blank_lines.between_comment_and_declaration=0`:

```dart
// --- Lifecycle ---
@override
void initState() {}
```

## Strings

### `strings.quotes_avoid_escapes`

With `strings.quotes: single`, a string that contains a single quote keeps its double quotes rather than gaining a backslash. Prettier does this unconditionally; a key makes the choice explicit. Type: bool, default `true`. Stays inside the safety check: with `quotes` set, the check already compares string tokens by value rather than by lexeme.

Before:

```dart
final msg = "don't";
```

After with `strings.quotes=single strings.quotes_avoid_escapes=true` (today): unchanged.

After with `strings.quotes=single strings.quotes_avoid_escapes=false`:

```dart
final msg = 'don\'t';
```

## File level

### `line_ending`

Today Beaver writes whatever ending the source used most, which is the right default. A key lets a repository pin one. Type: `auto | lf | crlf`, default `auto`. No before/after: only the invisible bytes differ.

## Complementing the existing keys

Each current key, and the smallest addition that would round it out. Entries already covered above are only referenced.

### `wrap.keep_existing_line_breaks` and `wrap.chop_on_trailing_comma`

Stay as the global defaults; every list carries its own copy, preset `inherit`, resolved after the chain merges (decided above). A team can then keep developer breaks in collections but not in argument lists, which is the most common mixed request.

### `wrap.before_operator`

Becomes an alias for `wrap.break_before` containing `binary_operator`.

### `wrap.chained_calls`

Gets `chop_from` (alias of `min_calls`), `keep_first_call_on_receiver_line` and `align` like every other list. `keep_single_line_if_fits` stays chain-specific.

### `wrap.simple_blocks_on_one_line` and `wrap.simple_lambdas_on_one_line`

IntelliJ's "Keep when reformatting" row has one more member worth adding: `wrap.simple_methods_on_one_line`, a method or function whose block body is one statement. Useful for `void` one-liners that cannot become `=>` bodies without reading oddly. Bool, default `false`. `wrap.simple_case_bodies_on_one_line` above completes the row.

Before:

```dart
void close() { _controller.close(); }
```

After with `wrap.simple_methods_on_one_line=true`: unchanged.

After with `false` (today):

```dart
void close() {
  _controller.close();
}
```

### `wrap.chop_on_named_arguments`

Matches argument names. Its natural sibling matches the callee: `wrap.chop_on_calls: [Column, Row, Scaffold]` chops the argument list of any invocation whose name matches, however short. Type: list of non-empty dotted names, default `[]`; a malformed entry is a configuration error and there are no wildcards. Decided in review:

> Entries match callable-name segments, case-sensitively, without type resolution. A single-segment entry matches either the final or penultimate segment. An entry with two or more segments must match the complete suffix of the callable name.

| Entry | Matches | Does not match |
|---|---|---|
| `Row` | `Row(...)`, `m.Row(...)`, `Row.center(...)`, `m.Row.center(...)`, `controller.Row(...)` | `RowFactory(...)`, `Row.center.extra(...)` |
| `Row.center` | `Row.center(...)`, `m.Row.center(...)` | `Row(...)`, `Other.center(...)` |
| `m.Row.center` | `m.Row.center(...)` | `other.Row.center(...)` |

- **Name segments, not constructor names.** `Text` matches `Text.rich(...)` and equally any syntactically identical static or instance access; `Theme` matching `Theme.of(...)` is expected. Capitalisation is never a type heuristic. Longer entries let a user distinguish an import prefix or receiver where the syntax supplies one; that is lexical precision, not proof of which declaration is called.
- **The name comes from the callable expression**, not from searching tokens or descendants. Type arguments are not segments. A computed target such as `callbacks[index](x)` has no dotted name; the outer invocation in `getBuilder()(x)` does not borrow the inner call's name. `argumentList` in `expressions.dart` sees only the `ArgumentList`, so the matcher reads the parent invocation.
- **Formatting consequences.** Only the matched invocation's own argument list is chopped; nested calls keep their own settings and matching; `never` suppresses the trigger; a match defeats trailing-argument hugging and kept groups of arguments sharing a line, as a named-argument match already does.

Before:

```dart
return Row(children: [a, b]);
```

After with `wrap.chop_on_calls=[Row]`:

```dart
return Row(
  children: [a, b],
);
```

### `trailing_commas`

Decided in review. The global scalar stays and gains a fourth value, `add_when_chopped` (today's schema has `preserve`, `remove`, `add_when_wrapped`). Per-construct control is a `trailing_commas` field on the list maps that have an optional trailing comma, preset `inherit`, resolved after the chain merges exactly like the two companion flags. The separate top-level construct map from the first draft is withdrawn: it would have introduced a second naming scheme for the same constructs.

```yaml
trailing_commas: add_when_wrapped

wrap:
  arguments:
    trailing_commas: inherit
  collection_literals:
    trailing_commas: remove
```

- **Only on comma-capable constructs.** Initially `arguments`, `parameters`, `collection_literals` and `enum_values`. Binary expressions, chains, cascades and the other lists do not accept the field; a setting that does nothing is not offered. Switch expressions are separate: their commas are preserved exactly today and excluded from the verifier's optional-comma normalisation, and giving them a wrap policy does not by itself authorise changing those commas.
- **Records follow the global key**, literals, types and patterns alike, as an explicit initial fallback that leaves room for record-specific control later. Implementation trap: record literals and patterns are built with the arguments policy and record types with the parameters policy, so the shared helpers must receive the effective settings of the actual construct, not inherit an argument or parameter comma override by accident. A required comma, as in `(value,)`, is never touched, whatever `remove` says.
- **The oscillation check becomes per construct.** It runs on effective values after `inherit` is resolved, over every affected construct including records on the global settings. Its diagnostic names the construct, the three values and their sources, including the global source behind an inherited value. It also respects the precedence settled for `chop_from`: a construct whose effective policy is `never` has no comma-triggered chop to undo, and `chop_always` chops regardless of the comma, so neither combination is rejected; the old three-value test is not an unconditional rule.
- **`add_when_chopped` is defined by the resulting arrangement, not the policy name.** A list counts as chopped when its own items each start a line, whether that came from `chop_if_long`, `chop_always`, `chop_from`, a kept break or a named-argument match under `if_long`. A multi-line argument inside a filled list does not make the list chopped.

Before:

```dart
const sizes = [
  8,
  16,
  24,
];
```

After with `wrap.collection_literals.trailing_commas=remove`:

```dart
const sizes = [8, 16, 24];
```

### `indent.continuation` and `indent.align.*`

Per-construct indentation is the `indent` field of each list map (decided under `wrap.initializer_lists`), inheriting `indent.continuation` or `indent.size` by construct; no `indent.<construct>` keys. `indent.align.*` moves into each list's `align` field and gains `binary_operands` as a target; the three existing keys stay as aliases.

### `indent.style` and `indent.size`: EditorConfig integration

Tabs versus spaces stays Beaver's decision, not the editor's: a formatter writes the whitespace, so it must know. The editor setting only governs what typing inserts before the next format. Flutter repositories often hold Dart, Kotlin, Swift, scripts and configuration files, and an `.editorconfig` may already state the team's shared whitespace policy; reading it avoids two competing sources for indentation and line endings. Decided in review:

> EditorConfig integration is an optional capability, disabled by default. When enabled, supported EditorConfig properties supply defaults above the Dart preset and below every explicit Beaver setting. Implementation may be deferred until matching, value mapping, provenance, and filename handling are specified and tested.

- **Key.** `editorconfig: false | true`, preset `false`, inheriting through `extends` like any key, so a child can switch off an inherited `true`. Because the flag lives in `.beaver.yaml`, a project without a Beaver file never consults EditorConfig. Default off is the answer to the `[*]` surprise: an `indent_size = 4` meant for other languages must not reach Dart unasked.
- **Precedence** when enabled, lowest to highest: `dart` preset, applicable EditorConfig properties, explicit settings anywhere in the Beaver `extends` chain. An explicit Beaver value wins regardless of directory proximity; preset defaults are not explicit values.
- **Real EditorConfig resolution.** Sections matched against the formatted file name, ancestor files processed up to `root = true`, section order honoured, `unset` handled. Reading only the nearest file is not enough.
- **Bounded surface.** `indent_style`, `indent_size` (with `tab` and `tab_width` derivation defined, not approximated) and `end_of_line` (`lf`, `crlf`; `cr` unsupported and reported) only. Enabling integration authorises no other property to affect Beaver.
- **`line_ending: auto` stays unambiguous.** It always means Beaver's source-based detection. EditorConfig supplies `lf` or `crlf` only when no Beaver file sets `line_ending`; an explicit Beaver `auto` overrides EditorConfig and restores detection.
- **File name required.** Resolution runs against the formatted file or `--stdin-name`, also when `--config` is given. With integration enabled, `config --print` requires `--for` and stdin formatting requires `--stdin-name`; both flags already exist, the requirement is a validation rule.
- **Provenance** records the winning EditorConfig path, section and property, including a derivation through `tab_width`. The template shows `editorconfig: false` with the precedence explained.
- **Cost.** Opt-in removes none of the parser, matching, discovery, provenance or tests; this is a substantial resolution feature. Until it is built, behaviour is identical to having no integration.

### `blank_lines.max_consecutive`

IntelliJ splits "Keep maximum blank lines" into "in declarations", "in code" and "before '}'". Beaver's one cap serves all three. Add `blank_lines.max_consecutive_in_code` (inside function bodies), type `integer | inherit`, preset `inherit`, resolved against the effective `max_consecutive` after the chain merges, and `blank_lines.at_block_edges` above for the third. A team can then allow two blank lines between members but one inside a body.

Before:

```dart
class A {
  void a() {
    x();


    y();
  }


  void b() {}
}
```

After with `blank_lines.max_consecutive=2 blank_lines.max_consecutive_in_code=1`:

```dart
class A {
  void a() {
    x();

    y();
  }


  void b() {}
}
```

### `blank_lines.between_members`

Complemented by `blank_lines.keep_between_non_block_members` and `blank_lines.after_last_member` above.

### `braces.else_on_new_line`

Rider has one toggle per keyword: `else`, `catch`, `finally`, and `while` of a `do` loop. Decided in review: add `braces.catch_on_new_line`, `braces.finally_on_new_line` and `braces.while_on_new_line`, each `true | false | inherit`, preset `inherit`, resolved against the effective `else_on_new_line` after the whole chain merges, under the same rules as every other inheriting field: omitting a key keeps the inherited configuration, an explicit boolean sets an independent preference, an explicit `inherit` restores the link. `else_on_new_line` stays a plain boolean, so the fallback direction is fixed and there are no cycles. The formatter receives booleans; `config --print` shows the effective value with both sources; the template shows `inherit`.

```yaml
braces:
  else_on_new_line: false
  catch_on_new_line: inherit
  finally_on_new_line: inherit
  while_on_new_line: inherit
```

Scope: `catch_on_new_line` governs the start of the whole handler clause, so for `on SomeException catch (e)` the break goes before `on` and `on SomeException` is never split from `catch (e)`; `while_on_new_line` governs only the trailing `while` of a `do` loop, not ordinary `while` statements.

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

### `spaces.after_colon_in_named_argument`

Complemented by the colon siblings above, so every colon position has its own key.

### `strings.quotes`

Complemented by `strings.quotes_avoid_escapes` above.

### `exclude`

An `include` list would let a config format only `lib/**` and `test/**` without listing everything else under `exclude`. Type: list of globs, default `['**']`. Low priority; `exclude` covers most layouts.

## Deferred cleanup transformations

These change tokens or the syntax tree, which `beaver format`'s check forbids. Decided in review:

> `beaver format` retains its current token, structural, and comment-preservation checks. The four rewrites remain deferred candidates under a future `cleanup:` namespace, executed only by an explicit `beaver cleanup` command. Cleanup transforms the source, independently verifies that only configured and eligible changes occurred, then formats the cleaned text using the ordinary formatter and its unchanged verifier. Canonical comparison must preserve all information outside explicitly permitted differences, including comment placement. Nothing is written unless both verification stages pass. Each transformation requires specified safety conditions and verification; the complete pipeline must be idempotent. No cleanup transformation runs implicitly during formatting.

What this means in practice:

- **Why not a third normalisation in `format`.** Not because the verification spec is frozen, but because the formatting contract (tokens, structure and comments preserved under two small documented exceptions) is the product's specific guarantee, and a cleanup command can offer transformations under a different contract. A lint that disagrees with a cleanup setting is a configuration conflict the team resolves by disabling the lint; it argues for separating cleanup from formatting, not against the capability.
- **Verification shape.** Every transformation ships with independently specified eligibility conditions, permitted changes, and a check that rejects any change outside them. Comparing both trees after the transformation's own canonical normalisation is an acceptable implementation only if the canonical form keeps token values, operators, order and structure: the current fingerprint records node kinds and child counts only, which cannot tell `return a;` from `return b;` once the token check is relaxed. Normalisation applies only to the constructs the configured transformation is eligible for, so a normaliser that strips every single-statement block cannot hide an unintended removal elsewhere. Comments keep their text, order and placement relative to surviving syntax, with explicit anchor mappings where syntax changes; only `cleanup.comment_spacing` is exempt, and only for its one permitted text change.
- **Pipeline.** Original, transform, verify permitted cleanup changes, format the cleaned text, ordinary format verification against the cleaned text, write. Running the whole command again must produce identical output.
- **Configuration.** The keys live under one top-level `cleanup:` section of `.beaver.yaml`, so a reader can see which keys `format` honours. `format` ignores them in the sense of not executing them; once the schema knows them, typos and invalid values are still configuration errors. Until the command exists they are proposal entries, absent from the schema and from the generated template.
- **Existing alternatives are partial.** The official fixes cover one direction each: `curly_braces_in_flow_control_structures` adds braces (and itself permits a braceless single-line `if` without `else`), `prefer_expression_function_bodies` prefers `=>`, `empty_constructor_bodies` prefers `;`. None covers the reverse preference. Documentation should name targeted invocations (`dart fix --apply --code=<lint>`) rather than a blanket `dart fix --apply`, which also applies API migrations, and keep them out of the validation path.

Each entry below keeps its intended options under its future `cleanup.*` name.

### `cleanup.flow_control_braces`

Add or remove braces around the single statement of an `if`, `else`, `for`, `while` or `do` body. Rider: "Braces for ifs: Enforce always / Remove / Do not change". Type: `preserve | add | remove`, default `preserve`. Adding braces is always meaning-preserving. Removing is not, so `remove` keeps the braces when the statement is a local declaration (`if (x) { var y = 1; }` does not compile without them), when the body contains a nested `if` without `else` and the outer one has an `else` (dangling else), or when the block holds a comment. `wrap.braceless_bodies` and `wrap.simple_blocks_on_one_line` then decide whether the result sits on one line.

Before:

```dart
if (items.isEmpty) return null;
```

After with `cleanup.flow_control_braces=add`:

```dart
if (items.isEmpty) {
  return null;
}
```

After with `cleanup.flow_control_braces=add wrap.simple_blocks_on_one_line=true`:

```dart
if (items.isEmpty) { return null; }
```

### `cleanup.function_bodies`

Convert a block body whose only statement is `return expr;` or `throw expr;` into `=> expr;`, or the reverse. The `prefer_expression_function_bodies` lint plus `dart fix` does the first direction today. Type: `preserve | expression | block`, default `preserve`. `expression` is safe when the block holds exactly one `return` or `throw` statement and no comments; a bare `return;`, a generator (`sync*`, `async*`) and a setter whose statement is an assignment are left as blocks. `block` is always safe and is what teams want who find `=>` bodies hard to breakpoint.

Before:

```dart
int twice(int x) {
  return x * 2;
}
```

After with `cleanup.function_bodies=expression`:

```dart
int twice(int x) => x * 2;
```

### `cleanup.empty_constructor_bodies`

Replace an empty constructor body `{}` with `;`, or the reverse. The `empty_constructor_bodies` lint plus `dart fix` does the first direction today. Type: `preserve | semicolon | braces`, default `preserve`. Both directions are meaning-preserving for generative constructors, including ones with an initializer list (`A() : super() {}` becomes `A() : super();`). `braces` leaves `const` constructors alone, since a `const` constructor may not have a block body, and both values leave `factory` constructors alone, since a factory must have a body. A block holding a comment is kept.

Methods and functions are excluded on purpose: `void f() {}` is a concrete empty method and `void f();` is an abstract one, so the same rewrite changes the program. The safety check would reject it, which is the point of the check.

Before:

```dart
class Logger {
  Logger() {}
  Logger.named(this.name) : super() {}
  const Logger.silent();
  factory Logger.shared() { return _shared; }
  void flush() {}
}
```

After with `cleanup.empty_constructor_bodies=semicolon`:

```dart
class Logger {
  Logger();
  Logger.named(this.name) : super();
  const Logger.silent();
  factory Logger.shared() {
    return _shared;
  }
  void flush() {}
}
```

### `cleanup.comment_spacing`

Insert a space after `//` when the comment text starts without one. Changes the comment lexeme, so it is the one transformation with a permitted comment-text change, limited to that single space. Type: `preserve | add`, default `preserve`. `add` skips doc comments (`///`) and empty `//`. The draft heuristic "skip comments whose first character is not a letter, digit or quote" does not establish that a comment is prose: tool directives start with letters (`//ignore:`, `//coverage:`, `//TODO`), so any real version needs an explicit allowlist of directive prefixes to leave alone, which is fragile on its own. Deferred with that open point. Commented-out code (`//foo();`) does get the space; that is the point.

Before:

```dart
final retries = 3; //never more than three
//TODO: make configurable
//--------------------------------
```

After with `cleanup.comment_spacing=add`:

```dart
final retries = 3; // never more than three
// TODO: make configurable
//--------------------------------
```

## Considered and parked

Each of these is a one-token whitespace rule, cheap to build, with no observed demand in Dart code. Rider and ReSharper have them because C# culture has several brace and spacing schools; Dart has one. Add any of them when someone asks, not before. Every key in this list costs a rule page, an example folder and a golden test for as long as it exists.

- `spaces.around_ternary`, `spaces.after_unary_not`, `spaces.after_semicolon_in_for`: nobody writes `a?b:c`, `! x` or `for (;i<n;i++)` on purpose.
- `spaces.inside_control_parentheses` (`if ( x )`), `spaces.inside_type_arguments` (`List< int >`), `spaces.in_empty_parentheses`, `spaces.in_empty_brackets`: siblings of existing keys for symmetry only.
- `spaces.before_opening_brace` (`void f(){`), `spaces.before_parameter_parentheses`, `spaces.before_argument_parentheses` (`f (x)`): GNU and old C# habits that do not survive contact with `dart format` users.
- **Allman braces**, parked in review as four independent booleans, since the choices are independent and a three-value enum restricts combinations: `braces.opening_brace_on_new_line.types` (class-like declaration bodies, including extensions and extension types), `.functions` (named functions, methods, constructors, getters, setters), `.lambdas` (anonymous function-expression bodies), `.control` (an explicitly enumerated set of control-flow bodies), all preset `false`, no `inherit`. Categories must be defined without overlap before implementation; collections, records and patterns never acquire Allman layout for containing braces, and switch expressions need an explicit scope decision. Lambda brace placement takes precedence over any hugging layout that would put `{` on the preceding line; it does not itself request chopping of the enclosing argument list (`test('x', ()` followed by `{` on its own line remains a possible hugged layout), and the interaction with hugging must be specified before implementation. Cost is substantial but unestimated: every brace-owning rule assumes the opener ends the line. Absent from the schema and the template until implemented; demand may come from anywhere, not only C# migrations.
- `braces.empty_body: two_lines` (`{` and `}` on separate lines for an empty body): ReSharper "Empty block style".
- `final_newline: false`: Dart style requires the newline and no tool wants it absent.
- `wrap.type_parameters` as its own policy: the generic fallback already chops long type parameter lists sensibly, and short ones never split.

## Rejected

These show up in ReSharper, IntelliJ or clang-format, and users will ask for them. They are rejected for one of two reasons: they rewrite the tree or text in ways the safety check cannot bound, so they belong in `dart fix` or a lint, or they are allowed by the check but make every edit reflow its neighbours.

- **Import sorting and member ordering** (constructors first, private methods last, a full file layout). Reorders the tree. Not for `beaver format`: no mainstream formatter moves code (`dart format`, gofmt, Prettier, Black and rustfmt all refuse, rustfmt sorts imports only), and Rider itself keeps File Layout in Code Cleanup, not in Reformat, because a format-on-save that moves the member under the cursor is unusable. It is also not quite meaning-preserving in Dart: instance field initializers run in declaration order, so reordering fields with side-effecting initializers changes behaviour, and a standalone section comment (`// --- Lifecycle ---`) between members ends up attached to the wrong one. The Flutter convention (constructor first, `build` last, private helpers next to their callers) also contradicts the C# "private down" layout, so no single default would be right. Covered today by `directives_ordering`, the `sort_constructors_first` family and the configurable `member-ordering` rule in dart_code_metrics. If demand is real, it is a separate explicit command (`beaver arrange`) with its own check: same multiset of members, each member's tokens unchanged, comments travelling with their member, and a refusal when a free-standing comment or a side-effecting field initializer sits in the way.
- **Comment text beyond one space:** reflowing long comments to `line_length`, converting `/** */` to `///`. Unlike `cleanup.comment_spacing`, these cannot be bounded to one permitted change.
- **String interpolation braces** (`$x` vs `${x}`) and **escape normalisation** inside strings. Changes the string token.
- **Column alignment across lines:** consecutive assignments, map values, trailing comments (clang-format `AlignConsecutiveAssignments`, `AlignTrailingComments`). Allowed by the check, rejected because renaming one variable reflows every neighbouring line, and neither `dart format` nor IntelliJ Dart offers it.
