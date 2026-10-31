import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/config/schema.dart';

void main() {
  test('dart preset defines every key with valid values', () {
    final settings = BeaverConfig.dart.settings;
    expect(settings.keys.toSet(), schema.keys.toSet());
    for (final MapEntry(:key, :value) in settings.entries) {
      expect(schema[key]!.accepts(value), isTrue, reason: key);
    }
    final dart = BeaverConfig.dart;
    expect(dart.lineLength, 80);
    expect(dart.indentSize, 2);
    expect(
      [dart.arguments, dart.parameters, dart.chainedCalls].map((l) => l.indent),
      everyElement(isA<Inherit>()),
    );
    expect(dart.initializerLists.indent, isA<FirstItem>());
    expect(dart.switchExpressions.policy, WrapPolicy.chopIfLong);
    expect(dart.switchExpressions.chopFrom, 1);
    expect(
      dart.arguments.breakAfterOpen && dart.arguments.breakBeforeClose,
      isTrue,
    );
    expect(dart.chopOnNamedArguments, isEmpty);
    expect(dart.arguments.trailingCommas, TrailingCommas.addWhenWrapped);
    expect(dart.arguments.chopOnTrailingComma, isTrue);
    expect(dart.quotes, Quotes.preserve);
    expect(
      dart.exclude,
      containsAll(['**/*.g.dart', '**/*.freezed.dart', 'build/**']),
    );
  });

  test('no key is both a leaf and a prefix', () {
    for (final key in schema.keys) {
      expect(
        schema.keys.where((other) => other.startsWith('$key.')),
        isEmpty,
        reason: key,
      );
    }
  });

  test('every inheriting key has a fallback that ends at a plain key', () {
    for (final MapEntry(:key, value: type) in schema.entries) {
      expect(
        type is InheritOr,
        fallbacks.containsKey(key),
        reason: '$key accepts inherit exactly when it has a fallback',
      );
      final seen = {key};
      var current = key;
      for (
        var next = fallbacks[current];
        next != null;
        next = fallbacks[next]
      ) {
        expect(seen.add(next), isTrue, reason: 'cycle through $next');
        expect(schema, contains(next), reason: next);
        current = next;
      }
      expect(schema[current], isNot(isA<InheritOr>()), reason: current);
    }
  });

  test('the preset resolves every inherit', () {
    expect(BeaverConfig.dart.values.values, isNot(contains('inherit')));
  });

  test('no align, close_bracket or keep_single_line_if_fits key', () {
    expect(
      schema.keys.where(
        (k) =>
            k.endsWith('.align') ||
            k.contains('close_bracket') && !k.contains('break_before') ||
            k.endsWith('keep_single_line_if_fits'),
      ),
      isEmpty,
    );
  });

  group('value types', () {
    test('IndentType', () {
      const type = InheritOr(IndentType());
      expect(type.accepts('first_item'), isTrue);
      expect(type.accepts(4), isTrue);
      expect(type.accepts(-1), isFalse);
      expect(type.describe(), 'inherit | an integer >= 0 | first_item');
    });

    test('ReceiverKindListType', () {
      const type = ReceiverKindListType();
      expect(type.accepts(['type_names', 'calls']), isTrue);
      expect(type.accepts(true), isTrue);
      expect(type.accepts(['classes']), isFalse);
    });

    test('InheritOr', () {
      const type = InheritOr(BoolType());
      expect(type.accepts('inherit'), isTrue);
      expect(type.accepts(false), isTrue);
      expect(type.accepts('yes'), isFalse);
      expect(type.describe(), 'inherit | true | false');
    });

    test('IntOrPreserveType', () {
      const type = IntOrPreserveType();
      expect(type.accepts('preserve'), isTrue);
      expect(type.accepts(0), isTrue);
      expect(type.accepts(2), isTrue);
      expect(type.accepts(-1), isFalse);
      expect(type.accepts('some'), isFalse);
      expect(type.describe(), 'preserve | an integer >= 0');
    });

    test('DottedNameListType', () {
      const type = DottedNameListType();
      expect(type.accepts(<Object?>[]), isTrue);
      expect(
        type.accepts(['Row', 'Row.center', r'm.$Row', '_Private']),
        isTrue,
      );
      for (final bad in ['Row*', 'Row..center', '.Row', 'Row.', '', '1Row']) {
        expect(type.accepts([bad]), isFalse, reason: bad);
      }
      expect(type.accepts('Row'), isFalse);
    });

    test('IntType minimum', () {
      const type = IntType(min: 1);
      expect(type.accepts(1), isTrue);
      expect(type.accepts(0), isFalse);
      expect(type.describe(), 'an integer >= 1');
    });
  });
}
