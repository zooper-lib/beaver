/// Formats every `.dart` file under the given directories with each given
/// configuration and checks the safety invariants: verification
/// passes, a second pass is a no-op, ignored regions are untouched.
///
///     dart run tool/corpus.dart --config a.yaml --config b.yaml dir...
///
/// No `--config` means the `dart` preset alone.
library;

import 'dart:io';

import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/config/loader.dart';
import 'package:zooper_beaver/src/format.dart';
import 'package:zooper_beaver/src/parse/parse.dart';

void main(List<String> args) {
  final configs = <String, BeaverConfig>{};
  final directories = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--config') {
      final path = args[++i];
      final file = parseConfigFile(File(path).readAsStringSync(), path);
      configs[path] = BeaverConfig.dart.merge(file.values);
    } else {
      directories.add(args[i]);
    }
  }
  if (configs.isEmpty) configs['preset dart'] = BeaverConfig.dart;

  final files = [
    for (final d in directories)
      ...Directory(d)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
  ];
  var failed = false;
  for (final MapEntry(key: name, value: config) in configs.entries) {
    var ok = 0, unparseable = 0;
    final problems = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      try {
        final once = format(source, config: config);
        final twice = format(once, config: config);
        if (twice != once) {
          problems.add('${file.path}: not idempotent');
        } else {
          ok++;
        }
      } on ParseFailure {
        unparseable++;
      } catch (e) {
        problems.add('${file.path}: $e');
      }
    }
    print(
      '$name: ${files.length} files, $ok ok, $unparseable unparseable, '
      '${problems.length} failures',
    );
    problems.take(20).forEach((p) => print('  $p'));
    failed |= problems.isNotEmpty;
  }
  exitCode = failed ? 1 : 0;
}
