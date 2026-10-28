import 'package:test/test.dart' hide group;
import 'package:test/test.dart' as t show group;
import 'package:zooper_beaver/src/config/config.dart' show IndentStyle;
import 'package:zooper_beaver/src/emit/emit.dart';
import 'package:zooper_beaver/src/ir/doc.dart';
import 'package:zooper_beaver/src/ir/printer.dart';

String layout(
  Doc doc, {
  int width = 80,
  int indentSize = 2,
  IndentStyle style = IndentStyle.spaces,
  String lineEnding = '\n',
}) {
  final commands = printDoc(doc, lineLength: width, indentSize: indentSize);
  final out = emit(
    commands,
    style: style,
    indentSize: indentSize,
    lineEnding: lineEnding,
  );
  return out.substring(0, out.length - lineEnding.length);
}

/// `name(a, b)` with a trailing comma when broken.
Doc call(String name, List<Doc> args, {GroupId? id}) => group(
  concat([
    text('$name('),
    indent(
      concat([
        softline,
        join(concat([text(','), line]), args),
      ]),
    ),
    ifBreak(text(',')),
    softline,
    text(')'),
  ]),
  id: id,
);

void main() {
  t.group('Doc', () {
    test('every node kind can be built', () {
      final id = GroupId('g');
      final docs = <Doc>[
        text('a'),
        line,
        softline,
        hardline,
        literalline,
        group(text('a'), shouldBreak: true, id: id),
        indent(text('a')),
        align(2, text('a')),
        alignString('> ', text('a')),
        ifBreak(text('a'), text('b'), id),
        fill([text('a'), line, text('b')]),
        breakParent,
        lineSuffix(text('a')),
        concat([text('a'), text('b')]),
        const Marker(0, isStart: true),
      ];
      expect(
        docs.map((d) => d.runtimeType).toSet(),
        containsAll([
          Text,
          Line,
          Group,
          Indent,
          Align,
          IfBreak,
          Fill,
          BreakParent,
          LineSuffix,
          Concat,
          Marker,
        ]),
      );
      expect(() => layout(concat(docs)), returnsNormally);
    });
  });

  t.group('propagateBreaks', () {
    test('a group containing a hard line is broken at any width', () {
      final inner = group(concat([text('a'), hardline, text('b')]));
      final outer = group(concat([text('x'), line, inner]));
      propagateBreaks(outer);
      expect((inner as Group).shouldBreak, isTrue);
      expect((outer as Group).shouldBreak, isTrue);
      expect(layout(outer, width: 1000), 'x\na\nb');
    });

    test('BreakParent breaks its ancestors', () {
      final doc = group(concat([text('a'), line, text('b'), breakParent]));
      expect(layout(doc, width: 100), 'a\nb');
    });
  });

  t.group('printer', () {
    test('outer group breaks, inner fits', () {
      final doc = concat([
        call('print', [
          call('fetchUser', [text('userId'), text('includeAvatar: true')]),
          text('fallback'),
        ]),
        text(';'),
      ]);
      expect(
        layout(doc, width: 42),
        'print(\n'
        '  fetchUser(userId, includeAvatar: true),\n'
        '  fallback,\n'
        ');',
      );
    });

    test('everything fits', () {
      final doc = concat([
        call('foo', [text('a'), text('b'), text('c')]),
        text(';'),
      ]);
      expect(layout(doc), 'foo(a, b, c);');
    });

    test('direct lines break together', () {
      final doc = call('f', [text('first'), text('second'), text('third')]);
      expect(layout(doc, width: 10), 'f(\n  first,\n  second,\n  third,\n)');
    });

    test('nested indentation adds up', () {
      Doc block(Doc body) => concat([
        text('{'),
        indent(concat([hardline, body])),
        hardline,
        text('}'),
      ]);
      final doc = block(
        block(call('foo', [text('argument1'), text('argument2')])),
      );
      final lines = layout(doc, width: 20).split('\n');
      expect(
        lines.firstWhere((l) => l.contains('argument1')),
        '      argument1,',
      );
    });
  });

  t.group('Fill', () {
    test('packs as many items per line as fit', () {
      final operands = [for (var i = 1; i <= 8; i++) text('operand$i')];
      final parts = <Doc>[];
      for (final (i, operand) in operands.indexed) {
        if (i > 0) parts.add(line);
        parts.add(
          i < operands.length - 1 ? concat([operand, text(' +')]) : operand,
        );
      }
      final out = layout(fill(parts), width: 32);
      expect(out.split('\n'), hasLength(3));
      expect(out.split('\n').first, 'operand1 + operand2 + operand3 +');
    });

    test('honours a hard separator', () {
      final out = layout(
        fill([text('a'), hardline, text('b'), line, text('c')]),
      );
      expect(out, 'a\nb c');
    });
  });

  t.group('IfBreak', () {
    test('trailing comma only when broken', () {
      final doc = call('f', [text('aaaa'), text('bbbb')]);
      expect(layout(doc, width: 80), 'f(aaaa, bbbb)');
      expect(layout(doc, width: 8), 'f(\n  aaaa,\n  bbbb,\n)');
    });

    test('resolves against a sibling group by id', () {
      final anchor = GroupId('anchor');
      Doc chain(int width) => concat([
        group(text('target'), id: anchor),
        group(
          concat([
            ifBreak(
              indent(concat([hardline, text('.a()')])),
              align(6, concat([hardline, text('.a()')])),
              anchor,
            ),
          ]),
        ),
      ]);
      expect(layout(chain(80)), 'target\n      .a()');
    });
  });

  t.group('LineSuffix', () {
    test('trailing comment stays on its line', () {
      final doc = group(
        concat([
          text('foo('),
          indent(
            concat([
              softline,
              text('a,'),
              lineSuffix(text(' // about a')),
              breakParent,
              line,
              text('b'),
            ]),
          ),
          softline,
          text(')'),
        ]),
      );
      expect(layout(doc), 'foo(\n  a, // about a\n  b\n)');
    });
  });

  t.group('emit', () {
    test('tabs for levels, spaces for alignment', () {
      final doc = concat([
        text('{'),
        indent(
          concat([
            hardline,
            text('x ='),
            align(4, concat([hardline, text('y;')])),
          ]),
        ),
        hardline,
        text('}'),
      ]);
      expect(layout(doc, style: IndentStyle.tabs), '{\n\tx =\n\t    y;\n}');
    });

    test('CRLF line endings and a single trailing newline', () {
      expect(detectLineEnding('a\r\nb\r\n'), '\r\n');
      expect(detectLineEnding('a\nb\r\nc\n'), '\n');
      final commands = printDoc(
        concat([text('a'), hardline, text('b'), hardline, hardline]),
        lineLength: 80,
        indentSize: 2,
      );
      expect(emit(commands, lineEnding: '\r\n'), 'a\r\nb\r\n');
    });

    test('blank lines carry no indentation', () {
      final doc = indent(concat([text('a'), hardline, hardline, text('b')]));
      expect(layout(doc), 'a\n\n  b');
    });
  });
}
