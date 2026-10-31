import 'package:test/test.dart';
import 'package:zooper_beaver/src/config/editorconfig.dart';

/// Resolves [path] against in-memory [files], returning property → value.
Map<String, String> resolve(String path, Map<String, String> files) => {
  for (final MapEntry(:key, :value) in resolveEditorConfig(
    path,
    (path) => files[path],
  ).entries)
    key: value.value,
};

/// Runs [cases] (file relative to `/t` → expected properties) against a
/// single root `.editorconfig` with [sections], as the core glob tests do.
void globCases(String sections, Map<String, Map<String, String>> cases) {
  final files = {'/t/.editorconfig': 'root = true\n$sections'};
  for (final MapEntry(key: file, value: expected) in cases.entries) {
    test(file, () => expect(resolve('/t/$file', files), expected));
  }
}

void main() {
  group('glob: star', () {
    globCases(
      '''
[a*e.c]
key=value

[Bar/*]
keyb=valueb

[*]
keyc=valuec
''',
      {
        'ace.c': {'key': 'value', 'keyc': 'valuec'},
        'ae.c': {'key': 'value', 'keyc': 'valuec'},
        'abcde.c': {'key': 'value', 'keyc': 'valuec'},
        'a/e.c': {'keyc': 'valuec'},
        'Bar/foo.txt': {'keyb': 'valueb', 'keyc': 'valuec'},
        'Bar/.editorconfig': {'keyb': 'valueb', 'keyc': 'valuec'},
        '.editorconfig': {'keyc': 'valuec'},
        'Bar/sub/foo.txt': {'keyc': 'valuec'},
      },
    );
  });

  group('glob: star star', () {
    globCases(
      '''
[a**z.c]
key1=value1

[b/**z.c]
key2=value2

[c**/z.c]
key3=value3

[d/**/z.c]
key4=value4
''',
      {
        'a/z.c': {'key1': 'value1'},
        'amnz.c': {'key1': 'value1'},
        'am/nz.c': {'key1': 'value1'},
        'a/mnz.c': {'key1': 'value1'},
        'amn/z.c': {'key1': 'value1'},
        'a/mn/z.c': {'key1': 'value1'},
        'b/z.c': {'key2': 'value2'},
        'b/mnz.c': {'key2': 'value2'},
        'b/mn/z.c': {'key2': 'value2'},
        'c/z.c': {'key3': 'value3'},
        'cmn/z.c': {'key3': 'value3'},
        'c/mn/z.c': {'key3': 'value3'},
        'd/z.c': {'key4': 'value4'},
        'd/mn/z.c': {'key4': 'value4'},
        'd/mnz.c': {},
        'x/d/z.c': {},
      },
    );
  });

  group('glob: question mark', () {
    globCases('[som?.c]\nkey = value\n', {
      'some.c': {'key': 'value'},
      'som.c': {},
      'something.c': {},
      'som/.c': {},
      'sub/some.c': {'key': 'value'},
    });
  });

  group('glob: brackets', () {
    globCases(
      r'''
; Character choice
[[ab].a]
choice=true

; Negative character choice
[[!ab].b]
choice=true

; Character range
[[d-g].c]
range=true

; Negative character range
[[!d-g].d]
range=true

; Range and choice
[[abd-g].e]
range_and_choice=true

; Choice with slash
[[b/].f]
slash_in_brackets=true

; Close bracket inside
[[\]ab].g]
close_inside=true

; Close bracket outside
[[ab]].g]
close_outside=true

; Negative close bracket inside
[[!\]ab].g]
close_inside=false

; Negative close bracket outside
[[!ab]].g]
close_outside=false

; Slash inside brackets
[ab[e/]cd.i]
slash_inside=true

; Slash after a half-open bracket
[ab[/c]
slash_half_open=true
''',
      {
        'a.a': {'choice': 'true'},
        'c.a': {},
        'c.b': {'choice': 'true'},
        'a.b': {},
        'f.c': {'range': 'true'},
        'h.c': {},
        'h.d': {'range': 'true'},
        'f.d': {},
        'e.e': {'range_and_choice': 'true'},
        'a.e': {'range_and_choice': 'true'},
        'c.e': {},
        'b.f': {},
        '[b/].f': {'slash_in_brackets': 'true'},
        '].g': {'close_inside': 'true'},
        'b].g': {'close_outside': 'true'},
        'c.g': {'close_inside': 'false'},
        'c].g': {'close_outside': 'false'},
        'ab/cd.i': {},
        'abecd.i': {},
        'ab[e/]cd.i': {'slash_inside': 'true'},
        'ab[/c': {'slash_half_open': 'true'},
      },
    );
  });

  group('glob: braces', () {
    globCases(
      r'''
; word choice
[*.{py,js,html}]
choice=true

; single choice
[{single}.b]
choice=single

; empty choice
[{}.c]
empty=all

; choice with empty word
[a{b,c,}.d]
empty=word

; choice with empty words
[a{,b,,c,}.e]
empty=words

; no closing brace
[{.f]
closing=false

; nested braces
[{word,{also},this}.g]
nested=true

; nested braces, adjacent at start
[{{a,b},c}.k]
nested_start=true

; nested braces, adjacent at end
[{a,{b,c}}.l]
nested_end=true

; closing inside beginning
[{},b}.h]
closing=inside

; missing closing braces
[{{,b,c{d}.i]
closing=missing

; escaped comma
[{a\,b,cd}.txt]
comma=yes

; escaped closing brace
[{e,\},f}.txt]
closing=yes

; escaped backslash
[{g,\\,i}.txt]
backslash=yes

; patterns nested in braces
[{some,a{*c,b}[ef]}.j]
patterns=nested

; numeric braces
[{3..120}]
number=true

; numeric braces with negative numbers
[{-3..-1}.n]
negative=true

; word and number braces
[{aardvark..antelope}]
words=a
''',
      {
        'a.py': {'choice': 'true'},
        'a.js': {'choice': 'true'},
        'a.html': {'choice': 'true'},
        'a.xml': {},
        '{single}.b': {'choice': 'single'},
        'single.b': {},
        '{}.c': {'empty': 'all'},
        '.c': {},
        'a.d': {'empty': 'word'},
        'ab.d': {'empty': 'word'},
        'ac.d': {'empty': 'word'},
        'a,.d': {},
        'a.e': {'empty': 'words'},
        'ab.e': {'empty': 'words'},
        'ac.e': {'empty': 'words'},
        'a,.e': {},
        '{.f': {'closing': 'false'},
        '.f': {},
        'word,this}.g': {},
        '{also,this}.g': {},
        'word.g': {'nested': 'true'},
        '{also}.g': {'nested': 'true'},
        'this.g': {'nested': 'true'},
        'also.g': {},
        'a.k': {'nested_start': 'true'},
        'b.k': {'nested_start': 'true'},
        'c.k': {'nested_start': 'true'},
        'd.k': {},
        'a.l': {'nested_end': 'true'},
        'b.l': {'nested_end': 'true'},
        'c.l': {'nested_end': 'true'},
        'd.l': {},
        '{},b}.h': {'closing': 'inside'},
        '{{,b,c{d}.i': {'closing': 'missing'},
        '{.i': {},
        'b.i': {},
        'c{d.i': {},
        '.i': {},
        'a,b.txt': {'comma': 'yes'},
        'a.txt': {},
        'cd.txt': {'comma': 'yes'},
        'e.txt': {'closing': 'yes'},
        '}.txt': {'closing': 'yes'},
        'f.txt': {'closing': 'yes'},
        'g.txt': {'backslash': 'yes'},
        r'\.txt': {'backslash': 'yes'},
        'i.txt': {'backslash': 'yes'},
        'some.j': {'patterns': 'nested'},
        'abe.j': {'patterns': 'nested'},
        'abf.j': {'patterns': 'nested'},
        'abg.j': {},
        'ace.j': {'patterns': 'nested'},
        'acf.j': {'patterns': 'nested'},
        'acg.j': {},
        'abce.j': {'patterns': 'nested'},
        'abcf.j': {'patterns': 'nested'},
        'abcg.j': {},
        'ae.j': {},
        '.j': {},
        '1': {},
        '3': {'number': 'true'},
        '15': {'number': 'true'},
        '60': {'number': 'true'},
        '5a': {},
        '120': {'number': 'true'},
        '121': {},
        '060': {},
        'sub/15': {'number': 'true'},
        '-3.n': {'negative': 'true'},
        '-2.n': {'negative': 'true'},
        '-1.n': {'negative': 'true'},
        '-4.n': {},
        '0.n': {},
        'aardvark': {},
        'antelope': {},
        '{aardvark..antelope}': {'words': 'a'},
      },
    );
  });

  group('glob: path anchoring', () {
    globCases(
      '''
[*.dart]
any_depth=true

[lib/*.dart]
anchored=true

[/src/*.dart]
leading_slash=true

[**/gen/*.dart]
star_star_prefix=true
''',
      {
        'a.dart': {'any_depth': 'true'},
        'x/y/a.dart': {'any_depth': 'true'},
        'lib/a.dart': {'any_depth': 'true', 'anchored': 'true'},
        'x/lib/a.dart': {'any_depth': 'true'},
        'lib/x/a.dart': {'any_depth': 'true'},
        'src/a.dart': {'any_depth': 'true', 'leading_slash': 'true'},
        'x/src/a.dart': {'any_depth': 'true'},
        'gen/a.dart': {'any_depth': 'true', 'star_star_prefix': 'true'},
        'x/y/gen/a.dart': {'any_depth': 'true', 'star_star_prefix': 'true'},
      },
    );

    test('anchoring is relative to the nearer file', () {
      final files = {
        '/r/.editorconfig': 'root = true\n[lib/*.dart]\nouter=true\n',
        '/r/pkg/.editorconfig': '[lib/*.dart]\ninner=true\n',
      };
      expect(resolve('/r/pkg/lib/a.dart', files), {'inner': 'true'});
      expect(resolve('/r/lib/a.dart', files), {'outer': 'true'});
    });
  });

  group('EditorConfigGlob', () {
    test('matches relative paths directly', () {
      expect(EditorConfigGlob('*.dart').matches('lib/a.dart'), isTrue);
      expect(EditorConfigGlob('lib/*.dart').matches('lib/a.dart'), isTrue);
      expect(EditorConfigGlob('lib/*.dart').matches('a/lib/a.dart'), isFalse);
      expect(EditorConfigGlob(r'\*.dart').matches('*.dart'), isTrue);
      expect(EditorConfigGlob(r'\*.dart').matches('a.dart'), isFalse);
      expect(EditorConfigGlob('{a,{1..3}}.x').matches('a.x'), isTrue);
      expect(EditorConfigGlob('{a,{1..3}}.x').matches('4.x'), isFalse);
    });
  });

  group('parser', () {
    test('comments, spacing, case and malformed lines', () {
      final files = {
        '/t/.editorconfig': '''
; comment
# comment
ROOT = TRUE
[*]
Indent_Style=Space
indent_size =  4
end_of_line = CRLF
custom = MixedCase
not a property
= no key
[unclosed
key = after unclosed
''',
      };
      expect(resolve('/t/a.dart', files), {
        'indent_style': 'space',
        'indent_size': '4',
        'end_of_line': 'crlf',
        'custom': 'MixedCase',
        'key': 'after unclosed',
      });
    });

    test('CRLF line endings', () {
      final files = {
        '/t/.editorconfig': 'root=true\r\n[*]\r\nindent_size=4\r\n',
      };
      expect(resolve('/t/a.dart', files), {'indent_size': '4'});
    });

    test('properties in the preamble other than root are ignored', () {
      final files = {
        '/t/.editorconfig': 'root = true\nindent_size = 4\n'
        '[*]\ntab_width = 8\n',
      };
      expect(resolve('/t/a.dart', files), {'tab_width': '8'});
    });

    test('root inside a section does not stop the walk', () {
      final files = {
        '/.editorconfig': '[*]\nouter = true\n',
        '/t/.editorconfig': '[*]\nroot = true\n',
      };
      expect(resolve('/t/a.dart', files), {'outer': 'true', 'root': 'true'});
    });
  });

  group('precedence', () {
    test('a nearer file overrides an ancestor', () {
      final files = {
        '/repo/.editorconfig': 'root = true\n[*.dart]\nindent_size = 4\n',
        '/repo/lib/.editorconfig': '[*.dart]\nindent_size = 2\n',
      };
      expect(resolve('/repo/lib/a.dart', files), {'indent_size': '2'});
      expect(resolve('/repo/a.dart', files), {'indent_size': '4'});
    });

    test('root stops the walk', () {
      final reads = <String>[];
      final files = {
        '/.editorconfig': '[*]\nouter = true\n',
        '/repo/.editorconfig': 'root = true\n[*]\nindent_size = 4\n',
      };
      final result = resolveEditorConfig('/repo/lib/a.dart', (path) {
        reads.add(path);
        return files[path];
      });
      expect(result.keys, ['indent_size']);
      expect(reads, ['/repo/lib/.editorconfig', '/repo/.editorconfig']);
    });

    test('without root, every ancestor is consulted', () {
      final files = {
        '/.editorconfig': '[*]\nouter = true\nindent_size = 8\n',
        '/repo/.editorconfig': '[*]\nindent_size = 4\n',
      };
      expect(resolve('/repo/a.dart', files), {
        'outer': 'true',
        'indent_size': '4',
      });
    });

    test('unset removes a value', () {
      final files = {
        '/repo/.editorconfig': 'root = true\n[*]\n'
        'indent_size = 4\ntab_width = 4\n',
        '/repo/lib/.editorconfig': '[*.dart]\nindent_size = unset\n',
      };
      expect(resolve('/repo/lib/a.dart', files), {'tab_width': '4'});
    });

    test('unset is case-insensitive and a later section can set again', () {
      final files = {
        '/t/.editorconfig': 'root = true\n[*]\nfoo = bar\n'
        '[*.dart]\nfoo = UNSET\n[a.*]\nfoo = baz\n',
      };
      expect(resolve('/t/b.dart', files), isEmpty);
      expect(resolve('/t/a.dart', files), {'foo': 'baz'});
    });

    test('later sections override earlier ones', () {
      final files = {
        '/t/.editorconfig': 'root = true\n[*]\nindent_size = 4\n'
        '[*.dart]\nindent_size = 2\n',
      };
      expect(resolve('/t/a.dart', files), {'indent_size': '2'});
      expect(resolve('/t/a.yaml', files), {'indent_size': '4'});
    });

    test('a later section wins even when less specific', () {
      final files = {
        '/t/.editorconfig': 'root = true\n[*.dart]\nindent_size = 2\n'
        '[*]\nindent_size = 4\n',
      };
      expect(resolve('/t/a.dart', files), {'indent_size': '4'});
    });

    test('no .editorconfig yields no properties', () {
      expect(resolve('/repo/a.dart', {}), isEmpty);
    });
  });

  group('provenance', () {
    test('records the file and section of each value', () {
      final files = {
        '/repo/.editorconfig': 'root = true\n[*]\n'
        'indent_size = 4\ntab_width = 8\n',
        '/repo/lib/.editorconfig': '[*.dart]\nindent_size = tab\n',
      };
      final result = resolveEditorConfig('/repo/lib/a.dart', (p) => files[p]);
      final size = result['indent_size']!;
      expect(size.value, 'tab');
      expect(size.path, '/repo/lib/.editorconfig');
      expect(size.section, '[*.dart]');
      final tab = result['tab_width']!;
      expect(tab.value, '8');
      expect(tab.path, '/repo/.editorconfig');
      expect(tab.section, '[*]');
    });
  });
}
