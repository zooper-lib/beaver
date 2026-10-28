import 'package:test/test.dart';
import 'package:zooper_beaver/src/parse/parse.dart';

void main() {
  test('syntax error becomes a structured ParseFailure', () {
    expect(
      () => parse('void main() {\n  foo(;\n}\n'),
      throwsA(
        isA<ParseFailure>().having((f) => f.errors.first.line, 'line', 2),
      ),
    );
  });

  test('offset conversion on LF input', () {
    final parsed = parse('var a = 1;\nvar b = 2;\n');
    expect(parsed.offsetOf(2, 5), 15);
    expect(parsed.positionOf(15), (2, 5));
    expect(parsed.offsetOf(3, 1), parsed.source.length);
    expect(() => parsed.offsetOf(1, 12), throwsRangeError);
    expect(() => parsed.offsetOf(4, 1), throwsRangeError);
  });

  test('offset conversion on CRLF input', () {
    final parsed = parse('var a = 1;\r\nvar b = 2;\r\n');
    expect(parsed.offsetOf(2, 1), 12);
    expect(parsed.positionOf(12), (2, 1));
    // End of line 1 is before the \r, not on it.
    expect(parsed.offsetOf(1, 11), 10);
    expect(() => parsed.offsetOf(1, 12), throwsRangeError);
  });

  test('UTF-16 columns and surrogate pairs on non-BMP input', () {
    final parsed = parse("var s = '😀x';\n");
    // 😀 is two code units at columns 10 and 11.
    expect(parsed.offsetOf(1, 10), 9);
    expect(() => parsed.offsetOf(1, 11), throwsRangeError);
    expect(parsed.offsetOf(1, 12), 11);
    expect(parsed.positionOf(11), (1, 12));
  });
}
