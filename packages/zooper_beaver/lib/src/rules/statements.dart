/// Statements: blocks, control flow, switch, try, jumps.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../ir/doc.dart';
import 'builder.dart';
import 'expressions.dart';
import 'lists.dart';

extension StatementRules on DocBuilder {
  Doc? buildStatement(AstNode node) => switch (node) {
    Block() => block(node),
    ExpressionStatement() => concat([
      visit(node.expression),
      tok(node.semicolon),
    ]),
    VariableDeclarationStatement() => concat([
      visit(node.variables),
      tok(node.semicolon),
    ]),
    PatternVariableDeclarationStatement() => concat([
      visit(node.declaration),
      tok(node.semicolon),
    ]),
    FunctionDeclarationStatement() => visit(node.functionDeclaration),
    EmptyStatement() => tok(node.semicolon),
    ReturnStatement() => keywordStatement(
      node.returnKeyword,
      node.expression,
      node.semicolon,
    ),
    BreakStatement() => keywordStatement(
      node.breakKeyword,
      node.label,
      node.semicolon,
    ),
    ContinueStatement() => keywordStatement(
      node.continueKeyword,
      node.label,
      node.semicolon,
    ),
    YieldStatement() => concat([
      tok(node.yieldKeyword),
      tok(node.star),
      space,
      visit(node.expression),
      tok(node.semicolon),
    ]),
    IfStatement() => ifStatement(node),
    WhileStatement() => concat([
      controlHead(node.whileKeyword, node.leftParenthesis, [
        visit(node.condition),
      ], node.rightParenthesis),
      controlBody(node.body),
    ]),
    DoStatement() => concat([
      tok(node.doKeyword),
      controlBody(node.body),
      node.body is Block ? space : hardline,
      controlHead(node.whileKeyword, node.leftParenthesis, [
        visit(node.condition),
      ], node.rightParenthesis),
      tok(node.semicolon),
    ]),
    ForStatement() => concat([
      if (node.awaitKeyword != null) ...[tok(node.awaitKeyword), space],
      forHead(
        node.forKeyword,
        node.leftParenthesis,
        node.forLoopParts,
        node.rightParenthesis,
      ),
      controlBody(node.body),
    ]),
    ForPartsWithDeclarations() => forParts(node, visit(node.variables)),
    ForPartsWithExpression() => forParts(node, visit(node.initialization)),
    ForPartsWithPattern() => forParts(node, visit(node.variables)),
    ForEachPartsWithDeclaration() => forEachParts(
      node,
      visit(node.loopVariable),
    ),
    ForEachPartsWithIdentifier() => forEachParts(node, visit(node.identifier)),
    ForEachPartsWithPattern() => forEachParts(
      node,
      concat([
        for (final annotation in node.metadata) ...[visit(annotation), space],
        tok(node.keyword),
        space,
        visit(node.pattern),
      ]),
    ),
    SwitchStatement() => switchStatement(node),
    SwitchCase() => switchMember(node, [
      tok(node.keyword),
      space,
      visit(node.expression),
    ]),
    SwitchPatternCase() => switchMember(node, [
      tok(node.keyword),
      space,
      visit(node.guardedPattern),
    ]),
    SwitchDefault() => switchMember(node, [tok(node.keyword)]),
    TryStatement() => tryStatement(node),
    CatchClause() => catchClause(node),
    LabeledStatement() => concat([
      for (final label in node.labels) ...[visit(label), hardline],
      visit(node.statement),
    ]),
    Label() => concat([tok(node.name), tok(node.colon)]),
    AssertStatement() => concat([assertion(node), tok(node.semicolon)]),
    _ => null,
  };

  Doc block(Block node) {
    final statements = node.statements;
    if (statements.length == 1 && _oneLineAllowed(node)) {
      final statement = statements.single;
      final hasComments =
          comments.leading[statement] != null ||
          comments.trailing[statement] != null ||
          comments.danglingBefore[node.rightBracket] != null;
      if (!hasComments) {
        return group(
          concat([
            tok(node.leftBracket),
            indent(concat([line, visit(statement)])),
            line,
            tok(node.rightBracket),
          ]),
        );
      }
    }
    return braces(
      node.leftBracket,
      statements.isEmpty ? null : sequence(statements),
      node.rightBracket,
    );
  }

  /// Whether a one-statement [block] may print as `{ statement }` when it
  /// fits: lambda bodies under `simple_lambdas_on_one_line`, other blocks
  /// that are not declaration bodies under `simple_blocks_on_one_line`.
  bool _oneLineAllowed(Block block) {
    final parent = block.parent;
    if (parent is BlockFunctionBody) {
      return parent.parent is FunctionExpression &&
          parent.parent!.parent is! FunctionDeclaration &&
          config.simpleLambdasOnOneLine;
    }
    return config.simpleBlocksOnOneLine;
  }

  /// `return expr;`, `break label;`.
  Doc keywordStatement(Token keyword, AstNode? operand, Token semicolon) =>
      concat([
        tok(keyword),
        if (operand != null) ...[space, visit(operand)],
        tok(semicolon),
      ]);

  /// `if (` parts `)`.
  Doc controlHead(Token keyword, Token open, List<Doc> parts, Token close) =>
      concat([
        tok(keyword),
        if (config.spaceBeforeControlParens) space,
        tok(open),
        if (config.spaceInsideParens) space,
        ...parts,
        if (config.spaceInsideParens) space,
        tok(close),
      ]);

