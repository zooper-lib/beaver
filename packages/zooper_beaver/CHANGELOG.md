## Unreleased

### Breaking (formatted output)

Two preset defaults change, so a project formatted with 0.1.0 can change on the next run:

- `blank_lines.between_comment_and_declaration` is `preserve`: a blank line between an ordinary comment and the declaration below it now stays (0.1.0 removed it). Doc comments and `// ignore:` directives still stay next to their declaration. Set `blank_lines.between_comment_and_declaration: 0` for the old output.
- `wrap.cascades.keep_existing_line_breaks` is `inherit` (`true` under the preset): a break you typed before the section of a one-section cascade now stays (0.1.0 joined it when it fit). Set `wrap.cascades.keep_existing_line_breaks: false` for the old output.

Every other new key defaults to the 0.1.0 output. One more change applies only to configurations that set `braces.else_on_new_line: true`: the new `braces.while_on_new_line` follows it, so the `while` of a `do` loop moves to its own line; set `braces.while_on_new_line: false` for the old output.

### Added

- Every wrappable list is a map with `policy`, `chop_from`, `keep_existing_line_breaks` and `chop_on_trailing_comma`, plus `align`, `indent`, `close_bracket` and `trailing_commas` where they apply. `wrap.<list>: <policy>` stays valid as a shorthand, and `indent.align.*`, `wrap.chained_calls.min_calls` and `wrap.before_operator` stay valid as aliases.
- `inherit` links a per-list field to its global key; `config --print` shows where `inherit` was set and where the value came from.
- New lists: `wrap.cascades`, `wrap.initializer_lists`, `wrap.switch_expressions`, `wrap.class_header` and `wrap.enum_values`.
- New wrap keys: `wrap.arguments.hug_block_argument`, `wrap.chop_on_calls`, `wrap.close_bracket`, `wrap.break_before.*`, `wrap.chained_calls.keep_first_call_on_receiver_line`, `wrap.annotations`, `wrap.braceless_bodies`, `wrap.control_conditions`, `wrap.simple_case_bodies_on_one_line`, `wrap.simple_methods_on_one_line`, and `trailing_commas: add_when_chopped`.
- New spacing, blank-line, brace and string keys: `spaces.before_trailing_comment` and five colon keys; `blank_lines.at_block_edges`, `after_last_member`, `max_consecutive_in_code`, `between_top_level_declarations`, `between_import_groups`, `between_comment_and_declaration` and the two `keep_between_non_block_*` keys; `braces.catch_on_new_line`, `finally_on_new_line` and `while_on_new_line`; `strings.quotes_avoid_escapes`.
- `line_ending: auto | lf | crlf` and `include:` (globs, default `['**']`).
- `editorconfig: true` reads `indent_style`, `indent_size` and `end_of_line` from `.editorconfig`, below any explicit Beaver setting. While it is on, `config --print` needs `--for` and `--stdin` needs `--stdin-name`.
- `beaver config --template` prints every setting with its preset value and alternatives; the same text is in `docs/beaver.template.yaml`.

## 0.1.0

First release.

- `beaver` command: format files in place, `--check` and `--diff` for CI, `--stdin` for editors (with `--range` for selections), `config --print` and `init`.
- `.beaver.yaml` configuration with the built-in `dart` preset, `extends:` inheritance and `exclude:` patterns; generated files are skipped by default.
- Rules for wrapping (arguments, parameters, collections, binary and conditional expressions, method chains), trailing commas, indentation and alignment, spaces, blank lines, braces and string quotes.
- Line breaks you typed are kept; a trailing comma puts every item on its own line.
- `// beaver-ignore`, `// beaver-ignore-start` / `-end` and `// dart format off` / `on`.
- Every result is verified to be the same program before it is written.
- Prebuilt, unsigned binaries for Linux, macOS and Windows; extensions for VS Code and IntelliJ IDEA / Android Studio.
