/// AST → Doc. One builder per format call; the syntax areas live in
/// extensions in the sibling files and are dispatched from [DocBuilder.build].
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../comments/attach.dart';
import '../config/config.dart';
import '../directives/directives.dart';
import '../ir/doc.dart';
import 'collections.dart';
import 'declarations.dart';
import 'expressions.dart';
import 'statements.dart';
import 'strings.dart';

const Doc space = Text(' ');

final class DocBuilder {
  DocBuilder(this.source, this.config, this.comments, [this.directives]);

  final String source;
  final BeaverConfig config;
  final CommentMap comments;
  final Directives? directives;
  final _printed = Set<SourceComment>.identity();

  /// Comments that were never printed; non-empty means a rule dropped one.
  Iterable<SourceComment> get unprinted =>
      comments.all.where((c) => !_printed.contains(c));

  /// [node] with its leading and trailing comments.
  Doc visit(AstNode? node) {
    if (node == null) return empty;
    var doc = build(node);
    if (directives?.ignoredNodes.contains(node) ?? false) {
      // `// beaver-ignore`: the emitter prints the node's raw source.
      doc = concat([
        Marker(startOf(node), isStart: true),
        doc,
        Marker(node.end, isStart: false),
      ]);
    }
    final leading = comments.leading[node];
    final trailing = comments.trailing[node];
    if (leading == null && trailing == null) return doc;
    return concat([
      if (leading != null) leadingComments(leading, node),
      doc,
      if (trailing != null) trailingComments(trailing),
    ]);
  }

  /// Dispatch to the rule for [node]'s syntax; unknown syntax falls back to
  /// [generic], which keeps every token and the source's spacing.
  Doc build(AstNode node) =>
      buildDeclaration(node) ??
      buildStatement(node) ??
      buildCollection(node) ??
      buildString(node) ??
      buildExpression(node) ??
      generic(node);

  // Tokens and comments.

  /// [comment]'s text; a start or end directive also carries the marker the
  /// emitter splices raw source at.
  Doc commentDoc(SourceComment comment) {
    final text = Text(comment.text);
    return switch (directives?.kinds[comment]) {
      DirectiveKind.start => concat([text, Marker(comment.end, isStart: true)]),
      DirectiveKind.end => concat([
        Marker(comment.offset, isStart: false),
        text,
      ]),
      _ => text,
    };
  }

  /// Marks [comment] printed; false if it already was.
  bool markPrinted(SourceComment comment) => _printed.add(comment);

  /// [token]'s text (or [replacement], for a quote change), preceded by any
  /// dangling comments in front of it.
  Doc tok(Token? token, [String? replacement]) {
    if (token == null) return empty;
    final dangling = comments.danglingBefore[token];
    final text = Text(replacement ?? token.lexeme);
    if (dangling == null) return text;
    final parts = <Doc>[];
    for (final c in dangling) {
      if (!_printed.add(c)) continue;
      parts.add(
        c.newlineBefore
            ? hardline
            : c.isLineComment
            ? spaceBeforeTrailingComment
            : space,
      );
      parts.add(commentDoc(c));
      parts.add(_endsLine(c) ? hardline : space);
    }
    return concat([...parts, text]);
  }

  /// Prints the dangling comments before [token] on their own lines, for an
  /// owner that places them inside its empty body. Returns `null` if there
  /// are none.
  Doc? danglingLines(Token token) {
    final dangling = comments.danglingBefore[token]
        ?.where(_printed.add)
        .toList();
    if (dangling == null || dangling.isEmpty) return null;
    final parts = <Doc>[];
    for (final (i, c) in dangling.indexed) {
      if (i > 0) {
        parts.add(
          _endsLine(dangling[i - 1]) || c.newlineBefore ? hardline : space,
        );
        if (blankLineBefore(c.offset)) parts.add(hardline);
      }
      parts.add(commentDoc(c));
    }
    return concat(parts);
  }

