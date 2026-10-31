import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/format.dart';

void main() {
  test('a statement formats without wrapper text', () {
    expect(formatStatement('a=b;'), 'a = b;\n');
    expect(formatStatement('a=b=c;'), 'a = b = c;\n');
  });

  test('a compilation unit formats', () {
    expect(format('var a=b;'), 'var a = b;\n');
  });

  group('line endings', () {
    String run(String source, String setting) => format(
      source,
      config: BeaverConfig.dart.merge({'line_ending': setting}),
    );

    test('auto follows CRLF input', () {
      expect(
        run('var a=1;\r\nvar b=2;\r\n', 'auto'),
        'var a = 1;\r\nvar b = 2;\r\n',
      );
    });

    test('auto keeps LF input', () {
      expect(run('var a=1;\nvar b=2;\n', 'auto'), 'var a = 1;\nvar b = 2;\n');
    });

    test('pinned LF', () {
      expect(run('var a=1;\r\nvar b=2;\r\n', 'lf'), 'var a = 1;\nvar b = 2;\n');
    });

    test('pinned CRLF', () {
      expect(
        run('var a=1;\nvar b=2;\n', 'crlf'),
        'var a = 1;\r\nvar b = 2;\r\n',
      );
    });
  });
}
