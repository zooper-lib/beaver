# Spec Delta

## MODIFIED Requirements

### Requirement: `--stdin-name` provides context only
`--stdin-name <path>` SHALL be used for configuration discovery, EditorConfig resolution, exclusion matching and diagnostics. Beaver SHALL NOT read the file at that path. When the effective configuration has `editorconfig: true`, `--stdin` without `--stdin-name` SHALL fail with exit code 64 and leave stdout empty.

#### Scenario: Unsaved buffer
- **WHEN** the file on disk differs from the stdin content
- **THEN** the output is based solely on the stdin content

#### Scenario: Config discovery from name
- **WHEN** `--stdin-name packages/app/lib/a.dart` is given
- **THEN** configuration is resolved as for that path

#### Scenario: Name required with EditorConfig
- **WHEN** `--config team.beaver.yaml` sets `editorconfig: true` and `beaver --stdin --config team.beaver.yaml` runs without `--stdin-name`
- **THEN** Beaver exits with code 64 and stdout is empty