  /// Blank lines between [last], the last comment leading [node], and
  /// [node]: none for a statement or list item, a doc comment, or a
  /// line-sensitive directive that must stay next to its target.
  int _gapBeforeDeclaration(SourceComment last, AstNode node) {
    final isDeclaration =
        node is CompilationUnitMember ||
        node is ClassMember ||
        node is EnumConstantDeclaration;
    final text = last.text;
    if (!isDeclaration ||
        text.startsWith('///') ||
        text.startsWith('/**') ||
        RegExp(
          r'^//\s*(ignore:|ignore_for_file:|coverage:ignore-line)',
        ).hasMatch(text)) {
      return 0;
    }
    final setting =
        config.values['blank_lines.between_comment_and_declaration'];
    if (setting is int) return setting;
    return capBlank(blankLinesIn(last.end, startOf(node)));
  }

  bool _endsLine(SourceComment c) =>
      c.isLineComment || c.position != CommentPosition.remaining;

  /// [list], the comments leading [node]. Between the last one and a
  /// declaration, `blank_lines.between_comment_and_declaration` decides.
  Doc leadingComments(List<SourceComment> list, [AstNode? node]) {
    final parts = <Doc>[];
    for (final c in list) {
      if (!_printed.add(c)) continue;
      parts.add(commentDoc(c));
      if (_endsLine(c)) {
        parts.add(hardline);
        final next = c.token.next;
        if (identical(c, list.last)) {
          final gap = node == null ? 0 : _gapBeforeDeclaration(c, node);
          for (var b = 0; b < gap; b++) {
            parts.add(hardline);
          }
        } else if (next != null && blankLineBefore(next.offset)) {
          // Keep one blank line between separated comments.
          parts.add(hardline);
        }
      } else {
        parts.add(space);
      }
    }
    return concat(parts);
  }

  /// The gap between code and a `//` comment ending its line.
  Doc get spaceBeforeTrailingComment =>
      Text(' ' * config.spaceBeforeTrailingComment);

  Doc trailingComments(List<SourceComment> list) {
    final parts = <Doc>[];
    // Whether the last part printed ends the line already.
    var atLineStart = false;
    for (final c in list) {
      if (!_printed.add(c)) continue;
      // A deferred (line suffix) comment prints before the next newline, so
      // it is only in place if the token after it starts a line anyway.
      // Otherwise print it here and break the line ourselves.
      final deferrable = c.deferrable;
      if (c.newlineBefore) {
        final comment = concat([
          // A deferred comment prints at the end of some later line.
          if (deferrable || !atLineStart) hardline,
          if (blankLineBefore(c.offset)) hardline,
          commentDoc(c),
        ]);
        if (deferrable) {
          parts.addAll([lineSuffix(comment), breakParent]);
        } else {
          parts.addAll([comment, hardline]);
          atLineStart = true;
        }
      } else if (_endsLine(c)) {
        final gap = c.isLineComment ? spaceBeforeTrailingComment : space;
        if (deferrable) {
          parts.addAll([
            lineSuffix(concat([gap, commentDoc(c)])),
            breakParent,
          ]);
        } else {
          parts.addAll([gap, commentDoc(c), hardline]);
          atLineStart = true;
        }
      } else {
        parts.addAll([space, commentDoc(c)]);
        atLineStart = false;
      }
    }
    return concat(parts);
  }

  // Source queries.

  /// Whether a comment that must end its line (`//`, or any comment
  /// followed by a newline) lies between [start] and [end]. Such a comment
  /// forces the construct around it to break, whatever its wrap policy.
  bool hasLineCommentIn(int start, int end) =>
      _commentsIn(start, end).any(_endsLine);

  /// Whether any comment lies between [start] and [end].
  bool hasCommentIn(int start, int end) => _commentsIn(start, end).isNotEmpty;

  Iterable<SourceComment> _commentsIn(int start, int end) sync* {
    final all = comments.all;
    var low = 0, high = all.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (all[middle].offset < start) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    for (var i = low; i < all.length && all[i].end <= end; i++) {
      yield all[i];
    }
  }

