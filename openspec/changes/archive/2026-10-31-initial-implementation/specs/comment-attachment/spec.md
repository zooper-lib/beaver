# Spec Delta

## Purpose

Defines how comments in the source are associated with syntax and where they appear in formatted output, so that no comment is lost, moved to a different construct, or merged into code.

## ADDED Requirements

### Requirement: Every comment is placed exactly once
Every comment in the input SHALL appear exactly once in the output with its text unchanged, in the same order relative to other comments.

#### Scenario: Comment count preserved
- **WHEN** a file with N comments is formatted
- **THEN** the output contains the same N comment texts in the same order

### Requirement: Three-way classification by position
Each comment SHALL be classified by its position relative to code on its line: own-line (newline before and after), end-of-line (code before, newline after), or remaining (code on both sides). Each comment SHALL be given the smallest enclosing node, the last node ending before it, and the first node starting after it, and attached as leading, trailing or dangling accordingly.

#### Scenario: Own-line comment leads the next node
- **WHEN** input is `foo();\n// about bar\nbar();`
- **THEN** the comment is printed on its own line immediately before `bar();`

#### Scenario: End-of-line comment trails the preceding node
- **WHEN** input is `foo(a, // about a\n    b);` and the argument list breaks
- **THEN** `// about a` is printed at the end of the line containing `a,` and `b` starts the next line

#### Scenario: Remaining comment leads the following node
- **WHEN** input is `foo(/* x */ a)`
- **THEN** output is `foo(/* x */ a)`

### Requirement: Dangling comments stay inside their construct
A comment with no preceding or following node inside its enclosing construct SHALL be printed inside that construct, indented one level, and the construct SHALL be printed in broken form.

#### Scenario: Comment in an empty body
- **WHEN** input is `void init() {\n  // nothing yet\n}`
- **THEN** output keeps the comment on its own line inside the braces

#### Scenario: Comment in an empty argument list
- **WHEN** input is `foo(/* none */)`
- **THEN** output is `foo(/* none */)`

### Requirement: End-of-line comments never swallow code
An end-of-line `//` comment SHALL always be followed by a newline before any further code token, regardless of how the surrounding construct wraps.

#### Scenario: Comment before a closing bracket
- **WHEN** input is `foo(a, b // last\n);`
- **THEN** `);` is on the line after the comment

### Requirement: Documentation comments stay with their declaration
A `///` or `/** */` comment immediately preceding a declaration SHALL be printed immediately before that same declaration, with no blank line between them.

#### Scenario: Doc comment on a class
- **WHEN** input is `/// Doc for A.\nclass A {}\n\nclass B {}`
- **THEN** the doc comment precedes `class A`, not `class B`, with no blank line in between

### Requirement: Blank lines around own-line comments
Blank lines between an own-line comment and the code before it SHALL be preserved up to `blank_lines.max_consecutive`; the comment SHALL be followed directly by the node it leads.

#### Scenario: Separated comment block
- **WHEN** input has a statement, one blank line, a comment, and another statement
- **THEN** output keeps the blank line before the comment and none after it

### Requirement: Comments inside wrappable constructs force a break
A comment positioned between items of a wrappable construct SHALL cause that construct to print in broken form so the comment can occupy its own line or line end.

#### Scenario: Own-line comment between arguments
- **WHEN** input is `foo(a,\n    // about b\n    b);`
- **THEN** the argument list is broken and `// about b` is on its own line before `b`

### Requirement: Block comments inline
A `/* */` comment with code on both sides SHALL remain inline with a single space on each side.

#### Scenario: Inline block comment
- **WHEN** input is `a /* note */+ b`
- **THEN** output is `a /* note */ + b`
