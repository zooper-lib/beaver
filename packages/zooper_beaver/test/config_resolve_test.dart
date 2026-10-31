import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/config.dart';
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
          '`wrap.arguments` (`wrap.arguments.policy`); allowed: never | if_long | '
          'chop_if_long | chop_always',
        ),
      );
    });

    test('invalid canonical value', () {
      expect(
        () =>
            parseConfigFile('wrap:\n  arguments:\n    policy: sometimes', 'f'),
        configError(
          '`wrap.arguments.policy`; allowed: never | if_long | chop_if_long | '
          'chop_always',
        ),
      );
    });

    test('field not offered on a construct', () {
      expect(
        () => parseConfigFile(
          'wrap:\n  chained_calls:\n    trailing_commas: remove',
          'f',
        ),
        configError('`wrap.chained_calls.trailing_commas`'),
      );
    });

    test('align is refused where it has no effect', () {
      for (final list in [
        'cascades',
        'conditional_expressions',
        'switch_expressions',
        'class_header',
      ]) {
        expect(
          () => parseConfigFile('wrap:\n  $list:\n    align: true', 'f'),
          configError('`wrap.$list.align`'),
          reason: list,
        );
      }
    });

    test('chop_on_calls entries are dotted names', () {
      expect(
        () => parseConfigFile("wrap: {chop_on_calls: ['Row*']}", 'f'),
        configError('Row*'),
      );
      expect(
        () => parseConfigFile("wrap: {chop_on_calls: ['Row..center']}", 'f'),
        configError('wrap.chop_on_calls'),
      );
    });

    test('policy, else_on_new_line and chop_on_calls entries are checked', () {
      expect(
        () => parseConfigFile('wrap:\n  arguments:\n    policy: inherit', 'f'),
        configError('wrap.arguments.policy'),
      );
      expect(
        () => parseConfigFile('braces:\n  else_on_new_line: inherit', 'f'),
        configError('braces.else_on_new_line'),
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
      expect(resolve('p/a.dart').config.arguments.trailingCommas, isNotNull);
    });
  });

  group('aliases and normalisation', () {
    Map<String, Object?> parse(String yaml) =>
        parseConfigFile(yaml, 'f').values;

    test('long form', () {
      expect(
        parse(
          'wrap: {arguments: {policy: chop_if_long, chop_from: 4, '
          'keep_existing_line_breaks: false}}',
        ),
        {
          'wrap.arguments.policy': 'chop_if_long',
          'wrap.arguments.chop_from': 4,
          'wrap.arguments.keep_existing_line_breaks': false,
        },
      );
    });

    test('every alias maps to its canonical key', () {
      expect(parse('wrap: {arguments: chop_always}'), {
        'wrap.arguments.policy': 'chop_always',
      });
      expect(parse('indent: {align: {parameters: true}}'), {
        'wrap.parameters.align': true,
      });
      expect(parse('wrap: {chained_calls: {min_calls: 3}}'), {
        'wrap.chained_calls.chop_from': 3,
      });
      expect(parse('wrap: {before_operator: true}'), {
        'wrap.break_before.binary_operator': true,
      });
    });

    test('conflicting spellings in one file name both keys', () {
      expect(
        () => parse(
          'indent: {align: {arguments: true}}\n'
          'wrap: {arguments: {align: false}}',
        ),
        allOf(
          configError('`indent.align.arguments`'),
          configError('`wrap.arguments.align`'),
        ),
      );
    });

    test('identical duplicate spellings are accepted', () {
      expect(
        parse(
          'wrap: {before_operator: true, break_before: {binary_operator: true}}',
        ),
        {'wrap.break_before.binary_operator': true},
      );
    });

    test('different spellings across layers: the nearer file wins', () {
      write('team.yaml', 'wrap: {arguments: {align: true}}');
      write(
        '.beaver.yaml',
        'extends: team.yaml\nindent: {align: {arguments: false}}',
      );
      expect(resolve('a.dart').config.arguments.align, isFalse);
    });

    test('a shorthand child keeps an inherited field', () {
      write('team.yaml', 'wrap: {arguments: {chop_from: 4}}');
      write('.beaver.yaml', 'extends: team.yaml\nwrap: {arguments: never}');
      final values = resolve('a.dart').config.values;
      expect(values['wrap.arguments.policy'], 'never');
      expect(values['wrap.arguments.chop_from'], 4);
    });

    test('a shorthand replaces only the policy', () {
      write(
        'team.yaml',
        'wrap: {parameters: {policy: chop_always, chop_from: 3}}',
      );
      write('.beaver.yaml', 'extends: team.yaml\nwrap: {parameters: if_long}');
      final values = resolve('a.dart').config.values;
      expect(values['wrap.parameters.policy'], 'if_long');
      expect(values['wrap.parameters.chop_from'], 3);
    });
  });

  group('inherit', () {
    test('follows a child\'s global override', () {
      write('.beaver.yaml', 'wrap: {keep_existing_line_breaks: false}');
      final config = resolve('a.dart').config;
      expect(
        config.values['wrap.collection_literals.keep_existing_line_breaks'],
        false,
      );
      expect(config.collectionLiterals.keepExistingLineBreaks, isFalse);
    });

    test('explicit inherit restores the link', () {
      write(
        'team.yaml',
        'wrap: {arguments: {keep_existing_line_breaks: false}}',
      );
      write(
        '.beaver.yaml',
        'extends: team.yaml\nwrap:\n  keep_existing_line_breaks: true\n'
            '  arguments: {keep_existing_line_breaks: inherit}',
      );
      expect(resolve('a.dart').config.arguments.keepExistingLineBreaks, isTrue);
    });

    test('omission keeps the parent value', () {
      write(
        'team.yaml',
        'wrap: {arguments: {keep_existing_line_breaks: false}}',
      );
      write(
        '.beaver.yaml',
        'extends: team.yaml\nwrap: {keep_existing_line_breaks: true}',
      );
      expect(
        resolve('a.dart').config.arguments.keepExistingLineBreaks,
        isFalse,
      );
    });

    test('cascade indent follows indent.size', () {
      write('.beaver.yaml', 'indent: {size: 4}');
      expect(resolve('a.dart').config.values['wrap.cascades.indent'], 4);
    });

    test('chain and binary indent follow indent.continuation', () {
      write('.beaver.yaml', 'indent: {continuation: 6}');
      final values = resolve('a.dart').config.values;
      expect(values['wrap.chained_calls.indent'], 6);
      expect(values['wrap.binary_expressions.indent'], 6);
    });

    test('enum values follow a customised collection policy', () {
      write('.beaver.yaml', 'wrap: {collection_literals: chop_always}');
      expect(
        resolve('a.dart').config.enumValues.policy,
        WrapPolicy.chopAlways,
      );
    });

    test('enum values set independently', () {
      write(
        '.beaver.yaml',
        'wrap: {collection_literals: chop_always, enum_values: chop_if_long}',
      );
      final config = resolve('a.dart').config;
      expect(config.enumValues.policy, WrapPolicy.chopIfLong);
      expect(config.collectionLiterals.policy, WrapPolicy.chopAlways);
    });

    test('catch follows else', () {
      write('.beaver.yaml', 'braces: {else_on_new_line: true}');
      expect(
        resolve('a.dart').config.values['braces.catch_on_new_line'],
        true,
      );
    });

    test('max_consecutive_in_code follows max_consecutive', () {
      write('.beaver.yaml', 'blank_lines: {max_consecutive: 2}');
      expect(
        resolve('a.dart').config.values['blank_lines.max_consecutive_in_code'],
        2,
      );
    });

    test('around_class_declarations: inherit follows the general count', () {
      write(
        '.beaver.yaml',
        'blank_lines: {around_class_declarations: inherit, '
            'between_top_level_declarations: 2}',
      );
      expect(
        resolve(
          'a.dart',
        ).config.values['blank_lines.around_class_declarations'],
        2,
      );
    });

    test('the effective configuration holds no inherit', () {
      expect(
        resolve('a.dart').config.values.values,
        isNot(contains('inherit')),
      );
    });

    test('provenance names where inherit was set and the value source', () {
      final project = write(
        '.beaver.yaml',
        'wrap: {chop_on_trailing_comma: false}',
      );
      final r = resolve('a.dart');
      expect(r.config.values['wrap.arguments.chop_on_trailing_comma'], false);
      final source = r.provenance['wrap.arguments.chop_on_trailing_comma']!;
      expect(source.origin, 'preset dart');
      expect(source.fallback, 'wrap.chop_on_trailing_comma');
      expect(source.fallbackOrigin, project);
      expect(r.provenance['line_length']!.fallback, isNull);
    });
  });

  group('trailing-comma conflicts per construct', () {
    test('an inherited value completes the conflict', () {
      write(
        '.beaver.yaml',
        'trailing_commas: remove\nwrap: {keep_existing_line_breaks: false}',
      );
      expect(
        () => resolve('a.dart'),
        allOf(
          configError('trailing_commas: remove'),
          configError('wrap.chop_on_trailing_comma from preset dart'),
          configError('keep_existing_line_breaks: false'),
        ),
      );
    });

    test('a conflict on one construct only', () {
      write(
        '.beaver.yaml',
        'wrap:\n  collection_literals:\n    trailing_commas: remove\n'
            '    keep_existing_line_breaks: false',
      );
      expect(() => resolve('a.dart'), configError('for collection_literals:'));
    });

    test('suppression by close-bracket placement', () {
      write(
        '.beaver.yaml',
        'wrap:\n  keep_existing_line_breaks: false\n'
            '  arguments: {close_bracket: after_last_item}',
      );
      expect(
        () => resolve('a.dart'),
        configError(
          'wrap.arguments.close_bracket: after_last_item',
        ),
      );
      expect(() => resolve('a.dart'), configError('suppresses the optional'));
    });

    test('policy never is exempt, a threshold alone is not', () {
      const conflict =
          'wrap:\n  keep_existing_line_breaks: false\n'
          '  parameters: {close_bracket: after_last_item}\n'
          '  collection_literals: {close_bracket: after_last_item}\n'
          '  enum_values: {close_bracket: own_line}\n'
          '  arguments:\n    close_bracket: after_last_item\n';
      write('.beaver.yaml', '${conflict}    policy: never\n');
      expect(
        () => resolve('a.dart'),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.message,
            'message',
            isNot(contains('for arguments')),
          ),
        ),
      );
      write(
        '.beaver.yaml',
        '${conflict}    policy: chop_if_long\n    chop_from: 3\n',
      );
      expect(() => resolve('a.dart'), configError('for arguments:'));
    });
  });

  group('editorconfig', () {
    test('disabled by default', () {
      write('.editorconfig', 'root = true\n[*]\nindent_size = 4\n');
      write('.beaver.yaml', 'line_length: 80');
      expect(resolve('lib/a.dart').config.indentSize, 2);
    });

    test('a child disables an inherited true', () {
      write('.editorconfig', 'root = true\n[*]\nindent_size = 4\n');
      write('team.yaml', 'editorconfig: true');
      write('.beaver.yaml', 'extends: team.yaml\neditorconfig: false');
      expect(resolve('lib/a.dart').config.indentSize, 2);
    });

    test('EditorConfig beats the preset', () {
      write('.editorconfig', 'root = true\n[*.dart]\nindent_size = 4\n');
      write('.beaver.yaml', 'editorconfig: true');
      final r = resolve('lib/a.dart');
      expect(r.config.indentSize, 4);
      expect(r.config.values['wrap.arguments.indent'], 4);
    });

    test('a Beaver setting anywhere in the chain beats a nearer EditorConfig', () {
      write('team.yaml', 'indent: {size: 2}');
      write('.beaver.yaml', 'extends: team.yaml\neditorconfig: true');
      write('lib/.editorconfig', '[*.dart]\nindent_size = 4\n');
      expect(resolve('lib/a.dart').config.indentSize, 2);
    });

    test('a nearer file overrides an ancestor, and section order counts', () {
      write('.beaver.yaml', 'editorconfig: true');
      write('.editorconfig', 'root = true\n[*.dart]\nindent_size = 4\n');
      write(
        'lib/.editorconfig',
        '[*]\nindent_size = 8\n[*.dart]\nindent_size = 3\n',
      );
      expect(resolve('lib/a.dart').config.indentSize, 3);
    });

    test('unset removes a value', () {
      write('.beaver.yaml', 'editorconfig: true');
      write('.editorconfig', 'root = true\n[*]\nindent_size = 4\n');
      write('lib/.editorconfig', '[*.dart]\nindent_size = unset\n');
      expect(resolve('lib/a.dart').config.indentSize, 2);
    });

    test('tab size derived from tab_width, with provenance', () {
      write('.beaver.yaml', 'editorconfig: true');
      final ec = write(
        '.editorconfig',
        'root = true\n[*.dart]\nindent_style = tab\nindent_size = tab\ntab_width = 4\n',
      );
      final r = resolve('a.dart');
      expect(r.config.indentStyle, IndentStyle.tabs);
      expect(r.config.indentSize, 4);
      final source = r.provenance['indent.size']!;
      expect(source.origin, ec);
      expect(source.detail, '[*.dart] indent_size, tab_width');
    });

    test('unrelated properties are ignored', () {
      write('.beaver.yaml', 'editorconfig: true');
      write('.editorconfig', 'root = true\n[*]\nmax_line_length = 120\n');
      expect(resolve('a.dart').config.lineLength, 80);
    });

    test('end_of_line maps lf and crlf, and reports cr', () {
      write('.beaver.yaml', 'editorconfig: true');
      final ec = write(
        '.editorconfig',
        'root = true\n[*]\nend_of_line = crlf\n',
      );
      expect(resolve('a.dart').config.values['line_ending'], 'crlf');
      write('.editorconfig', 'root = true\n[*]\nend_of_line = cr\n');
      final r = resolve('a.dart');
      expect(r.config.values['line_ending'], 'auto');
      expect(
        r.warnings.single,
        allOf(contains(ec), contains('[*]'), contains('cr')),
      );
    });

    test('an explicit line_ending: auto overrides EditorConfig', () {
      write('.beaver.yaml', 'editorconfig: true\nline_ending: auto');
      write('.editorconfig', 'root = true\n[*]\nend_of_line = crlf\n');
      expect(resolve('a.dart').config.values['line_ending'], 'auto');
    });

    test('an explicit config still resolves EditorConfig for the file', () {
      final team = write('team.yaml', 'editorconfig: true');
      write('lib/.editorconfig', 'root = true\n[a.dart]\nindent_size = 4\n');
      expect(resolve('lib/a.dart', explicit: team).config.indentSize, 4);
      expect(resolve('lib/b.dart', explicit: team).config.indentSize, 2);
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
      expect(r.provenance['line_length']!.origin, team);
      expect(r.provenance['indent.continuation']!.origin, app);
      expect(r.provenance['indent.style']!.origin, 'preset dart');
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

    test('include: only lib and test', () {
      write('.beaver.yaml', 'include: ["lib/**", "test/**"]');
      final r = resolve('lib/a.dart');
      expect(r.excludedBy(p.join(tmp.path, 'tool/gen.dart')), 'not in include');
      expect(r.excludedBy(p.join(tmp.path, 'lib/a.dart')), isNull);
      expect(r.excludedBy(p.join(tmp.path, 'test/a_test.dart')), isNull);
    });

    test('include: exclude still wins', () {
      write('.beaver.yaml', 'include: ["lib/**"]');
      final r = resolve('lib/a.dart');
      expect(r.excludedBy(p.join(tmp.path, 'lib/a.g.dart')), '**/*.g.dart');
    });

    test('include replaces along the chain', () {
      write('team.yaml', 'include: ["lib/**"]');
      write('.beaver.yaml', 'extends: team.yaml\ninclude: ["bin/**"]');
      final r = resolve('bin/a.dart');
      expect(r.config.include, ['bin/**']);
      expect(r.excludedBy(p.join(tmp.path, 'lib/a.dart')), 'not in include');
    });

    test('.dart_tool is never formattable', () {
      write('.beaver.yaml', '');
      final file = p.join(tmp.path, '.dart_tool/build/x.dart');
      expect(resolveConfig(file, read: read).excludedBy(file), 'protected');
    });
  });
}
