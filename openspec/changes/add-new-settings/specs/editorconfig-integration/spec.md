# Spec Delta

## Purpose

Defines the opt-in reading of `.editorconfig` files as a source of indentation and line-ending defaults, its place in the precedence order, and how its values are reported.

## ADDED Requirements

### Requirement: Integration is opt-in
The `editorconfig` key SHALL accept `true` or `false`, preset `false`, and SHALL inherit through `extends` like any other key. EditorConfig files SHALL be consulted only when the effective value is `true`. A project without a `.beaver.yaml` therefore never consults EditorConfig.

#### Scenario: Disabled by default
- **WHEN** a project has `.editorconfig` with `[*]` and `indent_size = 4` and a `.beaver.yaml` that does not set `editorconfig`
- **THEN** Dart files are indented with the preset `indent.size` 2

#### Scenario: Child disables an inherited true
- **WHEN** a team file sets `editorconfig: true` and the project file extending it sets `editorconfig: false`
- **THEN** no EditorConfig file is read for that project

### Requirement: Precedence between preset, EditorConfig and Beaver settings
When integration is enabled, values SHALL resolve from lowest to highest precedence as: the `dart` preset, applicable EditorConfig properties, explicit settings anywhere in the Beaver `extends` chain. An explicit Beaver value SHALL win regardless of directory proximity. Preset defaults SHALL NOT count as explicit values.

#### Scenario: EditorConfig beats the preset
- **WHEN** `editorconfig: true`, no Beaver file sets `indent.size`, and the matching EditorConfig section sets `indent_size = 4`
- **THEN** the effective `indent.size` is 4

#### Scenario: Beaver setting beats a nearer EditorConfig
- **WHEN** a team file higher in the `extends` chain sets `indent.size: 2` and an `.editorconfig` next to the formatted file sets `indent_size = 4`
- **THEN** the effective `indent.size` is 2

### Requirement: Full EditorConfig resolution
EditorConfig resolution SHALL match sections against the formatted file's path, process `.editorconfig` files from the file's directory upward until one declares `root = true`, let later sections and nearer files override earlier ones, and treat `unset` as removing the property. Reading only the nearest file SHALL NOT be sufficient.

#### Scenario: Nearer file overrides an ancestor
- **WHEN** `repo/.editorconfig` has `root = true` and `[*.dart]` `indent_size = 4`, and `repo/lib/.editorconfig` has `[*.dart]` `indent_size = 2`
- **THEN** `repo/lib/a.dart` resolves `indent_size` to 2

#### Scenario: Root stops the walk
- **WHEN** `repo/.editorconfig` declares `root = true` and the parent of `repo` also has an `.editorconfig`
- **THEN** the parent's file is not read

#### Scenario: Unset removes a value
- **WHEN** an ancestor section sets `indent_size = 4` and a nearer matching section sets `indent_size = unset`
- **THEN** EditorConfig supplies no `indent.size` and the preset value applies

#### Scenario: Section order
- **WHEN** one file has `[*]` `indent_size = 4` followed by `[*.dart]` `indent_size = 2`
- **THEN** `a.dart` resolves `indent_size` to 2

### Requirement: Supported properties
Only `indent_style`, `indent_size` and `end_of_line` SHALL affect Beaver. `indent_style` maps to `indent.style` (`space` to `spaces`, `tab` to `tabs`). `indent_size` maps to `indent.size`; `indent_size = tab` takes the value of `tab_width`. `end_of_line` maps `lf` and `crlf` to `line_ending`. Every other property SHALL be ignored.

#### Scenario: Tab size derived from tab_width
- **WHEN** the matching section sets `indent_style = tab`, `indent_size = tab` and `tab_width = 4`
- **THEN** the effective values are `indent.style: tabs` and `indent.size: 4`

#### Scenario: Unrelated property ignored
- **WHEN** the matching section sets `max_line_length = 120`
- **THEN** the effective `line_length` is unaffected

#### Scenario: Unsupported line ending
- **WHEN** the matching section sets `end_of_line = cr`
- **THEN** EditorConfig supplies no `line_ending` and a diagnostic names the file, the section and the unsupported value

### Requirement: Explicit `line_ending: auto` overrides EditorConfig
EditorConfig SHALL supply `line_ending` only when no Beaver file in the chain sets `line_ending`. An explicit `line_ending: auto` in a Beaver file SHALL override EditorConfig and select source-based detection.

#### Scenario: Explicit auto restores detection
- **WHEN** `editorconfig: true`, the project file sets `line_ending: auto`, EditorConfig sets `end_of_line = crlf`, and the input uses `\n`
- **THEN** the output uses `\n`

### Requirement: A file name is required when integration is enabled
EditorConfig resolution SHALL run against the formatted file's path, or the `--stdin-name` path for stdin, also when `--config` is given. With integration enabled, stdin formatting without `--stdin-name` and `config --print` without `--for` SHALL be usage errors with exit code 64.

#### Scenario: Stdin without a name
- **WHEN** the effective configuration has `editorconfig: true` and `beaver --stdin` runs without `--stdin-name`
- **THEN** Beaver exits with code 64 and a diagnostic stating that `--stdin-name` is required while EditorConfig integration is enabled

#### Scenario: Explicit config still resolves EditorConfig
- **WHEN** `--config team.beaver.yaml` with `editorconfig: true` formats `lib/a.dart`
- **THEN** EditorConfig sections are matched against `lib/a.dart`

### Requirement: EditorConfig provenance
`config --print` SHALL report, for a value supplied by EditorConfig, the `.editorconfig` path, the section header and the property name, including the `tab_width` property when `indent.size` was derived from it.

#### Scenario: Derived indent size
- **WHEN** `indent.size` comes from `indent_size = tab` and `tab_width = 4` in `repo/.editorconfig` section `[*.dart]`
- **THEN** the output shows `indent.size: 4` with `repo/.editorconfig`, `[*.dart]`, `indent_size` and `tab_width` as its source
