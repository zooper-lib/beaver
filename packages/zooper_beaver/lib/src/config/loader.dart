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
/// shorthand `wrap.<list>: <policy>` stands for `wrap.<list>.policy`.
const _aliases = {
  'indent.align.arguments': 'wrap.arguments.align',
  'indent.align.parameters': 'wrap.parameters.align',
  'indent.align.chained_calls': 'wrap.chained_calls.align',
  'wrap.chained_calls.min_calls': 'wrap.chained_calls.chop_from',
  'wrap.before_operator': 'wrap.break_before.binary_operator',
};

final _shorthands = {
  for (final list in listConstructs)
    'wrap.${list.name}': 'wrap.${list.name}.policy',
};

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
  for (final MapEntry(:key, :value) in values.entries) {
    final canonical = _aliases[key] ?? _shorthands[key] ?? key;
    final type = schema[canonical];
    if (type == null) {
      throw ConfigException(
        '$origin: unknown key `$key`; known keys here: ${_siblings(key)}.',
      );
    }
    final name = canonical == key ? '`$key`' : '`$key` (`$canonical`)';
    if (!type.accepts(value)) {
      throw ConfigException(
        '$origin: invalid value `$value` for $name; allowed: ${type.describe()}.',
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
