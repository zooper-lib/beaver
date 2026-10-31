# config-resolution Specification

## Purpose

Defines how Beaver finds, inherits, validates and resolves the `.beaver.yaml` configuration that governs formatting of a given file, including the built-in `dart` preset and exclusion patterns.

## Requirements

### Requirement: Nearest configuration file wins

Beaver SHALL locate configuration by walking from the formatted file's directory up to the filesystem root and using the first `.beaver.yaml` found. Files above it SHALL NOT be read unless referenced through `extends:`. When no file is found, the `dart` preset applies.

#### Scenario: Nested project file shadows root file
- **WHEN** `repo/.beaver.yaml` and `repo/packages/app/.beaver.yaml` both exist and `repo/packages/app/lib/a.dart` is formatted
- **THEN** only `repo/packages/app/.beaver.yaml` and its `extends:` chain contribute values; `repo/.beaver.yaml` is ignored

#### Scenario: No configuration file
- **WHEN** no `.beaver.yaml` exists on the path from the file's directory to the filesystem root
- **THEN** the file is formatted with the `dart` preset

#### Scenario: Explicit config flag
- **WHEN** `--config <path>` is given
- **THEN** that file is used for every formatted file and discovery is skipped

### Requirement: Explicit inheritance via a single `extends` key

A configuration file SHALL inherit through exactly one key, `extends`, whose value is either a built-in preset name or a path to another `.beaver.yaml` resolved relative to the declaring file. There SHALL be no separate `preset` key. A chain whose last file has no `extends` SHALL implicitly extend `dart`.

#### Scenario: Extending a shared team file
- **WHEN** `packages/app/.beaver.yaml` contains `extends: ../../config/team.beaver.yaml` and `line_length: 80`
- **THEN** every value not set in the app file comes from the team file (and transitively from its chain), and `line_length` is 80

#### Scenario: Chain terminates in the implicit preset
- **WHEN** a file has no `extends` key
- **THEN** its unset keys take the `dart` preset's values

#### Scenario: Cycle in the chain
- **WHEN** file A extends B and B extends A
- **THEN** resolution fails with exit code 78 and a diagnostic naming both files

#### Scenario: Unknown preset name
- **WHEN** `extends: compact` is given and `compact` is not a built-in preset or an existing file
- **THEN** resolution fails with exit code 78

### Requirement: Scalar and map keys replace inherited values

For every key except `exclude`, a value set in a file SHALL replace the inherited value for that key. Nested maps are merged key by key. Merging SHALL operate on canonical keys after each layer has been normalised, so a shorthand and its long form replace exactly the same key.

#### Scenario: Override one nested key
- **WHEN** the chain yields `indent: {size: 2, continuation: 4}` and the user file sets `indent: {continuation: 2}`
- **THEN** the effective config has `indent.size` 2 and `indent.continuation` 2

#### Scenario: Shorthand replaces only the policy
- **WHEN** the chain yields `wrap.parameters.policy: chop_always` and `wrap.parameters.chop_from: 3`, and the user file sets `wrap: {parameters: if_long}`
- **THEN** the effective config has `wrap.parameters.policy` `if_long` and `wrap.parameters.chop_from` 3

### Requirement: Exclusion lists concatenate along the chain

The `exclude` list SHALL be the concatenation of every `exclude` list in the chain, deduplicated. A file SHALL NOT be able to remove an inherited exclusion pattern.

#### Scenario: Adding a pattern keeps the defaults
- **WHEN** a file extending `dart` sets `exclude: ["**/*.pb.dart"]`
- **THEN** `**/*.g.dart` and the other `dart` preset exclusions remain in effect alongside `**/*.pb.dart`

### Requirement: Unknown keys and invalid values are configuration errors

Beaver SHALL reject a configuration containing a key not in the schema, a value of the wrong type, or a value outside the allowed set, with exit code 78 and a diagnostic naming the file, the key and the allowed values. When the key was written through an alias, the diagnostic SHALL name the key as the user wrote it and the canonical key.

#### Scenario: Misspelled key
- **WHEN** a file contains `line_lenght: 100`
- **THEN** resolution fails with exit code 78 and the diagnostic names `line_lenght`

#### Scenario: Invalid enum value
- **WHEN** a file contains `wrap: {arguments: sometimes}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments` and `wrap.arguments.policy` and lists `never`, `if_long`, `chop_if_long`, `chop_always`

#### Scenario: Invalid canonical value
- **WHEN** a file contains `wrap: {arguments: {policy: sometimes}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments.policy` and lists the four policies

### Requirement: Incompatible trailing-comma settings are configuration errors

