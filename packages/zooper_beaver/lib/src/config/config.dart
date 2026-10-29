/// The resolved configuration the engine formats with.
library;

import 'package:yaml/yaml.dart';

import 'dart_preset.dart';

enum WrapPolicy { never, ifLong, chopIfLong, chopAlways }

enum TrailingCommas { preserve, remove, addWhenWrapped }

enum Quotes { preserve, single, double }

enum IndentStyle { spaces, tabs }

/// Flattens nested YAML maps into dotted keys; lists and scalars are leaves.
Map<String, Object?> flatten(Map<Object?, Object?> map, [String prefix = '']) {
  final result = <String, Object?>{};
  for (final MapEntry(:key, :value) in map.entries) {
    final dotted = '$prefix$key';
    if (value is Map) {
      result.addAll(flatten(value, '$dotted.'));
    } else {
      result[dotted] = value is List ? List<Object?>.of(value) : value;
    }
  }
  return result;
}

/// A complete configuration: every schema key has a value.
final class BeaverConfig {
  BeaverConfig(Map<String, Object?> values) : values = Map.unmodifiable(values);

  static final dart = BeaverConfig(
    flatten(loadYaml(dartPresetYaml) as YamlMap),
  );

  /// Dotted key → value, already validated against the schema.
  final Map<String, Object?> values;

  /// A copy with [overrides] (dotted keys) replacing values.
  BeaverConfig merge(Map<String, Object?> overrides) =>
      BeaverConfig({...values, ...overrides});

  T _get<T>(String key) => values[key] as T;
  bool _flag(String key) => _get<bool>(key);
  int _int(String key) => _get<int>(key);

  static WrapPolicy _policy(Object? value) => switch (value) {
    'never' => WrapPolicy.never,
    'if_long' => WrapPolicy.ifLong,
    'chop_always' => WrapPolicy.chopAlways,
    _ => WrapPolicy.chopIfLong,
  };

  int get lineLength => _int('line_length');
  int get indentSize => _int('indent.size');
  IndentStyle get indentStyle =>
      values['indent.style'] == 'tabs' ? IndentStyle.tabs : IndentStyle.spaces;
  int get continuationIndent => _int('indent.continuation');
  bool get indentSwitchCases => _flag('indent.switch_cases');
  bool get alignArguments => _flag('indent.align.arguments');
  bool get alignParameters => _flag('indent.align.parameters');
  bool get alignChainedCalls => _flag('indent.align.chained_calls');

  WrapPolicy get wrapArguments => _policy(values['wrap.arguments']);
  WrapPolicy get wrapParameters => _policy(values['wrap.parameters']);
  WrapPolicy get wrapCollections => _policy(values['wrap.collection_literals']);
  WrapPolicy get wrapBinary => _policy(values['wrap.binary_expressions']);
  WrapPolicy get wrapConditional =>
      _policy(values['wrap.conditional_expressions']);
  bool get breakBeforeOperator => _flag('wrap.before_operator');
  WrapPolicy get wrapChains => _policy(values['wrap.chained_calls.policy']);
  int get chainMinCalls => _int('wrap.chained_calls.min_calls');
  bool get chainKeepSingleLineIfFits =>
      _flag('wrap.chained_calls.keep_single_line_if_fits');
  bool get keepExistingLineBreaks => _flag('wrap.keep_existing_line_breaks');
  bool get chopOnTrailingComma => _flag('wrap.chop_on_trailing_comma');
  bool get simpleBlocksOnOneLine => _flag('wrap.simple_blocks_on_one_line');
  bool get simpleLambdasOnOneLine => _flag('wrap.simple_lambdas_on_one_line');
  List<String> get chopOnNamedArguments =>
      _get<List<Object?>>('wrap.chop_on_named_arguments').cast<String>();

  TrailingCommas get trailingCommas => switch (values['trailing_commas']) {
    'preserve' => TrailingCommas.preserve,
    'remove' => TrailingCommas.remove,
    _ => TrailingCommas.addWhenWrapped,
  };

  bool get spaceAroundAssignment => _flag('spaces.around_assignment');
  bool get spaceAroundBinary => _flag('spaces.around_binary_operators');
  bool get spaceAroundArrow => _flag('spaces.around_arrow');
  bool get spaceAfterComma => _flag('spaces.after_comma');
  bool get spaceBeforeComma => _flag('spaces.before_comma');
  bool get spaceAfterNamedColon =>
      _flag('spaces.after_colon_in_named_argument');
  bool get spaceInsideParens => _flag('spaces.inside_parentheses');
  bool get spaceInsideBrackets => _flag('spaces.inside_brackets');
  bool get spaceInsideBraces => _flag('spaces.inside_braces');
  bool get spaceBeforeControlParens =>
      _flag('spaces.before_control_parentheses');
  bool get spaceInEmptyBraces => _flag('spaces.in_empty_braces');
  bool get spaceAfterCast => _flag('spaces.after_cast');

  int get maxBlankLines => _int('blank_lines.max_consecutive');
  int get blankLinesAfterImports => _int('blank_lines.after_imports');
  int get blankLinesBetweenMembers => _int('blank_lines.between_members');
  int get blankLinesBeforeFirstMember =>
      _int('blank_lines.before_first_member');
  int get blankLinesAroundClasses =>
      _int('blank_lines.around_class_declarations');

  bool get elseOnNewLine => _flag('braces.else_on_new_line');

  Quotes get quotes => switch (values['strings.quotes']) {
    'single' => Quotes.single,
    'double' => Quotes.double,
    _ => Quotes.preserve,
  };

  List<String> get exclude => _get<List<Object?>>('exclude').cast<String>();
}
