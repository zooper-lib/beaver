# Spec Delta

## MODIFIED Requirements

### Requirement: Line endings
The printer SHALL emit the line ending selected by the effective `line_ending`: `lf` emits `\n`, `crlf` emits `\r\n`, and `auto` (the preset) emits the line ending that dominates the input (`\r\n` if the input uses it, else `\n`). The output SHALL end with exactly one line ending.

#### Scenario: CRLF input
- **WHEN** `line_ending: auto` and the input uses `\r\n` endings
- **THEN** every output line ends with `\r\n`

#### Scenario: Pinned LF
- **WHEN** `line_ending: lf` and the input uses `\r\n` endings
- **THEN** every output line ends with `\n`

#### Scenario: Pinned CRLF
- **WHEN** `line_ending: crlf` and the input uses `\n` endings
- **THEN** every output line ends with `\r\n`
