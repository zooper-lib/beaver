import 'dart:io';

import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/config/schema.dart';

void main() {
  test('the rule showcase index lists every key', () {
    final index = File('../../example/README.md').readAsStringSync();
    for (final key in schema.keys) {
      expect(index, contains('`$key`'), reason: key);
    }
  });

  test('dart preset defines every key with valid values', () {
    final values = BeaverConfig.dart.values;
    expect(values.keys.toSet(), schema.keys.toSet());
    for (final MapEntry(:key, :value) in values.entries) {
      expect(schema[key]!.accepts(value), isTrue, reason: key);
    }
    final dart = BeaverConfig.dart;
    expect(dart.lineLength, 80);
    expect(dart.indentSize, 2);
    expect(
      dart.alignArguments || dart.alignParameters || dart.alignChainedCalls,
      isFalse,
    );
    expect(dart.chopOnNamedArguments, isEmpty);
    expect(dart.trailingCommas, TrailingCommas.addWhenWrapped);
    expect(dart.chopOnTrailingComma, isTrue);
    expect(dart.quotes, Quotes.preserve);
    expect(
      dart.exclude,
      containsAll(['**/*.g.dart', '**/*.freezed.dart', 'build/**']),
    );
  });
}
