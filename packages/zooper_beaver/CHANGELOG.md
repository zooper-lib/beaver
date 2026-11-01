## 0.3.0

Settings cleanup: each layout question has one key, and every term is defined with real output in `docs/rules/wrap.md`. Output under the `dart` preset is unchanged.

### Breaking (configuration)

These spellings now fail with exit code 78 and a message naming the replacement:

- `policy: chop_always` on any list: write `policy: chop_if_long` with `chop_from: 1`. On a chain, `chop_always` with `keep_single_line_if_fits: false` is `chop_from: 2`.
- `wrap.chained_calls.keep_single_line_if_fits`: use `chop_from`. A chain below the threshold that fits already stays on one line under `fill` and `chop_if_long`.
- `chop_on_trailing_comma` on `binary_expressions`, `conditional_expressions`, `chained_calls`, `cascades`, `initializer_lists`, `switch_expressions` and `class_header`, which never read it. It stays on `arguments`, `parameters`, `collection_literals`, `enum_values` and as the global `wrap.chop_on_trailing_comma`.

### Breaking (formatted output)

- `align: true` (and `indent.align.*: true`) is now an alias of `indent: first_item`, which only aligns; it no longer moves the brackets. A configuration that relied on it to keep the first item on the `(` line and the `)` after the last item needs `break_after_open_bracket: false` and `break_before_close_bracket: false` on that list to keep its look. On a chain, alignment applies only when the first call stays on the receiver line, so add `keep_first_call_on_receiver_line` (for example `true`).
- `align: false` is accepted and dropped. On `wrap.initializer_lists`, whose preset is `first_item`, write `indent: inherit` to turn alignment off.
- With both `break_after_open_bracket: false` and `break_before_close_bracket: false` (the layout `align: true` used to produce), a source trailing comma is dropped and no longer chops the list, since nothing would keep the chop on the next run. `align: true` used to keep that comma.

### Renamed (old spellings stay valid as aliases)

- Policy value `if_long` is `fill`.
- `close_bracket: own_line | after_last_item` is `break_before_close_bracket: true | false`, on `wrap` and on the four bracketed lists.
- `align: true` is `indent: first_item`; `indent` takes `inherit | <integer> | first_item` (not `first_item` on `cascades`).

### Added

- `wrap.break_after_open_bracket` (preset `true`, plus `inherit` fields on the four bracketed lists): `false` keeps the first item on the bracket's line. A source break right after the opening bracket now follows this field instead of `keep_existing_line_breaks`.
- `wrap.chained_calls.keep_first_call_on_receiver_line` takes a list of receiver kinds: `type_names`, `identifiers`, `this`, `calls`, `properties`. `true` means every kind, `false` means `[]` (the preset).
- `wrap.switch_expressions` preset is `policy: chop_if_long` with `chop_from: 1` (the same output as before).
- A glossary at the top of `docs/rules/wrap.md`, and the sub-option rule: a sub-option whose parent is not in effect (`chop_from` under `never`, `indent_from` under `first_item`, `trailing_commas` under `break_before_close_bracket: false`) is ignored.

## 0.2.0

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
