import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/loader.dart';
import 'package:zooper_beaver/src/config/resolve.dart';

String? read(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : null;
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('beaver_config'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String write(String relative, String contents) {
    final file = File(p.join(tmp.path, relative))
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
    return file.path;
  }

  ResolvedConfig resolve(String relative, {String? explicit}) =>
      resolveConfig(p.join(tmp.path, relative), read: read, explicit: explicit);

  Matcher configError(String text) => throwsA(
    isA<ConfigException>().having((e) => e.message, 'message', contains(text)),
  );

  group('validation', () {
    test('misspelled key names file, key and the known keys', () {
      expect(
        () => parseConfigFile('line_lenght: 100', '/x/.beaver.yaml'),
        configError('/x/.beaver.yaml: unknown key `line_lenght`'),
      );
      expect(
        () => parseConfigFile('line_lenght: 100', '/x/.beaver.yaml'),
        configError('line_length'),
      );
    });

    test('invalid value names the allowed values', () {
      expect(
        () => parseConfigFile('wrap:\n  arguments: sometimes', 'f'),
        configError(
          '`wrap.arguments`; allowed: never | if_long | chop_if_long | chop_always',
        ),
      );
    });

    test('wrong type', () {
      expect(
        () => parseConfigFile('line_length: wide', 'f'),
        configError('line_length'),
      );
    });

    test('remove + chop_on_trailing_comma without kept breaks is rejected', () {
      write(
        'p/.beaver.yaml',
        'trailing_commas: remove\n'
            'wrap:\n  keep_existing_line_breaks: false\n',
      );
      expect(
        () => resolve('p/a.dart'),
        configError(
          'wrap.chop_on_trailing_comma: true (preset dart), '
          'wrap.keep_existing_line_breaks: false (${tmp.path}/p/.beaver.yaml)',
        ),
      );
      write(
        'p/.beaver.yaml',
        'trailing_commas: remove\n'
            'wrap:\n  keep_existing_line_breaks: false\n'
            '  chop_on_trailing_comma: false\n',
      );
      expect(resolve('p/a.dart').config.trailingCommas, isNotNull);
    });
  });

  group('discovery and inheritance', () {
    test('no file means the dart preset', () {
      final r = resolve('lib/a.dart');
      expect(r.config.lineLength, 80);
      expect(r.chain, ['preset dart']);
    });

    test('nested project file shadows the root file', () {
      write('.beaver.yaml', 'line_length: 120');
      final app = write('packages/app/.beaver.yaml', 'indent:\n  size: 4');
      final r = resolve('packages/app/lib/a.dart');
      expect(r.config.indentSize, 4);
      expect(r.config.lineLength, 80, reason: 'root file is not read');
      expect(r.chain, [app, 'preset dart']);
    });

    test('extending a team file, with key-by-key map merge', () {
      final team = write(
        'config/team.beaver.yaml',
        'line_length: 100\nindent:\n  size: 2\n  continuation: 4',
      );
      final app = write(
        'packages/app/.beaver.yaml',
        'extends: ../../config/team.beaver.yaml\nindent:\n  continuation: 2',
      );
      final r = resolve('packages/app/lib/a.dart');
      expect(r.config.lineLength, 100);
      expect(r.config.indentSize, 2);
      expect(r.config.continuationIndent, 2);
      expect(r.provenance['line_length'], team);
      expect(r.provenance['indent.continuation'], app);
      expect(r.provenance['indent.style'], 'preset dart');
    });

    test('cycle is a configuration error naming both files', () {
      write('a.beaver.yaml', 'extends: b.beaver.yaml');
      write('b.beaver.yaml', 'extends: a.beaver.yaml');
      write('.beaver.yaml', 'extends: a.beaver.yaml');
      expect(() => resolve('x.dart'), configError('a.beaver.yaml'));
      expect(() => resolve('x.dart'), configError('cycle'));
    });

    test('unknown preset is a configuration error', () {
      write('.beaver.yaml', 'extends: compact');
      expect(() => resolve('x.dart'), configError('extends: compact'));
    });

    test('exclusions concatenate along the chain', () {
      write('.beaver.yaml', 'exclude: ["**/*.pb.dart"]');
      final r = resolve('lib/a.dart');
      expect(r.config.exclude, containsAll(['**/*.g.dart', '**/*.pb.dart']));
    });

    test('--config skips discovery', () {
      write('.beaver.yaml', 'line_length: 120');
      final other = write('other.yaml', 'line_length: 90');
      expect(resolve('lib/a.dart', explicit: other).config.lineLength, 90);
    });
  });

  group('effective root and exclusion', () {
    test(
      'inherited pattern anchors at the project, not the declaring file',
      () {
        write('config/shared.beaver.yaml', 'exclude: ["lib/gen/**"]');
        write(
          'packages/app/.beaver.yaml',
          'extends: ../../config/shared.beaver.yaml',
        );
        final file = p.join(tmp.path, 'packages/app/lib/gen/x.dart');
        final r = resolveConfig(file, read: read);
        expect(r.root, p.join(tmp.path, 'packages/app'));
        expect(r.excludedBy(file), 'lib/gen/**');
        expect(
          r.excludedBy(p.join(tmp.path, 'packages/app/lib/x.dart')),
          isNull,
        );
      },
    );

    test('root falls back to the pubspec directory, never the cwd', () {
      write('pkg/pubspec.yaml', 'name: pkg');
      final file = p.join(tmp.path, 'pkg/lib/src/a.g.dart');
      final before = Directory.current;
      final rootA = resolveConfig(file, read: read).root;
      Directory.current = tmp;
      final rootB = resolveConfig(file, read: read).root;
      Directory.current = before;
      expect(rootA, p.join(tmp.path, 'pkg'));
      expect(rootB, rootA);
      expect(resolveConfig(file, read: read).excludedBy(file), '**/*.g.dart');
    });

    test('glob matching is case-sensitive', () {
      write('.beaver.yaml', 'exclude: ["**/*.G.dart"]');
      final file = p.join(tmp.path, 'lib/a.g.dart');
      final r = resolveConfig(file, read: read);
      // The preset's lower-case pattern still matches; the custom one alone
      // would not.
      expect(r.excludedBy(file), '**/*.g.dart');
      expect(r.excludedBy(p.join(tmp.path, 'lib/a.G.dart')), '**/*.G.dart');
      expect(r.excludedBy(p.join(tmp.path, 'lib/b.dart')), isNull);
    });

    test('.dart_tool is never formattable', () {
      write('.beaver.yaml', '');
      final file = p.join(tmp.path, '.dart_tool/build/x.dart');
      expect(resolveConfig(file, read: read).excludedBy(file), 'protected');
    });
  });
}
