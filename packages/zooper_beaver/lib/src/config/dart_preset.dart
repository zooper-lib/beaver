/// The built-in `dart` preset: dart_style 3.x conventions. Embedded as a
/// string because AOT binaries cannot read package assets.
const dartPresetYaml = r'''
line_length: 80
indent:
  size: 2
  style: spaces
  continuation: 4
  switch_cases: true
  align:
    arguments: false
    parameters: false
    chained_calls: false
wrap:
  arguments: chop_if_long
  parameters: chop_if_long
  collection_literals: chop_if_long
  binary_expressions: chop_if_long
  conditional_expressions: chop_if_long
  before_operator: false
  chained_calls:
    policy: chop_if_long
    min_calls: 0
    keep_single_line_if_fits: true
  keep_existing_line_breaks: true
  chop_on_trailing_comma: true
  simple_blocks_on_one_line: false
  simple_lambdas_on_one_line: false
  chop_on_named_arguments: []
trailing_commas: add_when_wrapped
spaces:
  around_assignment: true
  around_binary_operators: true
  around_arrow: true
  after_comma: true
  before_comma: false
  after_colon_in_named_argument: true
  inside_parentheses: false
  inside_brackets: false
  inside_braces: false
  before_control_parentheses: true
  in_empty_braces: false
  after_cast: true
blank_lines:
  max_consecutive: 1
  after_imports: 1
  between_members: 1
  before_first_member: 0
  around_class_declarations: 1
braces:
  else_on_new_line: false
strings:
  quotes: preserve
exclude:
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "**/*.gr.dart"
  - "**/*.mocks.dart"
  - "**/generated/**"
  - "build/**"
''';
