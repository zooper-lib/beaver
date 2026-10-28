# Spec Delta

## Purpose

Defines how Beaver finds, inherits, validates and resolves the `.beaver.yaml` configuration that governs formatting of a given file, including the built-in `dart` preset and exclusion patterns.

## ADDED Requirements

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
For every key except `exclude`, a value set in a file SHALL replace the inherited value for that key. Nested maps are merged key by key.

#### Scenario: Override one nested key
- **WHEN** the chain yields `indent: {size: 2, continuation: 4}` and the user file sets `indent: {continuation: 2}`
- **THEN** the effective config has `indent.size` 2 and `indent.continuation` 2

### Requirement: Exclusion lists concatenate along the chain
The `exclude` list SHALL be the concatenation of every `exclude` list in the chain, deduplicated. A file SHALL NOT be able to remove an inherited exclusion pattern.

#### Scenario: Adding a pattern keeps the defaults
- **WHEN** a file extending `dart` sets `exclude: ["**/*.pb.dart"]`
- **THEN** `**/*.g.dart` and the other `dart` preset exclusions remain in effect alongside `**/*.pb.dart`

### Requirement: Unknown keys and invalid values are configuration errors
Beaver SHALL reject a configuration containing a key not in the schema, a value of the wrong type, or a value outside the allowed set, with exit code 78 and a diagnostic naming the file, the key and the allowed values.

#### Scenario: Misspelled key
- **WHEN** a file contains `line_lenght: 100`
- **THEN** resolution fails with exit code 78 and the diagnostic names `line_lenght`

#### Scenario: Invalid enum value
- **WHEN** a file contains `wrap: {arguments: sometimes}`
- **THEN** resolution fails with exit code 78 and the diagnostic lists `never`, `if_long`, `chop_if_long`, `chop_always`

### Requirement: Every key has a value after resolution
After resolving the chain, every key in the schema SHALL have a value, because every chain terminates in a preset that defines all keys.

#### Scenario: Effective config is complete
- **WHEN** `beaver config --print` runs for any file
- **THEN** the output contains every schema key with a concrete value

### Requirement: Single built-in preset `dart`
Beaver v1 SHALL ship exactly one built-in preset, `dart`, whose values follow dart_style 3.x conventions: `line_length` 80, `indent.size` 2, all `indent.align.*` false, `chop_on_named_arguments` empty, `trailing_commas: add_when_wrapped`, `chop_on_trailing_comma: true`, `strings.quotes: preserve`, and the default exclusion list for generated code.

#### Scenario: Preset values
- **WHEN** a file is formatted with no configuration
- **THEN** it is formatted at 80 columns with 2-space indentation, no alignment, and generated-file patterns excluded

### Requirement: Effective config inspection shows provenance
`beaver config --print` SHALL print the fully resolved configuration and, for each key, the file (or preset) that set its value. `--for <file>` SHALL resolve as if formatting that file; without it, resolution starts at the current directory.

#### Scenario: Provenance for an overridden key
- **WHEN** `line_length` is set in `repo/.beaver.yaml` and the user runs `beaver config --print --for repo/lib/a.dart`
- **THEN** the output shows `line_length` with its value and the path `repo/.beaver.yaml` as its source

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
