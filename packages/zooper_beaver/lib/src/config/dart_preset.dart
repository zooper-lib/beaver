/// The built-in `dart` preset: dart_style 3.x conventions. Embedded as a
/// string because AOT binaries cannot read package assets.
const dartPresetYaml = r'''
line_length: 80
line_ending: auto
editorconfig: false
indent:
  size: 2
  style: spaces
  continuation: 4
  switch_cases: true
wrap:
  keep_existing_line_breaks: true
  chop_on_trailing_comma: true
  close_bracket: own_line
  break_before:
    binary_operator: false
    conditional_operator: true
    arrow: false
    assignment: false
  simple_blocks_on_one_line: false
  simple_lambdas_on_one_line: false
  chop_on_named_arguments: []
  chop_on_calls: []
  annotations: own_line
  braceless_bodies: same_line_if_fits
  control_conditions: continuation
  simple_case_bodies_on_one_line: false
  simple_methods_on_one_line: false
  arguments:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: false
    indent: inherit
    close_bracket: inherit
    trailing_commas: inherit
    hug_block_argument: true
  parameters:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: false
    indent: inherit
    close_bracket: inherit
    trailing_commas: inherit
  collection_literals:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: false
    indent: inherit
    close_bracket: inherit
    trailing_commas: inherit
  enum_values:
    policy: inherit
    chop_from: inherit
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: inherit
    indent: inherit
    close_bracket: inherit
    trailing_commas: inherit
  binary_expressions:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: false
    indent: inherit
  conditional_expressions:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
  chained_calls:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    align: false
    indent: inherit
    keep_single_line_if_fits: true
    keep_first_call_on_receiver_line: false
  cascades:
    policy: chop_if_long
    chop_from: 2
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
    indent: inherit
  initializer_lists:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: false
    chop_on_trailing_comma: inherit
    align: true
    indent: inherit
    colon: auto
  switch_expressions:
    policy: chop_always
    chop_from: 0
    keep_existing_line_breaks: inherit
    chop_on_trailing_comma: inherit
  class_header:
    policy: chop_if_long
    chop_from: 0
    keep_existing_line_breaks: false
    chop_on_trailing_comma: inherit
    clauses_on_new_line: true
trailing_commas: add_when_wrapped
spaces:
  around_assignment: true
  around_binary_operators: true
  around_arrow: true
  after_comma: true
  before_comma: false
  before_colon_in_named_argument: false
  after_colon_in_named_argument: true
  before_colon_in_map_entry: false
  after_colon_in_map_entry: true
  before_colon_in_initializer_list: true
  before_colon_in_switch_case: false
  inside_parentheses: false
  inside_brackets: false
  inside_braces: false
  before_control_parentheses: true
  in_empty_braces: false
  after_cast: true
  before_trailing_comment: 1
blank_lines:
  max_consecutive: 1
  max_consecutive_in_code: inherit
  at_block_edges: 0
  after_imports: 1
  between_members: 1
  before_first_member: 0
  after_last_member: 0
  keep_between_non_block_members: true
  between_import_groups: preserve
  between_comment_and_declaration: preserve
  between_top_level_declarations: preserve
  around_class_declarations: 1
  keep_between_non_block_top_level_declarations: true
braces:
  else_on_new_line: false
  catch_on_new_line: inherit
  finally_on_new_line: inherit
  while_on_new_line: inherit
strings:
  quotes: preserve
  quotes_avoid_escapes: true
include:
  - "**"
exclude:
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.gr.dart"
  - "**/*.mocks.dart"
  - "**/generated/**"
  - "build/**"
''';
