# Spec Delta

## ADDED Requirements

### Requirement: Template output
`beaver config --template` SHALL write the reference template to stdout and exit 0. It SHALL NOT read any `.beaver.yaml` and SHALL produce the same output in every directory.

#### Scenario: Independent of the project
- **WHEN** `beaver config --template` runs in a directory whose `.beaver.yaml` sets `line_length: 120`
- **THEN** the output shows `line_length: 80`, the preset value

### Requirement: `config --print` requires `--for` with EditorConfig integration
When the effective configuration has `editorconfig: true`, `beaver config --print` without `--for` SHALL fail with exit code 64 and a diagnostic stating that `--for` is required while EditorConfig integration is enabled.

#### Scenario: Missing --for
- **WHEN** the current directory's `.beaver.yaml` sets `editorconfig: true` and `beaver config --print` runs
- **THEN** Beaver exits with code 64 and nothing is written to stdout

## MODIFIED Requirements

### Requirement: Command surface
The `beaver` executable SHALL support: `beaver [options] <paths...>` (format in place), `--check`, `--diff`, `--stdin [--stdin-name <path>] [--range <range>]`, `--config <file>`, `--verbose`, `--version`, `beaver config --print [--for <file>]`, `beaver config --template`, and `beaver init`. Options and subcommands SHALL be documented in `--help`.

#### Scenario: Help lists every mode
- **WHEN** `beaver --help` runs
- **THEN** the output names every option and subcommand above
