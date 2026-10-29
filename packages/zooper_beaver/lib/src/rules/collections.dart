/// Collection literals and their elements.
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../ir/doc.dart';
import 'builder.dart';
import 'lists.dart';
import 'statements.dart';

extension CollectionRules on DocBuilder {
  Doc? buildCollection(AstNode node) => switch (node) {
    ListLiteral() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      visit(node.typeArguments),
      delimited(
        open: node.leftBracket,
        items: node.elements,
        close: node.rightBracket,
        policy: config.wrapCollections,
        spaceInside: config.spaceInsideBrackets,
      ),
    ]),
    SetOrMapLiteral() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      visit(node.typeArguments),
      delimited(
        open: node.leftBracket,
        items: node.elements,
        close: node.rightBracket,
        policy: config.wrapCollections,
        spaceInside: config.spaceInsideBraces,
      ),
    ]),
    MapLiteralEntry() => concat([
      tok(node.keyQuestion),
      visit(node.key),
      tok(node.separator),
      space,
      tok(node.valueQuestion),
      visit(node.value),
    ]),
    SpreadElement() => concat([
      tok(node.spreadOperator),
      visit(node.expression),
    ]),
    NullAwareElement() => concat([tok(node.question), visit(node.value)]),
    IfElement() => _ifElement(node),
    ForElement() => group(
      concat([
        if (node.awaitKeyword != null) ...[tok(node.awaitKeyword), space],
        forHead(
          node.forKeyword,
          node.leftParenthesis,
          node.forLoopParts,
          node.rightParenthesis,
        ),
        _body(node.body),
      ]),
    ),
    _ => null,
  };

  /// An `if`/`for` element's body: hugged, or on its own line when the
  /// element splits, and always when it is another `if` or `for`.
  Doc _body(CollectionElement body) {
    if (_hugs(body)) return concat([space, visit(body)]);
    final nested = body is IfElement || body is ForElement;
    return indent(concat([nested ? hardline : line, visit(body)]));
  }

  /// A collection (or a spread of one) as an `if`/`for` element's body
  /// stays on the head's line and splits inside: `if (c) ...[`.
  bool _hugs(CollectionElement element) => switch (element) {
    SpreadElement(:final expression) => _hugs(expression),
    ListLiteral(:final elements) || SetOrMapLiteral(:final elements) =>
      elements.isNotEmpty,
    _ => false,
  };

  Doc _ifElement(IfElement node) {
    final elseElement = node.elseElement;
    final caseClause = node.caseClause;
    return group(
      concat([
        controlHead(node.ifKeyword, node.leftParenthesis, [
          visit(node.expression),
          if (caseClause != null) ...[space, visit(caseClause)],
        ], node.rightParenthesis),
        _body(node.thenElement),
        if (elseElement != null) ...[
          _hugs(node.thenElement) ? space : line,
          tok(node.elseKeyword),
          elseElement is IfElement || _hugs(elseElement)
              ? concat([space, visit(elseElement)])
              : indent(concat([line, visit(elseElement)])),
        ],
      ]),
    );
  }
}
