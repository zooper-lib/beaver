# Tasks

Specs: `specs/*/spec.md`. Design: `design.md`. Every new key lands with its golden cases under `packages/zooper_beaver/test/golden/<area>/`, an `example/<key>/` folder, and an entry in the matching `docs/rules/*.md` page, whose examples `test/docs_test.dart` checks against the goldens. Unless a task says otherwise, "goldens unchanged" means `dart test` passes with no golden file edited.

## 1. Configuration foundation

- [x] 1.1 Add the value types `InheritOr`, `IntOrPreserveType` and `DottedNameListType`, plus `min` on `IntType`, to `config/schema.dart`, each with a `describe()` text; verify by unit tests in `config_schema_test.dart` covering accepted and rejected values for each type
- [x] 1.2 Add the list-construct table to `schema.dart` (arguments, parameters, collection_literals, enum_values, binary_expressions, conditional_expressions, chained_calls, cascades, initializer_lists, switch_expressions, class_header, with their optional fields and `indent` fallbacks) and generate the canonical list keys from it; move the existing keys to canonical names (`wrap.<list>.policy`, `wrap.<list>.align`, `wrap.chained_calls.chop_from`, `wrap.break_before.binary_operator`) in the schema and the `dart` preset YAML; verify a schema test that every schema key is defined by the preset and no key is both a leaf and a prefix
- [x] 1.3 Replace `validateValues` with `normalizeAndValidateValues` in `config/loader.dart`. It holds the single alias table, rewrites shorthand and legacy spellings, rejects conflicting spellings in one layer, accepts identical duplicates, and reports the user's spelling plus the canonical key; verify config tests for every config-resolution scenario under "Aliases map one-to-one", "Conflicting spellings in one layer" and "Unknown keys and invalid values"
- [x] 1.4 Switch the golden runner (`test/src/golden_runner.dart`) to normalise file options and case options separately, then fold them onto the preset; verify `golden_runner_test.dart` cases for "Shorthand case option keeps a file-level field" and "Conflicting spellings in one case"
- [x] 1.5 Implement post-merge `inherit` resolution in `config/resolve.dart` using a const fallback table (per-list flags, per-list `indent`, `enum_values.*` → `collection_literals.*`, `braces.*_on_new_line`, `max_consecutive_in_code`, `around_class_declarations`); verify config tests for the "`inherit` links a key to its fallback", "Inheriting list fields", "Enum values follow collection literals" and "Inheriting scalar keys" scenarios, and a unit test that every fallback chain terminates at a non-inheriting key
- [x] 1.6 Change provenance to `Map<String, Source>`, carrying the setting's origin and the fallback value's origin, and update `config --print` to show both; verify config tests for "Provenance for an inherited key" and "No inherit in the effective config", and that `cli_test.dart` `config --print` cases still pass
- [x] 1.7 Replace the global trailing-comma conflict check with the per-construct check on resolved values (records checked on globals, `never`/`chop_always` exempt, `after_last_item` counted as suppression once group 3 adds it); verify config tests for every scenario under "Incompatible trailing-comma settings"
- [x] 1.8 Introduce `ListSettings` in `config/config.dart` with one accessor per construct; remove `wrapArguments`, `alignArguments`, `alignParameters`, `alignChainedCalls`, `chainMinCalls` and `breakBeforeOperator`; change `delimited()` and the chain, binary and enum callers to take `ListSettings` and read the per-list `keep_existing_line_breaks`, `chop_on_trailing_comma` and `trailing_commas`; give records `ListSettings` with the global comma and break flags; verify `dart analyze` is clean and the goldens are unchanged
- [x] 1.9 Add golden cases for the per-construct flags (`keep_existing_line_breaks` per list using the corners example, `chop_on_trailing_comma` per list, a record under a conflicting argument override); verify they pass in `test/golden/wrap/`
- [x] 1.10 Rename the `example/` folders for the aliased keys (`indent.align.*` → `wrap.<list>.align`, `wrap.before_operator` → `wrap.break_before.binary_operator`, `wrap.chained_calls.min_calls` → `wrap.chained_calls.chop_from`). Rewrite `docs/rules/wrap.md` and `docs/rules/indent.md` with canonical names, the long and short forms, `inherit` and its fallbacks, and the aliases listed once; verify `example_test.dart` and `docs_test.dart` pass

## 2. Reference template

