# Spec Delta

## MODIFIED Requirements

### Requirement: Option precedence and isolation
Each case SHALL start from the `dart` preset, then apply file-level options, then case options. File-level and case options SHALL each be normalised to canonical keys and validated on their own before they are merged, exactly as configuration files are, so a shorthand and its long form behave identically. Options from one case SHALL NOT affect another.

#### Scenario: Case overrides file option
- **WHEN** the file sets `wrap.arguments=chop_always` and a case sets `wrap.arguments=chop_if_long`
- **THEN** that case uses `chop_if_long` and the next case without the option uses `chop_always`

#### Scenario: Shorthand case option keeps a file-level field
- **WHEN** the file sets `wrap.arguments.chop_from=3` and a case sets `wrap.arguments=if_long`
- **THEN** that case runs with `wrap.arguments.policy` `if_long` and `wrap.arguments.chop_from` 3

#### Scenario: Conflicting spellings in one case
- **WHEN** a case sets `indent.align.arguments=true wrap.arguments.align=false`
- **THEN** the suite fails with a diagnostic naming the file, the case and both keys
