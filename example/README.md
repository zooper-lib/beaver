# Rule showcase

Every `.beaver.yaml` key, every value, and the code Beaver produces with it. Nothing here is written by hand except the inputs: each output is the formatter's real output, and `packages/zooper_beaver/test/example_test.dart` fails if one goes stale.

## How to read it

```
example/
  wrap.arguments/                 one folder per configuration key
    before.dart                   the input, shared by every value
    never/
      .beaver.yaml                only this key; everything else is the dart preset
      after.dart                  before.dart formatted with that config
    if_long/
    chop_if_long/
    chop_always/
```

Open a key's `before.dart`, then compare the `after.dart` files of its values. Each `.beaver.yaml` sets just that one key; every other key keeps its `dart` preset value. Three folders need a second key to show a difference, and their `.beaver.yaml` says so: `wrap.chained_calls.policy` sets `keep_single_line_if_fits: false` (otherwise `chop_always` keeps a chain that fits on one line), `wrap.chained_calls.keep_single_line_if_fits` sets `policy: chop_always`, and `strings.quotes_avoid_escapes` sets `strings.quotes: single`. A field of a list map without a folder of its own (such as `wrap.cascades.indent`) is shown by its list's folder; [`docs/beaver.template.yaml`](../docs/beaver.template.yaml) lists every field.

`exclude/`, `include/` and `editorconfig/` are different, because they are about which files get formatted, or where settings come from, rather than how. `editorconfig/lib/counter.dart` is already formatted with the four-space indentation its `.editorconfig` asks for (`beaver --check example/editorconfig` passes). In `include/`, only `lib/` is included, so `tool/gen.dart` is skipped. In `exclude/`: `lib/model.dart` is formatted, `lib/model.g.dart` is skipped by the preset's `**/*.g.dart` pattern, and `legacy/old.dart` is skipped by the folder's own `legacy/**` pattern. Run `beaver --check --verbose example/exclude` to see the skips.

## Protected from formatting and analysis

The inputs must stay unformatted and the outputs must stay exactly what Beaver produced, so:

- `example/.beaver.yaml` excludes every `before.dart` from Beaver: the CLI, and the VS Code and IntelliJ plugins, leave them unchanged. A test fails if that exclusion is removed.
- `.vscode/settings.json` sets `dart.doNotFormat` for `example/**`, so the Dart extension's `dart format` (for example on save) never touches these files. `dart format` itself has no exclusion setting: don't run it on `example/`. In IntelliJ or Android Studio, add `example/**` under Settings → Editor → Code Style → Formatter → Do not format.
- `example/analysis_options.yaml` excludes the folder from analysis: the code uses placeholder names and is not meant to compile.

## Try it

From the repository root, with `beaver` on your `PATH` (or `dart run packages/zooper_beaver/bin/beaver.dart` in its place):

```sh
# Format one input with one value's config (--stdin-name selects the config):
beaver --stdin --stdin-name example/wrap.arguments/if_long/after.dart < example/wrap.arguments/before.dart

# Show the effective config for a value folder, with where each setting comes from:
beaver config --print --for example/wrap.arguments/if_long/after.dart

# Every output is stable under its own config (the inputs are excluded by example/.beaver.yaml):
beaver --check example
```

To try a value that has no folder, copy a value folder, edit its `.beaver.yaml`, and run the first command with the new folder's path.

After changing a rule, regenerate every output:

```sh
for d in example/*/*/; do
  [ -f "${d}.beaver.yaml" ] && [ -f "${d}../before.dart" ] || continue
  beaver --stdin --stdin-name "${d}after.dart" < "${d}../before.dart" > "${d}after.dart"
done
```

