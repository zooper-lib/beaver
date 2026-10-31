/// Parses and validates one `.beaver.yaml`.
library;

import 'package:yaml/yaml.dart';

import 'config.dart';
import 'schema.dart';

/// A configuration problem (exit 78, `EX_CONFIG`).
final class ConfigException implements Exception {
  const ConfigException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// One configuration file's own settings.
final class ConfigFile {
  const ConfigFile(this.path, this.extendsValue, this.values);

  /// Where it came from (a file path, or `preset:dart`).
  final String path;

  /// The raw `extends:` value, if any.
  final String? extendsValue;

  /// Canonical dotted key → validated value, as set in this file only.
  final Map<String, Object?> values;
}

/// Parses [text] read from [path] and validates every key and value against
/// the schema. Throws [ConfigException] naming the file and key.
ConfigFile parseConfigFile(String text, String path) {
  final Object? document;
  try {
    document = loadYaml(text, sourceUrl: Uri.file(path));
  } on YamlException catch (e) {
    throw ConfigException('$path: invalid YAML: ${e.message}');
  }
  if (document == null) return ConfigFile(path, null, const {});
  if (document is! YamlMap) {
    throw ConfigException('$path: expected a map of settings.');
  }
  final values = flatten(document);
  final extendsValue = values.remove('extends');
  if (extendsValue != null && extendsValue is! String) {
    throw ConfigException('$path: `extends` must be a preset name or a path.');
  }
  return ConfigFile(
    path,
    extendsValue as String?,
    normalizeAndValidateValues(values, path),
  );
}

/// One-to-one alternative spellings → canonical key. Besides these, the
/// shorthand `wrap.<list>: <policy>` stands for `wrap.<list>.policy`, and
/// [_rewrite] handles the spellings that change the value too.
const _aliases = {
  'wrap.chained_calls.min_calls': 'wrap.chained_calls.chop_from',
  'wrap.before_operator': 'wrap.break_before.binary_operator',
};

final _shorthands = {
  for (final list in listConstructs)
    'wrap.${list.name}': 'wrap.${list.name}.policy',
};

/// The canonical key and value for [key] (already through [_aliases] and
/// [_shorthands]) set to [value], or `null` for a spelling that is dropped.
/// Throws for a removed spelling, naming its replacement.
(String, Object?)? _rewrite(String key, Object? value, String origin) {
  final dot = key.lastIndexOf('.');
  final (prefix, field) = (key.substring(0, dot + 1), key.substring(dot + 1));
  if (field == 'policy' && value == 'chop_always') {
    throw ConfigException(
      '$origin: `$key: chop_always` was removed and is replaced by '
      '`chop_from`: write `policy: chop_if_long` and `chop_from: 1`.'
      '${key == 'wrap.chained_calls.policy' ? ' On a chain, '
                '`chop_always` with `keep_single_line_if_fits: false` '
                'corresponds to `chop_from: 2`.' : ''}',
    );
  }
  if (key == 'wrap.chained_calls.keep_single_line_if_fits') {
    throw ConfigException(
      '$origin: `$key` was removed; use `chop_from` instead '
      '(`chop_from: 2` chops every chain of two or more calls).',
    );
  }
  if (field == 'policy' && value == 'if_long') return (key, 'fill');
  if (field == 'close_bracket' && (prefix == 'wrap.' || _isList(prefix))) {
    final placed = switch (value) {
      'own_line' => true,
      'after_last_item' => false,
      _ => value,
    };
    return ('${prefix}break_before_close_bracket', placed);
  }
  // `align` only ever meant "use indent" when false.
  final list = key.startsWith('indent.align.')
      ? 'wrap.${key.substring('indent.align.'.length)}.'
      : field == 'align'
      ? prefix
      : null;
  if (list != null &&
      schema['${list}indent']?.accepts('first_item') == true &&
      value is bool) {
    return value ? ('${list}indent', 'first_item') : null;
  }
  if (key == 'wrap.chained_calls.keep_first_call_on_receiver_line' &&
      value is bool) {
    return (key, value ? ReceiverKindListType.kinds : const <String>[]);
  }
  return (key, value);
}

bool _isList(String prefix) =>
    _shorthands.containsKey(prefix.substring(0, prefix.length - 1));

/// Rewrites dotted [values] (one configuration source) to canonical keys
/// and checks them against the schema; [origin] names the source in
/// diagnostics. Two spellings of one key with different values are an
/// error; identical ones are accepted.
Map<String, Object?> normalizeAndValidateValues(
  Map<String, Object?> values,
  String origin,
) {
  final result = <String, Object?>{};
  final spelling = <String, String>{};
  for (final MapEntry(:key, value: written) in values.entries) {
    final rewritten = _rewrite(
      _aliases[key] ?? _shorthands[key] ?? key,
      written,
      origin,
    );
    if (rewritten == null) continue;
    final (canonical, value) = rewritten;
    final type = schema[canonical];
    if (type == null) {
      throw ConfigException(
        '$origin: unknown key `$key`; known keys here: ${_siblings(key)}.',
      );
    }
    final name = canonical == key ? '`$key`' : '`$key` (`$canonical`)';
    if (!type.accepts(value)) {
      throw ConfigException(
        '$origin: invalid value `$written` for $name; allowed: ${type.describe()}.',
      );
    }
    if (spelling[canonical] case final other?
        when !_equal(result[canonical], value)) {
      throw ConfigException(
        '$origin: `$other` and `$key` both set `$canonical`, to '
        '`${result[canonical]}` and `$value`; keep one of them.',
      );
    }
    spelling[canonical] = key;
    result[canonical] = value;
  }
  return result;
}

bool _equal(Object? a, Object? b) => a is List && b is List
    ? a.length == b.length && a.indexed.every((e) => e.$2 == b[e.$1])
    : a == b;

/// Schema keys at the same nesting level as [key] (top-level names for a
/// top-level key, `wrap.*` names for a key under `wrap`).
String _siblings(String key) {
  final dot = key.lastIndexOf('.');
  final prefix = dot < 0 ? '' : key.substring(0, dot + 1);
  final names = <String>{
    for (final k in schema.keys)
      if (k.startsWith(prefix)) k.substring(prefix.length).split('.').first,
  };
  return names.isEmpty
      ? schema.keys.map((k) => k.split('.').first).toSet().join(', ')
      : names.join(', ');
}
