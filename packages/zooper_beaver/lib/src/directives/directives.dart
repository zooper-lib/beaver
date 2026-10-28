/// Ignore directives: recognition, the region table and its validation.
/// Regions are spliced from raw source by the emitter at marker offsets.
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../comments/attach.dart';
import '../parse/parse.dart';

enum DirectiveKind { ignore, start, end }

/// The directive [comment] is, if any: exact match after trimming.
DirectiveKind? directiveOf(String comment) => switch (comment.trim()) {
  '// beaver-ignore' => DirectiveKind.ignore,
  '// beaver-ignore-start' || '// dart format off' => DirectiveKind.start,
  '// beaver-ignore-end' || '// dart format on' => DirectiveKind.end,
  _ => null,
};

/// Overlapping, nested or stray directives (exit 65).
final class DirectiveException implements Exception {
  const DirectiveException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class Directives {
  Directives._(this.regions, this.ignoredNodes, this.kinds);

  /// Ignored byte ranges `[start, end)` of the source, in order.
  final List<(int, int)> regions;

  /// Nodes led by `// beaver-ignore`, printed as their raw source.
  final Set<AstNode> ignoredNodes;

  /// Start and end directive comments.
  final Map<SourceComment, DirectiveKind> kinds;

  bool get isEmpty => regions.isEmpty;
}

/// Builds the region table from the attached [comments]. Throws
/// [DirectiveException] for a start inside an open region or an end with no
/// open region, naming the lines.
Directives findDirectives(CommentMap comments, ParsedSource parsed) {
  // (start, end, node led by `// beaver-ignore`, or null for a directive pair)
  final regions = <(int, int, AstNode?)>[];
  final kinds = Map<SourceComment, DirectiveKind>.identity();
  SourceComment? open;

  int line(SourceComment c) => parsed.positionOf(c.offset).$1;

  for (final comment in comments.all) {
    final kind = directiveOf(comment.text);
    switch (kind) {
      case null:
        break;
      case DirectiveKind.ignore:
        // Sugar for the range of the node it leads; elsewhere a no-op.
        final node = comment.following;
        if (open == null &&
            node != null &&
            (comments.leading[node]?.contains(comment) ?? false)) {
          regions.add((startOf(node), node.end, node));
        }
      case DirectiveKind.start:
        if (open != null) {
          throw DirectiveException(
            'Ignore region started on line ${line(open)} is still open at the '
            'start directive on line ${line(comment)}.',
          );
        }
        open = comment;
        kinds[comment] = kind;
      case DirectiveKind.end:
        if (open == null) {
          throw DirectiveException(
            'End directive on line ${line(comment)} has no open ignore region.',
          );
        }
        regions.add((open.end, comment.offset, null));
        kinds[comment] = kind;
        open = null;
    }
  }
  if (open != null) regions.add((open.end, parsed.source.length, null));

  regions.sort((a, b) => a.$1 - b.$1);
  final kept = <(int, int, AstNode?)>[];
  for (final region in regions) {
    if (kept.isNotEmpty && region.$1 < kept.last.$2) {
      // An ignored node inside another ignored node is already covered;
      // any other overlap involves a start/end pair and is ambiguous.
      if (region.$3 != null && kept.last.$3 != null) continue;
      throw DirectiveException(
        'Ignore regions overlap at lines '
        '${parsed.positionOf(kept.last.$1).$1} and '
        '${parsed.positionOf(region.$1).$1}.',
      );
    }
    kept.add(region);
  }
  return Directives._(
    [for (final (start, end, _) in kept) (start, end)],
    Set.identity()..addAll([for (final (_, _, node) in kept) ?node]),
    kinds,
  );
}
