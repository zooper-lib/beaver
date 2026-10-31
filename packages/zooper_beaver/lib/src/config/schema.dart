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
  String describe() => 'true | false';
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

/// `inherit` (the key's documented fallback) or a value of [inner].
final class InheritOr extends ValueType {
  const InheritOr(this.inner);
  final ValueType inner;

  @override
  bool accepts(Object? value) => value == 'inherit' || inner.accepts(value);

  @override
  String describe() => 'inherit | ${inner.describe()}';
}

/// `preserve` (keep the source count) or an integer >= 0.
final class IntOrPreserveType extends ValueType {
  const IntOrPreserveType();

  @override
  bool accepts(Object? value) =>
      value == 'preserve' || (value is int && value >= 0);

  @override
  String describe() => 'preserve | an integer >= 0';
}

/// Dotted Dart names such as `Row` or `Row.center`; no wildcards.
final class DottedNameListType extends ValueType {
  const DottedNameListType();

  static final _name = RegExp(r'^[A-Za-z_$][\w$]*(\.[A-Za-z_$][\w$]*)*$');

  @override
  bool accepts(Object? value) =>
      value is List &&
      value.every((item) => item is String && _name.hasMatch(item));

  @override
  String describe() => 'a list of dotted names such as Row or Row.center';
}

const _policy = EnumType(['never', 'if_long', 'chop_if_long', 'chop_always']);
const _bool = BoolType();
const _closeBracket = EnumType(['own_line', 'after_last_item']);
const _indentFrom = EnumType(['line', 'target']);
const _trailingCommas = EnumType([
  'preserve',
  'remove',
  'add_when_wrapped',
  'add_when_chopped',
]);

/// A wrappable list, configured by the map `wrap.<name>`.
final class ListConstruct {
  const ListConstruct(
    this.name, {
    this.indent,
    this.align = true,
    this.delimited = false,
    this.inheritsFrom,
    this.extra = const {},
  });

  final String name;

  /// The key `indent: inherit` falls back to; `null` when the list has no
  /// `indent` field.
  final String? indent;

  /// Whether the list has an `align` field; `false` where alignment has no
  /// meaning (a setting that does nothing is not offered).
  final bool align;

  /// Whether the list owns a closing delimiter and an optional trailing
  /// comma (`close_bracket` and `trailing_commas` fields).
  final bool delimited;

  /// The list every field falls back to (`enum_values` follows
  /// `collection_literals`).
  final String? inheritsFrom;

  /// Construct-specific fields.
  final Map<String, ValueType> extra;

  /// Field name → type, in documentation order.
  Map<String, ValueType> get fields {
    final own = <String, ValueType>{
      'policy': _policy,
      'chop_from': const IntType(),
      'keep_existing_line_breaks': const InheritOr(_bool),
      'chop_on_trailing_comma': const InheritOr(_bool),
      if (align) 'align': _bool,
      if (indent != null) 'indent': const InheritOr(IntType()),
      if (delimited) ...{
        'close_bracket': const InheritOr(_closeBracket),
        'trailing_commas': const InheritOr(_trailingCommas),
      },
      ...extra,
    };
    if (inheritsFrom == null) return own;
    return {
      for (final MapEntry(:key, :value) in own.entries)
        key: value is InheritOr ? value : InheritOr(value),
    };
  }

  /// The key [field] falls back to under `inherit`, if it accepts it.
  String? fallback(String field) {
    if (inheritsFrom != null) return 'wrap.$inheritsFrom.$field';
    return switch (field) {
      'keep_existing_line_breaks' => 'wrap.keep_existing_line_breaks',
      'chop_on_trailing_comma' => 'wrap.chop_on_trailing_comma',
      'close_bracket' => 'wrap.close_bracket',
      'trailing_commas' => 'trailing_commas',
      'indent' => indent,
      _ => null,
    };
  }
}

/// Every wrappable list, in documentation order.
const listConstructs = [
  ListConstruct(
    'arguments',
    indent: 'indent.size',
    delimited: true,
    extra: {'hug_block_argument': _bool},
  ),
  ListConstruct('parameters', indent: 'indent.size', delimited: true),
  ListConstruct('collection_literals', indent: 'indent.size', delimited: true),
  ListConstruct(
    'enum_values',
    indent: 'indent.size',
    delimited: true,
    inheritsFrom: 'collection_literals',
  ),
  ListConstruct(
    'binary_expressions',
    indent: 'indent.continuation',
    extra: {'break_after_prefix': _bool, 'indent_from': _indentFrom},
  ),
  ListConstruct('conditional_expressions', align: false),
  ListConstruct(
    'chained_calls',
    indent: 'indent.continuation',
    extra: {
      'keep_single_line_if_fits': _bool,
      'keep_first_call_on_receiver_line': _bool,
      'break_after_prefix': _bool,
      'indent_from': _indentFrom,
    },
  ),
  ListConstruct('cascades', indent: 'indent.size', align: false),
  ListConstruct(
    'initializer_lists',
    indent: 'indent.size',
    extra: {
      'colon': EnumType(['auto', 'new_line', 'end_of_header']),
    },
  ),
  ListConstruct('switch_expressions', align: false),
  ListConstruct(
    'class_header',
    align: false,
    extra: {'clauses_on_new_line': _bool},
  ),
];

