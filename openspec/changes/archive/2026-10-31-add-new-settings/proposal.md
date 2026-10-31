# Proposal

## Why

Beaver offers the four wrap policies but keeps break preservation and trailing-comma chopping global, special-cases the item threshold for chains (`min_calls`), and has no knob at all for cascades, switch expressions, initializer lists, annotations, block-argument hugging, close-bracket placement, operator break side beyond binary operators, and several spacing and blank-line positions that Rider, IntelliJ, ReSharper and clang-format users expect. Teams also have to assemble the configuration surface from the rule pages. This change adds the next round of `.beaver.yaml` keys in one coherent shape, so every wrappable list is configured the same way and every key is discoverable from one generated file.

## What Changes

- **Canonical per-construct maps.** Every wrappable list gets the same long-form fields: `policy`, `chop_from`, `keep_existing_line_breaks`, `chop_on_trailing_comma`, `align`, and where applicable `indent`, `close_bracket` and `trailing_commas`. The scalar `wrap.<list>: <policy>` stays valid as an alias of `wrap.<list>.policy`. `indent.align.arguments|parameters|chained_calls`, `wrap.chained_calls.min_calls` and `wrap.before_operator` become aliases of their canonical keys.
- **`inherit` value.** Per-construct `keep_existing_line_breaks`, `chop_on_trailing_comma`, `close_bracket`, `trailing_commas` and `indent`, plus `braces.catch_on_new_line|finally_on_new_line|while_on_new_line`, `blank_lines.max_consecutive_in_code` and `blank_lines.around_class_declarations`, accept `inherit`, resolved after the whole `extends` chain merges. The formatter only receives concrete values.
- **Configuration foundation.** Each layer is normalised to canonical keys and validated on its own before merging, and the golden harness's file and case options go through the same step. Conflicting spellings of one key in one layer are a configuration error. Diagnostics use the user's spelling. `config --print` shows both sources for an inherited value. The trailing-comma oscillation check runs per construct on the effective values.
- **`chop_from: N`** on every list: it forces one item per line at N or more syntactic items. `policy: never` suppresses it.
- **New wrap keys:** `wrap.cascades`, `wrap.initializer_lists` (with `colon: auto | new_line | end_of_header`), `wrap.switch_expressions`, `wrap.annotations`, `wrap.arguments.hug_block_argument`, `wrap.braceless_bodies`, `wrap.simple_case_bodies_on_one_line`, `wrap.simple_methods_on_one_line`, `wrap.control_conditions`, `wrap.class_header` (with `clauses_on_new_line`), `wrap.close_bracket` (global and per list), `wrap.break_before.{binary_operator, conditional_operator, arrow, assignment}`, `wrap.chained_calls.keep_first_call_on_receiver_line`, `wrap.binary_expressions` (with `align`), `wrap.chop_on_calls`.
- **New spacing keys:** `spaces.before_trailing_comment`, `spaces.before_colon_in_named_argument`, `spaces.before_colon_in_map_entry`, `spaces.after_colon_in_map_entry`, `spaces.before_colon_in_initializer_list`, `spaces.before_colon_in_switch_case`.
- **New blank-line keys:** `blank_lines.at_block_edges`, `blank_lines.after_last_member`, `blank_lines.keep_between_non_block_members`, `blank_lines.keep_between_non_block_top_level_declarations`, `blank_lines.between_top_level_declarations`, `blank_lines.between_import_groups`, `blank_lines.between_comment_and_declaration`, `blank_lines.max_consecutive_in_code`. The schema gains an integer-or-`preserve` value type.
- **New brace, string and file keys:** `braces.catch_on_new_line`, `braces.finally_on_new_line`, `braces.while_on_new_line`, `strings.quotes_avoid_escapes`, `line_ending: auto | lf | crlf`, and `include` (a list of globs, default `['**']`).
- **`trailing_commas: add_when_chopped`** as a fourth global value, with a per-construct `trailing_commas` field on `arguments`, `parameters`, `collection_literals` and `enum_values`.
- **EditorConfig integration:** `editorconfig: false | true`, off by default. When enabled, `indent_style`, `indent_size` and `end_of_line` from a full EditorConfig resolution supply values above the preset and below any explicit Beaver setting. While it is enabled, `config --print` requires `--for` and stdin formatting requires `--stdin-name`.
- **Reference template:** `beaver config --template` prints every key with its preset value and its alternatives. The output is generated from the schema, a test keeps `docs/beaver.template.yaml` in sync, and the README and install guide point to it.
- **BREAKING (formatted output):** two deliberate preset changes. `blank_lines.between_comment_and_declaration` defaults to `preserve`, so a blank line between an ordinary comment and the declaration below it now survives. `wrap.cascades.keep_existing_line_breaks: inherit` resolves to `true`, so a developer's break inside a one-section cascade now stays. Every other new key defaults to today's output.

