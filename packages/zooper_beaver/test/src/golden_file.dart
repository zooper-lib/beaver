/// Parser for golden test files in dart_style's `.stmt`/`.unit` grammar,
/// extended with `key=value` configuration options.
library;

import 'package:yaml/yaml.dart';

final class GoldenOptions {
  GoldenOptions({
    this.leadingIndent,
    List<String>? experiments,
    Map<String, Object?>? config,
  }) : experiments = experiments ?? [],
       config = config ?? {};

  /// `(indent N)`: leading indentation applied by the harness.
  int? leadingIndent;

  /// `(experiment X)`: parser experiment flags.
  final List<String> experiments;

  /// Dotted configuration keys and their YAML values.
  final Map<String, Object?> config;
}

final class GoldenCase {
  GoldenCase({
    required this.line,
    required this.description,
    required this.options,
    required this.input,
    required this.expected,
  });

  /// 1-based line of the `>>>` header.
  final int line;
  final String description;
  final GoldenOptions options;
  final String input;

  /// Output expected at the latest language version, or `null` when the
  /// newest output section marks the case unsupported.
  final String? expected;

  bool get hasSelectionMarkers =>
      input.contains('‹') ||
      input.contains('›') ||
      (expected?.contains('‹') ?? false);

  String get label =>
      description.isEmpty ? 'line $line' : 'line $line: $description';
}

final class GoldenFile {
  GoldenFile(this.path, this.pageWidth, this.options, this.cases);

  final String path;
  final int? pageWidth;
  final GoldenOptions options;
  final List<GoldenCase> cases;

  bool get isUnit => path.endsWith('.unit');
}

final class GoldenFormatException implements Exception {
  GoldenFormatException(this.path, this.line, this.message);
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line: $message';
}

final _outputHeader = RegExp(r'^<<<(?: (\d+)\.(\d+))?(.*)$');
final _unicodeEscape = RegExp(r'×([0-9a-fA-F]{2,4})');

GoldenFile parseGoldenFile(String path, String contents) {
  final lines = contents.split('\n');
  if (lines.last.isEmpty) lines.removeLast();
  final isUnit = path.endsWith('.unit');
  var i = 0;

  Never fail(int line, String message) =>
      throw GoldenFormatException(path, line, message);

  int? pageWidth;
  if (i < lines.length && lines[i].contains('|')) {
    pageWidth = lines[i].indexOf('|');
    i++;
  }

  var fileOptions = GoldenOptions();
  if (i < lines.length &&
      !lines[i].startsWith('###') &&
      !lines[i].startsWith('>>>')) {
    final (options, rest) = parseOptions(
      lines[i],
      () => fail(i + 1, 'Malformed file options.'),
    );
    if (rest.trim().isNotEmpty) {
      fail(i + 1, 'Unexpected text in file options: "$rest".');
    }
    fileOptions = options;
    i++;
  }

  void skipComments() {
    while (i < lines.length && lines[i].startsWith('###')) {
      i++;
    }
  }

  skipComments();
  final cases = <GoldenCase>[];
  while (i < lines.length) {
    final headerLine = i + 1;
    if (!lines[i].startsWith('>>>')) {
      fail(headerLine, 'Expected ">>>", got "${lines[i]}".');
    }
    final (options, description) = parseOptions(
      lines[i++].substring(3),
      () => fail(headerLine, 'Malformed options.'),
    );
    skipComments();

    final input = StringBuffer();
    while (i < lines.length && !lines[i].startsWith('<<<')) {
      input.writeln(lines[i++]);
    }

    final sections = <(int, int, String, String)>[];
    String? unversioned;
    while (i < lines.length && lines[i].startsWith('<<<')) {
      final match = _outputHeader.firstMatch(lines[i++])!;
      skipComments();
      final output = StringBuffer();
      while (i < lines.length &&
          !lines[i].startsWith('>>>') &&
          !lines[i].startsWith('<<<')) {
        output.writeln(lines[i++]);
      }
      var text = output.toString();
      if (!isUnit && text.endsWith('\n')) {
        text = text.substring(0, text.length - 1);
      }
      text = _unescape(text);
      if (match[1] == null) {
        if (unversioned != null)
          fail(headerLine, 'Several unversioned outputs.');
        unversioned = text;
      } else {
        sections.add((
          int.parse(match[1]!),
          int.parse(match[2]!),
          match[3]!,
          text,
        ));
      }
    }

    String? expected;
    if (sections.isNotEmpty) {
      sections.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
      final newest = sections.last;
      expected = newest.$3.contains('(unsupported)') ? null : newest.$4;
    } else if (unversioned != null) {
      expected = unversioned;
    } else {
      fail(headerLine, 'Case has no output section.');
    }

    cases.add(
      GoldenCase(
        line: headerLine,
        description: description.trim(),
        options: options,
        input: _unescape(input.toString()),
        expected: expected,
      ),
    );
  }

  return GoldenFile(path, pageWidth, fileOptions, cases);
}

