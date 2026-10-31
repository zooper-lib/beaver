/// Configuration resolution: discovery, the `extends` chain, the
/// effective root and exclusion matching. File access is injected so the
/// engine stays free of `dart:io`.
library;

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'editorconfig.dart';
import 'loader.dart';
import 'schema.dart';

/// Reads the file at [path], or returns `null` if there is none.
typedef ReadFile = String? Function(String path);

const configFileName = '.beaver.yaml';
const _presetOrigin = 'preset dart';

/// Directories never traversed or formatted, whatever the configuration.
const protectedDirectories = {'.dart_tool', '.git'};

/// Where a key's effective value comes from.
final class Source {
  const Source(this.origin, {this.detail, this.fallback, this.fallbackOrigin});

  /// The file (or `preset dart`) that set the key, possibly to `inherit`.
  final String origin;

  /// For a value from EditorConfig: the section and properties
  /// (`[*.dart] indent_size, tab_width`).
  final String? detail;

  /// For a key set to `inherit`: the key at the end of its fallback chain,
  /// and the file (or preset) that set that key's value.
  final String? fallback;
  final String? fallbackOrigin;
}

final class ResolvedConfig {
  ResolvedConfig._(
    this.config,
    this.provenance,
    this.chain,
    this.root,
    this.warnings,
  );

  final BeaverConfig config;

  /// Canonical dotted key → where its value comes from.
  final Map<String, Source> provenance;

  /// The files consulted, nearest first, ending with `preset dart`.
  final List<String> chain;

  /// The directory exclusion patterns are matched against.
  final String root;

  /// Problems that do not stop formatting, such as an EditorConfig value
  /// Beaver cannot use.
  final List<String> warnings;

  late final List<(String, Glob)> _globs = [
    for (final pattern in config.exclude) (pattern, _glob(pattern)),
  ];

  late final List<Glob> _includes = [
    for (final pattern in config.include) _glob(pattern),
  ];

  static Glob _glob(String pattern) =>
      Glob(pattern, context: p.posix, caseSensitive: true);

