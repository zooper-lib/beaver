/// Method chains and cascades.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';
import 'expressions.dart';

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
  /// continuation indent, per `wrap.chained_calls`. When the receiver's kind
  /// is in `keep_first_call_on_receiver_line`, the first call stays on its
  /// line; `indent: first_item` then aligns the rest under its `.` while
  /// the target is flat.
  Doc chain(Expression expression) {
    final (target, leaf, selectors) = _unwind(expression);
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
    final settings = config.chainedCalls;
    for (; i < selectors.length; i++) {
      final selector = selectors[i];
      if (selector.isMember || lines.isEmpty) {
        lines.add(selector.doc);
        kept.add(
          settings.keepExistingLineBreaks &&
              newlinesBetween(selector.previousEnd, selector.start) > 0,
        );
      } else {
        lines[lines.length - 1] = concat([lines.last, selector.doc]);
      }
    }

    var policy = settings.policy;
    if (policy == WrapPolicy.never) {
      if (!hasLineCommentIn(expression.offset, expression.end)) {
        return concat([target, ...head, ...lines]);
      }
      policy = WrapPolicy.chopIfLong;
    }
    final minCalls = settings.chopFrom;
    final forced = minCalls > 0 && calls >= minCalls;

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
        return policy == WrapPolicy.fill
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

    // A chain moved after a prefix (`break_after_prefix`) was already
    // indented by the move, so its calls stay in the target's column.
    final step = config.chainBreakAfterPrefix && followsPrefix(expression)
        ? 0
        : settings.indent.columns;
    final continued = align(step, separated(lines, kept, first: true));
    final keepFirst = config.chainKeepFirstCallKinds.contains(
      _receiverKind(leaf, head.isNotEmpty),
    );
    if (settings.indent is! FirstItem || !keepFirst) {
      // The calls, offset by [offset] from the enclosing indentation.
      Doc calls(int offset) => keepFirst
          ? concat([
              lines.first,
              align(
                offset,
                separated(lines.sublist(1), kept.sublist(1), first: true),
              ),
            ])
          : align(offset, separated(lines, kept, first: true));
      final fromLine = concat([target, ...head, calls(step)]);
      final receiver = concat([target, ...head]);
      // `indent_from` has no parent under `first_item`.
      if (!config.chainIndentFromTarget ||
          settings.indent is FirstItem ||
          hasHardLine(receiver)) {
        return group(fromLine);
      }
      // `indent_from: target`: offset from the target's column when the
      // target fits on one line, from the line otherwise.
      return ConditionalGroup(
        [
          fromLine,
          alignToColumn(
            concat([printedFlat(receiver), calls(settings.indent.columns)]),
          ),
          fromLine,
        ],
        firstLineOnly: const {1},
      );
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

  /// The kind of the receiver [leaf] (followed by properties when
  /// [hasProperties]), or `null` when it is none of them.
  ReceiverKind? _receiverKind(Expression leaf, bool hasProperties) {
    bool upper(String name) =>
        name.replaceFirst(RegExp(r'^[_$]+'), '').startsWith(RegExp('[A-Z]'));
    if (hasProperties) return ReceiverKind.properties;
    return switch (leaf) {
      SimpleIdentifier(:final name) when upper(name) => ReceiverKind.typeNames,
      SimpleIdentifier() => ReceiverKind.identifiers,
      PrefixedIdentifier(:final identifier) when upper(identifier.name) =>
        ReceiverKind.typeNames,
      PrefixedIdentifier() || PropertyAccess() => ReceiverKind.properties,
      ThisExpression() || SuperExpression() => ReceiverKind.thisOrSuper,
      MethodInvocation() || FunctionExpressionInvocation() =>
        ReceiverKind.calls,
      _ => null,
    };
  }

  /// The chain's innermost target (printed, and its node) and the
  /// selectors after it.
  (Doc, Expression, List<_Selector>) _unwind(Expression expression) {
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
          return (
            _leaf(current, expression),
            current,
            selectors.reversed.toList(),
          );
      }
    }
    return (visit(current), current, selectors.reversed.toList());
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

  /// A target and its `..` sections, per `wrap.cascades`. Only breaks
  /// before a section are cascade-level breaks; newlines inside the target
  /// or a section are not.
  Doc cascade(CascadeExpression node) {
    final settings = config.cascades;
    final sections = node.cascadeSections;
    final target = node.target;
    var policy = settings.policy;
    if (policy == WrapPolicy.never && hasLineCommentIn(node.offset, node.end)) {
      policy = WrapPolicy.chopIfLong;
    }
    final never = policy == WrapPolicy.never;
    final forced = !never && settings.reachesThreshold(sections.length);
    final kept = [
      for (final (i, section) in sections.indexed)
        !never &&
            settings.keepExistingLineBreaks &&
            newlinesBetween(
                  i == 0 ? target.end : sections[i - 1].end,
                  section.offset,
                ) >
                0,
    ];
    if (sections.length == 1 &&
        !forced &&
        !kept.single &&
        (target is ListLiteral || target is SetOrMapLiteral)) {
      // Decided on its own, so a collection that splits keeps the section
      // on its last line: `]..sort()`.
      return concat([
        visit(target),
        group(
          indentBy(
            settings.indent.columns,
            concat([never ? empty : softline, visit(sections.single)]),
          ),
        ),
      ]);
    }
    final separator = never ? empty : (forced ? hardline : softline);
    Doc layout(Iterable<Expression> run) {
      final parts = [
        for (final section in run) ...[separator, visit(section)],
      ];
      return policy == WrapPolicy.fill && !forced
          ? Fill(_fillParts(parts))
          : concat(parts);
    }

    final Doc body;
    if (!kept.contains(true)) {
      body = layout(sections);
    } else {
      // A kept break is hard and starts a run that breaks on its own.
      final parts = <Doc>[];
      var start = 0;
      for (var i = 1; i <= sections.length; i++) {
        if (i < sections.length && !kept[i]) continue;
        final run = sections.sublist(start, i);
        if (kept[start]) {
          parts.addAll([
            hardline,
            group(
              concat([
                visit(run.first),
                if (run.length > 1) layout(run.skip(1)),
              ]),
            ),
          ]);
        } else {
          parts.add(group(layout(run)));
        }
        start = i;
      }
      body = concat(parts);
    }
    return group(
      concat([visit(target), indentBy(settings.indent.columns, body)]),
    );
  }

  /// A cascade section (`..a()`, `..b = c`, `?..[i]`): the cascade operator
  /// is a token of the section's innermost node.
  Doc cascadeSection(Expression section) => _leaf(section, section);
}
