import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/loader.dart';
import 'package:zooper_beaver/src/verify/verification_failure.dart';

import 'src/golden_file.dart';
import 'src/golden_runner.dart';

void main() {
  final file = parseGoldenFile('sample.stmt', '''
>>> Passes.
a=b;
<<<
a = b;
>>> Fails.
a=c;
<<<
a = b;
''');

  String spaced(GoldenFile f, GoldenCase c, String input) =>
      input.trim().replaceAll(RegExp(r'\s*=\s*'), ' = ');

  test('a matching case passes and a differing one mismatches', () {
    expect(
      runCase(file, file.cases[0], formatter: spaced).outcome,
      Outcome.match,
    );
    expect(
      runCase(file, file.cases[1], formatter: spaced).outcome,
      Outcome.mismatch,
    );
  });

  test('verification failure and non-idempotence are safety failures', () {
    expect(
      runCase(
        file,
        file.cases[0],
        formatter: (_, _, _) => throw const VerificationFailure('tokens', 'x'),
      ).outcome,
      Outcome.safetyFailure,
    );
    var calls = 0;
    expect(
      runCase(
        file,
        file.cases[0],
        formatter: (_, _, _) => 'a = b;${'!' * calls++}',
      ).outcome,
      Outcome.safetyFailure,
    );
  });

  group('options', () {
    String run(String contents, int index) {
      final file = loadGoldenFile('t.stmt', contents);
      return formatCase(file, file.cases[index], file.cases[index].input);
    }

    test('case-level override', () {
      const contents = '''
>>> (wrap.arguments=chop_always)
f(a, b);
<<<
x
''';
      expect(run(contents, 0), 'f(\n  a,\n  b,\n);');
    });

    test('list value', () {
      const contents = '''
>>> (wrap.chop_on_named_arguments=[child,children])
Padding(child: x);
<<<
x
''';
      expect(run(contents, 0), 'Padding(\n  child: x,\n);');
    });

    test('file options apply to every case and cases are isolated', () {
      const contents = '''
(wrap.arguments=chop_always)
>>> (wrap.arguments=chop_if_long)
f(a, b);
<<<
x
>>>
f(a, b);
<<<
x
''';
      expect(run(contents, 0), 'f(a, b);');
      expect(run(contents, 1), 'f(\n  a,\n  b,\n);');
    });

    test('an unknown option fails with file and case', () {
      expect(
        () => loadGoldenFile(
          't.stmt',
          '>>> (wrap.argumnets=never) Desc.\nf();\n<<<\nf();\n',
        ),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('t.stmt'),
              contains('Desc.'),
              contains('wrap.argumnets'),
            ),
          ),
        ),
      );
    });
  });
}
