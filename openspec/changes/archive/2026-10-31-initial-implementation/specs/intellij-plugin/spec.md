# Spec Delta

## Purpose

Defines the behaviour of the Beaver plugin for IntelliJ IDEA and Android Studio: formatting through the `beaver` CLI via the platform's external-formatter service, obtaining a verified binary, and reporting what it is using.

## ADDED Requirements

### Requirement: Integration through the external formatter service
The plugin SHALL provide formatting for Dart files through the platform's documented external formatter service so that Reformat Code, Reformat Selection, reformat of a folder, and Reformat on Save all route to Beaver.

#### Scenario: Reformat Code
- **WHEN** the user invokes Reformat Code on a Dart file
- **THEN** the document content is replaced with the CLI's output

#### Scenario: Folder reformat
- **WHEN** the user reformats a directory
- **THEN** every Dart file in it is formatted through Beaver

#### Scenario: Reformat on save
- **WHEN** Reformat on Save is enabled and a Dart file is saved
- **THEN** the saved content is Beaver's output

### Requirement: The editor document is authoritative
The plugin SHALL pass the current document text to `beaver --stdin --stdin-name <path>` and SHALL never save the document and ask Beaver to read it from disk.

#### Scenario: Unsaved document
- **WHEN** the document has unsaved changes
- **THEN** the result reflects those changes

### Requirement: Selection formatting
Reformat Selection SHALL pass the selection as `--range` in protocol coordinates; only the expanded region SHALL change.

#### Scenario: Selected statements
- **WHEN** the user selects two statements and reformats
- **THEN** only those statements change

### Requirement: Asynchronous and non-blocking
Formatting SHALL run off the UI thread and SHALL be cancellable.

#### Scenario: Large file
- **WHEN** a large file is formatted
- **THEN** the UI stays responsive

### Requirement: Failures never modify the document
On non-zero exit, crash, or cancellation the document SHALL remain unchanged and the diagnostic SHALL be shown. Excluded files SHALL produce no change and no error.

#### Scenario: Syntax error
- **WHEN** the CLI exits 65
- **THEN** the document is unchanged and the message is shown

### Requirement: Local edits
The plugin SHALL apply the output by replacing only the span between the common prefix and suffix of document and output.

#### Scenario: Small change
- **WHEN** one line changes
- **THEN** the caret position outside that line is preserved

### Requirement: Binary resolution order
The plugin SHALL locate the binary in this order: explicit path setting, `beaver` on PATH, a verified cached binary, a verified download. Each candidate SHALL be validated by `--version` and protocol version. An explicit or PATH binary that is missing or incompatible SHALL be an error with guidance, not a fallback.

#### Scenario: PATH binary used
- **WHEN** a compatible `beaver` is on PATH
- **THEN** no download occurs

### Requirement: Verified download
When no binary is available, the plugin SHALL download the binary for the current OS and architecture named in a manifest embedded in the plugin at build time, over HTTPS, and SHALL verify its SHA-256 against that embedded manifest before any execution. A mismatch SHALL be reported as a security failure and the file discarded.

#### Scenario: Checksum mismatch
- **WHEN** the downloaded file's hash differs from the embedded manifest
- **THEN** the file is deleted, nothing is executed, and an error is shown

#### Scenario: Unsupported platform
- **WHEN** the manifest has no entry for the current OS/architecture
- **THEN** an error lists the supported platforms and the path setting as the alternative

### Requirement: Cache
Downloaded binaries SHALL be stored in a user-writable cache keyed by formatter version and platform, installed atomically with executable permission, and reused offline. Partially downloaded files SHALL never be executed. Concurrent download attempts SHALL not corrupt the cache.

#### Scenario: Offline reuse
- **WHEN** the network is unavailable and a verified binary is cached
- **THEN** formatting works

#### Scenario: Interrupted download
- **WHEN** a download is interrupted
- **THEN** no partial file is left at the executable's final path

### Requirement: Declared formatter and protocol versions
Each plugin release SHALL declare the formatter version it downloads by default and the protocol version it supports, independently of its own version number.

#### Scenario: Plugin-only update
- **WHEN** the plugin is updated for IDE compatibility without a formatter change
- **THEN** the declared formatter version is unchanged

### Requirement: Formatter information action
The plugin SHALL provide an action showing formatter version, protocol version, binary source, path, platform and the resolved configuration file for the current document.

#### Scenario: Show information
- **WHEN** the user runs the action
- **THEN** all listed fields are displayed

### Requirement: Exclusion and configuration follow the CLI
The plugin SHALL apply no exclusion or configuration logic of its own; all such behaviour comes from the CLI via `--stdin-name`.

#### Scenario: Excluded file
- **WHEN** a `.g.dart` file is reformatted
- **THEN** it is unchanged and no error is shown
