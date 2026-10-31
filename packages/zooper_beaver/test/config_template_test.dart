import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/config/resolve.dart';
import 'package:zooper_beaver/src/config/schema.dart';
import 'package:zooper_beaver/src/config/template.dart';

void main() {
  final template = configTemplate();

  test('every schema key appears exactly once', () {
    final keys = flatten(loadYaml(template) as YamlMap).keys.toList();
    expect(keys, schema.keys.toList());
  });

  test('a policy line lists the alternatives', () {
    expect(
      template,
      contains(
        '  arguments:  # or the shorthand arguments: <policy>\n'
        '    policy: chop_if_long  # never | if_long | chop_if_long | chop_always\n',
      ),
    );
  });

  test('saved as .beaver.yaml it resolves to the preset', () {
    final tmp = Directory.systemTemp.createTempSync('beaver_template');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File(p.join(tmp.path, '.beaver.yaml')).writeAsStringSync(template);
    final resolved = resolveConfig(
      p.join(tmp.path, 'a.dart'),
      read: (path) {
        final file = File(path);
        return file.existsSync() ? file.readAsStringSync() : null;
      },
    );
    expect(resolved.chain.first, endsWith('.beaver.yaml'));
    expect(resolved.config.settings, BeaverConfig.dart.settings);
  });
}
