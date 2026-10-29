# Spec Delta

## Purpose

Defines how Beaver is packaged, versioned and installed: the pub package, the standalone binaries, the release artifacts that editor plugins depend on, and the version information they check.

## ADDED Requirements

### Requirement: Package and executable names
The pub package SHALL be `zooper_beaver` and SHALL declare the executable `beaver`. All user-facing names (binary, `.beaver.yaml`, directives, extension identifiers) SHALL use `beaver`.

#### Scenario: Install from pub
- **WHEN** `dart install zooper_beaver@<version>` runs
- **THEN** a `beaver` command is available on PATH

### Requirement: Standalone binaries for five targets
Each release SHALL publish self-contained executables that require no Dart SDK for Windows x64, Linux x64, Linux arm64, macOS x64 and macOS arm64, all built from the same tagged source revision.

#### Scenario: Run without SDK
- **WHEN** a released binary runs on a machine with no Dart SDK
- **THEN** it formats files

### Requirement: Release artifacts
Each release SHALL publish the five binaries, a `checksums.txt` with SHA-256 for each, and a machine-readable manifest mapping platform to file name and hash that the IntelliJ plugin embeds at build time.

#### Scenario: Manifest contents
- **WHEN** the manifest is read
- **THEN** it contains the formatter version and, for each of the five platforms, the file name and SHA-256

### Requirement: Version and protocol reporting
`beaver --version` SHALL report the formatter version and the CLI protocol version. The protocol version SHALL change only when the stdin/CLI contract changes incompatibly.

#### Scenario: Plugin compatibility check
- **WHEN** a plugin runs `beaver --version` on a candidate binary
- **THEN** it can read both numbers and decide compatibility

### Requirement: Independent plugin versioning
The VS Code extension and the IntelliJ plugin SHALL have version numbers independent of the formatter's. Each plugin release SHALL declare the formatter version it bundles or downloads and the protocol version it supports.

#### Scenario: Formatter patch without plugin change
- **WHEN** formatter 1.2.1 is released
- **THEN** existing plugins continue to work with it if the protocol version is unchanged

### Requirement: Analyzer dependency range
The package SHALL depend on `package:analyzer` with a one-major range and its SDK constraint SHALL equal the range's lower bound requirement. The test suite SHALL pass with the analyzer resolved at the lower bound and at the latest version in range.

#### Scenario: Older SDK installs
- **WHEN** a user's SDK satisfies the lower bound but not the latest analyzer's constraint
- **THEN** `dart install zooper_beaver` succeeds

### Requirement: No version pinning in configuration
`.beaver.yaml` SHALL have no key that pins a formatter version. Teams pin by the binary they install.

#### Scenario: Version key rejected
- **WHEN** a configuration contains `version: 1.2.0`
- **THEN** it is rejected as an unknown key

### Requirement: Platform signing where required
macOS binaries SHALL be signed and notarized and Windows binaries signed where the platform would otherwise block or warn on execution.

#### Scenario: macOS execution
- **WHEN** a user runs the downloaded macOS binary
- **THEN** it runs without a Gatekeeper block

### Requirement: Reference corpus provenance
The imported dart_style test corpus SHALL ship with upstream's license and a record of the upstream release it was copied from, and SHALL be refreshed only by copying a newer upstream release as a deliberate change.

#### Scenario: Corpus update
- **WHEN** the corpus is updated
- **THEN** `UPSTREAM.md` records the new release and the compatibility score is re-baselined in the same change
