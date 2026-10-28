import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:zooper_beaver/src/comments/attach.dart';
import 'package:zooper_beaver/src/parse/parse.dart';

(CommentMap, CompilationUnit) attach(String source) {
  final parsed = parse(source);
  return (attachComments(parsed.unit, source), parsed.unit);
}

SourceComment only(CommentMap map) => map.all.single;

void main() {
  test('comment at file start leads the first declaration', () {
    final (map, unit) = attach('// header\nvar a = 1;\n');
    final c = only(map);
    expect(c.enclosing, same(unit));
    expect(c.preceding, isNull);
    expect(c.following, same(unit.declarations.first));
    expect(c.position, CommentPosition.ownLine);
    expect(map.leading[unit.declarations.first], [c]);
  });

  test('comment between members has both neighbours', () {
    final (map, unit) = attach(
      'class A {\n  int a = 0;\n  // b\n  int b = 0;\n}\n',
    );
    final members = (unit.declarations.single as ClassDeclaration).body.members;
    final c = only(map);
    expect(c.preceding, same(members.first));
    expect(c.following, same(members.last));
    expect(map.leading[members.last], [c]);
  });

  test('end-of-line comment in argument list trails the argument', () {
    final (map, unit) = attach('f() {\n  foo(a, // about a\n      b);\n}\n');
    final c = only(map);
    expect(c.enclosing, isA<ArgumentList>());
    expect(c.position, CommentPosition.endOfLine);
    expect(map.trailing[c.preceding], [c]);
    expect(c.preceding.toString(), 'a');
  });

  test('remaining comment leads the following argument', () {
    final (map, _) = attach('f() => foo(/* x */ a);\n');
    final c = only(map);
    expect(c.position, CommentPosition.remaining);
    expect(map.leading[c.following], [c]);
  });

  test('comment in an empty body is dangling', () {
    final (map, _) = attach('void init() {\n  // nothing yet\n}\n');
    final c = only(map);
    expect(c.enclosing, isA<Block>());
    expect(c.preceding, isNull);
    expect(c.following, isNull);
    expect(map.dangling[c.enclosing], [c]);
    expect(map.danglingBefore[c.nextToken], [c]);
  });

  test('doc comment leads its declaration, not the next one', () {
    final (map, unit) = attach('/// Doc for A.\nclass A {}\n\nclass B {}\n');
    expect(map.leading[unit.declarations.first], [only(map)]);
  });

  test('inline block comment before an operator trails the left operand', () {
    final (map, _) = attach('var x = a /* note */+ b;\n');
    final c = only(map);
    expect(c.enclosing, isA<BinaryExpression>());
    expect(map.trailing[c.preceding], [c]);
  });

  test('comment after a keyword token becomes dangling, not misplaced', () {
    final (map, _) = attach(
      'void f(bool x) {\n  if (x) // c\n    return;\n}\n',
    );
    final c = only(map);
    // `)` lies between `x` and the comment, so it leads the statement.
    expect(map.leading[c.following], [c]);
  });
}
