/// The rule showcase in `example/` is real formatter output: every
/// `<key>/<value>/after.dart` is `<key>/before.dart` formatted with that
/// folder's `.beaver.yaml`, and every configuration key has a folder.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zooper_beaver/beaver.dart';
import 'package:zooper_beaver/src/config/resolve.dart';
import 'package:zooper_beaver/src/config/schema.dart';

const _example = '../../example';

String? _read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

void main() {
  test('every configuration key has a folder', () {
    for (final key in schema.keys) {
      expect(
        Directory(p.join(_example, key)).existsSync(),
        isTrue,
        reason: key,
      );
    }
  });

  test('inputs are excluded from formatting', () {
    for (final key in schema.keys) {
      final before = p.join(_example, key, 'before.dart');
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
