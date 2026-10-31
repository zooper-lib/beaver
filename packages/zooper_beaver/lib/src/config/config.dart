/// The resolved configuration the engine formats with.
library;

import 'package:yaml/yaml.dart';

import 'dart_preset.dart';
import 'schema.dart';

enum WrapPolicy { never, fill, chopIfLong }

enum TrailingCommas { preserve, remove, addWhenWrapped, addWhenChopped }

/// What precedes a chain's first call (`keep_first_call_on_receiver_line`).
enum ReceiverKind { typeNames, identifiers, thisOrSuper, calls, properties }

/// A list's `indent`. [columns] is the offset of the broken items from the
/// list's baseline; for [FirstItem] it is the `inherit` offset, used when
/// the first item does not share a line with what precedes it.
sealed class ListIndent {
  const ListIndent(this.columns);
  final int columns;
}

final class Inherit extends ListIndent {
  const Inherit(super.columns);
}

final class Columns extends ListIndent {
  const Columns(super.columns);
}

final class FirstItem extends ListIndent {
  const FirstItem(super.columns);
}

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

/// The key [key] takes its effective value from in [settings]: itself, or
/// the end of its fallback chain while the values say `inherit`.
String effectiveKey(String key, Map<String, Object?> settings) {
  var current = key;
  while (settings[current] == 'inherit') {
    current = fallbacks[current]!;
  }
  return current;
}

/// The resolved settings of one wrappable list.
final class ListSettings {
  const ListSettings({
    required this.policy,
    required this.chopFrom,
    required this.keepExistingLineBreaks,
    required this.chopOnTrailingComma,
    required this.indent,
    required this.breakAfterOpen,
    required this.breakBeforeClose,
    required this.trailingCommas,
  });

  final WrapPolicy policy;

  /// Item count from which the list always chops; 0 disables it.
  final int chopFrom;
  final bool keepExistingLineBreaks;
  final bool chopOnTrailingComma;
  final ListIndent indent;

  /// `break_after_open_bracket` and `break_before_close_bracket`.
  final bool breakAfterOpen;
  final bool breakBeforeClose;
  final TrailingCommas trailingCommas;

  /// Whether a list of [count] items reaches `chop_from`, which chops it
  /// under every policy but `never`.
  bool reachesThreshold(int count) => chopFrom > 0 && count >= chopFrom;

  /// For lists that borrow another list's settings but never align (type
  /// argument and parameter lists, assertions, object patterns).
  ListSettings get unaligned => ListSettings(
    policy: policy,
    chopFrom: chopFrom,
    keepExistingLineBreaks: keepExistingLineBreaks,
    chopOnTrailingComma: chopOnTrailingComma,
    indent: Inherit(indent.columns),
    breakAfterOpen: breakAfterOpen,
    breakBeforeClose: breakBeforeClose,
    trailingCommas: trailingCommas,
  );
}

/// A complete configuration: every schema key has a value.
final class BeaverConfig {
  BeaverConfig(Map<String, Object?> settings)
    : settings = Map.unmodifiable(settings),
      values = Map.unmodifiable({
        for (final key in settings.keys)
          key: settings[effectiveKey(key, settings)],
      });

  static final dart = BeaverConfig(
    flatten(loadYaml(dartPresetYaml) as YamlMap),
  );

  /// Canonical dotted key → value as configured, already validated against
  /// the schema. Inheriting keys may hold `inherit`.
  final Map<String, Object?> settings;

  /// Canonical dotted key → effective value: [settings] with every
  /// `inherit` replaced by its fallback's value.
  final Map<String, Object?> values;

  /// A copy with [overrides] (canonical dotted keys) replacing settings.
  /// `inherit` is resolved afterwards, so an overridden global key reaches
  /// the lists that inherit it.
  BeaverConfig merge(Map<String, Object?> overrides) =>
      BeaverConfig({...settings, ...overrides});

  T _get<T>(String key) => values[key] as T;
  bool _flag(String key) => _get<bool>(key);

  /// The boolean [key], for construct-specific fields read by one rule.
  bool flag(String key) => _flag(key);
  int _int(String key) => _get<int>(key);

  static WrapPolicy _policy(Object? value) => switch (value) {
    'never' => WrapPolicy.never,
    'fill' => WrapPolicy.fill,
    _ => WrapPolicy.chopIfLong,
  };

  static TrailingCommas _trailingCommas(Object? value) => switch (value) {
    'preserve' => TrailingCommas.preserve,
    'remove' => TrailingCommas.remove,
    'add_when_chopped' => TrailingCommas.addWhenChopped,
    _ => TrailingCommas.addWhenWrapped,
  };

  /// `wrap.<list>.indent`; lists without the field use `indent.size`.
  ListIndent _indent(String key) {
    final value = values[key];
    if (value == null) return Inherit(indentSize);
    if (value is int) {
      return settings[key] == 'inherit' ? Inherit(value) : Columns(value);
    }
    // `first_item`: the inherit offset is the first integer down the chain.
    var fallback = fallbacks[key]!;
    while (values[fallback] is! int) {
      fallback = fallbacks[fallback]!;
    }
    return FirstItem(_int(fallback));
  }