## Line length and indentation

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`line_length`](line_length/before.dart) | [`40`](line_length/40/after.dart) · **[`80`](line_length/80/after.dart)** · [`120`](line_length/120/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`line_ending`](line_ending/before.dart) | **[`auto`](line_ending/auto/after.dart)** · [`lf`](line_ending/lf/after.dart) · [`crlf`](line_ending/crlf/after.dart) | [cli.md](../docs/cli.md) |
| [`indent.size`](indent.size/before.dart) | **[`2`](indent.size/2/after.dart)** · [`4`](indent.size/4/after.dart) | [indent.md](../docs/rules/indent.md) |
| [`indent.style`](indent.style/before.dart) | **[`spaces`](indent.style/spaces/after.dart)** · [`tabs`](indent.style/tabs/after.dart) | [indent.md](../docs/rules/indent.md) |
| [`indent.continuation`](indent.continuation/before.dart) | [`2`](indent.continuation/2/after.dart) · **[`4`](indent.continuation/4/after.dart)** · [`8`](indent.continuation/8/after.dart) | [indent.md](../docs/rules/indent.md) |
| [`indent.switch_cases`](indent.switch_cases/before.dart) | [`false`](indent.switch_cases/false/after.dart) · **[`true`](indent.switch_cases/true/after.dart)** | [indent.md](../docs/rules/indent.md) |
| [`wrap.arguments.align`](wrap.arguments.align/before.dart) | **[`false`](wrap.arguments.align/false/after.dart)** · [`true`](wrap.arguments.align/true/after.dart) | [indent.md](../docs/rules/indent.md) |
| [`wrap.parameters.align`](wrap.parameters.align/before.dart) | **[`false`](wrap.parameters.align/false/after.dart)** · [`true`](wrap.parameters.align/true/after.dart) | [indent.md](../docs/rules/indent.md) |
| [`wrap.chained_calls.align`](wrap.chained_calls.align/before.dart) | **[`false`](wrap.chained_calls.align/false/after.dart)** · [`true`](wrap.chained_calls.align/true/after.dart) | [indent.md](../docs/rules/indent.md) |

