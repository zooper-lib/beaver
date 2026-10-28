/// The `.beaver.yaml` schema: every key, its type and its allowed values.
library;

sealed class ValueType {
  const ValueType();

  /// Whether [value] is valid for this type.
  bool accepts(Object? value);

  /// Human-readable allowed values, for diagnostics.
  String describe();
}

final class IntType extends ValueType {
  const IntType({this.min = 0});
  final int min;

  @override
  bool accepts(Object? value) => value is int && value >= min;

  @override
  String describe() => 'an integer >= $min';
}

final class BoolType extends ValueType {
  const BoolType();

  @override
  bool accepts(Object? value) => value is bool;

  @override
  String describe() => 'true or false';
}

final class EnumType extends ValueType {
  const EnumType(this.values);
  final List<String> values;

  @override
  bool accepts(Object? value) => values.contains(value);

  @override
  String describe() => values.join(' | ');
}

final class StringListType extends ValueType {
  const StringListType();

  @override
  bool accepts(Object? value) =>
      value is List && value.every((item) => item is String);

  @override
  String describe() => 'a list of strings';
}

const _policy = EnumType(['never', 'if_long', 'chop_if_long', 'chop_always']);

/// Dotted key → type. Every key here must be defined by the `dart` preset.
const schema = <String, ValueType>{
  'line_length': IntType(min: 1),
  'indent.size': IntType(min: 1),
  'indent.style': EnumType(['spaces', 'tabs']),
  'indent.continuation': IntType(),
  'indent.switch_cases': BoolType(),
  'indent.align.arguments': BoolType(),
  'indent.align.parameters': BoolType(),
  'indent.align.chained_calls': BoolType(),
  'wrap.arguments': _policy,
  'wrap.parameters': _policy,
  'wrap.collection_literals': _policy,
  'wrap.binary_expressions': _policy,
  'wrap.conditional_expressions': _policy,
  'wrap.before_operator': BoolType(),
  'wrap.chained_calls.policy': _policy,
  // 0 disables the count-based chop.
  'wrap.chained_calls.min_calls': IntType(),
  'wrap.chained_calls.keep_single_line_if_fits': BoolType(),
  'wrap.keep_existing_line_breaks': BoolType(),
  'wrap.chop_on_trailing_comma': BoolType(),
  'wrap.simple_blocks_on_one_line': BoolType(),
  'wrap.simple_lambdas_on_one_line': BoolType(),
  'wrap.chop_on_named_arguments': StringListType(),
  'trailing_commas': EnumType(['preserve', 'remove', 'add_when_wrapped']),
  'spaces.around_assignment': BoolType(),
  'spaces.around_binary_operators': BoolType(),
  'spaces.around_arrow': BoolType(),
  'spaces.after_comma': BoolType(),
  'spaces.before_comma': BoolType(),
  'spaces.after_colon_in_named_argument': BoolType(),
  'spaces.inside_parentheses': BoolType(),
  'spaces.inside_brackets': BoolType(),
  'spaces.inside_braces': BoolType(),
  'spaces.before_control_parentheses': BoolType(),
  'spaces.in_empty_braces': BoolType(),
  'spaces.after_cast': BoolType(),
  'blank_lines.max_consecutive': IntType(),
  'blank_lines.after_imports': IntType(),
  'blank_lines.between_members': IntType(),
  'blank_lines.before_first_member': IntType(),
  'blank_lines.around_class_declarations': IntType(),
  'braces.else_on_new_line': BoolType(),
  'strings.quotes': EnumType(['preserve', 'single', 'double']),
  'exclude': StringListType(),
};
