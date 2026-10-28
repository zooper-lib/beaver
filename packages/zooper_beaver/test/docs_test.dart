/// Every example in the rule and directive docs is a golden test case.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _block = RegExp(r'```dart\n(.*?)\n```', dotAll: true);

void main() {
  final golden = [
    for (final f in Directory('test/golden').listSync(recursive: true))
      if (f is File && !p.isWithin('test/golden/dart_style', f.path))
        f.readAsStringSync(),
  ].join('\n');

  final docs = [
    ...Directory('../../docs/rules').listSync().whereType<File>(),
    File('../../docs/directives.md'),
  ];
  for (final doc in docs) {
    test(p.basename(doc.path), () {
      final examples = _block.allMatches(doc.readAsStringSync()).toList();
      expect(examples, isNotEmpty);
      for (final example in examples) {
        expect(golden, contains(example[1]!), reason: example[1]);
      }
    });
  }
}
