# ignore-directives Specification

## Purpose

Defines the comment directives that exclude a node or a region of source from formatting while the rest of the file is still formatted correctly.

## Requirements

### Requirement: Recognised directives
Beaver SHALL recognise exactly these line comments as directives: `// beaver-ignore`, `// beaver-ignore-start`, `// beaver-ignore-end`, and the aliases `// dart format off` (equivalent to start) and `// dart format on` (equivalent to end). Matching SHALL be exact after trimming surrounding whitespace.

#### Scenario: Alias honoured
- **WHEN** a file uses `// dart format off` and `// dart format on`
- **THEN** the region between them is treated as an ignored region

#### Scenario: Near-miss is a normal comment
- **WHEN** a file contains `// beaver-ignore please`
- **THEN** it is treated as an ordinary comment and formatting is unaffected

### Requirement: Ignored regions are byte-identical
Every byte of source between a start directive and its matching end directive SHALL appear unchanged in the output, including whitespace, indentation and line endings.

#### Scenario: Hand-aligned matrix
- **WHEN** a list literal between start and end directives has hand-aligned columns
- **THEN** the output contains those bytes exactly

### Requirement: Region boundaries may cut through constructs
Start and end directives SHALL be honoured at any position in the file, including inside an argument list or collection, and the formatted code around the region SHALL still be laid out correctly.

#### Scenario: Region inside an argument list
- **WHEN** a start directive follows the first argument and the end directive follows the closing parenthesis
- **THEN** the first argument is formatted, the remaining bytes through the parenthesis are unchanged, and the statement parses identically

### Requirement: The whole file is still parsed
A file containing ignored regions SHALL be parsed in full; an unparseable file SHALL be rejected (exit 65) even if the error is inside an ignored region.

#### Scenario: Syntax error inside region
- **WHEN** an ignored region contains invalid Dart
- **THEN** the file is rejected with exit code 65

### Requirement: Single-node ignore
`// beaver-ignore` SHALL exclude from formatting the source range of the node it is a leading comment of, whatever kind of node that is.

#### Scenario: Ignore a statement
- **WHEN** `// beaver-ignore` precedes `final x   =   1;`
- **THEN** that statement's bytes are unchanged in the output and the next statement is formatted

#### Scenario: Ignore an expression
- **WHEN** `// beaver-ignore` precedes one element inside a list literal
- **THEN** that element's bytes are unchanged and the rest of the list is formatted

### Requirement: Unterminated start runs to end of file
A start directive without a matching end SHALL ignore everything from the directive to the end of the file.

#### Scenario: No end directive
- **WHEN** a file contains `// beaver-ignore-start` and no end directive
- **THEN** all source after the directive is unchanged

### Requirement: Overlapping or nested regions are an error
A start directive inside an open region, or an end directive with no open region, SHALL cause the file to be rejected with exit code 65 and a diagnostic naming the line of each offending directive.

#### Scenario: Nested start
- **WHEN** two start directives appear before any end directive
- **THEN** the file is rejected with exit code 65

#### Scenario: Stray end
- **WHEN** an end directive appears with no preceding start
- **THEN** the file is rejected with exit code 65

### Requirement: Directives are themselves preserved
Directive comments SHALL appear in the output at their original position relative to surrounding code, with their text unchanged.

#### Scenario: Directive text unchanged
- **WHEN** a file contains `// beaver-ignore-start`
- **THEN** the output contains that exact comment

### Requirement: Range formatting respects ignored regions
When a formatting range overlaps an ignored region, the ignored bytes SHALL remain unchanged.

#### Scenario: Range across a region
- **WHEN** a `--range` covers a statement containing an ignored region
- **THEN** the statement is formatted outside the region and the region's bytes are unchanged
