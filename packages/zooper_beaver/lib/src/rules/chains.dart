/// Method chains and cascades.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';

/// One `.call(...)`, `.property`, `[index]`, `!` or `(args)` after a target.
final class _Selector {
  _Selector(
    this.doc, {
    required this.isCall,
    this.isMember = false,
    this.start = 0,
    this.previousEnd = 0,
  });
  final Doc doc;
  final bool isCall;

  /// Source offset of the selector, and of the end of what precedes it, for
  /// kept line breaks.
  final int start;
  final int previousEnd;

  /// A `.name` selector (call or property), which can start a line.
  final bool isMember;
}

extension ChainRules on DocBuilder {
  /// Whether [expression] has two or more calls after its target. Pure:
  /// builds no docs, so no comment is marked printed.
  bool isChain(Expression expression) {
    var calls = 0;
    Expression? current = expression;
    while (current != null) {
      switch (current) {
        case MethodInvocation(:final target) when !current.isCascaded:
          if (target != null) calls++;
          current = target;
        case PropertyAccess(:final target) when !current.isCascaded:
          current = target;
        case IndexExpression(:final target) when !current.isCascaded:
          current = target;
        case PostfixExpression(:final operand)
            when current.operator.type == TokenType.BANG:
          current = operand;
        case FunctionExpressionInvocation(:final function):
          current = function;
        default:
          current = null;
      }
    }
    return calls >= 2;
  }

  /// A target followed by selectors. With fewer than two calls the selectors
  /// print attached; otherwise, from the first call on, each `.member` (with
  /// the indexes, `!` and arguments after it) may move to its own line with
  /// continuation indent, per `wrap.chained_calls`, or aligned under the
  /// first `.` with `indent.align.chained_calls` while the target is flat.
  Doc chain(Expression expression) {
    final (target, selectors) = _unwind(expression);
    final calls = selectors.where((s) => s.isCall).length;
    if (calls < 2) {
      return concat([target, for (final s in selectors) s.doc]);
    }

    // Properties before the first call stay with the target.
    final head = <Doc>[];
    var i = 0;
    while (!selectors[i].isCall) {
      head.add(selectors[i++].doc);
    }
    final lines = <Doc>[];
    final kept = <bool>[];
    for (; i < selectors.length; i++) {
      final selector = selectors[i];
      if (selector.isMember || lines.isEmpty) {
        lines.add(selector.doc);
        kept.add(
          config.keepExistingLineBreaks &&
              newlinesBetween(selector.previousEnd, selector.start) > 0,
        );
      } else {
        lines[lines.length - 1] = concat([lines.last, selector.doc]);
      }
    }

    var policy = config.wrapChains;
    if (policy == WrapPolicy.never) {
      if (!hasLineCommentIn(expression.offset, expression.end)) {
        return concat([target, ...head, ...lines]);
      }
      policy = WrapPolicy.chopIfLong;
    }
    final minCalls = config.chainMinCalls;
    final forced =
        (minCalls > 0 && calls >= minCalls) ||
        (policy == WrapPolicy.chopAlways && !config.chainKeepSingleLineIfFits);

    // Lines separated as configured; kept source breaks are hard and split
    // the rest into runs that break on their own.
    Doc separated(
      List<Doc> items,
      List<bool> keptBefore, {
      required bool first,
    }) {
      // [leading]: a separator before the run's first item.
      Doc layoutRun(int from, int to, {required bool leading}) {
        final parts = <Doc>[];
        for (var k = from; k < to; k++) {
          if (k > from || leading) parts.add(forced ? hardline : softline);
          parts.add(items[k]);
        }
        return policy == WrapPolicy.ifLong
            ? Fill(_fillParts(parts))
            : concat(parts);
      }

      if (forced || !keptBefore.contains(true)) {
        return layoutRun(0, items.length, leading: first);
      }
      final parts = <Doc>[];
      var start = 0;
      for (var k = 1; k <= items.length; k++) {
        if (k == items.length || keptBefore[k]) {
          final keptStart = keptBefore[start];
          if (start > 0 || (first && keptStart)) parts.add(hardline);
          parts.add(
            group(
              layoutRun(start, k, leading: start == 0 && first && !keptStart),
            ),
          );
          start = k;
        }
      }
      return concat(parts);
    }

    final continued = cont(separated(lines, kept, first: true));
    if (!config.alignChainedCalls) {
      return group(concat([target, ...head, continued]));
    }
    // Alignment: aligned under the first call's `.` while the target printed flat,
    // continuation indent otherwise.
    final anchor = GroupId('chain target');
    final aligned = Align.toColumn(
      concat([
        lines.first,
        separated(lines.sublist(1), kept.sublist(1), first: true),
      ]),
    );
    return group(
      concat([
        group(concat([target, ...head]), id: anchor),
        IfBreak(continued, aligned, anchor),
      ]),
    );
  }

