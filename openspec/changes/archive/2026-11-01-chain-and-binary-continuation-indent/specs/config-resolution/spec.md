## ADDED Requirements

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