  /// Number of newlines in the source between [from] and [to].
  int newlinesBetween(int from, int to) {
    var count = 0;
    for (var i = from; i < to; i++) {
      if (source.codeUnitAt(i) == 0x0A) count++;
    }
    return count;
  }

  /// Whether the line before [offset] is blank (two newlines before it,
  /// ignoring spaces and tabs).
  bool blankLineBefore(int offset) {
    var newlines = 0;
    for (var i = offset - 1; i >= 0; i--) {
      final c = source.codeUnitAt(i);
      if (c == 0x0A) {
        if (++newlines == 2) return true;
      } else if (c != 0x20 && c != 0x09 && c != 0x0D) {
        return false;
      }
    }
    return false;
  }

  /// Start of [node] including its leading comments.
  int startWithComments(AstNode node) {
    final leading = comments.leading[node];
    return leading == null ? startOf(node) : leading.first.offset;
  }

  /// End of [node] including trailing comments on its line.
  int endWithComments(AstNode node) {
    final trailing = comments.trailing[node];
    if (trailing == null) return node.end;
    var end = node.end;
    for (final c in trailing) {
      if (!c.newlineBefore) end = c.end;
    }
    return end;
  }

  /// Blank lines in the source between two consecutive nodes.
  int blankLinesBetween(AstNode previous, AstNode next) =>
      blankLinesIn(endWithComments(previous), startWithComments(next));

  /// Whitespace-only lines between offsets [from] and [to].
  int blankLinesIn(int from, int to) {
    // Only whitespace-only lines count: a separator such as a `,` may sit on
    // a line of its own between the two.
    final lines = source.substring(from, to).split('\n');
    var blank = 0;
    for (var i = 1; i < lines.length - 1; i++) {
      if (lines[i].trim().isEmpty) blank++;
    }
    return blank;
  }

  /// Whether the source has a newline between [token] and the token after.
  bool newlineAfter(Token token) =>
      newlinesBetween(token.end, token.next!.offset) > 0;

  // Generic fallback.

  /// Every token of [node] in source order (child nodes through [visit]),
  /// separated as in the source: nothing where tokens touched, a space where
  /// there was whitespace, and a soft line where there was a newline. Correct
  /// for any syntax, if not pretty.
  ///
  /// Walks tokens rather than `childEntities`, which omits the commas
  /// between the elements of a node list.
  Doc generic(AstNode node) {
    final parts = <Doc>[];
    final children = childNodes(node);
    var childIndex = 0;
    final last = node.endToken;
    int? previousEnd;
    // Whether the last thing printed was a comment that ends its line.
    var afterLineComment = false;

    void separate(int start) {
      if (afterLineComment) {
        parts.add(hardline);
      } else if (previousEnd != null && previousEnd < start) {
        parts.add(newlinesBetween(previousEnd, start) > 0 ? line : space);
      }
      afterLineComment = false;
    }

    for (Token? token = firstTokenOf(node); token != null;) {
      while (childIndex < children.length &&
          children[childIndex].end <= token.offset &&
          !identical(firstTokenOf(children[childIndex]), token)) {
        childIndex++;
      }
      final child =
          childIndex < children.length &&
              identical(firstTokenOf(children[childIndex]), token)
          ? children[childIndex++]
          : null;

      // Comments in front of the token, placed here so the spacing around
      // them follows the source.
      for (final c
          in comments.danglingBefore[token] ?? const <SourceComment>[]) {
        if (!_printed.add(c)) continue;
        separate(c.offset);
        parts.add(commentDoc(c));
        previousEnd = c.end;
        afterLineComment = _endsLine(c);
      }

      final Token endToken;
      if (child != null) {
        separate(startWithComments(child));
        parts.add(visit(child));
        endToken = child.endToken;
      } else {
        separate(token.offset);
        parts.add(tok(token));
        endToken = token;
      }
      previousEnd = endToken.end;
      if (identical(endToken, last) || endToken.isEof) break;
      token = endToken.next;
    }
    return group(cont(concat(parts)));
  }