  ListSettings _list(String name) {
    final prefix = 'wrap.$name.';
    // Lists without bracket or comma fields read the global keys.
    bool flagOr(String field) =>
        values['$prefix$field'] as bool? ?? _flag('wrap.$field');
    return ListSettings(
      policy: _policy(values['${prefix}policy']),
      chopFrom: _int('${prefix}chop_from'),
      keepExistingLineBreaks: _flag('${prefix}keep_existing_line_breaks'),
      chopOnTrailingComma:
          values['${prefix}chop_on_trailing_comma'] as bool? ?? false,
      indent: _indent('${prefix}indent'),
      breakAfterOpen: flagOr('break_after_open_bracket'),
      breakBeforeClose: flagOr('break_before_close_bracket'),
      trailingCommas: _trailingCommas(
        values['${prefix}trailing_commas'] ?? values['trailing_commas'],
      ),
    );
  }

  /// Records take their policy from [policyFrom] but every other setting
  /// from the global keys, never from an argument or parameter override.
  ListSettings _record(ListSettings policyFrom) => ListSettings(
    policy: policyFrom.policy,
    chopFrom: 0,
    keepExistingLineBreaks: _flag('wrap.keep_existing_line_breaks'),
    chopOnTrailingComma: _flag('wrap.chop_on_trailing_comma'),
    indent: Inherit(indentSize),
    breakAfterOpen: _flag('wrap.break_after_open_bracket'),
    breakBeforeClose: _flag('wrap.break_before_close_bracket'),
    trailingCommas: _trailingCommas(values['trailing_commas']),
  );

  int get lineLength => _int('line_length');
  int get indentSize => _int('indent.size');
  IndentStyle get indentStyle =>
      values['indent.style'] == 'tabs' ? IndentStyle.tabs : IndentStyle.spaces;
  int get continuationIndent => _int('indent.continuation');
  bool get indentSwitchCases => _flag('indent.switch_cases');

  late final arguments = _list('arguments');
  late final parameters = _list('parameters');
  late final collectionLiterals = _list('collection_literals');
  late final enumValues = _list('enum_values');
  late final binaryExpressions = _list('binary_expressions');
  late final conditionalExpressions = _list('conditional_expressions');
  late final chainedCalls = _list('chained_calls');
  late final cascades = _list('cascades');
  late final initializerLists = _list('initializer_lists');
  late final switchExpressions = _list('switch_expressions');
  late final classHeader = _list('class_header');

  /// Record literals and patterns, laid out with the arguments policy.
  late final recordLiterals = _record(arguments);

  /// Record types, laid out with the parameters policy.
  late final recordTypes = _record(parameters);

  bool get breakBeforeBinaryOperator =>
      _flag('wrap.break_before.binary_operator');

  /// `wrap.chained_calls.keep_first_call_on_receiver_line`.
  late final Set<
    ReceiverKind
  > chainKeepFirstCallKinds = switch (values['wrap.chained_calls.keep_first_call_on_receiver_line']) {
    true => ReceiverKind.values.toSet(),
    final List<Object?> kinds => {
      for (final kind in kinds)
        ReceiverKind.values[ReceiverKindListType.kinds.indexOf(
          kind! as String,
        )],
    },
    _ => const {},
  };
  bool get chainBreakAfterPrefix =>
      _flag('wrap.chained_calls.break_after_prefix');
  bool get chainIndentFromTarget =>
      values['wrap.chained_calls.indent_from'] == 'target';
  bool get binaryBreakAfterPrefix =>
      _flag('wrap.binary_expressions.break_after_prefix');
  bool get binaryIndentFromTarget =>
      values['wrap.binary_expressions.indent_from'] == 'target';
  bool get simpleBlocksOnOneLine => _flag('wrap.simple_blocks_on_one_line');
  bool get simpleLambdasOnOneLine => _flag('wrap.simple_lambdas_on_one_line');
  List<String> get chopOnNamedArguments =>
      _get<List<Object?>>('wrap.chop_on_named_arguments').cast<String>();

  /// `wrap.chop_on_calls` entries, each split into its dotted segments.
  late final List<List<String>> chopOnCalls = [
    for (final entry in _get<List<Object?>>('wrap.chop_on_calls'))
      (entry! as String).split('.'),
  ];

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
  int get spaceBeforeTrailingComment => _int('spaces.before_trailing_comment');

  int get maxBlankLines => _int('blank_lines.max_consecutive');
  int get maxBlankLinesInCode => _int('blank_lines.max_consecutive_in_code');
  int get blankLinesAtBlockEdges => _int('blank_lines.at_block_edges');
  int get blankLinesAfterLastMember => _int('blank_lines.after_last_member');
  int get blankLinesAfterImports => _int('blank_lines.after_imports');
  int get blankLinesBetweenMembers => _int('blank_lines.between_members');
  int get blankLinesBeforeFirstMember =>
      _int('blank_lines.before_first_member');
  /// Meaningful only while `around_class_declarations` is an integer; under
  /// `inherit` the general top-level rule applies.
  int get blankLinesAroundClasses =>
      values['blank_lines.around_class_declarations'] as int? ?? 0;

  bool get elseOnNewLine => _flag('braces.else_on_new_line');

  Quotes get quotes => switch (values['strings.quotes']) {
    'single' => Quotes.single,
    'double' => Quotes.double,
    _ => Quotes.preserve,
  };

  List<String> get include => _get<List<Object?>>('include').cast<String>();
  List<String> get exclude => _get<List<Object?>>('exclude').cast<String>();
}
