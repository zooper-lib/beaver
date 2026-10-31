# Spec Delta

## ADDED Requirements

### Requirement: Gap between a comment and the declaration it leads
For ordinary own-line comments leading a declaration, the gap between the final comment and the declaration's first annotation or code token SHALL follow `blank_lines.between_comment_and_declaration`. `preserve` (the preset) SHALL keep the source gap up to the applicable cap, inserting nothing; an integer SHALL set an exact count. Doc comments and line-sensitive directives SHALL take precedence.

#### Scenario: Section heading kept apart
- **WHEN** the preset applies and input is `// --- Lifecycle ---\n\n@override\nvoid initState() {}`
- **THEN** output is unchanged

#### Scenario: Gap removed by an explicit zero
- **WHEN** `between_comment_and_declaration: 0` and the same input
- **THEN** output is `// --- Lifecycle ---\n@override\nvoid initState() {}`

#### Scenario: No gap stays no gap
- **WHEN** the preset applies and a comment is directly followed by a declaration
- **THEN** no blank line is inserted

#### Scenario: Only the last comment of a group
- **WHEN** `between_comment_and_declaration: 1` and two adjacent own-line comments lead a declaration
- **THEN** one blank line separates the second comment from the declaration and the two comments stay adjacent

#### Scenario: Annotations stay with the declaration
- **WHEN** `between_comment_and_declaration: 1` and a comment leads `@override\nvoid f() {}`
- **THEN** the blank line is before `@override` and none is between `@override` and `void f() {}`

#### Scenario: Directive keeps its target
- **WHEN** `between_comment_and_declaration: 1` and `// ignore: unused_field` leads a field declaration
- **THEN** no blank line is inserted between the directive and the field

#### Scenario: Doc comment unaffected
- **WHEN** `between_comment_and_declaration: preserve` and `/// Doc.` is followed by a blank line and a declaration
- **THEN** the documentation-comment rule applies and the blank line is removed

## MODIFIED Requirements

### Requirement: Blank lines around own-line comments
Blank lines between an own-line comment and the code before it SHALL be preserved up to `blank_lines.max_consecutive`. A comment leading a statement or list item SHALL be followed directly by the node it leads; a comment leading a declaration SHALL follow `blank_lines.between_comment_and_declaration`.

#### Scenario: Separated comment block
- **WHEN** input has a statement, one blank line, a comment, and another statement
- **THEN** output keeps the blank line before the comment and none after it