  /// [parts] (content, separator, content, ...) as Fill expects them; a
  /// leading separator is merged into an empty first content.
  List<Doc> _fillParts(List<Doc> parts) =>
      parts.isNotEmpty && parts.first is Line ? [empty, ...parts] : parts;

  (Doc, List<_Selector>) _unwind(Expression expression) {
    final selectors = <_Selector>[];
    var current = expression;
    bool hasComments(AstNode node) =>
        !identical(node, expression) &&
        (comments.leading[node] != null || comments.trailing[node] != null);

    while (!hasComments(current)) {
      switch (current) {
        case MethodInvocation(:final target?) when !current.isCascaded:
          selectors.add(
            _Selector(
              concat([
                tok(current.operator),
                visit(current.methodName),
                visit(current.typeArguments),
                visit(current.argumentList),
              ]),
              isCall: true,
              isMember: true,
              start: current.operator!.offset,
              previousEnd: target.end,
            ),
          );
          current = target;
        case PropertyAccess(:final target?) when !current.isCascaded:
          selectors.add(
            _Selector(
              concat([tok(current.operator), visit(current.propertyName)]),
              isCall: false,
              isMember: true,
              start: current.operator.offset,
              previousEnd: target.end,
            ),
          );
          current = target;
        case IndexExpression(:final target?) when !current.isCascaded:
          selectors.add(_Selector(_index(current), isCall: false));
          current = target;
        case PostfixExpression(:final operand)
            when current.operator.type == TokenType.BANG:
          selectors.add(_Selector(tok(current.operator), isCall: false));
          current = operand;
        case FunctionExpressionInvocation(:final function):
          selectors.add(
            _Selector(
              concat([
                visit(current.typeArguments),
                visit(current.argumentList),
              ]),
              isCall: false,
            ),
          );
          current = function;
        default:
          return (_leaf(current, expression), selectors.reversed.toList());
      }
    }
    return (visit(current), selectors.reversed.toList());
  }

  /// The innermost target: printed through [visit] unless it is the chain's
  /// own node (a call with no target), which has no selectors to unwind.
  Doc _leaf(Expression leaf, Expression whole) {
    if (!identical(leaf, whole)) return visit(leaf);
    return switch (leaf) {
      MethodInvocation() => concat([
        tok(leaf.operator),
        visit(leaf.methodName),
        visit(leaf.typeArguments),
        visit(leaf.argumentList),
      ]),
      PropertyAccess() => concat([
        tok(leaf.operator),
        visit(leaf.propertyName),
      ]),
      IndexExpression() => _index(leaf),
      _ => generic(leaf),
    };
  }

  Doc _index(IndexExpression node) => concat([
    tok(node.period),
    tok(node.question),
    tok(node.leftBracket),
    visit(node.index),
    tok(node.rightBracket),
  ]);

  Doc cascade(CascadeExpression node) {
    final sections = node.cascadeSections;
    final target = node.target;
    if (sections.length == 1 &&
        (target is ListLiteral || target is SetOrMapLiteral)) {
      // Decided on its own, so a collection that splits keeps the section
      // on its last line: `]..sort()`.
      return concat([
        visit(node.target),
        group(indent(concat([softline, visit(sections.single)]))),
      ]);
    }
    return group(
      concat([
        visit(node.target),
        indent(
          concat([
            for (final section in sections) ...[
              sections.length > 1 ? hardline : softline,
              visit(section),
            ],
          ]),
        ),
      ]),
    );
  }

  /// A cascade section (`..a()`, `..b = c`, `?..[i]`): the cascade operator
  /// is a token of the section's innermost node.
  Doc cascadeSection(Expression section) => _leaf(section, section);
}
