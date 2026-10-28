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

  /// Dotted key → validated value, as set in this file only.
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
  validateValues(values, path);
  return ConfigFile(path, extendsValue as String?, values);
}

/// Checks dotted [values] against the schema; [origin] names the source in
/// diagnostics.
void validateValues(Map<String, Object?> values, String origin) {
  for (final MapEntry(:key, :value) in values.entries) {
    final type = schema[key];
    if (type == null) {
      throw ConfigException(
        '$origin: unknown key `$key`; known keys here: ${_siblings(key)}.',
      );
    }
    if (!type.accepts(value)) {
      throw ConfigException(
        '$origin: invalid value `$value` for `$key`; allowed: ${type.describe()}.',
      );
    }
  }
}

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
