/// The rule showcase in `example/` is real formatter output: every
/// `<key>/<value>/after.dart` is `<key>/before.dart` formatted with that
/// folder's `.beaver.yaml`, and every configuration key has a folder. A
/// field of a list map without a folder of its own is shown by the list's
/// folder (`wrap.<list>`).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zooper_beaver/zooper_beaver.dart';
import 'package:zooper_beaver/src/config/resolve.dart';
import 'package:zooper_beaver/src/config/schema.dart';

const _example = '../../example';

String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

/// Names that show [key]: its own, and for a list field its list's.
List<String> _names(String key) {
  final [section, name, ...rest] = [...key.split('.'), '', ''];
  final isList =
      section == 'wrap' &&
      rest.first.isNotEmpty &&
      listConstructs.any((list) => list.name == name);
  return [key, if (isList) ...['wrap.$name', 'wrap.$name.policy']];
}

void main() {
  test('every configuration key has a folder', () {
    for (final key in schema.keys) {
      expect(
        _names(key).any((n) => Directory(p.join(_example, n)).existsSync()),
        isTrue,
        reason: key,
      );
    }
  });

  test('the index lists every key', () {
    final index = File(p.join(_example, 'README.md')).readAsStringSync();
    for (final key in schema.keys) {
      expect(
        _names(key).any((n) => index.contains('`$n`')),
        isTrue,
        reason: key,
      );
    }
  });

  test('inputs are excluded from formatting', () {
    for (final key in Directory(_example).listSync().whereType<Directory>()) {
      final before = p.join(key.path, 'before.dart');
      if (!File(before).existsSync()) continue;
      expect(
        resolveConfig(before, read: _read).excludedBy(p.absolute(before)),
        isNotNull,
        reason: before,
      );
    }
  });

  for (final after in Directory(_example).listSync(recursive: true)) {
    if (after is! File || p.basename(after.path) != 'after.dart') continue;
    final folder = p.relative(p.dirname(after.path), from: _example);
    test(folder, () {
      final before = File(p.join(after.parent.parent.path, 'before.dart'));
      final config = resolveConfig(after.path, read: _read).config;
      expect(
        format(before.readAsStringSync(), config: config),
        after.readAsStringSync(),
      );
    });
  }
}
