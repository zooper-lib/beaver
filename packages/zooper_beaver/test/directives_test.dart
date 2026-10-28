import 'package:test/test.dart';
import 'package:zooper_beaver/src/comments/attach.dart';
import 'package:zooper_beaver/src/directives/directives.dart';
import 'package:zooper_beaver/src/format.dart';
import 'package:zooper_beaver/src/parse/parse.dart';

Directives directives(String source) {
  final parsed = parse(source);
  return findDirectives(attachComments(parsed.unit, source), parsed);
}

Matcher rejected(String text) => throwsA(
  isA<DirectiveException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('exact forms only', () {
    expect(directiveOf('// beaver-ignore'), DirectiveKind.ignore);
    expect(directiveOf('// beaver-ignore-start'), DirectiveKind.start);
    expect(directiveOf('// beaver-ignore-end'), DirectiveKind.end);
    expect(directiveOf('// dart format off'), DirectiveKind.start);
    expect(directiveOf('// dart format on'), DirectiveKind.end);
    expect(directiveOf('// beaver-ignore please'), isNull);
    expect(directiveOf('//beaver-ignore'), isNull);
  });

  test('alias pair makes a region between the comments', () {
    const source = 'var a;\n// dart format off\nvar  b;\n// dart format on\n';
    final start = source.indexOf('off') + 3;
    final end = source.indexOf('// dart format on');
    expect(directives(source).regions, [(start, end)]);
  });

  test('nested start is rejected naming both lines', () {
    expect(
      () => directives(
        '// beaver-ignore-start\nvar a;\n// beaver-ignore-start\nvar b;\n',
      ),
      rejected('line 1'),
    );
    expect(
      () => directives(
        '// beaver-ignore-start\nvar a;\n// beaver-ignore-start\nvar b;\n',
      ),
      rejected('line 3'),
    );
  });

  test('stray end is rejected', () {
    expect(
      () => directives('var a;\n// beaver-ignore-end\n'),
      rejected('line 2'),
    );
  });

  test('unterminated start runs to end of file', () {
    const source = 'var a;\n// beaver-ignore-start\nvar  b;\n';
    expect(directives(source).regions, [
      (source.indexOf('start') + 5, source.length),
    ]);
  });

  test('a syntax error inside a region still rejects the file', () {
    expect(
      () => format('// beaver-ignore-start\nvar = ;\n// beaver-ignore-end\n'),
      throwsA(isA<ParseFailure>()),
    );
  });
}
