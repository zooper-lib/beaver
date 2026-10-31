/// EditorConfig resolution: the INI parser, the glob translator and the
/// upward walk. File access is injected so the engine stays free of
/// `dart:io`.
library;

import 'package:path/path.dart' as p;

import 'resolve.dart' show ReadFile;

const editorConfigFileName = '.editorconfig';

/// Properties whose values are case-insensitive and therefore lowercased.
const _caseInsensitive = {
  'charset',
  'end_of_line',
  'indent_size',
  'indent_style',
  'insert_final_newline',
  'tab_width',
  'trim_trailing_whitespace',
};

/// A resolved property value and where it was set.
final class EditorConfigValue {
  const EditorConfigValue(
    this.value, {
    required this.path,
    required this.section,
  });

  final String value;

  /// The `.editorconfig` file that set the value.
  final String path;

  /// The section header that set the value, brackets included (`[*.dart]`).
  final String section;
}

/// Resolves the EditorConfig properties for the file at [path] (absolute):
/// property name (lowercase) → value and provenance. Reads `.editorconfig`
/// from the file's directory upward until a file declares `root = true`.
Map<String, EditorConfigValue> resolveEditorConfig(String path, ReadFile read) {
  final file = p.normalize(p.absolute(path));

  // Nearest first.
  final files = <(String, _IniFile)>[];
  var directory = p.dirname(file);
  while (true) {
    final candidate = p.join(directory, editorConfigFileName);
    final text = read(candidate);
    if (text != null) {
      final ini = _IniFile.parse(text);
      files.add((candidate, ini));
      if (ini.root) break;
    }
    final parent = p.dirname(directory);
    if (parent == directory) break;
    directory = parent;
  }

  final result = <String, EditorConfigValue>{};
  for (final (configPath, ini) in files.reversed) {
    final relative = p.posix.joinAll(
      p.split(p.relative(file, from: p.dirname(configPath))),
    );
    for (final section in ini.sections) {
      if (!section.glob.matches(relative)) continue;
      for (final MapEntry(:key, :value) in section.properties.entries) {
        if (value.toLowerCase() == 'unset') {
          result.remove(key);
        } else {
          result[key] = EditorConfigValue(
            value,
            path: configPath,
            section: '[${section.name}]',
          );
        }
      }
    }
  }
  return result;
}

final class _Section {
  _Section(this.name) : glob = EditorConfigGlob(name);

  final String name;
  final EditorConfigGlob glob;
  final properties = <String, String>{};
}

final class _IniFile {
  _IniFile(this.root, this.sections);

  factory _IniFile.parse(String text) {
    var root = false;
    final sections = <_Section>[];
    for (final raw in text.split(RegExp(r'\r\n?|\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
        continue;
      }
      if (line.startsWith('[')) {
        if (line.endsWith(']') && line.length > 2) {
          sections.add(_Section(line.substring(1, line.length - 1)));
        }
        continue;
      }
      final equals = line.indexOf('=');
      if (equals <= 0) continue;
      final key = line.substring(0, equals).trim().toLowerCase();
      var value = line.substring(equals + 1).trim();
      if (key.isEmpty) continue;
      if (sections.isEmpty) {
        if (key == 'root') root = value.toLowerCase() == 'true';
        continue;
      }
      if (_caseInsensitive.contains(key)) value = value.toLowerCase();
      sections.last.properties[key] = value;
    }
    return _IniFile(root, sections);
  }

  final bool root;
  final List<_Section> sections;
}

/// An EditorConfig section glob, matched against a file path relative to
/// the `.editorconfig`'s directory with `/` separators.
///
/// A pattern without `/` matches the basename at any depth; one with `/` is
/// anchored to the `.editorconfig`'s directory.
final class EditorConfigGlob {
  factory EditorConfigGlob(String pattern) {
    final anchored = pattern.contains('/')
        ? pattern.startsWith('/')
              ? pattern
              : '/$pattern'
        : '/**/$pattern';
    final translator = _Translator();
    final source = translator.translate(anchored);
    return EditorConfigGlob._(
      pattern,
      RegExp('^$source\$', dotAll: true),
      translator.ranges,
    );
  }

  EditorConfigGlob._(this.pattern, this._regExp, this._ranges);

  final String pattern;
  final RegExp _regExp;

