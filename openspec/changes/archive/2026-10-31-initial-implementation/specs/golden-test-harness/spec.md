# Spec Delta

## Purpose

Defines the golden test file format and runner used for Beaver's own behaviour tests and for scoring compatibility against the dart_style reference corpus.

## ADDED Requirements

### Requirement: File grammar
Golden test files SHALL use the extension `.stmt` (each case is a statement) or `.unit` (each case is a compilation unit) and dart_style's grammar: an optional first line containing `|` whose column sets the line length; an optional line of parenthesized file-level options; `###` comment lines; `>>>` followed by optional parenthesized options and a description to start a case; input lines; one or more `<<<` output sections with an optional version and description.

#### Scenario: Upstream file parses unchanged
- **WHEN** any file from dart_style's `test/tall/` directory is loaded
- **THEN** the harness parses it without modification

### Requirement: Config options in cases
Options SHALL accept dotted configuration paths as `key=value`, where the value is a YAML scalar, a quoted string, or a bracketed list. Option strings SHALL be parsed respecting quotes and brackets, not split on whitespace. Values SHALL be validated against the real configuration schema.

#### Scenario: Case-level override
- **WHEN** a case header is `>>> (wrap.arguments=chop_always trailing_commas=remove) desc`
- **THEN** that case runs with those two values overriding the preset

#### Scenario: List value
- **WHEN** an option is `wrap.chop_on_named_arguments=[child,children]`
- **THEN** the case runs with that list

#### Scenario: Invalid option
- **WHEN** an option names an unknown key
- **THEN** the suite fails with a diagnostic naming the file and case

### Requirement: Option precedence and isolation
Each case SHALL start from the `dart` preset, then apply file-level options, then case options. Options from one case SHALL NOT affect another.

#### Scenario: Case overrides file option
- **WHEN** the file sets `wrap.arguments=chop_always` and a case sets `wrap.arguments=chop_if_long`
- **THEN** that case uses `chop_if_long` and the next case without the option uses `chop_always`

### Requirement: Legacy options keep upstream meaning
`(indent N)` SHALL apply N spaces of leading indentation to the case as a harness setting and SHALL NOT change `indent.size`. `(experiment X)` SHALL enable parser experiment X. `(trailing_commas preserve)` SHALL be equivalent to `trailing_commas=preserve chop_on_trailing_comma=true`.

#### Scenario: Leading indentation
- **WHEN** a case has `(indent 4)`
- **THEN** every output line is expected to be indented by four additional spaces and the configured indent size is unchanged

### Requirement: Versioned output selection
When a case has several `<<<` sections tagged with language versions, the section with the highest version SHALL be the expectation, because Beaver formats at the latest language version.

#### Scenario: Two tagged sections
- **WHEN** a case has `<<< 3.8` and `<<< 3.10` sections
- **THEN** the `3.10` output is the expectation

### Requirement: Selection-marker cases are skipped
Cases containing `‹` or `›` selection markers SHALL be reported as skipped, not as passes, failures or mismatches.

#### Scenario: Selection test file
- **WHEN** a case input contains `‹123›45;`
- **THEN** the case is counted as skipped

### Requirement: Statement cases
For `.stmt` files the harness SHALL format each case as a statement, with no wrapper text appearing in the output and verification applied to the statement.

#### Scenario: Bare statement
- **WHEN** a `.stmt` case input is `a=b=c;`
- **THEN** the output is compared to the expectation as a statement, e.g. `a = b = c;`

### Requirement: Beaver suites are strict
Every case under `test/golden/<area>/` SHALL pass: output equals expectation, structural verification passes, and formatting the output again yields the same output. Any failure fails the suite.

#### Scenario: Mismatch
- **WHEN** a Beaver case's output differs from its expectation
- **THEN** the suite fails naming the file, case, and a diff

### Requirement: Reference corpus is scored
Files under `test/golden/dart_style/tall/` SHALL be verbatim copies of upstream, accompanied by upstream's LICENSE and an `UPSTREAM.md` recording repository, release, language version and import date. For each eligible case the runner SHALL record exact match or formatting mismatch and SHALL report a match percentage overall and per area. A formatting mismatch SHALL NOT fail the suite; a structural-verification or idempotence failure on any case SHALL.

#### Scenario: Score report
- **WHEN** the reference run completes
- **THEN** the report lists eligible cases, exact matches, mismatches, skipped cases, and the percentage, overall and per area

#### Scenario: Safety failure in the corpus
- **WHEN** formatting a reference case fails structural verification
- **THEN** the suite fails even though mismatches alone would not

### Requirement: Short-style corpus not imported
Only upstream's `tall/` directory SHALL be imported; `short/` SHALL not be present.

#### Scenario: Corpus contents
- **WHEN** `test/golden/dart_style/` is listed
- **THEN** it contains `tall/`, `LICENSE` and `UPSTREAM.md` and no `short/`
