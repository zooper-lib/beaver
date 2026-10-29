# Spec Delta

## Purpose

Defines the document tree that formatting rules emit and the layout algorithm that turns it into text within a line width, so that every rule has exactly one describable effect on output.

## ADDED Requirements

### Requirement: Document instruction set
The layout engine SHALL accept a document tree built from exactly these instructions: `Text`, `Line` (soft, hard, literal), `Group` (with optional forced break and optional id), `Indent`, `Align` (by count or by string), `IfBreak` (with optional group id), `Fill`, `BreakParent`, `LineSuffix`, and `Concat`. No other layout primitive SHALL exist; `conditionalGroup` is deliberately absent.

#### Scenario: Rules compose only from the instruction set
- **WHEN** any formatting rule produces output
- **THEN** that output is a tree of the listed instructions and nothing else

### Requirement: Greedy left-to-right fitting
The printer SHALL process the document left to right. On reaching a `Group` it SHALL measure the group's flat width against the remaining width on the current line; if it fits, the group prints flat, otherwise the group breaks and the printer continues into its children with the same rule.

#### Scenario: Outer group breaks, inner fits
- **WHEN** `print(fetchUser(userId, includeAvatar: true), fallback);` exceeds the width but `fetchUser(userId, includeAvatar: true)` fits on its own line
- **THEN** the outer argument list breaks and the inner call stays on one line

#### Scenario: Everything fits
- **WHEN** a statement's flat width is within the line width
- **THEN** it prints on one line

### Requirement: Group break semantics
When a `Group` breaks, every soft `Line` that is a direct child of that group (not inside a nested group) SHALL become a newline; soft lines inside nested groups are decided by their own group.

#### Scenario: Direct lines break together
- **WHEN** a broken group contains three items separated by soft lines
- **THEN** all three items start on their own line

### Requirement: Hard lines force enclosing groups to break
A hard `Line` or a `BreakParent` anywhere inside a group SHALL cause that group and every enclosing group to print in broken mode.

#### Scenario: Preserved newline inside an argument list
- **WHEN** an argument list contains a hard line between two arguments
- **THEN** the argument list group prints broken

### Requirement: Fill lays out as many items per line as fit
`Fill` SHALL place its items on the current line while they fit and start a new line only where the next item would overflow, honouring any hard line among its separators.

#### Scenario: Paragraph-style wrapping
- **WHEN** a binary expression with eight operands is wrapped with `Fill` at a width that fits three operands per line
- **THEN** the output has three lines of operands, not eight

### Requirement: IfBreak resolves against a group's printed mode
`IfBreak(whenBroken, whenFlat)` SHALL print `whenBroken` if the nearest enclosing group is broken and `whenFlat` otherwise. With a group id, it SHALL resolve against that group's printed mode even when that group is not an ancestor.

#### Scenario: Trailing comma only when broken
- **WHEN** an argument list group breaks and its last item is followed by `IfBreak(",", "")`
- **THEN** the comma is printed; when the same group fits flat, no comma is printed

#### Scenario: Reference to a sibling group
- **WHEN** a chain's continuation is `IfBreak(indent, align, groupId: anchor)` and the anchor group printed flat
- **THEN** the align branch is used

### Requirement: Line suffix defers content to end of line
`LineSuffix` content SHALL be emitted immediately before the next newline on the current line, after any text printed in between.

#### Scenario: Trailing comment stays on its line
- **WHEN** `a, // about a` is followed by a soft line and more arguments
- **THEN** the comment appears at the end of the line containing `a,` and the following argument starts on the next line

### Requirement: Indentation and alignment are relative to the enclosing level
`Indent` SHALL add one configured indentation unit to the current level for the lines it contains; `Align` SHALL add the given number of spaces (or the given string) to the current level. Both nest additively.

#### Scenario: Nested indentation
- **WHEN** a statement nested two blocks deep breaks an argument list with `indent.size` 2
- **THEN** its wrapped arguments start at column 6 (two block levels plus one indent unit)

### Requirement: Flat width measurement treats hard lines as not fitting
When measuring whether a group fits flat, a hard `Line` inside it SHALL make the group not fit.

#### Scenario: Group with preserved break never prints flat
- **WHEN** a group of width 10 contains a hard line
- **THEN** it prints broken even at width 100

### Requirement: Indentation style
The printer SHALL emit indentation as spaces of `indent.size` per level when `indent.style` is `spaces`, and one tab per level when `indent.style` is `tabs`. Alignment padding SHALL always be spaces.

#### Scenario: Tabs with alignment
- **WHEN** `indent.style: tabs` and an aligned continuation is printed one level deep
- **THEN** the line starts with one tab followed by alignment spaces

### Requirement: Line endings
The printer SHALL emit the line ending that dominates the input (`\r\n` if the input uses it, else `\n`), and SHALL end the output with exactly one line ending.

#### Scenario: CRLF input
- **WHEN** the input uses `\r\n` endings
- **THEN** every output line ends with `\r\n`
