import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:zooper_beaver/src/cli/cli.dart';
import 'package:zooper_beaver/src/version.dart';

final class _Capture implements StreamConsumer<List<int>> {
  final bytes = <int>[];

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(bytes.addAll);

  @override
  Future<void> close() async {}

  @override
  String toString() => utf8.decode(bytes);
}

typedef Run = ({int code, String out, String err});

Future<Run> beaver(List<String> args, {String? stdin}) async {
  final out = _Capture(), err = _Capture();
  final outSink = IOSink(out), errSink = IOSink(err);
  final code = await runCli(
    args,
    input: stdin == null ? null : Stream.value(utf8.encode(stdin)),
    output: outSink,
    errors: errSink,
  );
  await outSink.close();
  await errSink.close();
  return (code: code, out: '$out', err: '$err');
}

const ugly = 'var  a=1;\n';
const pretty = 'var a = 1;\n';

void main() {
  late Directory tmp;
  late Directory previous;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('beaver_cli');
    previous = Directory.current;
    Directory.current = tmp;
  });
  tearDown(() {
    Directory.current = previous;
    tmp.deleteSync(recursive: true);
  });

  File write(String path, String contents) => File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);

  group('arguments', () {
    test('--help lists every mode', () async {
      final r = await beaver(['--help']);
      expect(r.code, 0);
      for (final mode in [
        '--check',
        '--diff',
        '--stdin',
        '--stdin-name',
        '--range',
        '--config',
        '--verbose',
        '--version',
        'config --print',
        '--for',
        'init',
      ]) {
        expect(r.out, contains(mode));
      }
    });

    test('unknown flag exits 64 before formatting', () async {
      write('a.dart', ugly);
      final r = await beaver(['--frobnicate', 'a.dart']);
      expect(r.code, 64);
      expect(File('a.dart').readAsStringSync(), ugly);
    });

    test('--version prints formatter and protocol version', () async {
      final r = await beaver(['--version']);
      expect(r.out.trim(), 'beaver $beaverVersion (protocol 1)');
      final pubspec =
          loadYaml(
            File(p.join(previous.path, 'pubspec.yaml')).readAsStringSync(),
          ) as YamlMap;
      expect(beaverVersion, pubspec['version']);
    });

    test('--range requires --stdin', () async {
      expect((await beaver(['--range', '1:1-1:2', 'a.dart'])).code, 64);
    });
  });

  group('file selection', () {
    test('overlapping arguments format a file once', () async {
      write('lib/a.dart', ugly);
      final r = await beaver(['--check', 'lib', 'lib/a.dart']);
      expect(r.out, 'lib/a.dart\n');
    });

    test('symlinked directories are not followed', () async {
      write('other/b.dart', ugly);
      write('lib/a.dart', pretty);
      Link('lib/linked').createSync(p.join(tmp.path, 'other'));
      final r = await beaver(['--check', 'lib']);
      expect(r.code, 0);
      expect(r.out, isEmpty);
    });

    test('explicitly named generated file is skipped with exit 0', () async {
      write('pubspec.yaml', 'name: x');
      write('lib/models/user.g.dart', ugly);
      final r = await beaver(['lib/models/user.g.dart']);
      expect(r.code, 0);
      expect(File('lib/models/user.g.dart').readAsStringSync(), ugly);
    });

    test('--verbose reports skips with the pattern on stderr', () async {
      write('pubspec.yaml', 'name: x');
      write('lib/a.g.dart', ugly);
      final r = await beaver(['--verbose', 'lib']);
      expect(r.err, contains('lib/a.g.dart (**/*.g.dart)'));
      expect(r.out, isEmpty);
    });

    test('non-Dart files in directories are ignored', () async {
      write('lib/a.yaml', 'not: dart');
      write('lib/a.dart', pretty);
      expect((await beaver(['lib'])).code, 0);
    });

    test('globs select Dart files', () async {
      write('lib/a.dart', ugly);
      write('lib/b.dart', ugly);
      final r = await beaver(['--check', 'lib/*.dart']);
      expect(r.out, 'lib/a.dart\nlib/b.dart\n');
    });

    test('.dart_tool is never traversed', () async {
      write('.dart_tool/x.dart', ugly);
      expect((await beaver(['--check', '.'])).out, isEmpty);
    });
  });

  group('modes', () {
    test('format in place; formatted files are not rewritten', () async {
      final a = write('a.dart', ugly);
      final b = write('b.dart', pretty);
      final stamp = DateTime(2020);
      b.setLastModifiedSync(stamp);
      expect((await beaver(['.'])).code, 0);
      expect(a.readAsStringSync(), pretty);
      expect(b.lastModifiedSync(), stamp);
    });

    test('--check lists every unformatted file and exits 1', () async {
      for (final name in ['a', 'b', 'c']) {
        write('$name.dart', ugly);
      }
      write('d.dart', pretty);
      final r = await beaver(['--check', '.']);
      expect(r.code, 1);
      expect(r.out, 'a.dart\nb.dart\nc.dart\n');
      expect(File('a.dart').readAsStringSync(), ugly);
    });

    test('--diff prints a unified diff', () async {
      write('a.dart', 'var x = 1;\n$ugly');
      final r = await beaver(['--diff', 'a.dart']);
      expect(r.code, 1);
      expect(
        r.out,
        '--- a.dart\n+++ a.dart\n@@ -1,2 +1,2 @@\n var x = 1;\n-var  a=1;\n+var a = 1;\n',
      );
    });
  });

  group('errors', () {
    test(
      'one unparseable file among many: others formatted, exit 65',
      () async {
        write('a.dart', ugly);
        write('b.dart', 'var = ;\n');
        write('c.dart', ugly);
        final r = await beaver(['.']);
        expect(r.code, 65);
        expect(r.err, contains('b.dart:1:'));
        expect(File('a.dart').readAsStringSync(), pretty);
        expect(File('c.dart').readAsStringSync(), pretty);
      },
    );

    test(
      'a broken shared config is reported once and its files skipped',
      () async {
        write('bad/.beaver.yaml', 'line_lenght: 100');
        write('bad/a.dart', ugly);
        write('bad/b.dart', ugly);
        write('good/c.dart', ugly);
        final r = await beaver(['.']);
        expect(r.code, 78);
        expect('unknown key'.allMatches(r.err), hasLength(1));
        expect(File('bad/a.dart').readAsStringSync(), ugly);
        expect(File('good/c.dart').readAsStringSync(), pretty);
      },
    );

    test('missing file exits 66', () async {
      final r = await beaver(['nope.dart']);
      expect(r.code, 66);
      expect(r.err, contains('nope.dart'));
    });

    test(
      'mixed check outcome takes the most severe code; stdout clean',
      () async {
        write('a.dart', ugly);
        write('b.dart', 'var = ;\n');
        final r = await beaver(['--check', '.']);
        expect(r.code, 65);
        expect(r.out, 'a.dart\n');
      },
    );

    test('an invalid --config stops before processing', () async {
      write('a.dart', ugly);
      write('c.yaml', 'nope: 1');
      final r = await beaver(['--config', 'c.yaml', 'a.dart']);
      expect(r.code, 78);
      expect(File('a.dart').readAsStringSync(), ugly);
    });
  });

  group('stdin', () {
    test('whole document in, formatted document out', () async {
      final r = await beaver(['--stdin'], stdin: ugly);
      expect((r.code, r.out), (0, pretty));
    });

    test('--stdin-name gives context but is never read', () async {
      write('lib/a.dart', 'var  disk=1;\n');
      write('lib/.beaver.yaml', 'spaces:\n  around_assignment: false');
      final r = await beaver([
        '--stdin',
        '--stdin-name',
        'lib/a.dart',
      ], stdin: ugly);
      expect(r.out, 'var a=1;\n');
    });

    test('excluded name echoes the input', () async {
      write('pubspec.yaml', 'name: x');
      final r = await beaver([
        '--stdin',
        '--stdin-name',
        'lib/a.g.dart',
      ], stdin: 'not dart at all {');
      expect((r.code, r.out), (0, 'not dart at all {'));
    });

    test('syntax error leaves stdout empty and exits 65', () async {
      final r = await beaver(['--stdin'], stdin: 'var = ;');
      expect((r.code, r.out), (65, ''));
      expect(r.err, contains('stdin:1:'));
    });

    test('--range formats only the covering units', () async {
      final r = await beaver([
        '--stdin',
        '--range',
        '2:1-2:2',
      ], stdin: 'var  a=1;\nvar  b=2;\n');
      expect(r.out, 'var  a=1;\nvar b = 2;\n');
    });

    test('reversed range is a usage error', () async {
      final r = await beaver(['--stdin', '--range', '2:1-1:1'], stdin: ugly);
      expect((r.code, r.out), (64, ''));
    });
  });

  group('config and init', () {
    test('config --print shows values with provenance', () async {
      write('.beaver.yaml', 'line_length: 100');
      final r = await beaver(['config', '--print', '--for', 'lib/a.dart']);
      expect(r.code, 0);
      expect(r.out, contains('line_length: 100  # .beaver.yaml'));
      expect(r.out, contains('indent.size: 2  # preset dart'));
    });

    test('init writes a starter file and refuses to overwrite', () async {
      expect((await beaver(['init'])).code, 0);
      final text = File('.beaver.yaml').readAsStringSync();
      expect(text, contains('extends: dart'));
      expect(loadYaml(text), {'extends': 'dart'});
      final again = await beaver(['init']);
      expect(again.code, 64);
      expect(File('.beaver.yaml').readAsStringSync(), text);
    });
  });
}