- [x] 2.1 Implement `config/template.dart` to generate the template from the schema, the construct table and the preset (canonical keys in documentation order, list maps in long form, preset values with `inherit` kept, `describe()` as trailing comment, integer minimums, list example entries, a shorthand note on map keys); verify unit tests that every schema key appears exactly once and that the output parsed as a `.beaver.yaml` resolves to the preset
- [x] 2.2 Add `beaver config --template` to the CLI (stdout, exit 0, ignores any `.beaver.yaml`) and list it in `--help`; verify the cli_test scenarios "Independent of the project" and "Help lists every mode"
- [x] 2.3 Commit `docs/beaver.template.yaml` and add a `docs_test.dart` check that fails when it differs from `config --template`; point `README.md`, `docs/install.md` and `docs/cli.md` at it; verify the docs test passes and fails after a deliberate one-line edit to the committed file

## 3. Wrapping keys

- [x] 3.1 Implement `chop_from` on every list in `delimited()` (feeding `forceChop`, suppressed by `never`, defeating fill, kept groups, hugging and `keep_single_line_if_fits`), with binary operand counting per flattened same-precedence run and chains reading `chop_from`; verify golden cases for every formatting-rules scenario under "Item threshold forces chopping", "Item counting for the threshold" and "Threshold interaction with each policy"
- [x] 3.2 Implement `wrap.cascades` (preset `chop_if_long`, `chop_from: 2`, `keep_existing_line_breaks: inherit` resolved to `false` for now, `indent: inherit`), replacing the hard-coded two-section rule and fixed indent in `chains.dart`; verify the "Cascade wrapping" scenarios except "Developer break kept" (done in 6.2), with the goldens otherwise unchanged
- [x] 3.3 Implement `wrap.initializer_lists` with `policy`, `chop_from`, `keep_existing_line_breaks`, `align`, `indent` and `colon: auto | new_line | end_of_header`; verify golden cases for both `align` values under both explicit colon positions plus the "Initializer list" scenarios, with goldens unchanged under the preset
- [x] 3.4 Implement `wrap.switch_expressions` (preset `chop_always`, commas preserved exactly) and `wrap.class_header` with `clauses_on_new_line`; verify the "Switch expression wrapping" and "Class header wrapping" scenarios
- [x] 3.5 Implement `wrap.arguments.hug_block_argument`, keeping the existing eligibility and precedence rules; verify the "Block-argument hugging" and "Block-argument eligibility and precedence" scenarios, including `if_long` filling when disabled
- [x] 3.6 Implement `wrap.chop_on_calls`, matching on the callable expression's dotted name (final or penultimate segment for one-segment entries, full suffix otherwise, no name for computed targets); verify the "Call-name-triggered expansion" and "Call name comes from the callable expression" scenarios
- [x] 3.7 Implement `wrap.close_bracket` (global, plus a per-list field with `inherit`) and `trailing_commas: add_when_chopped`, with the comma `IfBreak` emitted only in the chop layout; verify the "Closing delimiter placement", "Trailing comma when chopped" and "Per-construct trailing comma policy" scenarios and the config test "Suppression by close-bracket placement"
- [x] 3.8 Implement `wrap.break_before` (`binary_operator`, `conditional_operator`, `arrow`, `assignment`), `wrap.chained_calls.keep_first_call_on_receiver_line` and `wrap.binary_expressions.align`; verify the "Operator break side", "First chained call on the receiver line" and "Binary expression alignment" scenarios
- [x] 3.9 Implement `wrap.annotations`, `wrap.braceless_bodies`, `wrap.control_conditions`, `wrap.simple_case_bodies_on_one_line` and `wrap.simple_methods_on_one_line`; verify the matching formatting-rules scenarios
- [x] 3.10 Add the `example/` folders and `docs/rules/wrap.md` entries for every key in this group; verify `example_test.dart` and `docs_test.dart` pass

## 4. Spacing, braces and strings