  // Layout helpers.

  /// [items] separated by [separator]. Where [keptBefore] marks a source
  /// line break (index 0 is ignored), a hard line separates instead, and the
  /// items between kept breaks form runs that each break on their own, so a
  /// kept break never expands its siblings. [fill] packs each run
  /// paragraph-style.
  Doc runs(
    List<Doc> items,
    List<bool> keptBefore, {
    required Doc separator,
    bool fill = false,
  }) {
    Doc run(int from, int to) {
      final parts = <Doc>[];
      for (var k = from; k < to; k++) {
        if (k > from) parts.add(separator);
        parts.add(items[k]);
      }
      return fill ? Fill(parts) : concat(parts);
    }

    if (!keptBefore.skip(1).contains(true)) return run(0, items.length);
    final parts = <Doc>[];
    var start = 0;
    for (var k = 1; k <= items.length; k++) {
      if (k == items.length || keptBefore[k]) {
        if (start > 0) parts.add(hardline);
        parts.add(group(run(start, k)));
        start = k;
      }
    }
    return concat(parts);
  }

  /// [nodes] separated by their source commas and soft lines, spaced per
  /// `spaces.before_comma`/`after_comma`.
  Doc commaSeparated(List<AstNode> nodes) => concat([
    for (final (i, node) in nodes.indexed) ...[
      visit(node),
      if (i < nodes.length - 1) ...[
        if (config.spaceBeforeComma) space,
        tok(node.endToken.next),
        Line.soft(config.spaceAfterComma ? ' ' : ''),
      ],
    ],
  ]);

  /// Continuation indentation for wrapped expression lines.
  Doc cont(Doc doc) => align(config.continuationIndent, doc);

  /// [doc] indented by a list's `indent`: one indentation level when that
  /// is its width (a tab under `indent.style: tabs`), spaces otherwise.
  Doc indentBy(int width, Doc doc) =>
      width == config.indentSize ? indent(doc) : align(width, doc);

  /// Members or statements on their own lines, with blank lines decided by
  /// [blankLines] (previous, next, source blank lines → blank lines to print).
  Doc sequence(
    List<AstNode> nodes, {
    int? Function(AstNode previous, AstNode next, int sourceBlank)? blankLines,
  }) {
    final parts = <Doc>[];
    for (final (i, node) in nodes.indexed) {
      if (i > 0) {
        final previous = nodes[i - 1];
        final sourceBlank = blankLinesBetween(previous, node);
        final blank =
            blankLines?.call(previous, node, sourceBlank) ??
            _capBlank(sourceBlank);
        parts.add(hardline);
        for (var b = 0; b < blank; b++) {
          parts.add(hardline);
        }
      }
      parts.add(visit(node));
    }
    return concat(parts);
  }

  int _capBlank(int lines) =>
      lines > config.maxBlankLines ? config.maxBlankLines : lines;

  int capBlank(int lines) => _capBlank(lines);

  /// [lines] capped by `blank_lines.max_consecutive_in_code`, for blank
  /// lines inside function bodies.
  int capBlankInCode(int lines) {
    final cap = config.maxBlankLinesInCode;
    return lines > cap ? cap : lines;
  }

  /// `{ ... }` holding [body] on indented lines, or the dangling comments
  /// before [close], or nothing. [before] and [after] are blank lines to
  /// print after [open] and before [close].
  Doc braces(
    Token open,
    Doc? body,
    Token close, {
    int before = 0,
    int after = 0,
  }) {
    final dangling = danglingLines(close);
    if (body == null && dangling == null) {
      return concat([
        tok(open),
        if (config.spaceInEmptyBraces) space,
        tok(close),
      ]);
    }
    return concat([
      tok(open),
      indent(
        concat([
          for (var b = 0; b < before; b++) hardline,
          if (body != null) ...[hardline, body],
          if (dangling != null) ...[hardline, dangling],
        ]),
      ),
      for (var b = 0; b < after; b++) hardline,
      hardline,
      tok(close),
    ]);
  }
}