For each construct with an optional trailing comma, a resolved configuration whose effective values for that construct are a removing comma policy (`remove`, or a comma suppressed by `close_bracket: after_last_item`), `chop_on_trailing_comma: true` and `keep_existing_line_breaks: false` SHALL be rejected with exit code 78, unless the construct's policy is `never` or `chop_always`. Records SHALL be checked against the global values. The diagnostic SHALL name the construct, the keys, their values and where each was set, including the global source behind an inherited value, and the changes that resolve it.

#### Scenario: Inherited value completes the conflict
- **WHEN** a project file sets `trailing_commas: remove` and `wrap.keep_existing_line_breaks: false` and inherits `chop_on_trailing_comma: true` from the `dart` preset
- **THEN** resolution fails with exit code 78 and the diagnostic names all three keys and the preset as the source of `chop_on_trailing_comma`

#### Scenario: Conflict on one construct only
- **WHEN** a project file sets `wrap.collection_literals.trailing_commas: remove` and `wrap.collection_literals.keep_existing_line_breaks: false`, and the global values stay at the preset
- **THEN** resolution fails with exit code 78 and the diagnostic names `collection_literals`

#### Scenario: Suppression by close-bracket placement
- **WHEN** a project file sets `wrap.arguments.close_bracket: after_last_item` and `wrap.keep_existing_line_breaks: false`, with `trailing_commas: add_when_wrapped` and `chop_on_trailing_comma: true` from the preset
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.arguments.close_bracket` as suppressing the optional comma

#### Scenario: Policy never is exempt
- **WHEN** the arguments values would conflict but `wrap.arguments.policy: never`
- **THEN** resolution succeeds

#### Scenario: Threshold alone is not exempt
- **WHEN** the arguments values would conflict and `wrap.arguments.chop_from: 3` with policy `chop_if_long`
- **THEN** resolution fails with exit code 78

### Requirement: Every key has a value after resolution

After resolving the chain, every key in the schema SHALL have a value, because every chain terminates in a preset that defines all keys. A key configured as `inherit` SHALL have the concrete value of its fallback.

#### Scenario: Effective config is complete
- **WHEN** `beaver config --print` runs for any file
- **THEN** the output contains every schema key with a concrete value

#### Scenario: No inherit in the effective config
- **WHEN** `beaver config --print` runs with the preset alone
- **THEN** no key in the output has the value `inherit`

### Requirement: Single built-in preset `dart`

Beaver v1 SHALL ship exactly one built-in preset, `dart`, whose values follow dart_style 3.x conventions: `line_length` 80, `indent.size` 2, all `indent.align.*` false, `chop_on_named_arguments` empty, `trailing_commas: add_when_wrapped`, `chop_on_trailing_comma: true`, `strings.quotes: preserve`, and the default exclusion list for generated code. Keys not listed here take dart_style's behaviour.

#### Scenario: Preset values
- **WHEN** a file is formatted with no configuration
- **THEN** it is formatted at 80 columns with 2-space indentation, no alignment, and generated-file patterns excluded

### Requirement: Effective config inspection shows provenance

`beaver config --print` SHALL print the fully resolved configuration and, for each key, the file (or preset) that set its value. `--for <file>` SHALL resolve as if formatting that file; without it, resolution starts at the current directory. For a key resolved from `inherit`, the output SHALL state where `inherit` was configured and which file or preset supplied the fallback value.

#### Scenario: Provenance for an overridden key
- **WHEN** `line_length` is set in `repo/.beaver.yaml` and the user runs `beaver config --print --for repo/lib/a.dart`
- **THEN** the output shows `line_length` with its value and the path `repo/.beaver.yaml` as its source

#### Scenario: Provenance for an inherited key
- **WHEN** the preset sets `wrap.arguments.chop_on_trailing_comma: inherit` and `repo/.beaver.yaml` sets `wrap.chop_on_trailing_comma: false`
- **THEN** the output shows `wrap.arguments.chop_on_trailing_comma: false`, the preset as the source of `inherit`, and `repo/.beaver.yaml` as the source of the value

### Requirement: Effective root for exclusion patterns

Exclusion patterns SHALL be matched against paths relative to the effective root: the directory of the discovered project `.beaver.yaml`; if none, the nearest directory containing `pubspec.yaml`; if none, the formatted file's own directory. The current working directory SHALL never be the root. Patterns inherited through `extends:` SHALL also use this root, not the declaring file's location.

#### Scenario: Inherited pattern anchors at the project
- **WHEN** `config/shared.beaver.yaml` declares `exclude: ["lib/generated/**"]` and `packages/app/.beaver.yaml` extends it
- **THEN** `packages/app/lib/generated/x.dart` is excluded

#### Scenario: Working directory does not matter
- **WHEN** the same file is formatted from two different working directories
- **THEN** the exclusion decision is identical

### Requirement: Exclusion pattern syntax

Exclusion patterns SHALL use `package:glob` syntax and SHALL be matched case-sensitively.

#### Scenario: Case-sensitive match
- **WHEN** the pattern is `**/*.G.dart` and the file is `lib/a.g.dart`
- **THEN** the file is not excluded

### Requirement: Protected directories are never traversed

`.dart_tool/` and `.git/` SHALL never be traversed or formatted regardless of configuration.

#### Scenario: Attempt to include a protected directory
- **WHEN** a configuration contains no exclusion for `.dart_tool/` and `beaver .` runs
- **THEN** no file under `.dart_tool/` is formatted or reported

### Requirement: `init` writes a starter file

`beaver init` SHALL write a `.beaver.yaml` in the current directory containing `extends: dart` and commented examples of the available keys, and SHALL refuse to overwrite an existing file.

#### Scenario: Existing file
- **WHEN** `.beaver.yaml` already exists in the current directory and `beaver init` runs
- **THEN** nothing is written and the command exits with code 64 and a diagnostic

### Requirement: Canonical long-form keys

The schema SHALL hold only long-form leaf keys. Each wrappable list SHALL be a map with the fields `policy`, `chop_from`, `keep_existing_line_breaks` and `chop_on_trailing_comma`, plus `align`, `indent`, `close_bracket` and `trailing_commas` only on the lists where the field has an effect. No key SHALL be both a leaf and a prefix of other keys.

#### Scenario: Long form accepted
- **WHEN** a file contains `wrap: {arguments: {policy: chop_if_long, chop_from: 4, keep_existing_line_breaks: false}}`
- **THEN** the effective configuration has `wrap.arguments.policy` `chop_if_long`, `wrap.arguments.chop_from` 4 and `wrap.arguments.keep_existing_line_breaks` false

#### Scenario: Field not offered on a construct
- **WHEN** a file contains `wrap: {chained_calls: {trailing_commas: remove}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.chained_calls.trailing_commas`

#### Scenario: Field with no effect is refused
- **WHEN** a file contains `wrap: {cascades: {align: true}}` (likewise `conditional_expressions`, `switch_expressions` and `class_header`, which have nothing to align under a first item)
- **THEN** resolution fails with exit code 78 naming `wrap.cascades.align` as unknown

### Requirement: Aliases map one-to-one onto canonical keys

The following spellings SHALL be accepted without deprecation and SHALL behave identically to their canonical key: `wrap.<list>: <policy>` for `wrap.<list>.policy`; `indent.align.arguments`, `indent.align.parameters` and `indent.align.chained_calls` for `wrap.<list>.align`; `wrap.chained_calls.min_calls` for `wrap.chained_calls.chop_from`; `wrap.before_operator` for `wrap.break_before.binary_operator`.

#### Scenario: Shorthand policy
- **WHEN** a file contains `wrap: {arguments: chop_always}`
- **THEN** the effective `wrap.arguments.policy` is `chop_always`

#### Scenario: Legacy alignment key
- **WHEN** a file contains `indent: {align: {parameters: true}}`
- **THEN** the effective `wrap.parameters.align` is true

#### Scenario: Legacy chain threshold
- **WHEN** a file contains `wrap: {chained_calls: {min_calls: 3}}`
- **THEN** the effective `wrap.chained_calls.chop_from` is 3

### Requirement: Each layer is normalised before merging

Every configuration source SHALL be rewritten to canonical keys and validated on its own before it is merged with inherited values. A shorthand value in a child SHALL therefore override only the canonical key it aliases and keep every other inherited field of that map.

#### Scenario: Shorthand keeps an inherited threshold
- **WHEN** a team file sets `wrap.arguments.chop_from: 4` and the project file extending it sets `wrap: {arguments: never}`
- **THEN** the effective `wrap.arguments.policy` is `never` and `wrap.arguments.chop_from` is 4

### Requirement: Conflicting spellings in one layer are configuration errors

When one configuration source sets the same canonical key through two spellings with different values, resolution SHALL fail with exit code 78 and a diagnostic naming both keys. Identical values SHALL be accepted. Across layers, the nearer source SHALL win per canonical key whatever spelling either used.

#### Scenario: Alias and canonical key disagree
- **WHEN** one file sets `indent.align.arguments: true` and `wrap.arguments.align: false`
- **THEN** resolution fails with exit code 78 and the diagnostic names `indent.align.arguments` and `wrap.arguments.align`

#### Scenario: Identical duplicate
- **WHEN** one file sets `wrap.before_operator: true` and `wrap.break_before.binary_operator: true`
- **THEN** resolution succeeds

#### Scenario: Different spellings across layers
- **WHEN** a team file sets `wrap.arguments.align: true` and the project file extending it sets `indent.align.arguments: false`
- **THEN** the effective `wrap.arguments.align` is false

### Requirement: `inherit` links a key to its fallback

Keys documented as inheriting SHALL accept the value `inherit`, which SHALL resolve to the effective value of that key's documented fallback after the whole chain has merged, including a fallback overridden in a nearer file. Omitting such a key SHALL keep the parent layer's value; writing `inherit` SHALL restore the link. The formatter SHALL receive only resolved values.

#### Scenario: Inherit follows a child's global override
- **WHEN** the preset sets `wrap.collection_literals.keep_existing_line_breaks: inherit` and the project file sets `wrap.keep_existing_line_breaks: false`
- **THEN** the effective `wrap.collection_literals.keep_existing_line_breaks` is false

#### Scenario: Explicit inherit restores the link
- **WHEN** a team file sets `wrap.arguments.keep_existing_line_breaks: false`, and the project file extending it sets `wrap.keep_existing_line_breaks: true` and `wrap.arguments.keep_existing_line_breaks: inherit`
- **THEN** the effective `wrap.arguments.keep_existing_line_breaks` is true

#### Scenario: Omission keeps the parent value
- **WHEN** a team file sets `wrap.arguments.keep_existing_line_breaks: false` and the project file extending it sets only `wrap.keep_existing_line_breaks: true`
- **THEN** the effective `wrap.arguments.keep_existing_line_breaks` is false

### Requirement: Inheriting list fields and their fallbacks

These list fields SHALL accept `inherit`, preset `inherit`: `keep_existing_line_breaks`, `chop_on_trailing_comma` and `trailing_commas` (fallback: the global key of the same name); `close_bracket` (`wrap.close_bracket`); `indent` (`indent.continuation` for chained calls and binary expressions, `indent.size` otherwise). `policy`, `chop_from` and `align` SHALL NOT accept `inherit`, except on `wrap.enum_values`.

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
- **WHEN** a project file sets `wrap.collection_literals: chop_always` and does not set `wrap.enum_values`
- **THEN** the effective `wrap.enum_values.policy` is `chop_always`

#### Scenario: Enum set independently
- **WHEN** a project file sets `wrap.collection_literals: chop_always` and `wrap.enum_values: chop_if_long`
- **THEN** the effective `wrap.enum_values.policy` is `chop_if_long` and collection literals still chop always

### Requirement: Inheriting scalar keys and their fallbacks

`braces.catch_on_new_line`, `braces.finally_on_new_line` and `braces.while_on_new_line` SHALL accept `true`, `false` or `inherit`, preset `inherit`, falling back to `braces.else_on_new_line`, which stays a plain boolean. `blank_lines.max_consecutive_in_code` SHALL accept an integer or `inherit`, preset `inherit`, falling back to `blank_lines.max_consecutive`.

#### Scenario: Catch follows else
- **WHEN** `braces.else_on_new_line: true` and `braces.catch_on_new_line` is not set
- **THEN** the effective `braces.catch_on_new_line` is true

#### Scenario: Else does not accept inherit
- **WHEN** a file contains `braces: {else_on_new_line: inherit}`
- **THEN** resolution fails with exit code 78

### Requirement: `around_class_declarations` may hand off to the general rule

`blank_lines.around_class_declarations` SHALL accept a non-negative integer or `inherit`. With `inherit`, boundaries next to class-like declarations SHALL follow `blank_lines.between_top_level_declarations` and its grouping rule.

#### Scenario: Classes use the general count
- **WHEN** `around_class_declarations: inherit` and `between_top_level_declarations: 2`
- **THEN** two blank lines separate a class from an adjacent top-level function

### Requirement: Integer-or-preserve values

`blank_lines.between_import_groups`, `blank_lines.between_top_level_declarations` and `blank_lines.between_comment_and_declaration` SHALL accept `preserve` or a non-negative integer. Any other value SHALL be a configuration error.

#### Scenario: Invalid value
- **WHEN** a file contains `blank_lines: {between_import_groups: some}`
- **THEN** resolution fails with exit code 78 and the diagnostic lists `preserve` and a non-negative integer as allowed

### Requirement: `chop_on_calls` entries are validated

`wrap.chop_on_calls` SHALL be a list of non-empty dotted names whose segments are Dart identifiers, default empty. Wildcards SHALL NOT be accepted. A malformed entry SHALL be a configuration error.

#### Scenario: Wildcard entry
- **WHEN** a file contains `wrap: {chop_on_calls: ['Row*']}`
- **THEN** resolution fails with exit code 78 and the diagnostic names the entry

#### Scenario: Empty segment
- **WHEN** a file contains `wrap: {chop_on_calls: ['Row..center']}`
- **THEN** resolution fails with exit code 78

### Requirement: Include list

`include` SHALL be a list of glob patterns, preset `['**']`, matched with the same syntax and effective root as `exclude`, and replaced rather than concatenated along the chain. A file that matches no `include` pattern SHALL be treated exactly as an excluded file wherever exclusion applies.

#### Scenario: Only lib and test
- **WHEN** a project file sets `include: ['lib/**', 'test/**']` and `beaver .` runs
- **THEN** `tool/gen.dart` is skipped and `lib/a.dart` is formatted

#### Scenario: Exclude still wins
- **WHEN** `include: ['lib/**']` and `lib/a.g.dart` matches the default exclusions
- **THEN** `lib/a.g.dart` is skipped

### Requirement: New keys keep today's output by default

Every key added by this change SHALL have a `dart` preset value that reproduces the output Beaver produced before the key existed, with two exceptions: `blank_lines.between_comment_and_declaration` is `preserve`, and `wrap.cascades.keep_existing_line_breaks` is `inherit`, which resolves to `true` under the preset.

#### Scenario: Unaffected project
- **WHEN** a project without comment-separated declarations or broken one-section cascades is formatted before and after this change with the same `.beaver.yaml`
- **THEN** the output is identical

### Requirement: Reference template

`beaver config --template` SHALL print a YAML document generated from the schema that lists every canonical key once, set to its `dart` preset value (`inherit` where the preset says so), with the allowed values in a trailing comment. Integer keys SHALL state their minimum, list keys SHALL show an example entry, and map-shaped keys SHALL appear in long form with a comment that the scalar shorthand is accepted.

#### Scenario: Policy line
- **WHEN** `beaver config --template` runs
- **THEN** the output contains `policy: chop_if_long` under `wrap.arguments` with a trailing comment listing `never | if_long | chop_if_long | chop_always`

#### Scenario: Template parses as a configuration
- **WHEN** the template output is saved as `.beaver.yaml`
- **THEN** resolution succeeds and the effective configuration equals the `dart` preset

#### Scenario: Committed copy kept in sync
- **WHEN** the test suite runs and `docs/beaver.template.yaml` differs from the `config --template` output
- **THEN** the suite fails

### Requirement: Continuation placement fields

`wrap.chained_calls` and `wrap.binary_expressions` SHALL accept `break_after_prefix` (`true` | `false`) and `indent_from` (`line` | `target`). Neither field SHALL accept `inherit`, and no other list SHALL offer them. Preset `dart`: `wrap.chained_calls.break_after_prefix: false`, `wrap.binary_expressions.break_after_prefix: true`, `indent_from: line` on both, which reproduces the output from before the fields existed.

#### Scenario: Fields accepted
- **WHEN** a file contains `wrap: {chained_calls: {break_after_prefix: true, indent_from: target}}`
- **THEN** the effective configuration has `wrap.chained_calls.break_after_prefix` true and `wrap.chained_calls.indent_from` `target`

#### Scenario: Invalid base
- **WHEN** a file contains `wrap: {binary_expressions: {indent_from: statement}}`
- **THEN** resolution fails with exit code 78 and the diagnostic names `wrap.binary_expressions.indent_from` and the allowed values `line | target`

#### Scenario: Field not offered on another list
- **WHEN** a file contains `wrap: {arguments: {indent_from: target}}`
- **THEN** resolution fails with exit code 78 naming `wrap.arguments.indent_from` as unknown

#### Scenario: No inherit
- **WHEN** a file contains `wrap: {chained_calls: {break_after_prefix: inherit}}`
- **THEN** resolution fails with exit code 78 naming `wrap.chained_calls.break_after_prefix`

#### Scenario: Unchanged output without the fields
- **WHEN** a project is formatted before and after this change with the same `.beaver.yaml`, which sets neither field
- **THEN** the output is identical

#### Scenario: Listed in the reference template
- **WHEN** `beaver config --template` runs
- **THEN** both fields appear under `wrap.chained_calls` and `wrap.binary_expressions` with their preset values and alternatives
