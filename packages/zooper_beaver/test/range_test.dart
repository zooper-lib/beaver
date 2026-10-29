import 'package:test/test.dart';
import 'package:zooper_beaver/src/parse/parse.dart';
import 'package:zooper_beaver/src/range/range.dart';

/// Formats [source] for the range `l1:c1-l2:c2`.
String fmt(String source, String range) =>
    formatRange(source, parseRange(range));

const klass = '''
class A {
  void one() {
    var  a=1;
    var  b=2;
    var  c=3;
  }

  void two() {
    call( x,y );
  }

  void three() {
    var  d=4;
  }
}
''';

void main() {
  group('range syntax', () {
    test('valid range', () {
      expect(parseRange('3:5-5:11'), ((3, 5), (5, 11)));
    });

    test('malformed and reversed ranges are usage errors', () {
      expect(() => parseRange('3:5'), throwsA(isA<RangeException>()));
      expect(() => fmt(klass, '5:1-3:1'), throwsA(isA<RangeException>()));
      expect(() => fmt(klass, '99:1-99:2'), throwsA(isA<RangeException>()));
    });

    test('CRLF positions resolve to the characters an editor shows', () {
      final crlf = klass.replaceAll('\n', '\r\n');
      final out = fmt(crlf, '4:5-4:6');
      expect(out, crlf.replaceFirst('var  b=2;', 'var b = 2;'));
    });

    test('a position splitting a surrogate pair is rejected', () {
      expect(
        () => fmt("var s = '😀';\n", '1:11-1:11'),
        throwsA(isA<RangeException>()),
      );
    });
  });

  group('expansion ladder', () {
    test('selection inside a method body formats exactly those statements', () {
      final out = fmt(klass, '3:8-4:8');
      expect(
        out,
        klass
            .replaceFirst('var  a=1;', 'var a = 1;')
            .replaceFirst('var  b=2;', 'var b = 2;'),
      );
    });

    test('selection inside an argument formats the enclosing statement', () {
      final out = fmt(klass, '9:11-9:12');
      expect(out, klass.replaceFirst('call( x,y );', 'call(x, y);'));
    });

    test('selection spanning two members formats both', () {
      final out = fmt(klass, '4:5-9:5');
      expect(out, contains('void one() {\n    var a = 1;'));
      expect(out, contains('call(x, y);'));
      expect(out, contains('var  d=4;'), reason: 'third method untouched');
    });

    test('cursor inside a statement formats it', () {
      expect(
        fmt(klass, '5:7-5:7'),
        klass.replaceFirst('var  c=3;', 'var c = 3;'),
      );
    });

    test('cursor on a blank line leaves the document unchanged', () {
      expect(fmt(klass, '7:1-7:1'), klass);
    });
  });

  group('formatRange', () {
    test('an unformatted neighbour is untouched', () {
      final out = fmt(klass, '3:5-3:6');
      expect(out, contains('var a = 1;'));
      expect(out, contains('var  b=2;'));
    });

    test('a syntax error outside the range still rejects the document', () {
      expect(
        () => fmt('var a=1;\nvar = ;\n', '1:1-1:2'),
        throwsA(isA<ParseFailure>()),
      );
    });

    test('an ignored region inside the range is unchanged', () {
      const source = '''
void f() {
  call(a+b, // beaver-ignore-start
    c  +  d); // beaver-ignore-end
}
''';
      final out = fmt(source, '2:3-3:5');
      expect(out, contains('    c  +  d); // beaver-ignore-end'));
      expect(out, contains('a + b,'));
    });
  });
}