  /// Bounds of each `{n1..n2}`, in capture-group order.
  final List<(int, int)> _ranges;

  bool matches(String relativePath) {
    final match = _regExp.firstMatch('/$relativePath');
    if (match == null) return false;
    for (var i = 0; i < _ranges.length; i++) {
      // `null` when the range sits in an alternative that did not match.
      final text = match.group(i + 1);
      if (text == null) continue;
      final number = int.tryParse(text);
      final (low, high) = _ranges[i];
      if (number == null || '$number' != text) return false;
      if (number < low || number > high) return false;
    }
    return true;
  }
}

final class _Translator {
  final ranges = <(int, int)>[];

  static final _range = RegExp(r'^([+-]?\d+)\.\.([+-]?\d+)$');

  String translate(String glob) {
    final out = StringBuffer();
    var i = 0;
    while (i < glob.length) {
      final c = glob[i];
      switch (c) {
        case r'\':
          out.write(RegExp.escape(i + 1 < glob.length ? glob[++i] : c));
          i++;
        case '/' when glob.startsWith('**/', i + 1):
          // `/**/` also matches a single `/`.
          out.write('(?:/|/.*/)');
          i += 4;
        case '*' when glob.startsWith('**', i):
          out.write('.*');
          i += 2;
        case '*':
          out.write('[^/]*');
          i++;
        case '?':
          out.write('[^/]');
          i++;
        case '[':
          final close = _bracketEnd(glob, i);
          if (close == null) {
            out.write(r'\[');
            i++;
          } else {
            out.write(_charClass(glob.substring(i + 1, close)));
            i = close + 1;
          }
        case '{':
          final close = _braceEnd(glob, i);
          final body = close == null ? '' : glob.substring(i + 1, close);
          final alternatives = close == null ? const <String>[] : _split(body);
          final range = _range.firstMatch(body);
          if (close != null && range != null) {
            final a = int.parse(range[1]!);
            final b = int.parse(range[2]!);
            ranges.add(a <= b ? (a, b) : (b, a));
            out.write(r'([+-]?\d+)');
            i = close + 1;
          } else if (alternatives.length > 1) {
            out.write('(?:${alternatives.map(translate).join('|')})');
            i = close! + 1;
          } else {
            // Unmatched or single-word braces are literal.
            out.write(r'\{');
            i++;
          }
        default:
          out.write(RegExp.escape(c));
          i++;
      }
    }
    return out.toString();
  }

  /// The index of the `]` closing the `[` at [start], or `null` when there
  /// is none or a `/` comes first (the bracket is then literal).
  static int? _bracketEnd(String glob, int start) {
    var i = start + 1;
    if (i < glob.length && glob[i] == '!') i++;
    for (; i < glob.length; i++) {
      switch (glob[i]) {
        case r'\':
          i++;
        case '/':
          return null;
        case ']':
          return i;
      }
    }
    return null;
  }

  static String _charClass(String body) {
    final negated = body.startsWith('!');
    final out = StringBuffer(negated ? '[^/' : '[');
    for (var i = negated ? 1 : 0; i < body.length; i++) {
      var c = body[i];
      if (c == r'\' && i + 1 < body.length) c = body[++i];
      out.write(
        switch (c) {
          r'\' || ']' || '[' || '^' => '\\$c',
          _ => c,
        },
      );
    }
    out.write(']');
    return negated || body.isNotEmpty ? '$out' : r'\[\]';
  }

  /// The index of the `}` matching the `{` at [start], or `null`.
  static int? _braceEnd(String glob, int start) {
    var depth = 0;
    for (var i = start; i < glob.length; i++) {
      switch (glob[i]) {
        case r'\':
          i++;
        case '{':
          depth++;
        case '}':
          if (--depth == 0) return i;
      }
    }
    return null;
  }

  /// Splits a brace body at its top-level commas, keeping escapes.
  static List<String> _split(String body) {
    final parts = <String>[];
    var depth = 0;
    var from = 0;
    for (var i = 0; i < body.length; i++) {
      switch (body[i]) {
        case r'\':
          i++;
        case '{':
          depth++;
        case '}':
          depth--;
        case ',' when depth == 0:
          parts.add(body.substring(from, i));
          from = i + 1;
      }
    }
    parts.add(body.substring(from));
    return parts;
  }
}
