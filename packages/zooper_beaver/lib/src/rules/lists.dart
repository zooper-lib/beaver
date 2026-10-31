/// The shared wrappable-construct helper: argument and parameter lists,
/// collection literals, type argument lists, records.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../comments/attach.dart';
import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';

extension ListRules on DocBuilder {
  /// `open item, item close` laid out per the list's [settings].
  ///
  /// Items separated by a source newline (or a newline right after [open])
  /// keep that break when the list's `keep_existing_line_breaks` is on: the items
  /// between kept breaks form runs, each its own group, joined by hard lines,
  /// so a kept break never expands its siblings. [forceChop] (a source
  /// trailing comma under `chop_on_trailing_comma`, or a named-argument
  /// match) breaks every separator.
  ///
  /// With the list's `align`, items after the first align to its column
  /// instead of being indented.
  ///
  /// [optionalTrailingComma] is false for constructs whose trailing comma
  /// the verifier compares exactly; the source's comma is kept.
  ///
  /// [optionalStart] is the index of the first item inside [leftDelimiter]
  /// (`[` or `{` of optional parameters), closed by [rightDelimiter]. When
  /// the delimiters belong to a node of their own ([optionalNode], a record
  /// type's named fields), its comments print around them.
  Doc delimited({
    required Token open,
    required List<AstNode> items,
    required Token close,
    required ListSettings settings,
    bool spaceInside = false,
    bool forceChop = false,
    bool requiredTrailingComma = false,
    bool optionalTrailingComma = true,
    Token? leftDelimiter,
    Token? rightDelimiter,
    int optionalStart = -1,
    AstNode? optionalNode,
  }) {
    if (items.isEmpty) return emptyDelimited(open, close);
    var policy = settings.policy;

    final sourceTrailingComma = hasTrailingComma(items.last);
    // A comment that ends its line forces a break even under `never`.
    if (policy == WrapPolicy.never &&
        hasLineCommentIn(open.end, close.offset)) {
      policy = WrapPolicy.chopIfLong;
    }
    final never = policy == WrapPolicy.never;

    // Whether the source has a newline in each list-level gap: before item i,
    // then before the closing delimiter. Newlines inside items don't count.
    final gaps = [
      for (final (i, item) in items.indexed)
        newlinesBetween(
              i == 0 ? open.end : items[i - 1].endToken.next!.end,
              startWithComments(item),
            ) >
            0,
      newlinesBetween(
            items.last.endToken.end,
            (rightDelimiter ?? close).offset,
          ) >
          0,
    ];
    // A source trailing comma is a chop request unless the list is
    // already split with some items sharing a line: there its breaks decide
    // (`keep_existing_line_breaks`). Beaver's own broken output is then stable whatever its comma.
    final mixed =
        gaps.contains(true) && gaps.sublist(1, items.length).contains(false);
    final chop =
        !never &&
        (forceChop ||
            policy == WrapPolicy.chopAlways ||
            settings.reachesThreshold(items.length) ||
            (sourceTrailingComma &&
                !requiredTrailingComma &&
                settings.chopOnTrailingComma &&
                !mixed));
    final fill = policy == WrapPolicy.ifLong && !chop;
    final outer = GroupId('list');

    final comma = concat([if (config.spaceBeforeComma) space, Text(',')]);
    final insideFlat = spaceInside ? ' ' : '';
    final separatorFlat = never
        ? (config.spaceAfterComma ? space : empty)
        : Line.soft(config.spaceAfterComma ? ' ' : '');

    // Whether the source broke the line before item i.
    final kept = [
      for (var i = 0; i < items.length; i++)
        !never && settings.keepExistingLineBreaks && gaps[i],
    ];

    // Built once: it may carry comments, and only one of the two IfBreak
    // branches holding it prints.
    final leadingOptional = optionalNode == null
        ? null
        : comments.leading[optionalNode];
    final trailingOptional = optionalNode == null
        ? null
        : comments.trailing[optionalNode];
    final optionalOpen = concat([
      if (leadingOptional != null) leadingComments(leadingOptional),
      tok(leftDelimiter),
    ]);

    Doc itemDoc(int i) {
      final isLast = i == items.length - 1;
      return concat([
        if (i == optionalStart && i > 0) IfBreak(empty, optionalOpen, outer),
        visit(items[i]),
        if (!isLast) comma,
        if (i + 1 == optionalStart)
          IfBreak(concat([space, optionalOpen]), empty, outer),
      ]);
    }

    // `close_bracket: after_last_item` hugs the closer to the last item and
    // suppresses the optional comma; a comment ending that line still
    // needs the closer on a line of its own.
    final afterLastItem =
        settings.closeBracket == CloseBracket.afterLastItem &&
        !hasLineCommentIn(startWithComments(items.last), close.offset);
    final Doc trailing;
    if (requiredTrailingComma) {
      trailing = comma;
    } else if (!optionalTrailingComma) {
      // Not in the verifier's optional-comma allowlist: keep the source.
      trailing = sourceTrailingComma ? comma : empty;
    } else if (afterLastItem && !never) {
      trailing = empty;
    } else if (never) {
      trailing =
          sourceTrailingComma &&
              settings.trailingCommas == TrailingCommas.preserve
          ? comma
          : empty;
    } else {
      trailing = switch (settings.trailingCommas) {
        TrailingCommas.preserve => sourceTrailingComma ? comma : empty,
        TrailingCommas.remove => empty,
        TrailingCommas.addWhenWrapped => IfBreak(comma, empty, outer),
        // Only a chopped list, with every item starting its own line: not
        // a filled one, nor one whose kept breaks group several items.
        TrailingCommas.addWhenChopped =>
            fill ||
                (!chop && kept.contains(true) && kept.skip(1).contains(false))
            ? empty
            : IfBreak(comma, empty, outer),
      };
    }
    // Built before the closing tokens, which would otherwise print these
    // comments themselves.
    // Comments between `]`/`}` and `)` print with `)` itself.
    final closeComments = rightDelimiter != null
        ? danglingBeforeClose(rightDelimiter)
        : danglingBeforeClose(close);
    final closing = concat([
      if (rightDelimiter != null) tok(rightDelimiter),
      if (trailingOptional != null) trailingComments(trailingOptional),
      tok(close),
    ]);

    if (never) {
      return concat([
        tok(open),
        if (optionalStart == 0) optionalOpen,
        Text(insideFlat),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) separatorFlat,
          itemDoc(i),
        ],
        trailing,
        closeComments,
        Text(insideFlat),
        closing,
      ]);
    }

    if (settings.align) {
      // Alignment: items after the first line up under it; the brackets hug the
      // first and last item.
      final docs = [for (var i = 0; i < items.length; i++) itemDoc(i)];
      return group(
        concat([
          tok(open),
          if (optionalStart == 0) optionalOpen,
          Text(insideFlat),
          alignToColumn(
            concat([
              runs(docs, kept, separator: chop ? hardline : separatorFlat),
              // The bracket hugs the last item, so no comma is ever
              // "wrapped"; the source's comma stays (it may be the chop
              // request that keeps this layout stable).
              if (requiredTrailingComma ||
                  (sourceTrailingComma &&
                      settings.trailingCommas != TrailingCommas.remove &&
                      !afterLastItem) ||
                  (sourceTrailingComma && !optionalTrailingComma))
                comma,
              closeComments,
            ]),
          ),
          // The bracket hugs the last item, unless a comment there must
          // end its line.
          if (hasLineCommentIn(startWithComments(items.last), close.offset))
            hardline
          else
            Text(insideFlat),
          closing,
        ]),
        shouldBreak: chop,
        id: outer,
      );
    }

    final hasRuns = !chop && kept.contains(true);
    final first = chop || kept[0] ? hardline : Line.soft(insideFlat);

    // Blank lines between items survive, up to the cap, where the list
    // breaks; a soft separator gets them only when its group breaks.
    Doc blankBefore(int i, {required bool hard}) {
      if (!gaps[i]) return empty;
      final count = capBlank(blankLinesBetween(items[i - 1], items[i]));
      return concat([
        for (var b = 0; b < count; b++) hard ? hardline : IfBreak(softline),
      ]);
    }

    Doc layoutRun(int from, int to) {
      final parts = <Doc>[];
      for (var i = from; i < to; i++) {
        if (i > from) {
          // Fill parts alternate item and separator: no room for blanks.
          parts.add(
            fill
                ? separatorFlat
                : concat([
                    chop ? hardline : separatorFlat,
                    blankBefore(i, hard: chop),
                  ]),
          );
        }
        parts.add(itemDoc(i));
      }
      return fill ? Fill(parts) : concat(parts);
    }

    final Doc body;
    if (!hasRuns) {
      body = layoutRun(0, items.length);
    } else {
      final runs = <Doc>[];
      var start = 0;
      for (var i = 1; i <= items.length; i++) {
        if (i == items.length || kept[i]) {
          runs.addAll([
            if (start > 0) ...[hardline, blankBefore(start, hard: true)],
            group(layoutRun(start, i)),
          ]);
          start = i;
        }
      }
      body = concat(runs);
    }

    return group(
      concat([
        tok(open),
        if (optionalStart == 0) optionalOpen,
        indentBy(
          settings.indent,
          concat([first, body, trailing, closeComments]),
        ),
        if (afterLastItem)
          IfBreak(empty, Text(insideFlat), outer)
        else
          Line.soft(insideFlat),
        closing,
      ]),
      shouldBreak: chop,
      id: outer,
    );
  }

  /// Comments between the last item (and its comma) and [close].
  Doc danglingBeforeClose(Token close) {
    final dangling = comments.danglingBefore[close];
    if (dangling == null) return empty;
    final parts = <Doc>[];
    for (final c in dangling) {
      if (!markPrinted(c)) continue;
      parts.addAll([
        c.newlineBefore
            ? hardline
            : c.isLineComment
            ? spaceBeforeTrailingComment
            : space,
        commentDoc(c),
        if (c.isLineComment || c.position != CommentPosition.remaining)
          breakParent,
      ]);
    }
    return concat(parts);
  }

  /// `()` / `[]` / `{}` with any dangling comments inside.
  Doc emptyDelimited(Token open, Token close) {
    final dangling = comments.danglingBefore[close];
    final isBrace = open.type == TokenType.OPEN_CURLY_BRACKET;
    if (dangling == null) {
      return concat([
        tok(open),
        if (isBrace && config.spaceInEmptyBraces) space,
        tok(close),
      ]);
    }
    if (dangling.every(
      (c) => !c.isLineComment && c.position == CommentPosition.remaining,
    )) {
      return concat([tok(open), danglingLines(close)!, tok(close)]);
    }
    return concat([
      tok(open),
      indent(concat([hardline, danglingLines(close)!])),
      hardline,
      tok(close),
    ]);
  }

  /// Whether a `,` follows [last] in the source.
  bool hasTrailingComma(AstNode last) =>
      last.endToken.next?.type == TokenType.COMMA;
}
