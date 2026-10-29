/// Configuration resolution: discovery, the `extends` chain, the
/// effective root and exclusion matching. File access is injected so the
/// engine stays free of `dart:io`.
library;

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'loader.dart';

/// Reads the file at [path], or returns `null` if there is none.
typedef ReadFile = String? Function(String path);

const configFileName = '.beaver.yaml';
const _presetOrigin = 'preset dart';

/// Directories never traversed or formatted, whatever the configuration.
const protectedDirectories = {'.dart_tool', '.git'};

final class ResolvedConfig {
  ResolvedConfig._(this.config, this.provenance, this.chain, this.root);

  final BeaverConfig config;

  /// Dotted key → the file (or `preset dart`) that set its value.
  final Map<String, String> provenance;

  /// The files consulted, nearest first, ending with `preset dart`.
  final List<String> chain;

  /// The directory exclusion patterns are matched against.
  final String root;

  late final List<(String, Glob)> _globs = [
    for (final pattern in config.exclude)
      (pattern, Glob(pattern, context: p.posix, caseSensitive: true)),
  ];

  /// The pattern excluding [path], `protected` for `.dart_tool`/`.git`, or
  /// `null` if the file is formatted.
  String? excludedBy(String path) {
    final relative = p.posix.joinAll(p.split(p.relative(path, from: root)));
    final segments = p.posix.split(relative);
    if (segments.any(protectedDirectories.contains)) return 'protected';
    for (final (pattern, glob) in _globs) {
      if (glob.matches(relative)) return pattern;
    }
    return null;
  }
}

/// Resolves the configuration for the file at [path] (absolute; a directory
/// when [isDirectory], for `config --print` without `--for`). [explicit] is
/// `--config`, which skips discovery. Throws [ConfigException].
ResolvedConfig resolveConfig(
  String path, {
  required ReadFile read,
  String? explicit,
  bool isDirectory = false,
}) {
  final directory = isDirectory ? path : p.dirname(path);

  String? projectFile;
  String? firstFile;
  if (explicit != null) {
    firstFile = p.normalize(p.absolute(explicit));
    if (read(firstFile) == null) {
      throw ConfigException('$firstFile: configuration file not found.');
    }
  } else {
    projectFile = _findUp(directory, configFileName, read);
    firstFile = projectFile;
  }

  // Nearest first.
  final files = <ConfigFile>[];
  final visited = <String>{};
  var next = firstFile;
  while (next != null) {
    if (!visited.add(next)) {
      throw ConfigException(
        'Configuration cycle: ${files.last.path} extends $next, which is '
        'already in the chain (${visited.join(' → ')}).',
      );
    }
    final text = read(next);
    if (text == null) {
      throw ConfigException(
        '${files.last.path}: `extends: ${files.last.extendsValue}` is neither '
        'a built-in preset (dart) nor an existing file.',
      );
    }
    final file = parseConfigFile(text, next);
    files.add(file);
    final extendsValue = file.extendsValue;
    next = extendsValue == null || extendsValue == 'dart'
        ? null
        : p.normalize(p.join(p.dirname(file.path), extendsValue));
  }

  final values = Map.of(BeaverConfig.dart.values);
  final provenance = {for (final key in values.keys) key: _presetOrigin};
  final exclude = [...BeaverConfig.dart.exclude];
  for (final file in files.reversed) {
    for (final MapEntry(:key, :value) in file.values.entries) {
      if (key == 'exclude') {
        for (final pattern in (value! as List).cast<String>()) {
          if (!exclude.contains(pattern)) exclude.add(pattern);
        }
        provenance[key] = '${provenance[key]}, ${file.path}';
      } else {
        values[key] = value;
        provenance[key] = file.path;
      }
    }
  }
  values['exclude'] = exclude;

  // The chop deletes the comma that requested it, and with no kept
  // breaks the next run would undo the chop.
  const conflicting = [
    'trailing_commas',
    'wrap.chop_on_trailing_comma',
    'wrap.keep_existing_line_breaks',
  ];
  if (values[conflicting[0]] == 'remove' &&
      values[conflicting[1]] == true &&
      values[conflicting[2]] == false) {
    final settings = [
      for (final key in conflicting)
        '$key: ${values[key]} (${provenance[key]})',
    ].join(', ');
    throw ConfigException(
      'Incompatible settings: $settings. The trailing comma that requests a '
      'chop is removed, and without kept line breaks the next run would undo '
      'the chop. '
      'Change one of them: set trailing_commas to preserve or '
      'add_when_wrapped, wrap.chop_on_trailing_comma to false, or '
      'wrap.keep_existing_line_breaks to true.',
    );
  }

  final pubspec = _findUp(directory, 'pubspec.yaml', read);
  final root = projectFile != null
      ? p.dirname(projectFile)
      : pubspec != null
      ? p.dirname(pubspec)
      : directory;

  return ResolvedConfig._(BeaverConfig(values), provenance, [
    for (final f in files) f.path,
    _presetOrigin,
  ], root);
}

/// The nearest [name] in [directory] or its ancestors.
String? _findUp(String directory, String name, ReadFile read) {
  var current = p.normalize(p.absolute(directory));
  while (true) {
    final candidate = p.join(current, name);
    if (read(candidate) != null) return candidate;
    final parent = p.dirname(current);
    if (parent == current) return null;
    current = parent;
  }
}
