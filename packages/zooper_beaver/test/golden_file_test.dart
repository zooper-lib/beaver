import 'dart:io';

import 'package:test/test.dart';

import 'src/golden_file.dart';

void main() {
  test('every dart_style tall file parses', () {
    final files = Directory('test/golden/dart_style/tall')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.stmt') || f.path.endsWith('.unit'))
        .toList();
    expect(files, isNotEmpty);
    var cases = 0;
    for (final file in files) {
      cases += parseGoldenFile(file.path, file.readAsStringSync()).cases.length;
    }
    expect(cases, greaterThan(3000));
  });

  test('width header, file options, comments, cases', () {
    final file = parseGoldenFile('a.stmt', '''
40 columns                              |
(indent 2)
### A comment.
>>> (wrap.arguments=chop_always trailing_commas=remove) Override.
foo(a,b);
<<<
foo(
  a,
  b
);
>>> Plain.
a=b;
<<< 3.7
a = b;
<<< 3.10 Newer.
a  =  b;
''');
    expect(file.pageWidth, 40);
    expect(file.options.leadingIndent, 2);
    expect(file.cases, hasLength(2));
    final first = file.cases.first;
    expect(first.description, 'Override.');
    expect(first.options.config, {
      'wrap.arguments': 'chop_always',
      'trailing_commas': 'remove',
    });
    expect(first.input, 'foo(a,b);\n');
    expect(first.expected, 'foo(\n  a,\n  b\n);');
    expect(file.cases.last.expected, 'a  =  b;', reason: 'newest version wins');
  });

  group('options', () {
    Never malformed() => throw const FormatException('malformed');
    (Map<String, Object?>, String) config(String line) {
      final (options, rest) = parseOptions(line, malformed);
      return (options.config, rest);
    }

    test('list value', () {
      expect(config(' (wrap.chop_on_named_arguments=[child,children]) d').$1, {
        'wrap.chop_on_named_arguments': ['child', 'children'],
      });
    });

    test('quoted value with spaces', () {
      expect(config(" (a.b='x y' c=3) d").$1, {'a.b': 'x y', 'c': 3});
    });

    test('scalar types', () {
      expect(config(' (a=true b=80 c=never)').$1, {
        'a': true,
        'b': 80,
        'c': 'never',
      });
    });

    test('legacy forms', () {
      final (options, rest) = parseOptions(
        ' (indent 4) (experiment macros) (trailing_commas preserve) Desc.',
        malformed,
      );
      expect(options.leadingIndent, 4);
      expect(options.experiments, ['macros']);
      expect(options.config, {
        'trailing_commas': 'preserve',
        'wrap.chop_on_trailing_comma': true,
      });
      expect(rest.trim(), 'Desc.');
    });

    test('parenthesized prose is description', () {
      final (cfg, rest) = config(' (note: output is weird) x');
      expect(cfg, isEmpty);
      expect(rest.trim(), '(note: output is weird) x');
    });

    test('malformed legacy option fails', () {
      expect(() => config(' (indent four)'), throwsFormatException);
    });
  });

  test('selection markers and unsupported sections', () {
    final file = parseGoldenFile('s.stmt', '''
>>>
‹123›45;
<<<
‹123›45;
>>>
old;
<<< 3.7
old;
<<< 3.13 (unsupported)
''');
    expect(file.cases.first.hasSelectionMarkers, isTrue);
    expect(file.cases.last.expected, isNull);
  });
}
