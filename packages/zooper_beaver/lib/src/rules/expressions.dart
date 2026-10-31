/// Expressions: operators, assignments, invocations and arguments, access,
/// function expressions, types, patterns.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';
import 'chains.dart';
import 'lists.dart';

extension ExpressionRules on DocBuilder {
  Doc? buildExpression(AstNode node) => switch (node) {
    AssignmentExpression() => assignmentLike(
      visit(node.leftHandSide),
      node.operator,
      node.rightHandSide,
    ),
    PatternAssignment() => assignmentLike(
      visit(node.pattern),
      node.equals,
      node.expression,
    ),
    PatternVariableDeclaration() => concat([
      for (final a in node.metadata) ...[visit(a), space],
      tok(node.keyword),
      space,
      assignmentLike(visit(node.pattern), node.equals, node.expression),
    ]),
    BinaryExpression() => binary(node),
    ConditionalExpression() => conditional(node),
    PrefixExpression() => concat([
      tok(node.operator),
      if (_needsSpaceAfterPrefix(node)) space,
      visit(node.operand),
    ]),
    PostfixExpression() when node.operator.type == TokenType.BANG => chain(
      node,
    ),
    PostfixExpression() => concat([visit(node.operand), tok(node.operator)]),
    AsExpression() => concat([
      visit(node.expression),
      space,
      tok(node.asOperator),
      if (config.spaceAfterCast || node.type is! RecordTypeAnnotation) space,
      visit(node.type),
    ]),
    IsExpression() => concat([
      visit(node.expression),
      space,
      tok(node.isOperator),
      tok(node.notOperator),
      space,
      visit(node.type),
    ]),
    ParenthesizedExpression() => concat([
      tok(node.leftParenthesis),
      visit(node.expression),
      tok(node.rightParenthesis),
    ]),
    AwaitExpression() => concat([
      tok(node.awaitKeyword),
      space,
      visit(node.expression),
    ]),
    ThrowExpression() => concat([
      tok(node.throwKeyword),
      space,
      visit(node.expression),
    ]),
    MethodInvocation(isCascaded: true) ||
    PropertyAccess(isCascaded: true) ||
    IndexExpression(isCascaded: true) => cascadeSection(node as Expression),
    MethodInvocation() ||
    PropertyAccess() ||
    IndexExpression() ||
    FunctionExpressionInvocation() => chain(node as Expression),
    CascadeExpression() => cascade(node),
    InstanceCreationExpression() => concat([
      if (node.keyword != null) ...[tok(node.keyword), space],
      visit(node.constructorName),
      visit(node.argumentList),
    ]),
    ConstructorName() => concat([
      visit(node.type),
      tok(node.period),
      visit(node.name),
    ]),
    ArgumentList() => argumentList(node),
    NamedArgument() => concat([
      tok(node.name),
      if (config.flag('spaces.before_colon_in_named_argument')) space,
      assignmentRhs(
        node.colon,
        node.argumentExpression,
        spaced: config.spaceAfterNamedColon,
      ),
    ]),
    PrefixedIdentifier() => concat([
      visit(node.prefix),
      tok(node.period),
      visit(node.identifier),
    ]),
    SimpleIdentifier() => tok(node.token),
    NamedType() => concat([
      visit(node.importPrefix),
      tok(node.name),
      visit(node.typeArguments),
      tok(node.question),
    ]),
    ImportPrefixReference() => concat([tok(node.name), tok(node.period)]),
    TypeArgumentList() => delimited(
      open: node.leftBracket,
      items: node.arguments,
      close: node.rightBracket,
      settings: config.arguments.unaligned,
      optionalTrailingComma: false,
    ),
    GenericFunctionType() => concat([
      if (node.returnType != null) ...[visit(node.returnType), space],
      tok(node.functionKeyword),
      visit(node.typeParameters),
      visit(node.parameters),
      tok(node.question),
    ]),
    RecordTypeAnnotation() => recordType(node),
    SymbolLiteral() => concat([
      tok(node.poundSign),
      for (
        Token? t = node.poundSign.next;
        t != null && t.offset < node.end;
        t = t.next
      )
        tok(t),
    ]),
    RecordLiteral() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      delimited(
        open: node.leftParenthesis,
        items: node.fields,
        close: node.rightParenthesis,
        settings: config.recordLiterals,
        spaceInside: config.spaceInsideParens,
        requiredTrailingComma:
            node.fields.length == 1 &&
            node.fields.single is! RecordLiteralNamedField,
      ),
    ]),
    RecordPattern() => delimited(
      open: node.leftParenthesis,
      items: node.fields,
      close: node.rightParenthesis,
      settings: config.recordLiterals,
      spaceInside: config.spaceInsideParens,
      requiredTrailingComma:
          node.fields.length == 1 && node.fields.single.name == null,
    ),
    ObjectPattern() => concat([
      visit(node.type),
      delimited(
        open: node.leftParenthesis,
        items: node.fields,
        close: node.rightParenthesis,
        settings: config.arguments.unaligned,
        spaceInside: config.spaceInsideParens,
        optionalTrailingComma: false,
      ),
    ]),
    PatternField() => concat([visit(node.name), visit(node.pattern)]),
    PatternFieldName() => concat([
      tok(node.name),
      tok(node.colon),
      if (node.name != null) space,
    ]),
    ListPattern() => concat([
      visit(node.typeArguments),
      delimited(
        open: node.leftBracket,
        items: node.elements,
        close: node.rightBracket,
        settings: config.collectionLiterals,
        spaceInside: config.spaceInsideBrackets,
        optionalTrailingComma: false,
      ),
    ]),
    MapPattern() => concat([
      visit(node.typeArguments),
      delimited(
        open: node.leftBracket,
        items: node.elements,
        close: node.rightBracket,
        settings: config.collectionLiterals,
        spaceInside: config.spaceInsideBraces,
        optionalTrailingComma: false,
      ),
    ]),
    MapPatternEntry() => concat([
      visit(node.key),
      if (config.flag('spaces.before_colon_in_map_entry')) space,
      tok(node.separator),
      if (config.flag('spaces.after_colon_in_map_entry')) space,
      visit(node.value),
    ]),
    LogicalOrPattern() || LogicalAndPattern() => binaryPattern(
      node as DartPattern,
    ),
    RelationalPattern() => concat([
      tok(node.operator),
      space,
      visit(node.operand),
    ]),
    CastPattern() => concat([
      visit(node.pattern),
      space,
      tok(node.asToken),
      space,
      visit(node.type),
    ]),
    NullCheckPattern() => concat([visit(node.pattern), tok(node.operator)]),
    NullAssertPattern() => concat([visit(node.pattern), tok(node.operator)]),
    ParenthesizedPattern() => concat([
      tok(node.leftParenthesis),
      visit(node.pattern),
      tok(node.rightParenthesis),
    ]),
    GuardedPattern() => group(
      concat([
        visit(node.pattern),
        if (node.whenClause != null)
          cont(concat([line, visit(node.whenClause)])),
      ]),
    ),
    WhenClause() => concat([
      tok(node.whenKeyword),
      space,
      visit(node.expression),
    ]),
    CaseClause() => concat([
      tok(node.caseKeyword),
      space,
      visit(node.guardedPattern),
    ]),
    SwitchExpression() => switchExpression(node),
    SwitchExpressionCase() => concat([
      visit(node.guardedPattern),
      space,
      assignmentRhs(node.arrow, node.expression, blockIndent: true),
    ]),
    IntegerLiteral() => tok(node.literal),
    DoubleLiteral() => tok(node.literal),
    BooleanLiteral() => tok(node.literal),
    NullLiteral() => tok(node.literal),
    ThisExpression() => tok(node.thisKeyword),
    SuperExpression() => tok(node.superKeyword),
    RethrowExpression() => tok(node.rethrowKeyword),
    LabelReference() => tok(node.name),
    CatchClauseParameter() => tok(node.name),
    FunctionReference() => concat([
      visit(node.function),
      visit(node.typeArguments),
    ]),
    DotShorthandInvocation() => concat([
      tok(node.period),
      visit(node.memberName),
      visit(node.typeArguments),
      visit(node.argumentList),
    ]),
    DotShorthandPropertyAccess() => concat([
      tok(node.period),
      visit(node.propertyName),
    ]),
    DotShorthandConstructorInvocation() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      tok(node.period),
      visit(node.constructorName),
      visit(node.typeArguments),
      visit(node.argumentList),
    ]),
    RecordLiteralNamedField() => concat([
      tok(node.name),
      if (config.flag('spaces.before_colon_in_named_argument')) space,
      tok(node.colon),
      if (config.spaceAfterNamedColon) space,
      visit(node.fieldExpression),
    ]),
    RecordTypeAnnotationField() => concat([
      for (final a in node.metadata) ...[visit(a), space],
      visit(node.type),
      if (node.name != null) ...[space, tok(node.name)],
    ]),
    ConstantPattern() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      visit(node.expression),
    ]),
    DeclaredVariablePattern() => spaced([
      tok(node.keyword),
      visit(node.type),
      tok(node.name),
    ]),
    AssignedVariablePattern() => tok(node.name),
    WildcardPattern() => spaced([
      tok(node.keyword),
      visit(node.type),
      tok(node.name),
    ]),
    RestPatternElement() => concat([tok(node.operator), visit(node.pattern)]),
    DeclaredIdentifier() => concat([
      for (final a in node.metadata) ...[visit(a), space],
      spaced([tok(node.keyword), visit(node.type), tok(node.name)]),
    ]),
    _ => null,
  };

  /// [parts] separated by single spaces, skipping empty ones.
  Doc spaced(List<Doc> parts) => join(space, [
    for (final part in parts)
      if (!identical(part, empty)) part,
  ]);

  /// Whether [left]'s last and [right]'s first character are both operator
  /// characters, so printing them adjacent could lex as another token.
  bool touchingOperators(Token left, Token right) {
    const operatorChars = '!%&*+-./:<=>?^|~@#';
    final a = left.lexeme, b = right.lexeme;
    return a.isNotEmpty &&
        b.isNotEmpty &&
        operatorChars.contains(a[a.length - 1]) &&
        operatorChars.contains(b[0]);
  }

  bool _needsSpaceAfterPrefix(PrefixExpression node) {
    final operator = node.operator.lexeme;
    if (operator != '-' && operator != '+') return false;
    final next = node.operand.beginToken.lexeme;
    return next.startsWith('-') || next.startsWith('+');
  }

  /// `lhs = rhs`, `lhs += rhs`, and friends.
  Doc assignmentLike(Doc lhs, Token operator, Expression rhs) => concat([
    lhs,
    if (config.spaceAroundAssignment) space,
    assignmentRhs(operator, rhs),
  ]);

  /// `= rhs` / `=> rhs` / `name: rhs`. A block-like right side (call,
  /// collection, function) stays on the operator's line and splits inside;
  /// a conditional keeps its condition there when that fits; anything else
  /// moves to the next line, with continuation indent ([blockIndent]: one
  /// indentation unit), when it does not fit. [spaced] overrides the
  /// operator's spacing rule.
  Doc assignmentRhs(
    Token operator,
    Expression rhs, {
    bool? spaced,
    bool blockIndent = false,
  }) {
    spaced ??= operator.type == TokenType.FUNCTION
        ? config.spaceAroundArrow
        : config.spaceAroundAssignment;
    final op = tok(operator);
    final lead = Line.soft(spaced ? ' ' : '');
    Doc nextLine(Doc doc) => blockIndent ? indent(doc) : cont(doc);
    // `wrap.break_before.arrow`/`assignment`: the operator starts the next
    // line. The space before it is printed by the caller.
    final before = switch (operator.type) {
      TokenType.FUNCTION => config.flag('wrap.break_before.arrow'),
      TokenType.COLON => false,
      _ => config.flag('wrap.break_before.assignment'),
    };
    final beforeLead = concat([softline, op, if (spaced) space]);
    Doc moved(Doc value) => before
        ? nextLine(concat([beforeLead, value]))
        : concat([op, nextLine(concat([lead, value]))]);
    // Built without [visit], so only when no comment hangs on the node itself.
    if (rhs is ConditionalExpression &&
        config.conditionalExpressions.policy != WrapPolicy.never &&
        comments.leading[rhs] == null &&
        comments.trailing[rhs] == null) {
      final split = before
          ? conditional(rhs, lead: beforeLead)
          : concat([op, conditional(rhs, lead: lead)]);
      // After `=>` it moves to the next line when it fits there whole. The
      // alternatives build it twice, so only when it holds no comment.
      if (operator.type != TokenType.FUNCTION ||
          hasCommentIn(rhs.offset, rhs.end)) {
        return split;
      }
      final value = visit(rhs);
      return ConditionalGroup([
        concat([op, if (spaced) space, value]),
        moved(value),
        split,
      ]);
    }
    // `wrap.binary_expressions.break_after_prefix: false`: the first operand
    // stays on the operator's line.
    if (rhs is BinaryExpression && !config.binaryBreakAfterPrefix) {
      return concat([op, if (spaced) space, visit(rhs)]);
    }
    // `wrap.chained_calls.break_after_prefix: true`: a chain moves like any
    // other non-block value.
    if (!isBlockLike(rhs) || (config.chainBreakAfterPrefix && isChain(rhs))) {
      return before
          ? group(moved(visit(rhs)))
          : concat([op, group(nextLine(concat([lead, visit(rhs)])))]);
    }
    final value = visit(rhs);
    final hugged = concat([op, if (spaced) space, value]);
    if (operator.type != TokenType.FUNCTION || _delimitedBody(rhs)) {
      return hugged;
    }
    // After `=>` a call or chain moves to the next line when it fits there
    // whole; otherwise it stays on the arrow's line if that line fits, and
    // moves to the next line, splitting there, if not.
    final next = moved(value);
    return ConditionalGroup(
      [hugged, next, hugged, next],
      firstLineOnly: const {2},
    );
  }

  /// Bodies that open their own block on the operator's line: collections,
  /// function literals, `switch`, multi-line strings, cascades.
  bool _delimitedBody(Expression expression) => switch (expression) {
    ListLiteral() || SetOrMapLiteral() || RecordLiteral() => true,
    FunctionExpression() || SwitchExpression() || CascadeExpression() => true,
    SingleStringLiteral(:final isMultiline) => isMultiline,
    _ => false,
  };

  /// Expressions whose own delimiters give a good split, so they need not
  /// move to a new line after `=`, `=>` or `:`.
  bool isBlockLike(Expression expression) => switch (expression) {
    ListLiteral() || SetOrMapLiteral() || RecordLiteral() => true,
    FunctionExpression() || SwitchExpression() || CascadeExpression() => true,
    InstanceCreationExpression() => true,
    MethodInvocation() => true,
    AssignmentExpression(:final rightHandSide) => isBlockLike(rightHandSide),
    PropertyAccess(:final target) =>
      isChain(expression) || (target != null && isBlockLike(target)),
    IndexExpression() => isChain(expression),
    FunctionExpressionInvocation() => true,
    AwaitExpression(:final expression) => isBlockLike(expression),
    SingleStringLiteral(:final isMultiline) => isMultiline,
    _ => false,
  };

  /// Whether [node] is the value after a prefix that moves it to its own
  /// line when its list's `break_after_prefix` is on.
  bool followsPrefix(AstNode node) {
    final parent = node.parent;
    return parent is VariableDeclaration ||
        parent is AssignmentExpression ||
        parent is ExpressionFunctionBody ||
        parent is FormalParameterDefaultClause ||
        parent is NamedArgument ||
        parent is PatternVariableDeclaration ||
        parent is SwitchExpressionCase;
  }

  /// Whether an operand chain hangs off something that already indents it:
  /// a prefix that moved it to its own line, or a block-indented control
  /// condition.
  bool _parentIndents(AstNode node) {
    final parent = node.parent;
    return (config.binaryBreakAfterPrefix && followsPrefix(node)) ||
        // `wrap.control_conditions: block` indents the condition itself.
        (config.values['wrap.control_conditions'] == 'block' &&
            (parent is IfStatement ||
                parent is WhileStatement ||
                parent is DoStatement));
  }

  Doc binary(BinaryExpression node) {
    final precedence = node.operator.type.precedence;
    final operands = <Expression>[];
    final operators = <Token>[];
    void collect(Expression e) {
      if (e is BinaryExpression &&
          e.operator.type.precedence == precedence &&
          (identical(e, node) ||
              (comments.leading[e] == null && comments.trailing[e] == null))) {
        collect(e.leftOperand);
        operators.add(e.operator);
        operands.add(e.rightOperand);
      } else {
        operands.add(e);
      }
    }

    collect(node);
    final settings = config.binaryExpressions;
    var policy = settings.policy;
    if (policy == WrapPolicy.never && hasLineCommentIn(node.offset, node.end)) {
      policy = WrapPolicy.chopIfLong;
    }
    final spaced = config.spaceAroundBinary;
    final before = config.breakBeforeBinaryOperator;
    // Without spaces, keep one where two operator characters would touch
    // and lex as a different token (`x! == y` → `x!==y`).
    bool spaceBetween(Token left, Token right) =>
        spaced || touchingOperators(left, right);
    // One segment per line the expression may split into.
    final segments = <Doc>[];
    for (var i = 0; i < operands.length; i++) {
      final operand = visit(operands[i]);
      final isLast = i == operands.length - 1;
      segments.add(
        before
            ? concat([
                if (i > 0) ...[
                  tok(operators[i - 1]),
                  if (spaceBetween(operators[i - 1], operands[i].beginToken))
                    space,
                ],
                operand,
              ])
            : concat([
                operand,
                if (!isLast) ...[
                  if (spaceBetween(operands[i].endToken, operators[i])) space,
                  tok(operators[i]),
                ],
              ]),
      );
    }
    // The line (or space) between segments sits where `before` puts it.
    final separatorTouches = [
      for (var i = 1; i < operands.length; i++)
        before
            ? touchingOperators(operands[i - 1].endToken, operators[i - 1])
            : touchingOperators(operators[i - 1], operands[i].beginToken),
    ];
    final kept = [
      for (var i = 0; i < operands.length; i++)
        i > 0 &&
            policy != WrapPolicy.never &&
            settings.keepExistingLineBreaks &&
            newlinesBetween(
                  operands[i - 1].end,
                  startWithComments(operands[i]),
                ) >
                0,
    ];
    final keepSpace = spaced || separatorTouches.contains(true);
    // Operands of this one same-precedence run count for `chop_from`.
    final threshold =
        policy != WrapPolicy.never &&
        settings.reachesThreshold(operands.length);
    final body = runs(
      segments,
      kept,
      separator: switch (policy) {
        WrapPolicy.never => keepSpace ? space : empty,
        _ when threshold => hardline,
        WrapPolicy.chopAlways => hardline,
        _ => Line.soft(keepSpace ? ' ' : ''),
      },
      fill: policy == WrapPolicy.ifLong && !threshold,
    );
    if (settings.align) return group(alignToColumn(body));
    // `indent_from: target`: offset from the first operand's column.
    if (config.binaryIndentFromTarget) {
      return group(alignToColumn(align(settings.indent, body)));
    }
    return group(_parentIndents(node) ? body : align(settings.indent, body));
  }

  /// `a || b || c` (or `&&`): the whole chain splits at once, continuation
  /// lines indented.
  Doc binaryPattern(DartPattern node) {
    final operands = <DartPattern>[];
    final operators = <Token>[];
    void collect(DartPattern p) {
      final (left, operator, right) = switch (p) {
        LogicalOrPattern() => (p.leftOperand, p.operator, p.rightOperand),
        LogicalAndPattern() => (p.leftOperand, p.operator, p.rightOperand),
        _ => (null, null, null),
      };
      if (operator != null &&
          operator.type == _patternOperator(node) &&
          (identical(p, node) ||
              (comments.leading[p] == null && comments.trailing[p] == null))) {
        collect(left!);
        operators.add(operator);
        operands.add(right!);
      } else {
        operands.add(p);
      }
    }

    collect(node);
    final before = config.breakBeforeBinaryOperator;
    final parts = <Doc>[];
    for (var i = 0; i < operands.length; i++) {
      if (i > 0) {
        parts.addAll(
          before
              ? [line, tok(operators[i - 1]), space]
              : [space, tok(operators[i - 1]), line],
        );
      }
      parts.add(visit(operands[i]));
    }
    // A switch expression arm's patterns line up; elsewhere they indent.
    final inArm = node.parent?.parent is SwitchExpressionCase;
    return group(inArm ? concat(parts) : cont(concat(parts)));
  }

  TokenType? _patternOperator(DartPattern p) => switch (p) {
    LogicalOrPattern(:final operator) || LogicalAndPattern(:final operator) =>
      operator.type,
    _ => null,
  };

  /// `c ? a : b`. With [lead] (the line after `=`, `=>` or `:`), the
  /// condition stays on the operator's line only when it fits there.
  Doc conditional(ConditionalExpression node, {Doc? lead}) {
    final settings = config.conditionalExpressions;
    var policy = settings.policy;
    if (policy == WrapPolicy.never && hasLineCommentIn(node.offset, node.end)) {
      policy = WrapPolicy.chopIfLong;
    }
    // With `wrap.break_before.conditional_operator: false`, `?` and `:` end
    // their lines instead of starting them.
    final before = config.flag('wrap.break_before.conditional_operator');
    bool keptAt(Token operator) {
      if (policy == WrapPolicy.never || !settings.keepExistingLineBreaks) {
        return false;
      }
      final (from, to) = before
          ? (operator.previous!.end, operator.offset)
          : (operator.end, operator.next!.offset);
      return newlinesBetween(from, to) > 0;
    }

    // `a ? b : c ? d : e` is one chain: the nested condition follows `: `.
    final operands = <(Expression, bool)>[(node.condition, false)];
    final operators = <Token>[];
    var current = node;
    while (true) {
      operators.add(current.question);
      operands.add((current.thenExpression, true));
      operators.add(current.colon);
      final otherwise = current.elseExpression;
      if (otherwise is ConditionalExpression &&
          comments.leading[otherwise] == null &&
          comments.trailing[otherwise] == null) {
        operands.add((otherwise.condition, false));
        current = otherwise;
        continue;
      }
      operands.add((otherwise, true));
      break;
    }
    final segments = <Doc>[];
    final kept = <bool>[false];
    for (final (i, (expression, isBranch)) in operands.indexed) {
      // A branch's own wrapped lines indent past its `? ` or `: `.
      final value = before && isBranch
          ? align(2, visit(expression))
          : visit(expression);
      final segment = before
          ? concat([
              if (i > 0) ...[tok(operators[i - 1]), space],
              value,
            ])
          : concat([
              value,
              if (i < operators.length) ...[space, tok(operators[i])],
            ]);
      segments.add(
        i == 0 && lead != null ? group(concat([lead, segment])) : segment,
      );
      if (i > 0) kept.add(keptAt(operators[i - 1]));
    }
    final threshold =
        policy != WrapPolicy.never &&
        settings.reachesThreshold(segments.length);
    final body = runs(
      segments,
      kept,
      separator: switch (policy) {
        WrapPolicy.never => space,
        _ when threshold => hardline,
        WrapPolicy.chopAlways => hardline,
        _ => line,
      },
      fill: policy == WrapPolicy.ifLong && !threshold,
    );
    return group(cont(body));
  }

  Doc argumentList(ArgumentList node) {
    final arguments = node.arguments;
    final names = config.chopOnNamedArguments;
    final namedMatch =
        names.isNotEmpty &&
        arguments.any(
          (a) => a is NamedArgument && names.contains(a.name.lexeme),
        );
    final callMatch = _matchesChopOnCalls(node);
    final settings = config.arguments;
    final policy = settings.policy;
    Doc chopped() => delimited(
      open: node.leftParenthesis,
      items: arguments,
      close: node.rightParenthesis,
      settings: settings,
      spaceInside: config.spaceInsideParens,
      forceChop: namedMatch || callMatch,
    );
    final block =
        config.flag('wrap.arguments.hug_block_argument') &&
            policy != WrapPolicy.never &&
            policy != WrapPolicy.chopAlways &&
            !namedMatch &&
            !callMatch &&
            !settings.reachesThreshold(arguments.length) &&
            !settings.align
        ? _hugBlock(node)
        : null;
    if (block == null) return chopped();
    // The other arguments print flat around the hugged one, so a split
    // there can never read as a kept break next time.
    Doc hugged() => concat([
      tok(node.leftParenthesis),
      if (config.spaceInsideParens) space,
      for (final (i, argument) in arguments.indexed) ...[
        identical(argument, block)
            ? visit(argument)
            : printedFlat(visit(argument)),
        if (i < arguments.length - 1) ...[
          tok(argument.endToken.next),
          if (config.spaceAfterComma) space,
        ],
      ],
      if (config.spaceInsideParens) space,
      tok(node.rightParenthesis),
    ]);
    final others = arguments.where((a) => !identical(a, block));
    if (others.every(_isAtomic)) return hugged();
    // Simple but longer arguments: hug only if the line up to the block
    // fits; otherwise chop. Both layouts are built, so only without
    // comments.
    if (!others.every(_isSimple) ||
        hasCommentIn(
          node.leftParenthesis.previous?.end ?? 0,
          node.rightParenthesis.end,
        )) {
      return chopped();
    }
    final hug = hugged();
    return ConditionalGroup([hug, hug, chopped()], firstLineOnly: const {1});
  }

  /// Whether the invocation owning [node] has a callable name matching a
  /// `wrap.chop_on_calls` entry: a one-segment entry matches the final or
  /// penultimate segment, a longer one the complete suffix.
  bool _matchesChopOnCalls(ArgumentList node) {
    final entries = config.chopOnCalls;
    if (entries.isEmpty) return false;
    final name = switch (node.parent) {
      MethodInvocation(:final target, :final methodName) => target == null
          ? [methodName.name]
          : switch (_dottedName(target)) {
              final prefix? => [...prefix, methodName.name],
              null => null,
            },
      InstanceCreationExpression(:final constructorName) => [
        if (constructorName.type.importPrefix case final prefix?)
          prefix.name.lexeme,
        constructorName.type.name.lexeme,
        if (constructorName.name case final name?) name.name,
      ],
      FunctionExpressionInvocation(:final function) => _dottedName(function),
      _ => null,
    };
    if (name == null) return false;
    bool endsWith(List<String> suffix, int skip) {
      final end = name.length - skip;
      if (end < suffix.length) return false;
      for (var i = 0; i < suffix.length; i++) {
        if (name[end - suffix.length + i] != suffix[i]) return false;
      }
      return true;
    }

    return entries.any(
      (entry) => entry.length == 1
          ? endsWith(entry, 0) || endsWith(entry, 1)
          : endsWith(entry, 0),
    );
  }

  /// The segments of `a.b.c`, or `null` for anything computed.
  List<String>? _dottedName(Expression expression) => switch (expression) {
    SimpleIdentifier(:final name) => [name],
    PrefixedIdentifier(:final prefix, :final identifier) => [
      prefix.name,
      identifier.name,
    ],
    PropertyAccess(:final target?, :final propertyName, :final operator)
        when operator.type == TokenType.PERIOD => switch (_dottedName(target)) {
      final prefix? => [...prefix, propertyName.name],
      null => null,
    },
    _ => null,
  };

  /// The one argument that is a block-bodied function or a collection, with
  /// no trailing comma, kept breaks or other block arguments, that may hug
  /// the parentheses: `foo(a, () {` ... `})`, `f(a, [` ... `], b)`.
  AstNode? _hugBlock(ArgumentList node) {
    final arguments = node.arguments;
    if (arguments.isEmpty || hasTrailingComma(arguments.last)) return null;
    bool isBlock(AstNode argument) {
      final expression = argument is NamedArgument
          ? argument.argumentExpression
          : argument;
      return switch (expression) {
        FunctionExpression(:final body) => body is BlockFunctionBody,
        ListLiteral(:final elements) || SetOrMapLiteral(:final elements) =>
          elements.isNotEmpty,
        // A record hugs only as the sole argument: `add((a, b))`.
        RecordLiteral(:final fields) =>
          arguments.length == 1 && fields.length > 1,
        _ => false,
      };
    }

    final blocks = arguments.where(isBlock).toList();
    if (blocks.length != 1) return null;
    final block = blocks.single;
    // Outside the block, arguments are joined by plain spaces.
    final before = (node.leftParenthesis.end, startWithComments(block));
    final after = (endWithComments(block), node.rightParenthesis.offset);
    for (final (from, to) in [before, after]) {
      if (config.arguments.keepExistingLineBreaks &&
          newlinesBetween(from, to) > 0) {
        return null;
      }
      if (hasLineCommentIn(from, to)) return null;
    }
    return comments.leading[block] == null ? block : null;
  }

  /// Expressions that read well printed flat: atoms, and calls, accesses
  /// and indexes made of them.
  bool _isSimple(AstNode node) =>
      _isAtomic(node) ||
      switch (node) {
        NamedArgument(:final argumentExpression) =>
          _isSimple(argumentExpression),
        MethodInvocation(:final target, :final argumentList) =>
          (target == null || _isSimple(target)) &&
          argumentList.arguments.every(_isSimple),
        InstanceCreationExpression(:final argumentList) =>
          argumentList.arguments.every(_isSimple),
        PropertyAccess(:final target) => target != null && _isSimple(target),
        IndexExpression(:final target, :final index) =>
          target != null && _isSimple(target) && _isSimple(index),
        PostfixExpression(:final operand) => _isSimple(operand),
        StringInterpolation() => true,
        _ => false,
      };

  /// Expressions with no place to split.
  bool _isAtomic(AstNode node) => switch (node) {
    NamedArgument(:final argumentExpression) => _isAtomic(argumentExpression),
    SimpleIdentifier() || PrefixedIdentifier() || ThisExpression() => true,
    BooleanLiteral() || IntegerLiteral() || DoubleLiteral() || NullLiteral() =>
      true,
    SimpleStringLiteral(:final isMultiline) => !isMultiline,
    PropertyAccess(:final target) => target != null && _isAtomic(target),
    PrefixExpression(:final operand) => _isAtomic(operand),
    _ => false,
  };

  Doc recordType(RecordTypeAnnotation node) {
    final positional = node.positionalFields;
    final named = node.namedFields;
    return concat([
      delimited(
        open: node.leftParenthesis,
        items: [...positional, ...?named?.fields],
        close: node.rightParenthesis,
        settings: config.recordTypes,
        spaceInside: config.spaceInsideParens,
        requiredTrailingComma: positional.length == 1 && named == null,
        leftDelimiter: named?.leftBracket,
        rightDelimiter: named?.rightBracket,
        optionalStart: named == null ? -1 : positional.length,
        optionalNode: named,
      ),
      tok(node.question),
    ]);
  }

  /// `switch (x) { a => 1, b => 2 }`, arms laid out per
  /// `wrap.switch_expressions`. Arm commas print exactly as in the source.
  Doc switchExpression(SwitchExpression node) {
    final settings = config.switchExpressions;
    final cases = node.cases;
    var policy = settings.policy;
    if (policy == WrapPolicy.never &&
        hasLineCommentIn(node.leftBracket.end, node.rightBracket.offset)) {
      policy = WrapPolicy.chopIfLong;
    }
    final never = policy == WrapPolicy.never;
    final forced =
        !never &&
        (policy == WrapPolicy.chopAlways ||
            settings.reachesThreshold(cases.length));
    final kept = [
      for (final (i, c) in cases.indexed)
        !never &&
            settings.keepExistingLineBreaks &&
            newlinesBetween(
                  i == 0
                      ? node.leftBracket.end
                      : cases[i - 1].endToken.next!.end,
                  startWithComments(c),
                ) >
                0,
    ];
    final separator = never ? space : (forced ? hardline : line);
    final arms = <Doc>[];
    for (final (i, c) in cases.indexed) {
      arms.add(
        concat([
          visit(c),
          // Case commas are not in the optional-comma allowlist: keep as is.
          if (i < cases.length - 1 || hasTrailingComma(c)) tok(c.endToken.next),
        ]),
      );
    }
    // Blank lines between arms survive where the arms break.
    Doc blank(int i) =>
        !never && capBlank(blankLinesBetween(cases[i - 1], cases[i])) > 0
        ? IfBreak(softline)
        : empty;
    Doc between(int i) => concat([separator, blank(i)]);

    final Doc body;
    if (forced || !kept.skip(1).contains(true)) {
      final parts = <Doc>[];
      for (var i = 0; i < arms.length; i++) {
        if (i > 0) parts.add(between(i));
        parts.add(arms[i]);
      }
      body = policy == WrapPolicy.ifLong && !forced
          ? Fill([
              for (var i = 0; i < arms.length; i++) ...[
                if (i > 0) separator,
                arms[i],
              ],
            ])
          : concat(parts);
    } else {
      final parts = <Doc>[];
      var start = 0;
      for (var i = 1; i <= arms.length; i++) {
        if (i < arms.length && !kept[i]) continue;
        if (start > 0) parts.addAll([hardline, blank(start)]);
        parts.add(
          group(
            concat([
              for (var k = start; k < i; k++) ...[
                if (k > start) between(k),
                arms[k],
              ],
            ]),
          ),
        );
        start = i;
      }
      body = concat(parts);
    }
    final edge = never ? space : (forced || kept[0] ? hardline : line);
    return concat([
      tok(node.switchKeyword),
      if (config.spaceBeforeControlParens) space,
      tok(node.leftParenthesis),
      visit(node.expression),
      tok(node.rightParenthesis),
      space,
      cases.isEmpty
          ? emptyDelimited(node.leftBracket, node.rightBracket)
          : group(
              concat([
                tok(node.leftBracket),
                indent(concat([edge, body])),
                edge,
                tok(node.rightBracket),
              ]),
            ),
    ]);
  }
}