  /// A block after ` `, `;` glued, any other statement on the next line
  /// unless it fits.
  Doc controlBody(Statement body, {bool forceBreak = false}) => switch (body) {
    Block() => concat([space, visit(body)]),
    EmptyStatement() => visit(body),
    _ => group(indent(concat([line, visit(body)])), shouldBreak: forceBreak),
  };

  Doc ifStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    final then = node.thenStatement;
    final caseClause = node.caseClause;
    return concat([
      controlHead(node.ifKeyword, node.leftParenthesis, [
        visit(node.expression),
        if (caseClause != null) ...[space, visit(caseClause)],
      ], node.rightParenthesis),
      controlBody(then, forceBreak: elseStatement != null),
      if (elseStatement != null) ...[
        then is Block && !config.elseOnNewLine ? space : hardline,
        tok(node.elseKeyword),
        switch (elseStatement) {
          IfStatement() => concat([space, visit(elseStatement)]),
          Block() => concat([space, visit(elseStatement)]),
          _ => controlBody(elseStatement, forceBreak: true),
        },
      ],
    ]);
  }

  /// `init; cond; updaters`, splitting like an argument list when long.
  Doc forParts(ForParts node, Doc initializer) {
    final condition = node.condition;
    final updaters = node.updaters;
    return concat([
      initializer,
      tok(node.leftSeparator),
      if (condition != null) ...[line, visit(condition)],
      tok(node.rightSeparator),
      if (updaters.isNotEmpty) ...[line, commaSeparated(updaters)],
    ]);
  }

  /// `for (parts)`: classic `for` parts break like an argument list.
  Doc forHead(Token forKeyword, Token open, ForLoopParts parts, Token close) {
    if (parts is! ForParts) {
      return controlHead(forKeyword, open, [visit(parts)], close);
    }
    return concat([
      tok(forKeyword),
      if (config.spaceBeforeControlParens) space,
      group(
        concat([
          tok(open),
          indent(
            concat([
              softline,
              visit(parts),
              // A trailing comma after the updaters is outside `parts`.
              if (parts.endToken.next?.type == TokenType.COMMA)
                tok(parts.endToken.next),
              danglingBeforeClose(close),
            ]),
          ),
          softline,
          tok(close),
        ]),
      ),
    ]);
  }

  /// `variable in iterable`, splitting before `in` when it does not fit,
  /// unless the iterable splits better itself (a collection or a call).
  Doc forEachParts(ForEachParts node, Doc variable) {
    final iterable = node.iterable;
    if (isBlockLike(iterable)) {
      return concat([
        variable,
        space,
        tok(node.inKeyword),
        space,
        visit(iterable),
      ]);
    }
    return group(
      concat([
        variable,
        cont(concat([line, tok(node.inKeyword), space, visit(iterable)])),
      ]),
    );
  }

  Doc switchStatement(SwitchStatement node) {
    final members = node.members;
    final body = members.isEmpty ? null : sequence(members);
    return concat([
      controlHead(node.switchKeyword, node.leftParenthesis, [
        visit(node.expression),
      ], node.rightParenthesis),
      space,
      if (config.indentSwitchCases)
        braces(node.leftBracket, body, node.rightBracket)
      else
        concat([
          tok(node.leftBracket),
          if (body != null) ...[hardline, body],
          hardline,
          tok(node.rightBracket),
        ]),
    ]);
  }

  Doc switchMember(SwitchMember node, List<Doc> head) {
    final statements = node.statements;
    return concat([
      for (final label in node.labels) ...[visit(label), hardline],
      ...head,
      tok(node.colon),
      if (statements.isNotEmpty)
        indent(concat([hardline, sequence(statements)])),
    ]);
  }

  Doc tryStatement(TryStatement node) {
    final separator = config.elseOnNewLine ? hardline : space;
    return concat([
      tok(node.tryKeyword),
      space,
      visit(node.body),
      for (final clause in node.catchClauses) ...[separator, visit(clause)],
      if (node.finallyBlock != null) ...[
        separator,
        tok(node.finallyKeyword),
        space,
        visit(node.finallyBlock),
      ],
    ]);
  }

  Doc catchClause(CatchClause node) {
    final exceptionType = node.exceptionType;
    return concat([
      if (exceptionType != null) ...[
        tok(node.onKeyword),
        space,
        visit(exceptionType),
        space,
      ],
      if (node.catchKeyword != null) ...[
        tok(node.catchKeyword),
        if (config.spaceBeforeControlParens) space,
        tok(node.leftParenthesis),
        visit(node.exceptionParameter),
        if (node.stackTraceParameter != null) ...[
          tok(node.comma),
          space,
          visit(node.stackTraceParameter),
        ],
        tok(node.rightParenthesis),
        space,
      ],
      visit(node.body),
    ]);
  }

  Doc assertion(Assertion node) => concat([
    tok(node.assertKeyword),
    delimited(
      open: node.leftParenthesis,
      items: [node.condition, ?node.message],
      close: node.rightParenthesis,
      policy: config.wrapArguments,
      spaceInside: config.spaceInsideParens,
      optionalTrailingComma: false,
    ),
  ]);
}