/// Dotted key → type, in documentation order. Every key here must be
/// defined by the `dart` preset.
final schema = <String, ValueType>{
  'line_length': const IntType(min: 1),
  'line_ending': const EnumType(['auto', 'lf', 'crlf']),
  'editorconfig': _bool,
  'indent.size': const IntType(min: 1),
  'indent.style': const EnumType(['spaces', 'tabs']),
  'indent.continuation': const IntType(),
  'indent.switch_cases': _bool,
  'wrap.keep_existing_line_breaks': _bool,
  'wrap.chop_on_trailing_comma': _bool,
  'wrap.close_bracket': _closeBracket,
  'wrap.break_before.binary_operator': _bool,
  'wrap.break_before.conditional_operator': _bool,
  'wrap.break_before.arrow': _bool,
  'wrap.break_before.assignment': _bool,
  'wrap.simple_blocks_on_one_line': _bool,
  'wrap.simple_lambdas_on_one_line': _bool,
  'wrap.chop_on_named_arguments': const StringListType(),
  'wrap.chop_on_calls': const DottedNameListType(),
  'wrap.annotations': const EnumType(['own_line', 'same_line', 'preserve']),
  'wrap.braceless_bodies': const EnumType([
    'same_line_if_fits',
    'new_line',
    'preserve',
  ]),
  'wrap.control_conditions': const EnumType(['continuation', 'block']),
  'wrap.simple_case_bodies_on_one_line': _bool,
  'wrap.simple_methods_on_one_line': _bool,
  for (final list in listConstructs)
    for (final MapEntry(:key, :value) in list.fields.entries)
      'wrap.${list.name}.$key': value,
  'trailing_commas': _trailingCommas,
  'spaces.around_assignment': _bool,
  'spaces.around_binary_operators': _bool,
  'spaces.around_arrow': _bool,
  'spaces.after_comma': _bool,
  'spaces.before_comma': _bool,
  'spaces.before_colon_in_named_argument': _bool,
  'spaces.after_colon_in_named_argument': _bool,
  'spaces.before_colon_in_map_entry': _bool,
  'spaces.after_colon_in_map_entry': _bool,
  'spaces.before_colon_in_initializer_list': _bool,
  'spaces.before_colon_in_switch_case': _bool,
  'spaces.inside_parentheses': _bool,
  'spaces.inside_brackets': _bool,
  'spaces.inside_braces': _bool,
  'spaces.before_control_parentheses': _bool,
  'spaces.in_empty_braces': _bool,
  'spaces.after_cast': _bool,
  'spaces.before_trailing_comment': const IntType(min: 1),
  'blank_lines.max_consecutive': const IntType(),
  'blank_lines.max_consecutive_in_code': const InheritOr(IntType()),
  'blank_lines.at_block_edges': const IntType(),
  'blank_lines.after_imports': const IntType(),
  'blank_lines.between_members': const IntType(),
  'blank_lines.before_first_member': const IntType(),
  'blank_lines.after_last_member': const IntType(),
  'blank_lines.keep_between_non_block_members': _bool,
  'blank_lines.between_import_groups': const IntOrPreserveType(),
  'blank_lines.between_comment_and_declaration': const IntOrPreserveType(),
  'blank_lines.between_top_level_declarations': const IntOrPreserveType(),
  'blank_lines.around_class_declarations': const InheritOr(IntType()),
  'blank_lines.keep_between_non_block_top_level_declarations': _bool,
  'braces.else_on_new_line': _bool,
  'braces.catch_on_new_line': const InheritOr(_bool),
  'braces.finally_on_new_line': const InheritOr(_bool),
  'braces.while_on_new_line': const InheritOr(_bool),
  'strings.quotes': const EnumType(['preserve', 'single', 'double']),
  'strings.quotes_avoid_escapes': _bool,
  'include': const StringListType(),
  'exclude': const StringListType(),
};

/// Key accepting `inherit` → the key it then takes its value from. A
/// fallback may itself inherit; every chain ends at a plain key.
final fallbacks = <String, String>{
  for (final list in listConstructs)
    for (final field in list.fields.keys)
      if (list.fallback(field) case final fallback?)
        'wrap.${list.name}.$field': fallback,
  'blank_lines.max_consecutive_in_code': 'blank_lines.max_consecutive',
  'blank_lines.around_class_declarations': 'blank_lines.between_top_level_declarations',
  'braces.catch_on_new_line': 'braces.else_on_new_line',
  'braces.finally_on_new_line': 'braces.else_on_new_line',
  'braces.while_on_new_line': 'braces.else_on_new_line',
};
