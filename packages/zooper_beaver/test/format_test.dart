import 'package:test/test.dart';
import 'package:zooper_beaver/src/format.dart';

void main() {
  test('a statement formats without wrapper text', () {
    expect(formatStatement('a=b;'), 'a = b;\n');
    expect(formatStatement('a=b=c;'), 'a = b = c;\n');
  });

  test('a compilation unit formats', () {
    expect(format('var a=b;'), 'var a = b;\n');
  });
}
