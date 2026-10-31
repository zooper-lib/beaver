# stdin-protocol Specification

## Purpose

Defines the stdin/stdout contract editors use to format a buffer or a selection, which is the sole cross-editor integration surface and is versioned independently of formatting behaviour.

## Requirements

### Requirement: Whole document in, whole document out

With `--stdin`, Beaver SHALL read the complete document from stdin and, on success, write the complete resulting document to stdout. Partial output SHALL never be written.

#### Scenario: Successful format
- **WHEN** a valid document is piped to `beaver --stdin`
- **THEN** stdout contains the whole formatted document and the exit code is 0

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

### Requirement: Excluded names are echoed

When `--stdin-name` matches an exclusion pattern, Beaver SHALL write the input unchanged to stdout, SHALL NOT parse it, and SHALL exit 0.

#### Scenario: Generated file on save
- **WHEN** `--stdin-name lib/a.g.dart` is given with default exclusions
- **THEN** stdout equals stdin and the exit code is 0

### Requirement: Errors leave stdout empty

On a parse error, configuration error, or verification failure, stdout SHALL be empty, a diagnostic SHALL be written to stderr, and the exit code SHALL be 65, 78 or 70 respectively.

#### Scenario: Syntax error in buffer
- **WHEN** invalid Dart is piped to `beaver --stdin`
- **THEN** stdout is empty and the exit code is 65

### Requirement: Range syntax and coordinates

`--range L1:C1-L2:C2` SHALL use 1-based line and column numbers, columns counted in UTF-16 code units, start inclusive, end exclusive, referring to the input document. A range that is reversed, out of bounds, malformed, or splits a surrogate pair SHALL be a usage error (exit 64). `--range` SHALL require `--stdin`.

#### Scenario: Valid range
- **WHEN** `--range 3:5-5:11` is given for a document with at least five lines
- **THEN** the selection is interpreted from line 3 column 5 up to but not including line 5 column 11

#### Scenario: Reversed range
- **WHEN** `--range 5:1-3:1` is given
- **THEN** the exit code is 64

#### Scenario: CRLF document
- **WHEN** the document uses `\r\n` line endings
- **THEN** line and column positions resolve to the same characters an editor shows

### Requirement: Range expands along a fixed ladder

The selection SHALL be expanded to the smallest set of complete units covering it, trying in order: statements, class members, top-level declarations. Beaver SHALL never refuse a range.

#### Scenario: Selection inside a method body
- **WHEN** the selection covers part of two statements inside a method
- **THEN** exactly those two statements are reformatted

#### Scenario: Selection inside an argument
- **WHEN** the selection covers one argument of a call
- **THEN** the enclosing statement is reformatted

#### Scenario: Selection spanning two members
- **WHEN** the selection starts in one method and ends in the next
- **THEN** both methods are reformatted and the rest of the class is unchanged

### Requirement: Bytes outside the expanded range are preserved

Everything outside the expanded range SHALL be byte-identical to the input, including whitespace, line endings, comments and formatting that does not follow the configuration.

#### Scenario: Unformatted neighbour untouched
- **WHEN** the statement after the range is badly formatted
- **THEN** it is unchanged in the output

### Requirement: Empty selection

An empty range (start equals end) SHALL format the smallest enclosing unit at that position. If the position is in whitespace between units, the document SHALL be returned unchanged.

#### Scenario: Cursor inside a statement
- **WHEN** `--range 4:7-4:7` points inside a statement
- **THEN** that statement is reformatted

#### Scenario: Cursor on a blank line
- **WHEN** the position is on a blank line between two members
- **THEN** stdout equals stdin

### Requirement: Range formatting still verifies the whole document

The whole document SHALL be parsed and the structural verification SHALL run on the whole output.

#### Scenario: Syntax error outside the range
- **WHEN** the document has a syntax error outside the selected range
- **THEN** stdout is empty and the exit code is 65

### Requirement: Protocol version

The stdin protocol (flags, coordinate semantics, output and exit-code rules) SHALL carry a protocol version reported by `beaver --version`, incremented only on a breaking change to this contract.

#### Scenario: Protocol unchanged across a formatting release
- **WHEN** a release changes formatting behaviour but not this contract
- **THEN** the protocol version is unchanged