Out of scope, as the settings proposal itself decides: the `cleanup:` transformations and the `beaver cleanup` command (deferred), the parked keys (including Allman braces), and the rejected ideas (member ordering, comment reflow, string rewrites, column alignment). `beaver format` keeps its token, structure and comment preservation guarantees unchanged.

## Capabilities

### New Capabilities

- `editorconfig-integration`: opt-in EditorConfig resolution covering section matching, the ancestor walk to `root = true`, and `unset`. It maps the supported properties into Beaver values, defines where they sit in the precedence order and how provenance records them, and requires a file name when integration is enabled.

### Modified Capabilities

- `config-resolution`: canonical long-form schema with aliases, per-layer normalisation and validation before merge, same-layer conflict errors, `inherit` resolved after the merge, provenance with two sources, the per-construct trailing-comma oscillation check, the int-or-`preserve` value type, the `include` list, every new key and its preset value, and the generated reference template.
- `formatting-rules`: policy and threshold semantics (`chop_from`, `never` precedence), the per-construct break-preservation and comma flags, and every new wrap, spacing, blank-line, brace and string rule listed above, including `add_when_chopped`.
- `comment-attachment`: replaces "the comment is followed directly by the node it leads" for declarations with `blank_lines.between_comment_and_declaration`. Doc comments and line-sensitive directives keep precedence.
- `layout-printer`: line endings follow `line_ending` (and EditorConfig when enabled), with `auto` keeping the current detection. Indentation style and size can come from EditorConfig.
- `cli`: the `config --template` subcommand, and `config --print` requiring `--for` when EditorConfig integration is enabled.
- `stdin-protocol`: `--stdin-name` becomes required when EditorConfig integration is enabled.
- `golden-test-harness`: file-level and case-level options are each normalised to canonical keys before they are merged, so shorthand and long form behave identically in cases.

## Impact

- **Prerequisite:** `openspec/specs/` is still empty because `initial-implementation` has not been archived. It must be archived before this change's delta specs can be validated or archived against it.
- **Code:** `packages/zooper_beaver/lib/src/config` (schema, `validateValues` becomes `normalizeAndValidateValues`, `resolve.dart`, provenance, preset, template generator, EditorConfig resolver), `lib/src/rules` (`expressions.dart`, `chains.dart`, `declarations.dart` and the other rule files), `lib/src/comments`, `lib/src/emit` (line endings), `lib/src/cli` (`config --template`, flag validation), the golden runner's option handling.
- **Docs:** `docs/rules/*.md` (canonical names, aliases listed once, every new key with before/after examples), new `docs/beaver.template.yaml`, `README.md`, `docs/install.md`, `docs/cli.md`, `docs/stdin-protocol.md`.
- **Examples and tests:** new `example/<key>` folders for each new key, renamed folders for the aliased keys, new golden cases. Goldens affected by the two preset changes (`self_format` among them) are updated with reviewed diffs and a verified stable second pass.
- **Users:** existing configurations stay valid without edits. Formatting output changes only in the two places marked BREAKING above.
- **Dependencies:** none expected. EditorConfig glob matching may reuse `package:glob` if its semantics fit; otherwise it needs a small matcher.
