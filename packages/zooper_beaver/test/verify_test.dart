import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/format.dart';
import 'package:zooper_beaver/src/parse/parse.dart';
import 'package:zooper_beaver/src/verify/verify.dart';

void check(
  String input,
  String output, {
  BeaverConfig? config,
  List<(int, int)> regions = const [],
}) => verify(
  parse(input),
  output,
  config: config ?? BeaverConfig.dart,
  regions: regions,
);

Matcher failsAt(String stage) =>
    throwsA(isA<VerificationFailure>().having((f) => f.stage, 'stage', stage));

void main() {
  group('tokens', () {
    test('whitespace-only change passes', () {
      check('var x=f(a,b);', 'var x = f(a, b);\n');
    });

    test('optional trailing comma added passes', () {
      check('var x = f(a, b);', 'var x = f(\n  a,\n  b,\n);\n');
      check('var x = [a, b];', 'var x = [a, b,];\n');
    });

    test('required record comma removed fails', () {
      expect(() => check('var r = (42,);', 'var r = (42);'), failsAt('tokens'));
    });

    test('record pattern comma removed fails', () {
      expect(
        () => check(
          'void f(r) { final (v,) = r; }',
          'void f(r) { final (v) = r; }',
        ),
        failsAt('tokens'),
      );
    });

    test('reordered arguments fail', () {
      expect(() => check('f(a, b);'.wrap, 'f(b, a);'.wrap), failsAt('tokens'));
    });

    test('quote change passes when quotes may change', () {
      final single = BeaverConfig.dart.merge({'strings.quotes': 'single'});
      check('var s = "x";', "var s = 'x';", config: single);
      expect(() => check('var s = "x";', "var s = 'x';"), failsAt('tokens'));
    });

    test('string content change fails', () {
      final single = BeaverConfig.dart.merge({'strings.quotes': 'single'});
      expect(
        () => check("var s = 'a';", "var s = 'b';", config: single),
        failsAt('tokens'),
      );
    });

    test('unparseable output fails', () {
      expect(() => check('var x = 1;', 'var x = ;'), failsAt('parse'));
    });
  });

  group('fingerprint', () {
    test('identical programs pass', () {
      check('void f() { return; }', 'void f() {\n  return;\n}\n');
    });

    test('a statement wrapped in a block fails', () {
      expect(
        () => check(
          'void f(x) { if (x) return; }',
          'void f(x) { if (x) { return; } }',
        ),
        throwsA(isA<VerificationFailure>()),
      );
    });
  });

  group('comments', () {
    test('doc comment moved to another declaration fails', () {
      // Doc comments are AST nodes, so the fingerprint catches this first.
      expect(
        () => check(
          '/// A.\nclass A {}\nclass B {}',
          'class A {}\n/// A.\nclass B {}',
        ),
        throwsA(isA<VerificationFailure>()),
      );
    });

    test('line comment moved to another statement fails', () {
      expect(
        () =>
            check('var a = 1; // c\nvar b = 2;', 'var a = 1;\nvar b = 2; // c'),
        failsAt('comments'),
      );
    });

    test('dropped comment fails', () {
      expect(() => check('var a = 1; // c', 'var a = 1;'), failsAt('comments'));
    });

    test('comment moved across a removed optional comma passes', () {
      check('var x = [a, /* c */];', 'var x = [a /* c */];');
    });
  });

  group('regions', () {
    test('altered byte in an ignored region fails', () {
      const input = 'var m = [1,  0];';
      expect(
        () => check(input, 'var m = [1, 0];', regions: [(8, 16)]),
        failsAt('regions'),
      );
      check(input, 'var m = [1,  0];\n', regions: [(8, 16)]);
    });
  });

  group('pipeline', () {
    tearDown(() => debugCorruptOutput = null);

    test('an injected defect is caught and no text is returned', () {
      debugCorruptOutput = (s) => s.replaceFirst('b', 'c');
      expect(() => format('var a = b;'), failsAt('tokens'));
      expect(() => formatStatement('a = b;'), failsAt('tokens'));
    });
  });
}

extension on String {
  String get wrap => 'void g() { $this }';
}