## Wrapping

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`wrap.arguments`](wrap.arguments/before.dart) | [`never`](wrap.arguments/never/after.dart) · [`if_long`](wrap.arguments/if_long/after.dart) · **[`chop_if_long`](wrap.arguments/chop_if_long/after.dart)** · [`chop_always`](wrap.arguments/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.parameters`](wrap.parameters/before.dart) | [`never`](wrap.parameters/never/after.dart) · [`if_long`](wrap.parameters/if_long/after.dart) · **[`chop_if_long`](wrap.parameters/chop_if_long/after.dart)** · [`chop_always`](wrap.parameters/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.collection_literals`](wrap.collection_literals/before.dart) | [`never`](wrap.collection_literals/never/after.dart) · [`if_long`](wrap.collection_literals/if_long/after.dart) · **[`chop_if_long`](wrap.collection_literals/chop_if_long/after.dart)** · [`chop_always`](wrap.collection_literals/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.binary_expressions`](wrap.binary_expressions/before.dart) | [`never`](wrap.binary_expressions/never/after.dart) · [`if_long`](wrap.binary_expressions/if_long/after.dart) · **[`chop_if_long`](wrap.binary_expressions/chop_if_long/after.dart)** · [`chop_always`](wrap.binary_expressions/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.conditional_expressions`](wrap.conditional_expressions/before.dart) | [`never`](wrap.conditional_expressions/never/after.dart) · [`if_long`](wrap.conditional_expressions/if_long/after.dart) · **[`chop_if_long`](wrap.conditional_expressions/chop_if_long/after.dart)** · [`chop_always`](wrap.conditional_expressions/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.break_before.binary_operator`](wrap.break_before.binary_operator/before.dart) | **[`false`](wrap.break_before.binary_operator/false/after.dart)** · [`true`](wrap.break_before.binary_operator/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chained_calls.policy`](wrap.chained_calls.policy/before.dart) | [`never`](wrap.chained_calls.policy/never/after.dart) · [`if_long`](wrap.chained_calls.policy/if_long/after.dart) · **[`chop_if_long`](wrap.chained_calls.policy/chop_if_long/after.dart)** · [`chop_always`](wrap.chained_calls.policy/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chained_calls.chop_from`](wrap.chained_calls.chop_from/before.dart) | **[`0`](wrap.chained_calls.chop_from/0/after.dart)** · [`3`](wrap.chained_calls.chop_from/3/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chained_calls.keep_single_line_if_fits`](wrap.chained_calls.keep_single_line_if_fits/before.dart) | [`false`](wrap.chained_calls.keep_single_line_if_fits/false/after.dart) · **[`true`](wrap.chained_calls.keep_single_line_if_fits/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.keep_existing_line_breaks`](wrap.keep_existing_line_breaks/before.dart) | [`false`](wrap.keep_existing_line_breaks/false/after.dart) · **[`true`](wrap.keep_existing_line_breaks/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chop_on_trailing_comma`](wrap.chop_on_trailing_comma/before.dart) | [`false`](wrap.chop_on_trailing_comma/false/after.dart) · **[`true`](wrap.chop_on_trailing_comma/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.simple_blocks_on_one_line`](wrap.simple_blocks_on_one_line/before.dart) | **[`false`](wrap.simple_blocks_on_one_line/false/after.dart)** · [`true`](wrap.simple_blocks_on_one_line/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.simple_lambdas_on_one_line`](wrap.simple_lambdas_on_one_line/before.dart) | **[`false`](wrap.simple_lambdas_on_one_line/false/after.dart)** · [`true`](wrap.simple_lambdas_on_one_line/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chop_on_named_arguments`](wrap.chop_on_named_arguments/before.dart) | **[`empty`](wrap.chop_on_named_arguments/empty/after.dart)** · [`child_children`](wrap.chop_on_named_arguments/child_children/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.enum_values`](wrap.enum_values/before.dart) | **[`inherit`](wrap.enum_values/inherit/after.dart)** · [`never`](wrap.enum_values/never/after.dart) · [`if_long`](wrap.enum_values/if_long/after.dart) · [`chop_always`](wrap.enum_values/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.cascades`](wrap.cascades/before.dart) | [`never`](wrap.cascades/never/after.dart) · [`if_long`](wrap.cascades/if_long/after.dart) · **[`chop_if_long`](wrap.cascades/chop_if_long/after.dart)** · [`chop_always`](wrap.cascades/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.initializer_lists`](wrap.initializer_lists/before.dart) | [`never`](wrap.initializer_lists/never/after.dart) · [`if_long`](wrap.initializer_lists/if_long/after.dart) · **[`chop_if_long`](wrap.initializer_lists/chop_if_long/after.dart)** · [`chop_always`](wrap.initializer_lists/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.initializer_lists.colon`](wrap.initializer_lists.colon/before.dart) | **[`auto`](wrap.initializer_lists.colon/auto/after.dart)** · [`new_line`](wrap.initializer_lists.colon/new_line/after.dart) · [`end_of_header`](wrap.initializer_lists.colon/end_of_header/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.switch_expressions`](wrap.switch_expressions/before.dart) | [`never`](wrap.switch_expressions/never/after.dart) · [`if_long`](wrap.switch_expressions/if_long/after.dart) · [`chop_if_long`](wrap.switch_expressions/chop_if_long/after.dart) · **[`chop_always`](wrap.switch_expressions/chop_always/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.class_header`](wrap.class_header/before.dart) | [`never`](wrap.class_header/never/after.dart) · [`if_long`](wrap.class_header/if_long/after.dart) · **[`chop_if_long`](wrap.class_header/chop_if_long/after.dart)** · [`chop_always`](wrap.class_header/chop_always/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.class_header.clauses_on_new_line`](wrap.class_header.clauses_on_new_line/before.dart) | [`false`](wrap.class_header.clauses_on_new_line/false/after.dart) · **[`true`](wrap.class_header.clauses_on_new_line/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.arguments.hug_block_argument`](wrap.arguments.hug_block_argument/before.dart) | [`false`](wrap.arguments.hug_block_argument/false/after.dart) · **[`true`](wrap.arguments.hug_block_argument/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.arguments.chop_from`](wrap.arguments.chop_from/before.dart) | **[`0`](wrap.arguments.chop_from/0/after.dart)** · [`3`](wrap.arguments.chop_from/3/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chop_on_calls`](wrap.chop_on_calls/before.dart) | **[`empty`](wrap.chop_on_calls/empty/after.dart)** · [`Row`](wrap.chop_on_calls/Row/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.close_bracket`](wrap.close_bracket/before.dart) | **[`own_line`](wrap.close_bracket/own_line/after.dart)** · [`after_last_item`](wrap.close_bracket/after_last_item/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.break_before.conditional_operator`](wrap.break_before.conditional_operator/before.dart) | [`false`](wrap.break_before.conditional_operator/false/after.dart) · **[`true`](wrap.break_before.conditional_operator/true/after.dart)** | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.break_before.arrow`](wrap.break_before.arrow/before.dart) | **[`false`](wrap.break_before.arrow/false/after.dart)** · [`true`](wrap.break_before.arrow/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.break_before.assignment`](wrap.break_before.assignment/before.dart) | **[`false`](wrap.break_before.assignment/false/after.dart)** · [`true`](wrap.break_before.assignment/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.chained_calls.keep_first_call_on_receiver_line`](wrap.chained_calls.keep_first_call_on_receiver_line/before.dart) | **[`false`](wrap.chained_calls.keep_first_call_on_receiver_line/false/after.dart)** · [`true`](wrap.chained_calls.keep_first_call_on_receiver_line/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.binary_expressions.align`](wrap.binary_expressions.align/before.dart) | **[`false`](wrap.binary_expressions.align/false/after.dart)** · [`true`](wrap.binary_expressions.align/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.annotations`](wrap.annotations/before.dart) | **[`own_line`](wrap.annotations/own_line/after.dart)** · [`same_line`](wrap.annotations/same_line/after.dart) · [`preserve`](wrap.annotations/preserve/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.braceless_bodies`](wrap.braceless_bodies/before.dart) | **[`same_line_if_fits`](wrap.braceless_bodies/same_line_if_fits/after.dart)** · [`new_line`](wrap.braceless_bodies/new_line/after.dart) · [`preserve`](wrap.braceless_bodies/preserve/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.control_conditions`](wrap.control_conditions/before.dart) | **[`continuation`](wrap.control_conditions/continuation/after.dart)** · [`block`](wrap.control_conditions/block/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.simple_case_bodies_on_one_line`](wrap.simple_case_bodies_on_one_line/before.dart) | **[`false`](wrap.simple_case_bodies_on_one_line/false/after.dart)** · [`true`](wrap.simple_case_bodies_on_one_line/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |
| [`wrap.simple_methods_on_one_line`](wrap.simple_methods_on_one_line/before.dart) | **[`false`](wrap.simple_methods_on_one_line/false/after.dart)** · [`true`](wrap.simple_methods_on_one_line/true/after.dart) | [wrap.md](../docs/rules/wrap.md) |

## Trailing commas

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`trailing_commas`](trailing_commas/before.dart) | [`preserve`](trailing_commas/preserve/after.dart) · [`remove`](trailing_commas/remove/after.dart) · **[`add_when_wrapped`](trailing_commas/add_when_wrapped/after.dart)** · [`add_when_chopped`](trailing_commas/add_when_chopped/after.dart) | [wrap.md](../docs/rules/wrap.md) |

## Spaces

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`spaces.around_assignment`](spaces.around_assignment/before.dart) | [`false`](spaces.around_assignment/false/after.dart) · **[`true`](spaces.around_assignment/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.around_binary_operators`](spaces.around_binary_operators/before.dart) | [`false`](spaces.around_binary_operators/false/after.dart) · **[`true`](spaces.around_binary_operators/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.around_arrow`](spaces.around_arrow/before.dart) | [`false`](spaces.around_arrow/false/after.dart) · **[`true`](spaces.around_arrow/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.after_comma`](spaces.after_comma/before.dart) | [`false`](spaces.after_comma/false/after.dart) · **[`true`](spaces.after_comma/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_comma`](spaces.before_comma/before.dart) | **[`false`](spaces.before_comma/false/after.dart)** · [`true`](spaces.before_comma/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.after_colon_in_named_argument`](spaces.after_colon_in_named_argument/before.dart) | [`false`](spaces.after_colon_in_named_argument/false/after.dart) · **[`true`](spaces.after_colon_in_named_argument/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.inside_parentheses`](spaces.inside_parentheses/before.dart) | **[`false`](spaces.inside_parentheses/false/after.dart)** · [`true`](spaces.inside_parentheses/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.inside_brackets`](spaces.inside_brackets/before.dart) | **[`false`](spaces.inside_brackets/false/after.dart)** · [`true`](spaces.inside_brackets/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.inside_braces`](spaces.inside_braces/before.dart) | **[`false`](spaces.inside_braces/false/after.dart)** · [`true`](spaces.inside_braces/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_control_parentheses`](spaces.before_control_parentheses/before.dart) | [`false`](spaces.before_control_parentheses/false/after.dart) · **[`true`](spaces.before_control_parentheses/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.in_empty_braces`](spaces.in_empty_braces/before.dart) | **[`false`](spaces.in_empty_braces/false/after.dart)** · [`true`](spaces.in_empty_braces/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.after_cast`](spaces.after_cast/before.dart) | [`false`](spaces.after_cast/false/after.dart) · **[`true`](spaces.after_cast/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_trailing_comment`](spaces.before_trailing_comment/before.dart) | **[`1`](spaces.before_trailing_comment/1/after.dart)** · [`2`](spaces.before_trailing_comment/2/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_colon_in_named_argument`](spaces.before_colon_in_named_argument/before.dart) | **[`false`](spaces.before_colon_in_named_argument/false/after.dart)** · [`true`](spaces.before_colon_in_named_argument/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_colon_in_map_entry`](spaces.before_colon_in_map_entry/before.dart) | **[`false`](spaces.before_colon_in_map_entry/false/after.dart)** · [`true`](spaces.before_colon_in_map_entry/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.after_colon_in_map_entry`](spaces.after_colon_in_map_entry/before.dart) | [`false`](spaces.after_colon_in_map_entry/false/after.dart) · **[`true`](spaces.after_colon_in_map_entry/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_colon_in_initializer_list`](spaces.before_colon_in_initializer_list/before.dart) | [`false`](spaces.before_colon_in_initializer_list/false/after.dart) · **[`true`](spaces.before_colon_in_initializer_list/true/after.dart)** | [spaces.md](../docs/rules/spaces.md) |
| [`spaces.before_colon_in_switch_case`](spaces.before_colon_in_switch_case/before.dart) | **[`false`](spaces.before_colon_in_switch_case/false/after.dart)** · [`true`](spaces.before_colon_in_switch_case/true/after.dart) | [spaces.md](../docs/rules/spaces.md) |

## Blank lines

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`blank_lines.max_consecutive`](blank_lines.max_consecutive/before.dart) | [`0`](blank_lines.max_consecutive/0/after.dart) · **[`1`](blank_lines.max_consecutive/1/after.dart)** · [`2`](blank_lines.max_consecutive/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.max_consecutive_in_code`](blank_lines.max_consecutive_in_code/before.dart) | **[`inherit`](blank_lines.max_consecutive_in_code/inherit/after.dart)** · [`0`](blank_lines.max_consecutive_in_code/0/after.dart) · [`2`](blank_lines.max_consecutive_in_code/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.at_block_edges`](blank_lines.at_block_edges/before.dart) | **[`0`](blank_lines.at_block_edges/0/after.dart)** · [`1`](blank_lines.at_block_edges/1/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.after_imports`](blank_lines.after_imports/before.dart) | **[`1`](blank_lines.after_imports/1/after.dart)** · [`2`](blank_lines.after_imports/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.between_members`](blank_lines.between_members/before.dart) | **[`1`](blank_lines.between_members/1/after.dart)** · [`2`](blank_lines.between_members/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.before_first_member`](blank_lines.before_first_member/before.dart) | **[`0`](blank_lines.before_first_member/0/after.dart)** · [`1`](blank_lines.before_first_member/1/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.after_last_member`](blank_lines.after_last_member/before.dart) | **[`0`](blank_lines.after_last_member/0/after.dart)** · [`1`](blank_lines.after_last_member/1/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.keep_between_non_block_members`](blank_lines.keep_between_non_block_members/before.dart) | [`false`](blank_lines.keep_between_non_block_members/false/after.dart) · **[`true`](blank_lines.keep_between_non_block_members/true/after.dart)** | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.between_import_groups`](blank_lines.between_import_groups/before.dart) | **[`preserve`](blank_lines.between_import_groups/preserve/after.dart)** · [`0`](blank_lines.between_import_groups/0/after.dart) · [`1`](blank_lines.between_import_groups/1/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.between_comment_and_declaration`](blank_lines.between_comment_and_declaration/before.dart) | **[`preserve`](blank_lines.between_comment_and_declaration/preserve/after.dart)** · [`0`](blank_lines.between_comment_and_declaration/0/after.dart) · [`1`](blank_lines.between_comment_and_declaration/1/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.around_class_declarations`](blank_lines.around_class_declarations/before.dart) | **[`1`](blank_lines.around_class_declarations/1/after.dart)** · [`2`](blank_lines.around_class_declarations/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.between_top_level_declarations`](blank_lines.between_top_level_declarations/before.dart) | **[`preserve`](blank_lines.between_top_level_declarations/preserve/after.dart)** · [`1`](blank_lines.between_top_level_declarations/1/after.dart) · [`2`](blank_lines.between_top_level_declarations/2/after.dart) | [blank_lines.md](../docs/rules/blank_lines.md) |
| [`blank_lines.keep_between_non_block_top_level_declarations`](blank_lines.keep_between_non_block_top_level_declarations/before.dart) | [`false`](blank_lines.keep_between_non_block_top_level_declarations/false/after.dart) · **[`true`](blank_lines.keep_between_non_block_top_level_declarations/true/after.dart)** | [blank_lines.md](../docs/rules/blank_lines.md) |

