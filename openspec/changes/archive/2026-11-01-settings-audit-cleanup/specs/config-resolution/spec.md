# Spec Delta

## ADDED Requirements

### Requirement: Removed spellings are refused with the replacement named

A configuration containing `policy: chop_always` on any list, or `wrap.chained_calls.keep_single_line_if_fits`, SHALL be rejected with exit code 78 and a diagnostic that names the file, the key as written and the replacement. These spellings SHALL NOT be aliases: `chop_always` meant different things depending on a second key.

#### Scenario: chop_always on a list
- **WHEN** a file contains `wrap: {arguments: chop_always}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments.policy: chop_always` as replaced by `chop_from` and says to write `chop_from: 1`

#### Scenario: chop_always on a chain
- **WHEN** a file contains `wrap: {chained_calls: {policy: chop_always}}`
- **THEN** the diagnostic additionally says that `keep_single_line_if_fits: false` on a chain corresponds to `chop_from: 2`

#### Scenario: keep_single_line_if_fits
- **WHEN** a file contains `wrap: {chained_calls: {keep_single_line_if_fits: true}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.chained_calls.keep_single_line_if_fits` as removed and points to `chop_from`

#### Scenario: Explicit chop_from next to chop_always
- **WHEN** a file contains `wrap: {arguments: {policy: chop_always, chop_from: 3}}`
- **THEN** resolution fails with exit code 78 on `chop_always`; the `chop_from` value gets no special treatment

### Requirement: Sub-options without a parent are ignored

A sub-option whose parent setting is not in effect SHALL be ignored without a diagnostic, so that a child file can switch off an inherited behavior with one key. Sub-options: `chop_from` (parent: policy `fill` or `chop_if_long`), `indent_from` (parent: an integer or `inherit` value of `indent`), `trailing_commas` (parent: `break_before_close_bracket: true`). Peer settings that contradict each other remain configuration errors.

#### Scenario: Threshold under never
- **WHEN** a parent file sets `wrap.arguments: {policy: chop_if_long, chop_from: 3}` and the project file sets `wrap.arguments: never`
- **THEN** resolution succeeds and the effective `wrap.arguments.chop_from` is 3 with no effect

#### Scenario: Trailing commas without a closing-bracket line
- **WHEN** a file contains `wrap: {arguments: {break_before_close_bracket: false}}` and `trailing_commas: add_when_wrapped`
- **THEN** resolution succeeds and no diagnostic is printed

#### Scenario: Contradicting peers are still an error
- **WHEN** the three trailing-comma peer settings conflict as described under incompatible trailing-comma settings
- **THEN** resolution fails with exit code 78

### Requirement: Bracket placement fields

`wrap.break_after_open_bracket` and `wrap.break_before_close_bracket` SHALL accept `true` or `false`, and each delimiter-owning list map (`arguments`, `parameters`, `collection_literals`, `enum_values`) SHALL accept the same two fields with `inherit`. No other list SHALL offer them. Preset `dart`: both global keys `true`, every list `inherit`.

#### Scenario: Fields accepted
- **WHEN** a file contains `wrap: {break_after_open_bracket: false, arguments: {break_before_close_bracket: false}}`
- **THEN** the effective configuration has `wrap.break_after_open_bracket` false, `wrap.arguments.break_after_open_bracket` false via `inherit` and `wrap.arguments.break_before_close_bracket` false

#### Scenario: Not offered on a chain
- **WHEN** a file contains `wrap: {chained_calls: {break_after_open_bracket: false}}`
- **THEN** resolution fails with exit code 78 naming `wrap.chained_calls.break_after_open_bracket` as unknown

#### Scenario: Listed in the reference template
- **WHEN** `beaver config --template` runs
- **THEN** both fields appear at `wrap` level with `true` and under each of the four lists with `inherit`, and `close_bracket` does not appear

### Requirement: Receiver kinds list

`wrap.chained_calls.keep_first_call_on_receiver_line` SHALL accept a list drawn from `type_names`, `identifiers`, `this`, `calls` and `properties`, or the booleans `true` (every kind) and `false` (`[]`). An entry outside the set SHALL be a configuration error naming the entry and the allowed kinds. Preset `dart`: `[]`.

#### Scenario: List accepted
- **WHEN** a file contains `wrap: {chained_calls: {keep_first_call_on_receiver_line: [type_names, this]}}`
- **THEN** the effective value is the list `[type_names, this]`

#### Scenario: Boolean shorthand
- **WHEN** a file contains `wrap: {chained_calls: {keep_first_call_on_receiver_line: true}}`
- **THEN** the effective value lists every kind