  /// The pattern excluding [path], `protected` for `.dart_tool`/`.git`,
  /// `not in include` when no `include` pattern matches it, or `null` if
  /// the file is formatted.
  String? excludedBy(String path) {
    final relative = p.posix.joinAll(p.split(p.relative(path, from: root)));
    final segments = p.posix.split(relative);
    if (segments.any(protectedDirectories.contains)) return 'protected';
    for (final (pattern, glob) in _globs) {
      if (glob.matches(relative)) return pattern;
    }
    if (!_includes.any((glob) => glob.matches(relative))) {
      return 'not in include';
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

  final settings = Map.of(BeaverConfig.dart.settings);
  final origins = {for (final key in settings.keys) key: _presetOrigin};
  final exclude = [...BeaverConfig.dart.exclude];
  for (final file in files.reversed) {
    for (final MapEntry(:key, :value) in file.values.entries) {
      if (key == 'exclude') {
        for (final pattern in (value! as List).cast<String>()) {
          if (!exclude.contains(pattern)) exclude.add(pattern);
        }
        origins[key] = '${origins[key]}, ${file.path}';
      } else {
        settings[key] = value;
        origins[key] = file.path;
      }
    }
  }
  settings['exclude'] = exclude;

  // EditorConfig sits above the preset and below every Beaver file: it
  // fills only keys no file in the chain set.
  final details = <String, String>{};
  final warnings = <String>[];
  if (settings['editorconfig'] == true && !isDirectory) {
    final found = resolveEditorConfig(path, read);
    void apply(String key, Object? value, EditorConfigValue from, String what) {
      if (origins[key] != _presetOrigin) return;
      settings[key] = value;
      origins[key] = from.path;
      details[key] = '${from.section} $what';
    }

    if (found['indent_style'] case final style?) {
      switch (style.value) {
        case 'space':
          apply('indent.style', 'spaces', style, 'indent_style');
        case 'tab':
          apply('indent.style', 'tabs', style, 'indent_style');
      }
    }
    if (found['indent_size'] case final size?) {
      final width = found['tab_width'];
      final (value, what) = size.value == 'tab'
          ? (int.tryParse(width?.value ?? ''), 'indent_size, tab_width')
          : (int.tryParse(size.value), 'indent_size');
      if (value != null && value >= 1) {
        apply('indent.size', value, size, what);
      }
    }
    if (found['end_of_line'] case final ending?) {
      switch (ending.value) {
        case 'lf' || 'crlf':
          apply('line_ending', ending.value, ending, 'end_of_line');
        default:
          warnings.add(
            '${ending.path} ${ending.section}: end_of_line = ${ending.value} '
            'is not supported (only lf and crlf); ignored.',
          );
      }
    }
  }

  final provenance = <String, Source>{};
  for (final MapEntry(:key, value: origin) in origins.entries) {
    final fallback = effectiveKey(key, settings);
    provenance[key] = fallback == key
        ? Source(origin, detail: details[key])
        : Source(origin, fallback: fallback, fallbackOrigin: origins[fallback]);
  }
  final config = BeaverConfig(settings);
  _checkTrailingCommas(config, provenance);

  final pubspec = _findUp(directory, 'pubspec.yaml', read);
  final root = projectFile != null
      ? p.dirname(projectFile)
      : pubspec != null
      ? p.dirname(pubspec)
      : directory;

  return ResolvedConfig._(
    config,
    provenance,
    [for (final f in files) f.path, _presetOrigin],
    root,
    warnings,
  );
}

/// Rejects, per construct, a removed optional comma together with
/// comma-triggered chopping and no kept breaks: the chop deletes the comma
/// that requested it, and the next run would undo the chop. `never` has no
/// comma trigger and `chop_always` chops anyway. Records use the global keys.
void _checkTrailingCommas(BeaverConfig config, Map<String, Source> provenance) {
  final values = config.values;
  String describe(String key) {
    final source = provenance[key]!;
    final from = source.fallback == null
        ? source.origin
        : 'inherit from ${source.origin}; ${source.fallback} from '
              '${source.fallbackOrigin}';
    return '$key: ${values[key]} ($from)';
  }

  final problems = <String>[];
  for (final (name, prefix) in [
    for (final list in listConstructs)
      if (list.delimited) (list.name, 'wrap.${list.name}.'),
    ('records', ''),
  ]) {
    final policy = prefix.isEmpty ? null : values['${prefix}policy'];
    if (policy == 'never' || policy == 'chop_always') continue;
    final commas = '${prefix}trailing_commas';
    final close = prefix.isEmpty
        ? 'wrap.close_bracket'
        : '${prefix}close_bracket';
    final chop = prefix.isEmpty
        ? 'wrap.chop_on_trailing_comma'
        : '${prefix}chop_on_trailing_comma';
    final keep = prefix.isEmpty
        ? 'wrap.keep_existing_line_breaks'
        : '${prefix}keep_existing_line_breaks';
    final removes = values[commas] == 'remove';
    final suppresses = values[close] == 'after_last_item';
    if (!(removes || suppresses) ||
        values[chop] != true ||
        values[keep] != false) {
      continue;
    }
    problems.add(
      '$name: ${[
        describe(commas),
        if (suppresses) '${describe(close)}, which suppresses the optional trailing comma',
        describe(chop),
        describe(keep)].join(', ')}',
    );
  }
  if (problems.isEmpty) return;
  throw ConfigException(
    'Incompatible trailing-comma settings for ${problems.join('; for ')}. '
    'The trailing comma that requests a chop is removed, and without kept '
    'line breaks the next run would undo the chop. '
    'Change one of them for that construct: keep the optional comma '
    '(trailing_commas preserve or add_when_wrapped, close_bracket own_line), '
    'set chop_on_trailing_comma to false, set keep_existing_line_breaks to '
    'true, or use the policy never or chop_always.',
  );
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