## Braces

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`braces.else_on_new_line`](braces.else_on_new_line/before.dart) | **[`false`](braces.else_on_new_line/false/after.dart)** · [`true`](braces.else_on_new_line/true/after.dart) | [braces.md](../docs/rules/braces.md) |
| [`braces.catch_on_new_line`](braces.catch_on_new_line/before.dart) | **[`inherit`](braces.catch_on_new_line/inherit/after.dart)** · [`false`](braces.catch_on_new_line/false/after.dart) · [`true`](braces.catch_on_new_line/true/after.dart) | [braces.md](../docs/rules/braces.md) |
| [`braces.finally_on_new_line`](braces.finally_on_new_line/before.dart) | **[`inherit`](braces.finally_on_new_line/inherit/after.dart)** · [`false`](braces.finally_on_new_line/false/after.dart) · [`true`](braces.finally_on_new_line/true/after.dart) | [braces.md](../docs/rules/braces.md) |
| [`braces.while_on_new_line`](braces.while_on_new_line/before.dart) | **[`inherit`](braces.while_on_new_line/inherit/after.dart)** · [`false`](braces.while_on_new_line/false/after.dart) · [`true`](braces.while_on_new_line/true/after.dart) | [braces.md](../docs/rules/braces.md) |

## Strings

| Key | Values (preset value in bold) | Rule doc |
|---|---|---|
| [`strings.quotes`](strings.quotes/before.dart) | **[`preserve`](strings.quotes/preserve/after.dart)** · [`single`](strings.quotes/single/after.dart) · [`double`](strings.quotes/double/after.dart) | [strings.md](../docs/rules/strings.md) |
| [`strings.quotes_avoid_escapes`](strings.quotes_avoid_escapes/before.dart) | [`false`](strings.quotes_avoid_escapes/false/after.dart) · **[`true`](strings.quotes_avoid_escapes/true/after.dart)** | [strings.md](../docs/rules/strings.md) |

## Exclusion

| Key | Example | Rule doc |
|---|---|---|
| `exclude` | [`exclude/`](exclude/.beaver.yaml) | [cli.md](../docs/cli.md) |
| `include` | [`include/`](include/.beaver.yaml) | [cli.md](../docs/cli.md) |
| `editorconfig` | [`editorconfig/`](editorconfig/.beaver.yaml) | [indent.md](../docs/rules/indent.md#editorconfig) |