- [x] 4.1 Implement `spaces.before_trailing_comment` and the five colon keys; verify the "Space before a trailing comment" and "Colon spacing positions" scenarios, with goldens unchanged under the preset
- [x] 4.2 Implement `braces.catch_on_new_line`, `finally_on_new_line` and `while_on_new_line` (handler clause moves as a whole, only the `do` loop's `while`); verify the "Brace placement is whitespace only" scenarios
- [x] 4.3 Implement `strings.quotes_avoid_escapes`; verify the "Quote conversion that would need escapes" scenarios and that the verifier accepts `'don\'t'` produced from `"don't"`
- [x] 4.4 Add the `example/` folders and entries in `docs/rules/spaces.md`, `braces.md` and `strings.md`; verify `example_test.dart` and `docs_test.dart` pass

## 5. Blank lines, file-level keys and comments

- [x] 5.1 Implement `blank_lines.at_block_edges`, `after_last_member` and `max_consecutive_in_code`; verify the "Blank lines at block edges", "Blank lines after the last member" and "Blank-line cap inside code" scenarios
- [x] 5.2 Implement `blank_lines.between_top_level_declarations`, `around_class_declarations: inherit`, `keep_between_non_block_members` and `keep_between_non_block_top_level_declarations` with the syntactic block-body test; verify the "Blank lines between top-level declarations" and "Non-block declarations keep their grouping" scenarios
- [x] 5.3 Implement `blank_lines.between_import_groups` without reordering directives; verify the "Blank lines between import groups" scenario
- [x] 5.4 Implement `blank_lines.between_comment_and_declaration` in the declaration sequence with a temporary preset of `0` (today's output), excluding doc comments and line-sensitive directives; verify the comment-attachment scenarios that use an explicit value ("Gap removed by an explicit zero", "Only the last comment of a group", "Annotations stay with the declaration", "Directive keeps its target", "Doc comment unaffected"), with goldens unchanged
- [x] 5.5 Implement `line_ending: auto | lf | crlf` in `format.dart`/`emit`; verify the layout-printer "Line endings" scenarios
- [x] 5.6 Implement `include` (replaces along the chain, same root and glob syntax as `exclude`, an unmatched file treated as excluded for every selection method and for stdin echo); verify the config scenarios "Only lib and test" and "Exclude still wins" plus a stdin test echoing a file outside `include`
- [x] 5.7 Add the `example/` folders and entries in `docs/rules/blank_lines.md`, plus a page or section for `line_ending` and `include`; verify `example_test.dart` and `docs_test.dart` pass

## 6. Deliberate preset changes

- [x] 6.1 Set `blank_lines.between_comment_and_declaration: preserve` in the preset in its own commit; review every golden diff it causes (`self_format` included) and accept only gaps preserved from the source; verify the "Section heading kept apart" and "No gap stays no gap" scenarios and that formatting each changed golden output again changes nothing
- [x] 6.2 Set `wrap.cascades.keep_existing_line_breaks: inherit` in the preset in its own commit, counting only cascade-level gaps; review the golden diffs; verify the "Developer break kept in a one-section cascade", "Normalisation restored" and "Multi-line collection receiver" scenarios and second-pass stability
- [x] 6.3 Record both changes as breaking in `packages/zooper_beaver/CHANGELOG.md`, naming the key that restores the old output, and update the "New keys keep today's output by default" note in the rule pages; verify the changelog entry and the config scenario "Unaffected project" (a golden project without these constructs formats identically to the 0.1.0 output)

## 7. EditorConfig integration

- [x] 7.1 Implement `config/editorconfig.dart`: INI parsing, the EditorConfig glob translator (`*`, `**`, `?`, `[...]`, `{a,b}`, `{n1..n2}`, slash-less patterns matching basenames at any depth), and the upward walk through `ReadFile` honouring `root = true`, section order and `unset`; verify unit tests ported from the EditorConfig core glob and precedence cases, plus the "Full EditorConfig resolution" scenarios
- [x] 7.2 Add the `editorconfig` key and insert EditorConfig values after the merge only where provenance is still the preset (mapping `indent_style`, `indent_size` with `tab`/`tab_width`, and `end_of_line` lf/crlf; reporting `cr`; ignoring every other property); verify the "Integration is opt-in", "Precedence", "Supported properties" and "Explicit `line_ending: auto` overrides EditorConfig" scenarios
- [x] 7.3 Record EditorConfig provenance (path, section, property, `tab_width`) in `config --print`; verify the "Derived indent size" scenario
- [x] 7.4 Require `--for` for `config --print` and `--stdin-name` for `--stdin` when the effective configuration enables integration (exit 64, empty stdout), and resolve against the file name also under `--config`; verify the cli and stdin-protocol scenarios and "Explicit config still resolves EditorConfig"
- [x] 7.5 Document `editorconfig` (precedence, supported properties, file-name requirement) in the rule docs, `docs/cli.md` and `docs/stdin-protocol.md`, and regenerate `docs/beaver.template.yaml`; verify `docs_test.dart` and the template sync test pass

## 8. Integration checks

- [x] 8.1 Run the full suite, including the scored dart_style corpus; verify zero structural or idempotence failures and that the corpus match percentage did not drop from the 0.1.0 figure in `UPSTREAM.md` (except where explained by the two preset changes)
- [x] 8.2 Format the Beaver repository with a `.beaver.yaml` that sets every new key to a non-preset value; verify every file passes verification and a second run changes nothing
- [x] 8.3 Run `openspec validate add-new-settings --strict`; verify it passes

## Workflow follow-up

- Archive `initial-implementation` before archiving this change, so the base specs exist for the MODIFIED deltas.
- Archive this change with `/opsx:archive` once the tasks are done and reviewed.
