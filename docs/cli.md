# Command line

```
beaver [options] <paths...>
beaver --stdin [--stdin-name <path>] [--range <range>]
beaver config --print [--for <file>]
beaver init
```

## Selecting files

Paths may be files, directories or globs. Directories are searched recursively for `.dart` files, without following symbolic links; `.dart_tool/` and `.git/` are never entered. A file named in several arguments is processed once, and files are processed in sorted path order. A file named explicitly is formatted whatever its extension.

Exclusions from `.beaver.yaml` (`exclude:`, which by default covers generated code such as `**/*.g.dart`) apply to every file, also one named explicitly. Skipped files are silent; `--verbose` lists each one with the pattern that excluded it, on stderr.

## Modes

| Invocation | Effect |
|---|---|
| `beaver <paths>` | Rewrite files whose formatting differs. Unchanged files are not written (their timestamp does not change). |
| `beaver --check <paths>` | Change nothing; print every file that would change; exit 1 if there is one. |
| `beaver --diff <paths>` | Change nothing; print a unified diff for every file that would change; exit 1 if there is one. |
| `beaver --stdin` | Format the document on stdin and write it to stdout. See [the stdin protocol](stdin-protocol.md). |
| `beaver config --print [--for <file>]` | Print the resolved configuration and, for each key, the file or preset that set it. |
| `beaver init` | Write a starter `.beaver.yaml` in the current directory; never overwrites one. |
| `beaver --version` | Print `beaver <version> (protocol <n>)`. |

`--config <file>` uses that configuration for every file instead of discovering `.beaver.yaml`.

Every formatted file is verified to be the same program as before (same tokens apart from optional trailing commas and quote style, same syntax tree, same comments in the same places) before anything is written. There is no option to turn this off.

## Output and errors

Stdout carries only formatted content, diffs, file lists or configuration; all diagnostics go to stderr. A problem with one file (it does not parse, cannot be read, or its configuration is invalid) is reported and the other files are still processed; an error shared by many files, such as a broken `.beaver.yaml`, is reported once.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success, or nothing to change. |
| 1 | `--check` or `--diff` found files that would change. |
| 64 | Usage error: unknown flag, invalid combination, malformed `--range`, `init` over an existing file. Nothing is processed. |
| 65 | Input could not be parsed, or contains invalid ignore directives. |
| 66 | Input file not found or unreadable. |
| 70 | Internal error: formatted output failed verification. The file is left unchanged. |
| 78 | Invalid configuration. |

When several apply across files, the most severe wins, in the order 70, 78, 64, 65, 66, 1, 0. So a `--check` run that finds unformatted files and one unparseable file exits 65.

## Git pre-commit hook

Save as `.git/hooks/pre-commit` and make it executable. It refuses the commit when a staged Dart file is not formatted. File names are passed NUL-separated, so spaces and other unusual characters are safe, and exclusions apply because they apply to explicitly named files too.

```sh
#!/bin/sh
# Refuse the commit if a staged Dart file is not formatted.
[ -z "$(git diff --cached --name-only --diff-filter=ACMR -- '*.dart')" ] && exit 0
git diff --cached --name-only -z --diff-filter=ACMR -- '*.dart' | xargs -0 beaver --check
```

Staging caveat: Beaver checks the files in your working tree, not the staged snapshot. If you stage only part of a file, the check sees the unstaged lines too. Stage whole files, or run the check on the staged content alone with `git stash push --keep-index` before and `git stash pop` after.
