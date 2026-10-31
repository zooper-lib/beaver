# Spec Delta

## Purpose

Guarantees that formatting never changes what a program means: every formatted output is checked against its input before it is written, and a failed check leaves the input untouched.

## ADDED Requirements

### Requirement: Verification runs before any output is written
For every formatted document, Beaver SHALL verify the output against the input and SHALL write the output (to file or stdout) only if every check passes. On failure the target SHALL remain unchanged, a diagnostic naming the file and the failed check SHALL go to stderr, and the exit code SHALL be 70.

#### Scenario: Internal defect caught
- **WHEN** a formatting defect drops a token
- **THEN** the file on disk is unchanged, stderr names the file and the check, and the exit code is 70

#### Scenario: Stdin failure
- **WHEN** verification fails for `--stdin` input
- **THEN** nothing is written to stdout

### Requirement: Output must parse
The formatted output SHALL parse without syntax errors.

#### Scenario: Unparseable output
- **WHEN** the output does not parse
- **THEN** verification fails

### Requirement: Token sequence equivalence
The non-comment token sequences of input and output SHALL match in type, lexeme and order, after applying only the permitted normalizations: optional trailing commas and string quote changes.

#### Scenario: Identical program
- **WHEN** formatting only changes whitespace
- **THEN** the token check passes

#### Scenario: Reordered tokens
- **WHEN** the output has two arguments swapped
- **THEN** verification fails

### Requirement: Only syntactically optional trailing commas are normalized
A trailing comma SHALL be ignored by the token check only when it is the last separator of a construct where it is optional: argument lists, parameter lists, list literals, set and map literals, enum constant lists, and record literals, types or patterns having two or more positional fields or any named field. A single-positional-field record literal, record type or record pattern SHALL be compared exactly.

#### Scenario: Optional comma added
- **WHEN** the output adds a trailing comma to a broken argument list
- **THEN** the token check passes

#### Scenario: Required comma removed
- **WHEN** the output turns `(42,)` into `(42)`
- **THEN** verification fails

#### Scenario: Record pattern comma removed
- **WHEN** the output turns `final (v,) = r;` into `final (v) = r;`
- **THEN** verification fails

### Requirement: String literals compared by value when quotes may change
When `strings.quotes` is not `preserve`, string literal parts SHALL be compared by interpreted value; when it is `preserve`, by exact lexeme. Interpolation expressions SHALL be compared as ordinary tokens. Raw strings SHALL be compared by exact lexeme.

#### Scenario: Quote change accepted
- **WHEN** `strings.quotes: single` turns `"x"` into `'x'`
- **THEN** verification passes

#### Scenario: Content change rejected
- **WHEN** the output changes `'a'` to `'b'`
- **THEN** verification fails

### Requirement: Structural fingerprint equivalence
The ordered sequence of syntax node kinds and their nesting SHALL be identical between input and output.

#### Scenario: Statement became a block
- **WHEN** the output wraps a bare `return;` in braces
- **THEN** verification fails

#### Scenario: Comma list misclassified
- **WHEN** a trailing comma the token check wrongly treated as optional changes a parenthesized expression into a record
- **THEN** the fingerprint check fails

### Requirement: Comments preserved in place
Every comment SHALL appear in the output with identical text, in the same order, and with the same preceding and following non-comment tokens as in the input.

#### Scenario: Doc comment migrated
- **WHEN** the output moves a doc comment from `class A` to `class B`
- **THEN** verification fails

#### Scenario: Comment dropped
- **WHEN** the output lacks a comment present in the input
- **THEN** verification fails

### Requirement: Ignored regions byte-identical
Every ignored region SHALL be present in the output byte for byte.

#### Scenario: Region altered
- **WHEN** a byte inside an ignored region differs in the output
- **THEN** verification fails

### Requirement: Idempotence
Formatting the output again with the same configuration SHALL produce the same output. This check SHALL run in tests and on the corpus; in production it is implied by the design and MAY be sampled.

#### Scenario: Second pass is a no-op
- **WHEN** a formatted file is formatted again
- **THEN** the result is byte-identical

### Requirement: Verification is never disabled for performance
Verification SHALL run on every production formatting operation. There SHALL be no flag or configuration that disables it.

#### Scenario: No opt-out
- **WHEN** the CLI help and configuration schema are inspected
- **THEN** no option disables verification