#### Scenario: Unknown kind
- **WHEN** a file contains `wrap: {chained_calls: {keep_first_call_on_receiver_line: [classes]}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `classes` and lists the five kinds

#### Scenario: Shown in the reference template
- **WHEN** `beaver config --template` runs
- **THEN** the field appears as `keep_first_call_on_receiver_line: []` with a comment listing the kinds and `true | false`

## MODIFIED Requirements

### Requirement: Canonical long-form keys

The schema SHALL hold only long-form leaf keys. Each wrappable list SHALL be a map with the fields `policy`, `chop_from` and `keep_existing_line_breaks`, plus `chop_on_trailing_comma`, `break_after_open_bracket`, `break_before_close_bracket` and `trailing_commas` on the delimiter-owning lists only (`arguments`, `parameters`, `collection_literals`, `enum_values`), and `indent` on the lists where it has an effect. There SHALL be no `align` field and no `close_bracket` field. No key SHALL be both a leaf and a prefix of other keys.

#### Scenario: Long form accepted
- **WHEN** a file contains `wrap: {arguments: {policy: chop_if_long, chop_from: 4, keep_existing_line_breaks: false}}`
- **THEN** the effective configuration has `wrap.arguments.policy` `chop_if_long`, `wrap.arguments.chop_from` 4 and `wrap.arguments.keep_existing_line_breaks` false

#### Scenario: Field not offered on a construct
- **WHEN** a file contains `wrap: {chained_calls: {trailing_commas: remove}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.chained_calls.trailing_commas`

#### Scenario: Dead trailing-comma trigger is refused
- **WHEN** a file contains `wrap: {chained_calls: {chop_on_trailing_comma: true}}` (likewise `binary_expressions`, `conditional_expressions`, `cascades`, `initializer_lists`, `switch_expressions` and `class_header`, whose items the setting never reads)
- **THEN** resolution fails with exit code 78 naming `wrap.chained_calls.chop_on_trailing_comma` as unknown

#### Scenario: first_item refused where nothing precedes the first item
- **WHEN** a file contains `wrap: {cascades: {indent: first_item}}`
- **THEN** resolution fails with exit code 78 naming `wrap.cascades.indent` and listing `inherit` and an integer as the allowed values

#### Scenario: Field with no effect is refused
- **WHEN** a file contains `wrap: {cascades: {align: true}}`
- **THEN** resolution fails with exit code 78 naming `wrap.cascades.align` as unknown

### Requirement: Aliases map one-to-one onto canonical keys

The following spellings SHALL be accepted without deprecation and SHALL behave identically to their canonical key: `wrap.<list>: <policy>` for `wrap.<list>.policy`; the policy value `if_long` for `fill`; `wrap.<list>.align: true`, `indent.align.arguments`, `indent.align.parameters` and `indent.align.chained_calls` set to `true` for `wrap.<list>.indent: first_item`; `wrap.close_bracket` and `wrap.<list>.close_bracket` with `own_line` for `break_before_close_bracket: true` and `after_last_item` for `false` (`inherit` unchanged); `wrap.chained_calls.min_calls` for `wrap.chained_calls.chop_from`; `wrap.before_operator` for `wrap.break_before.binary_operator`. `align: false` and `indent.align.*: false` SHALL be accepted and dropped, since they only ever meant "use `indent`".

#### Scenario: Shorthand policy
- **WHEN** a file contains `wrap: {arguments: chop_if_long}`
- **THEN** the effective `wrap.arguments.policy` is `chop_if_long`

#### Scenario: Legacy policy value
- **WHEN** a file contains `wrap: {arguments: if_long}`
- **THEN** the effective `wrap.arguments.policy` is `fill`

#### Scenario: Legacy alignment key
- **WHEN** a file contains `indent: {align: {parameters: true}}`
- **THEN** the effective `wrap.parameters.indent` is `first_item`

#### Scenario: align true on a list
- **WHEN** a file contains `wrap: {arguments: {align: true, indent: 4}}`
- **THEN** resolution fails with exit code 78 as two spellings of `wrap.arguments.indent` in one layer

#### Scenario: align false dropped
- **WHEN** a file contains `wrap: {arguments: {align: false, indent: 4}}`
- **THEN** resolution succeeds and the effective `wrap.arguments.indent` is 4

#### Scenario: Legacy close bracket
- **WHEN** a file contains `wrap: {close_bracket: after_last_item, arguments: {close_bracket: own_line}}`
- **THEN** the effective `wrap.break_before_close_bracket` is false and `wrap.arguments.break_before_close_bracket` is true

#### Scenario: Legacy chain threshold
- **WHEN** a file contains `wrap: {chained_calls: {min_calls: 3}}`
- **THEN** the effective `wrap.chained_calls.chop_from` is 3

### Requirement: Unknown keys and invalid values are configuration errors

Beaver SHALL reject a configuration containing a key not in the schema, a value of the wrong type, or a value outside the allowed set, with exit code 78 and a diagnostic naming the file, the key and the allowed values. When the key was written through an alias, the diagnostic SHALL name the key as the user wrote it and the canonical key.

#### Scenario: Misspelled key
- **WHEN** a file contains `line_lenght: 100`
- **THEN** resolution fails with exit code 78 and the diagnostic names `line_lenght`

#### Scenario: Invalid enum value
- **WHEN** a file contains `wrap: {arguments: sometimes}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments` and `wrap.arguments.policy` and lists `never`, `fill`, `chop_if_long`

#### Scenario: Invalid canonical value
- **WHEN** a file contains `wrap: {arguments: {policy: sometimes}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments.policy` and lists the three policies

### Requirement: Incompatible trailing-comma settings are configuration errors

For each construct with an optional trailing comma, a resolved configuration whose effective values for that construct are a removing comma policy (`remove`, or a comma suppressed by `break_before_close_bracket: false`), `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` SHALL be rejected with exit code 78, unless the construct's policy is `never` or its `chop_from` is 1. Records SHALL be checked against the global values. The diagnostic SHALL name the construct, the keys, their values and where each was set, including the global source behind an inherited value, and the changes that resolve it.

#### Scenario: Inherited value completes the conflict
- **WHEN** a project file sets `trailing_commas: remove` and `wrap.keep_existing_line_breaks: false` and inherits `chop_on_trailing_comma: true` from the `dart` preset
- **THEN** resolution fails with exit code 78 and the diagnostic names all three keys and the preset as the source of `chop_on_trailing_comma`

#### Scenario: Conflict on one construct only
- **WHEN** a project file sets `wrap.collection_literals.trailing_commas: remove` and `wrap.collection_literals.keep_existing_line_breaks: false`, and the global values stay at the preset
- **THEN** resolution fails with exit code 78 and the diagnostic names `collection_literals`

#### Scenario: Suppression by close-bracket placement
- **WHEN** a project file sets `wrap.arguments.break_before_close_bracket: false` and `wrap.keep_existing_line_breaks: false`, with `trailing_commas: add_when_wrapped` and `chop_on_trailing_comma: true` from the preset
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments.break_before_close_bracket` as suppressing the optional comma

#### Scenario: Policy never is exempt
- **WHEN** the arguments values would conflict but `wrap.arguments.policy: never`
- **THEN** resolution succeeds

#### Scenario: Always chopped is exempt
- **WHEN** the arguments values would conflict but `wrap.arguments.chop_from: 1`
- **THEN** resolution succeeds, since every list chops regardless of the comma

#### Scenario: Threshold alone is not exempt
- **WHEN** the arguments values would conflict and `wrap.arguments.chop_from: 3` with policy `chop_if_long`
- **THEN** resolution fails with exit code 78

### Requirement: Single built-in preset `dart`

Beaver v1 SHALL ship exactly one built-in preset, `dart`, whose values follow dart_style 3.x conventions: `line_length` 80, `indent.size` 2, `wrap.<list>.indent: inherit` everywhere except `initializer_lists` (`first_item`), `break_after_open_bracket` and `break_before_close_bracket` `true`, `wrap.switch_expressions` `chop_if_long` with `chop_from: 1`, `keep_first_call_on_receiver_line: []`, `chop_on_named_arguments` empty, `trailing_commas: add_when_wrapped`, `chop_on_trailing_comma: true`, `strings.quotes: preserve`, and the default exclusion list for generated code. Keys not listed here take dart_style's behaviour.

#### Scenario: Preset values
- **WHEN** a file is formatted with no configuration
- **THEN** it is formatted at 80 columns with 2-space indentation, no alignment except initializer lists, and generated-file patterns excluded

#### Scenario: Preset output unchanged by this change
- **WHEN** the golden corpus is formatted with no configuration before and after this change
- **THEN** the output is byte-identical

### Requirement: Reference template

`beaver config --template` SHALL print a YAML document generated from the schema that lists every canonical key once, set to its `dart` preset value (`inherit` where the preset says so), with the allowed values in a trailing comment. Integer keys SHALL state their minimum, list keys SHALL show an example entry, and map-shaped keys SHALL appear in long form with a comment that the scalar shorthand is accepted. Aliases SHALL NOT appear.

#### Scenario: Policy line
- **WHEN** `beaver config --template` runs
- **THEN** the output contains `policy: chop_if_long` under `wrap.arguments` with a trailing comment listing `never | fill | chop_if_long`

#### Scenario: Indent line
- **WHEN** `beaver config --template` runs
- **THEN** the output contains `indent: inherit` under `wrap.arguments` with a trailing comment listing `inherit | an integer >= 0 | first_item`, and no `align` line

#### Scenario: Template parses as a configuration
- **WHEN** the template output is saved as `.beaver.yaml`
- **THEN** resolution succeeds and the effective configuration equals the `dart` preset

#### Scenario: Committed copy kept in sync
- **WHEN** the test suite runs and `docs/beaver.template.yaml` differs from the `config --template` output
- **THEN** the suite fails

### Requirement: Scalar and map keys replace inherited values

For every key except `exclude`, a value set in a file SHALL replace the inherited value for that key. Nested maps are merged key by key. Merging SHALL operate on canonical keys after each layer has been normalised, so a shorthand and its long form replace exactly the same key.

#### Scenario: Override one nested key
- **WHEN** the chain yields `indent: {size: 2, continuation: 4}` and the user file sets `indent: {continuation: 2}`
- **THEN** the effective config has `indent.size` 2 and `indent.continuation` 2

#### Scenario: Shorthand replaces only the policy
- **WHEN** the chain yields `wrap.parameters.policy: chop_if_long` and `wrap.parameters.chop_from: 3`, and the user file sets `wrap: {parameters: fill}`
- **THEN** the effective config has `wrap.parameters.policy` `fill` and `wrap.parameters.chop_from` 3

### Requirement: Conflicting spellings in one layer are configuration errors

When one configuration source sets the same canonical key through two spellings with different values, resolution SHALL fail with exit code 78 and a diagnostic naming both keys. Identical values SHALL be accepted. Across layers, the nearer source SHALL win per canonical key whatever spelling either used.

#### Scenario: Alias and canonical key disagree
- **WHEN** one file sets `indent.align.arguments: true` and `wrap.arguments.indent: 4`
- **THEN** resolution fails with exit code 78 and the diagnostic names `indent.align.arguments` and `wrap.arguments.indent`

#### Scenario: Identical duplicate
- **WHEN** one file sets `wrap.before_operator: true` and `wrap.break_before.binary_operator: true`
- **THEN** resolution succeeds

#### Scenario: Different spellings across layers
- **WHEN** a team file sets `wrap.arguments.align: true` and the project file extending it sets `wrap.arguments.indent: inherit`
- **THEN** the effective `wrap.arguments.indent` is `inherit`, resolved to `indent.size`

### Requirement: Inheriting list fields and their fallbacks

These list fields SHALL accept `inherit`, preset `inherit`: `keep_existing_line_breaks`, and on the delimiter-owning lists `chop_on_trailing_comma`, `break_after_open_bracket`, `break_before_close_bracket` and `trailing_commas` (fallback: the global key of the same name); `indent` (`indent.continuation` for chained calls and binary expressions, `indent.size` otherwise). `policy` and `chop_from` SHALL NOT accept `inherit`, except on `wrap.enum_values`.

#### Scenario: Two lists preset to false
- **WHEN** no file sets `wrap.initializer_lists.keep_existing_line_breaks` or `wrap.class_header.keep_existing_line_breaks`
- **THEN** both are `false`, not `inherit`, because a kept break would split a header that 0.1.0 joined

#### Scenario: Cascade indent follows indent.size
- **WHEN** `indent.size: 4` and `wrap.cascades.indent` is not set
- **THEN** the effective `wrap.cascades.indent` is 4

#### Scenario: Policy has no global fallback
- **WHEN** a file contains `wrap: {arguments: {policy: inherit}}`
- **THEN** resolution fails with exit code 78

### Requirement: Enum values follow collection literals by default

Every field of `wrap.enum_values` SHALL accept `inherit`, preset `inherit`, falling back to the same field of `wrap.collection_literals`, so a configuration that customised collection literals keeps its enum layout.

#### Scenario: Enum follows a customised collection policy
- **WHEN** a project file sets `wrap.collection_literals: fill` and does not set `wrap.enum_values`
- **THEN** the effective `wrap.enum_values.policy` is `fill`

#### Scenario: Enum set independently
- **WHEN** a project file sets `wrap.collection_literals: fill` and `wrap.enum_values: chop_if_long`
- **THEN** the effective `wrap.enum_values.policy` is `chop_if_long` and collection literals still fill
