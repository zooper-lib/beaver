/// Range formatting: expand a selection along the ladder statement →
/// class member → top-level declaration, format only those units, and keep
/// every other byte of the document.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

import '../comments/attach.dart';
import '../config/config.dart';
import '../format.dart';
import '../parse/parse.dart';

/// A malformed, reversed or out-of-bounds range (exit 64).
final class RangeException implements Exception {
  const RangeException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 1-based start (inclusive) and end (exclusive) line/column positions.
typedef LineRange = ((int, int), (int, int));

final _rangeSyntax = RegExp(r'^(\d+):(\d+)-(\d+):(\d+)$');

/// Parses `L1:C1-L2:C2`.
LineRange parseRange(String spec) {
  final match = _rangeSyntax.firstMatch(spec.trim());
  if (match == null) {
    throw RangeException('"$spec" is not of the form L1:C1-L2:C2.');
  }
  int at(int i) => int.parse(match[i]!);
  return ((at(1), at(2)), (at(3), at(4)));
}

/// [source] with the units covering [range] formatted and every other byte
/// unchanged. The whole document is parsed and the whole output verified.
String formatRange(
  String source,
  LineRange range, {
  BeaverConfig? config,
  List<String> experiments = const [],
}) {
  config ??= BeaverConfig.dart;
  final lineInfo = LineInfo.fromContent(source);
  int offset((int, int) position) {
    try {
      return offsetOfPosition(source, lineInfo, position.$1, position.$2);
    } on RangeError catch (e) {
      throw RangeException('${e.message}');
    }
  }

  final start = offset(range.$1);
  final end = offset(range.$2);
  if (end < start) {
    throw RangeException('The range ends before it starts.');
  }

  final parsed = parse(source, experiments: experiments);
  final units = _expand(parsed.unit, start, end);
  if (units == null) return source;
  return formatUnits(
    parsed,
    units,
    config: config,
    leadingLevels: _depth(units.first, config),
    experiments: experiments,
  );
}

/// The units to format: the innermost statement list, then member list,
/// then the compilation unit, whose items cover [start] and [end]. `null`
/// if the selection is empty and in whitespace between units.
List<AstNode>? _expand(CompilationUnit unit, int start, int end) {
  final startChain = _containers(unit, start, preferNext: true);
  final endChain = _containers(
    unit,
    end > start ? end - 1 : end,
    preferNext: false,
  );
  for (final (container, items, first) in startChain) {
    for (final (other, _, last) in endChain) {
      if (!identical(container, other)) continue;
      if (first == null || last == null) {
        if (start == end) return null;
        continue;
      }
      final from = items.indexOf(first);
      final to = items.indexOf(last);
      if (from < 0 || to < from) return null;
      return items.sublist(from, to + 1);
    }
  }
  return null;
}

/// Unit lists enclosing [offset], innermost first, each with the item at
/// [offset] — or, in whitespace between items, the next item when
/// [preferNext] and the previous one otherwise, and `null` for an empty
/// selection there.
List<(AstNode, List<AstNode>, AstNode?)> _containers(
  CompilationUnit unit,
  int offset, {
  required bool preferNext,
}) {
  final result = <(AstNode, List<AstNode>, AstNode?)>[];
  for (AstNode? node = unit; node != null;) {
    final items = _unitsOf(node);
    if (items != null) {
      AstNode? hit, before, after;
      for (final item in items) {
        if (startOf(item) <= offset && offset < item.end) {
          hit = item;
        } else if (item.end <= offset) {
          before = item;
        } else {
          after ??= item;
        }
      }
      result.add((node, items, hit ?? (preferNext ? after : before)));
    }
    node = childNodes(
      node,
    ).where((c) => startOf(c) <= offset && offset < c.end).firstOrNull;
  }
  return result.reversed.toList();
}

/// The formattable units directly inside [node], if it holds a list of them.
List<AstNode>? _unitsOf(AstNode node) => switch (node) {
  CompilationUnit() => node.sortedDirectivesAndDeclarations,
  BlockClassBody(:final members) => members,
  BlockEnumBody(:final members) => members,
  Block(:final statements) => statements,
  SwitchMember(:final statements) => statements,
  _ => null,
};

/// Indentation levels of a unit: one per enclosing block-like body.
int _depth(AstNode unit, BeaverConfig config) {
  var depth = 0;
  for (var node = unit.parent; node != null; node = node.parent) {
    if (node is Block ||
        node is BlockClassBody ||
        node is BlockEnumBody ||
        node is SwitchMember ||
        (node is SwitchStatement && config.indentSwitchCases)) {
      depth++;
    }
  }
  return depth;
}