String _unescape(String text) => text.replaceAllMapped(
  _unicodeEscape,
  (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
);

const _legacyOptions = {'indent', 'experiment', 'trailing_commas'};

/// Parses leading parenthesized option groups off [line]. A group is options
/// if it is a legacy form (`indent 4`, `experiment x`, `trailing_commas
/// preserve`) or made only of `key=value` tokens; otherwise it and the rest of
/// the line are the description.
(GoldenOptions, String) parseOptions(String line, Never Function() malformed) {
  final options = GoldenOptions();
  var pos = 0;
  while (true) {
    while (pos < line.length && line[pos] == ' ') {
      pos++;
    }
    if (pos >= line.length || line[pos] != '(') break;
    final close = _matchingParen(line, pos);
    if (close < 0) break;
    final tokens = _tokenize(line.substring(pos + 1, close));
    if (tokens.length == 2 &&
        _legacyOptions.contains(tokens[0]) &&
        !tokens[1].contains('=')) {
      switch (tokens) {
        case ['indent', final n]:
          options.leadingIndent = int.tryParse(n) ?? malformed();
        case ['experiment', final name]:
          options.experiments.add(name);
        case ['trailing_commas', 'preserve']:
          options.config['trailing_commas'] = 'preserve';
          options.config['wrap.chop_on_trailing_comma'] = true;
        default:
          malformed();
      }
    } else if (tokens.isNotEmpty && tokens.every((t) => t.contains('='))) {
      for (final token in tokens) {
        final eq = token.indexOf('=');
        final key = token.substring(0, eq);
        if (key.isEmpty) malformed();
        options.config[key] = _plain(loadYaml(token.substring(eq + 1)));
      }
    } else {
      break;
    }
    pos = close + 1;
  }
  return (options, line.substring(pos));
}

Object? _plain(Object? yaml) => switch (yaml) {
  YamlList() => [for (final item in yaml) _plain(item)],
  YamlMap() => {for (final e in yaml.entries) '${e.key}': _plain(e.value)},
  _ => yaml,
};

/// Index of the `)` closing the `(` at [open], skipping quotes and brackets.
int _matchingParen(String s, int open) {
  var depth = 0;
  String? quote;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (quote != null) {
      if (c == quote) quote = null;
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '(' || c == '[') {
      depth++;
    } else if (c == ')' || c == ']') {
      depth--;
      if (depth == 0) return c == ')' ? i : -1;
    }
  }
  return -1;
}

/// Splits on spaces outside quotes and brackets.
List<String> _tokenize(String s) {
  final tokens = <String>[];
  final current = StringBuffer();
  var depth = 0;
  String? quote;
  for (final c in s.split('')) {
    if (quote != null) {
      if (c == quote) quote = null;
    } else if (c == '"' || c == "'") {
      quote = c;
    } else if (c == '[') {
      depth++;
    } else if (c == ']') {
      depth--;
    } else if (c == ' ' && depth == 0) {
      if (current.isNotEmpty) tokens.add(current.toString());
      current.clear();
      continue;
    }
    current.write(c);
  }
  if (current.isNotEmpty) tokens.add(current.toString());
  return tokens;
}
