# Spec Delta

## Purpose

Defines the `beaver` command line: how files are selected and excluded, what each mode does, how errors are reported across many files, and the exit codes scripts and CI can rely on.

## ADDED Requirements

### Requirement: Command surface
The `beaver` executable SHALL support: `beaver [options] <paths...>` (format in place), `--check`, `--diff`, `--stdin [--stdin-name <path>] [--range <range>]`, `--config <file>`, `--verbose`, `--version`, `beaver config --print [--for <file>]`, and `beaver init`. Options and subcommands SHALL be documented in `--help`.

#### Scenario: Help lists every mode
- **WHEN** `beaver --help` runs
- **THEN** the output names every option and subcommand above

### Requirement: Path arguments
Each path argument SHALL be a file, a directory, or a glob. Directories SHALL be searched recursively for `.dart` files without following symbolic links. Files reached through several arguments SHALL be processed once. Processing order SHALL be deterministic (normalized path order).

#### Scenario: Directory and file overlap
- **WHEN** `beaver lib lib/a.dart` runs
- **THEN** `lib/a.dart` is formatted once

#### Scenario: Symlinked directory
- **WHEN** `lib/linked` is a symlink to another directory
- **THEN** files under it are not formatted by `beaver lib`

### Requirement: Exclusions apply to every selection method
A file matching an exclusion pattern SHALL be skipped whether it was named explicitly, found by directory search, or matched by a glob. Skipped files SHALL not be parsed and SHALL not affect the exit code. Skips SHALL be silent unless `--verbose` is given, in which case each skipped file and the matching pattern SHALL be listed on stderr.

#### Scenario: Explicitly named generated file
- **WHEN** `beaver lib/models/user.g.dart` runs with the default exclusions
- **THEN** the file is unchanged and the exit code is 0

#### Scenario: Verbose skip report
- **WHEN** `beaver --verbose lib` runs and `lib/a.g.dart` is excluded
- **THEN** stderr lists `lib/a.g.dart` with the pattern `**/*.g.dart`

### Requirement: Format in place
Without a mode flag, Beaver SHALL rewrite each selected file whose formatted content differs, after verification passes, and leave unchanged files untouched (no write, no modified timestamp change).

#### Scenario: Already formatted file
- **WHEN** a file is already formatted
- **THEN** it is not rewritten

### Requirement: Check mode
With `--check`, Beaver SHALL change nothing, print the path of every file whose formatted content would differ, and exit 1 if there is at least one such file, 0 otherwise. All files SHALL be reported in one run.

#### Scenario: Several files need formatting
- **WHEN** `beaver --check .` runs over a tree with three unformatted files
- **THEN** all three paths are printed and the exit code is 1

### Requirement: Diff mode
With `--diff`, Beaver SHALL change nothing and print a unified diff for every file whose formatted content differs. The exit code SHALL follow `--check` semantics.

#### Scenario: Diff output
- **WHEN** `beaver --diff lib/a.dart` runs and the file needs formatting
- **THEN** stdout contains a unified diff from the original to the formatted content

### Requirement: Per-file errors do not stop processing
A parse error, unreadable file, missing explicitly named file, or a broken `.beaver.yaml` discovered for some files SHALL be reported on stderr with the file path and processing SHALL continue with the remaining files. Each distinct error SHALL be reported once.

#### Scenario: One unparseable file among many
- **WHEN** `beaver .` runs and one file has a syntax error
- **THEN** every other file is formatted, stderr names the failing file, and the exit code is 65

#### Scenario: Broken config shared by many files
- **WHEN** a `.beaver.yaml` with an unknown key governs fifty files
- **THEN** the configuration error is reported once, those files are skipped, and other files proceed

### Requirement: Fatal errors stop before processing
Invalid flags, invalid flag combinations, and an invalid `--config` file SHALL stop Beaver before any file is processed.

#### Scenario: Unknown flag
- **WHEN** `beaver --frobnicate lib` runs
- **THEN** nothing is formatted and the exit code is 64

### Requirement: Exit codes
Beaver SHALL use these exit codes: 0 success or nothing to change; 1 `--check`/`--diff` found differences; 64 usage error; 65 input could not be parsed or contains invalid directives; 66 input file not found or unreadable; 70 internal error (verification failed); 78 invalid configuration. When several apply across files, the final code SHALL be the most severe in the order 70, 78, 64, 65, 66, 1, 0.

#### Scenario: Mixed outcomes
- **WHEN** a `--check` run finds unformatted files and one unparseable file
- **THEN** the exit code is 65

#### Scenario: Missing file
- **WHEN** `beaver nope.dart` runs
- **THEN** stderr reports the missing file and the exit code is 66

### Requirement: Diagnostics go to stderr
All diagnostics, warnings and progress output SHALL be written to stderr. Stdout SHALL carry only formatted content (`--stdin`), diffs (`--diff`), file lists (`--check`), or config output (`config --print`).

#### Scenario: Clean stdout in check mode
- **WHEN** `beaver --check .` reports an error and some unformatted files
- **THEN** stdout contains only file paths

### Requirement: Version reporting
`beaver --version` SHALL print the formatter version and the CLI protocol version in a stable, parseable form.

#### Scenario: Version output
- **WHEN** `beaver --version` runs
- **THEN** stdout contains the formatter version and the protocol version on one line

### Requirement: Non-Dart files are ignored
Only files with the `.dart` extension SHALL be formatted when discovered via directories or globs. An explicitly named non-`.dart` file SHALL be formatted as Dart source.

#### Scenario: Mixed directory
- **WHEN** `beaver lib` runs over a directory containing `.dart` and `.yaml` files
- **THEN** only the `.dart` files are considered
