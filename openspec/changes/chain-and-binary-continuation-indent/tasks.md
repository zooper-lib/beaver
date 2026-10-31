# Tasks

Specs: `specs/*/spec.md`. Design: `design.md`. "Goldens unchanged" means `dart test` in `packages/zooper_beaver` passes with no existing golden, example or self-format file edited.

## 1. Configuration

- [ ] 1.1 Add `break_after_prefix` (bool) and `indent_from` (`line` | `target`) as extras of `chained_calls` and `binary_expressions` in `listConstructs` (`config/schema.dart`), the preset values to `dart_preset.dart` (chains `false`/`line`, binary `true`/`line`) and accessors on `BeaverConfig`; verify `config_schema_test.dart`/`config_resolve_test.dart` cases for every config-resolution scenario except the template one, and that the goldens are unchanged
- [ ] 1.2 Regenerate `docs/beaver.template.yaml` from `beaver config --template`; verify `config_template_test.dart` and the `docs_test.dart` template check pass

## 2. Binary expressions

- [ ] 2.1 Implement `wrap.binary_expressions.break_after_prefix: false` in `assignmentRhs` (hugged right side) and in `_parentIndents` (no longer "already moved"); verify golden cases in `test/golden/wrap/` for "Binary expression kept on the prefix line" and the binary half of "Preset placement" and "Short expression is not moved", with the goldens unchanged
- [ ] 2.2 Implement `wrap.binary_expressions.indent_from: target` in `binary` (`alignToColumn` around the indented body, `align: true` checked first); verify golden cases for "Moved binary expression, target base", "Binary expression after `return`, target base", the binary half of "Alignment takes precedence", and a field-initializer case pinning today's preset output
- [ ] 2.3 Document both fields in the `wrap.binary_expressions` section of `docs/rules/wrap.md` with before/after examples for every value, and add the `indent_from` base to `indent.continuation` in `docs/rules/indent.md`; add `example/wrap.binary_expressions.break_after_prefix/{true,false}` and `example/wrap.binary_expressions.indent_from/{line,target}`; verify `docs_test.dart` and `example_test.dart` pass

## 3. Chained calls

- [ ] 3.1 Implement `wrap.chained_calls.break_after_prefix: true` in `assignmentRhs` (a chain takes the moving path, also after `=>`; single calls stay block-like) and in `_parentIndents` (moved chains keep their calls in the target's column under `line`); verify golden cases for "Chain moved after the prefix", "Moved chain that fits on its own line", "Moved chain, line base", and the chain half of "Preset placement" and "Short expression is not moved"
- [ ] 3.2 Implement `wrap.chained_calls.indent_from: target` in `chain` (`alignToColumn` from the target, falling back to the `line` layout through an `IfBreak` on the target group, `align: true` checked first, composing with `keep_first_call_on_receiver_line`); verify golden cases for "Chain after a named argument, target base", "Chain after a named argument, line base", "Moved chain, target base", "Broken chain target falls back to the line base" and the chain half of "Alignment takes precedence"
- [ ] 3.3 Document both fields in the `wrap.chained_calls` section of `docs/rules/wrap.md`, including the `date: DateFormat` case and the long-prefix trade-off; add `example/wrap.chained_calls.break_after_prefix/{true,false}` and `example/wrap.chained_calls.indent_from/{line,target}`; verify `docs_test.dart` and `example_test.dart` pass

## 4. Integration

- [ ] 4.1 Run the full suite, `dart analyze`, `dart run bin/beaver.dart --check .` from the repo root and `tool/corpus.dart` with every combination of the two fields on both lists; verify all pass, the corpus reports no safety failures, and the dart_style corpus match rate is unchanged
- [ ] 4.2 Format the Feng app's `pending_invitation_card.dart` through `--stdin` with its `.beaver.yaml` plus `wrap.chained_calls.indent_from: target`, writing only to stdout (that repo stays untouched); verify `.yMMMMd()` starts right of `DateFormat`

## Workflow follow-up

- Review the diff, commit on a feature branch, archive with `/opsx:archive chain-and-binary-continuation-indent`.
