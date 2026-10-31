# vscode-extension Specification

## Purpose

Defines the behaviour of the Beaver VS Code extension: formatting Dart documents and selections through the `beaver` CLI, locating and validating the binary, and reporting what it is using.

## Requirements

### Requirement: Document and selection formatting
The extension SHALL register as a document formatter and a range formatter for the `dart` language. Document formatting SHALL run `beaver --stdin --stdin-name <path>` with the buffer content; selection formatting SHALL add `--range` converted from the editor's 0-based positions to the protocol's 1-based coordinates.

#### Scenario: Format Document
- **WHEN** the user runs Format Document on an open Dart file
- **THEN** the buffer is replaced with the CLI's stdout

#### Scenario: Format Selection
- **WHEN** the user runs Format Selection
- **THEN** the CLI is invoked with the selection as `--range` and only the expanded region changes

### Requirement: The buffer is authoritative
The extension SHALL send the current buffer content, including unsaved changes, and SHALL never ask the CLI to read the file from disk.

#### Scenario: Unsaved edits
- **WHEN** the buffer has unsaved edits
- **THEN** the formatted result reflects those edits

### Requirement: Format on save
When the user enables `editor.formatOnSave` with Beaver as the `[dart]` default formatter, saving SHALL format the document through the same path as Format Document.

#### Scenario: Save
- **WHEN** a Dart file is saved with format-on-save enabled and Beaver selected
- **THEN** the saved content is the formatted output

### Requirement: Local edits
The extension SHALL compute the common prefix and suffix between the buffer and the output and return a single edit covering only the differing span.

#### Scenario: Change near the end
- **WHEN** only the last statement changes
- **THEN** the returned edit does not start at the top of the document

### Requirement: Failures never modify the buffer
When the CLI exits non-zero, crashes, or is cancelled, the extension SHALL return no edits and SHALL surface the stderr diagnostic. An excluded file (exit 0 with unchanged output) SHALL produce no edits and no error.

#### Scenario: Syntax error
- **WHEN** the CLI exits 65
- **THEN** the buffer is unchanged and the diagnostic is shown

#### Scenario: Excluded file on save
- **WHEN** a `.g.dart` file is saved
- **THEN** no error is shown and the buffer is unchanged

### Requirement: Stale results are discarded
If the document changes while a format request is in flight, the extension SHALL discard that request's result.

#### Scenario: Typing during format
- **WHEN** the user edits the buffer before the CLI returns
- **THEN** the late result is not applied

### Requirement: Binary resolution order
The extension SHALL locate the binary in this order: the explicit path setting, `beaver` on PATH, the bundled binary. Each candidate SHALL be validated by running `--version` and checking the protocol version. An explicit setting or PATH binary that is missing or incompatible SHALL be an error with guidance, not a fallback to the next candidate.

#### Scenario: PATH preferred over bundled
- **WHEN** a compatible `beaver` is on PATH and the extension bundles a newer one
- **THEN** the PATH binary is used

#### Scenario: Incompatible explicit path
- **WHEN** the setting points to a binary with an unsupported protocol version
- **THEN** formatting fails with a message naming the path and versions, and no other binary is used

### Requirement: Platform-specific packaging
The extension SHALL be published as one VSIX per supported platform, each bundling exactly the binary for that platform, and SHALL run as a workspace extension so the binary executes where the files live in remote sessions.

#### Scenario: Remote container
- **WHEN** VS Code on macOS is connected to a Linux container
- **THEN** the Linux VSIX is installed on the remote host and its binary is used

### Requirement: Formatter information command
The extension SHALL provide a command that shows the formatter version, protocol version, binary source (setting, PATH or bundled), binary path, platform, and the resolved configuration file for the active document.

#### Scenario: Show information
- **WHEN** the user runs the information command
- **THEN** all listed fields are displayed

### Requirement: Coexistence with the Dart extension
The extension SHALL only provide formatting. Analysis, completion, navigation and debugging from the official Dart extension SHALL remain available.

#### Scenario: Both installed
- **WHEN** both extensions are installed and Beaver is the default formatter
- **THEN** code completion and diagnostics still come from the Dart extension
