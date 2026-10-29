/// Comment attachment: every comment gets its enclosing, preceding and
/// following node, is classified by position, and is attached as leading,
/// trailing or dangling before layout.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

enum CommentPosition {
  /// Newline before and after.
  ownLine,

  /// Code before, newline after.
  endOfLine,

  /// Code after (and possibly before) on the same line.
  remaining,
}

final class SourceComment {
  SourceComment(this.token, this.position, {required this.newlineBefore});

  final Token token;
  final CommentPosition position;

  /// Only whitespace between the start of the line and the comment.
  final bool newlineBefore;

  /// The node relations computed by [attachComments].
  AstNode? enclosing;
  AstNode? preceding;
  AstNode? following;

  String get text => token.lexeme;
  int get offset => token.offset;
  int get end => token.end;
  bool get isLineComment => text.startsWith('//');

  /// The non-comment token this comment precedes.
  Token get nextToken => (token as CommentToken).parent!;

  /// Whether, as a trailing comment, this may be deferred to the end of the
  /// line (a line suffix) without moving past [nextToken]. Set by
  /// [attachComments].
  bool deferrable = false;
}

/// Comments of a compilation unit by attachment.
final class CommentMap {
  final leading = Map<AstNode, List<SourceComment>>.identity();
  final trailing = Map<AstNode, List<SourceComment>>.identity();
  final dangling = Map<AstNode, List<SourceComment>>.identity();

  /// Dangling comments by the token they precede, so the owner can print
  /// them in place when it prints that token.
  final danglingBefore = Map<Token, List<SourceComment>>.identity();

  /// Every comment, in source order.
  final all = <SourceComment>[];

  bool get isEmpty => all.isEmpty;
}

/// The first token of [node], skipping a leading documentation comment, which
/// is treated as an ordinary comment in front of the declaration.
Token firstTokenOf(AstNode node) {
  if (node is AnnotatedNode && node.documentationComment != null) {
    return node.metadata.isNotEmpty
        ? node.metadata.first.beginToken
        : node.firstTokenAfterCommentAndMetadata;
  }
  return node.beginToken;
}

int startOf(AstNode node) => firstTokenOf(node).offset;

final _childCache = Expando<List<AstNode>>();

/// Child nodes of [node] in source order, without documentation comments.
List<AstNode> childNodes(AstNode node) => _childCache[node] ??= [
  for (final child in node.childEntities)
    if (child is AstNode && child is! Comment) child,
]..sort((a, b) => startOf(a) - startOf(b));

/// Attaches every comment in [unit] (parsed from [source]).
CommentMap attachComments(AstNode unit, String source) {
  final map = CommentMap();
  for (Token? token = unit.beginToken; token != null; token = token.next) {
    for (Token? c = token.precedingComments; c != null; c = c.next) {
      map.all.add(_classify(c, source));
    }
    if (token.isEof) break;
  }
  Token? ledToken;
  for (final comment in map.all) {
    _locate(unit, comment);
    comment.deferrable = _startsLine(comment);
    // Once a comment leads the node at a token, later comments before the
    // same token must lead it too, or they would print out of order.
    final mustLead = identical(ledToken, comment.nextToken);
    if (_attach(map, comment, mustLead: mustLead)) {
      ledToken = comment.nextToken;
    }
  }
  return map;
}

SourceComment _classify(Token comment, String source) {
  var before = comment.offset - 1;
  while (before >= 0 && (source[before] == ' ' || source[before] == '\t')) {
    before--;
  }
  final newlineBefore =
      before < 0 || source[before] == '\n' || source[before] == '\r';
  var after = comment.end;
  while (after < source.length &&
      (source[after] == ' ' || source[after] == '\t')) {
    after++;
  }
  final newlineAfter =
      after >= source.length || source[after] == '\n' || source[after] == '\r';
  final position = newlineBefore && newlineAfter
      ? CommentPosition.ownLine
      : newlineAfter
      ? CommentPosition.endOfLine
      : CommentPosition.remaining;
  return SourceComment(comment, position, newlineBefore: newlineBefore);
}

/// Descends from [node] to the smallest node containing [comment], binary
/// searching each level's children for the neighbours.
void _locate(AstNode node, SourceComment comment) {
  while (true) {
    final children = childNodes(node);
    AstNode? preceding;
    AstNode? following;
    AstNode? container;
    var low = 0;
    var high = children.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      final child = children[middle];
      final start = startOf(child);
      if (start <= comment.offset && comment.end <= child.end) {
        container = child;
        break;
      }
      if (child.end <= comment.offset) {
        preceding = child;
        low = middle + 1;
      } else if (comment.end <= start) {
        following = child;
        high = middle;
      } else {
        break;
      }
    }
    if (container != null) {
      node = container;
      continue;
    }
    comment
      ..enclosing = node
      ..preceding = preceding
      ..following = following;
    return;
  }
}

/// Returns whether [comment] became a leading comment.
bool _attach(CommentMap map, SourceComment comment, {required bool mustLead}) {
  final preceding = comment.preceding;
  final following = comment.following;

  // A comment may only lead the following node if no token lies between
  // them, and trail the preceding node if at most a `,` or `;` lies between
  // (which prints glued to the node, before a trailing line comment's
  // deferred text). Otherwise printing it there would move it across code.
  final canLead =
      following != null &&
      identical(firstTokenOf(following), comment.nextToken);
  // With a separator in between, only a deferred (line suffix) comment ends
  // up after it.
  final touching =
      preceding != null &&
      identical(preceding.endToken.next, comment.nextToken);
  final canTrail =
      preceding != null &&
      (touching ||
          (comment.deferrable &&
              comment.position != CommentPosition.remaining &&
              _onlySeparatorsBetween(preceding, comment)));

  bool lead() {
    (map.leading[following!] ??= []).add(comment);
    return true;
  }

  bool trail() {
    (map.trailing[preceding!] ??= []).add(comment);
    return false;
  }

  if (mustLead && canLead) return lead();
  switch (comment.position) {
    case CommentPosition.ownLine:
      if (canLead) return lead();
      if (canTrail) return trail();
    case CommentPosition.endOfLine:
      if (canTrail) return trail();
      if (canLead) return lead();
    case CommentPosition.remaining:
      if (canLead) return lead();
      // Printed inline right after the node, so nothing may lie between.
      if (touching) return trail();
  }
  (map.dangling[comment.enclosing!] ??= []).add(comment);
  (map.danglingBefore[comment.nextToken] ??= []).add(comment);
  return false;
}

bool _onlySeparatorsBetween(AstNode preceding, SourceComment comment) {
  for (
    var token = preceding.endToken.next;
    token != null && !identical(token, comment.nextToken);
    token = token.next
  ) {
    if (token.type != TokenType.COMMA && token.type != TokenType.SEMICOLON) {
      return false;
    }
    // A comment on the separator would print before the deferred one.
    if (token.precedingComments != null) return false;
  }
  return true;
}

/// Whether the token after [comment] is always printed at the start of a
/// line once the line breaks: the next item of a list or sequence, a
/// cascade section, a closing bracket of a broken construct, or
/// the end of file.
bool _startsLine(SourceComment comment) {
  final next = comment.nextToken;
  if (next.isEof) return true;
  final type = next.type;
  // Cascade sections always start a line once the cascade breaks. Chain
  // selectors (`.`) only do when the chain splits, which is not known here.
  if (type == TokenType.PERIOD_PERIOD ||
      type == TokenType.QUESTION_PERIOD_PERIOD) {
    return true;
  }
  final enclosing = comment.enclosing;
  if (type == TokenType.CLOSE_PAREN ||
      type == TokenType.CLOSE_SQUARE_BRACKET ||
      type == TokenType.CLOSE_CURLY_BRACKET) {
    return enclosing is ArgumentList ||
        enclosing is FormalParameterList ||
        enclosing is ListLiteral ||
        enclosing is SetOrMapLiteral ||
        enclosing is RecordLiteral ||
        enclosing is Block ||
        enclosing is BlockClassBody ||
        enclosing is BlockEnumBody ||
        enclosing is SwitchStatement ||
        enclosing is SwitchExpression;
  }
  final following = comment.following;
  return following != null &&
      identical(firstTokenOf(following), next) &&
      (enclosing is Block ||
          enclosing is CompilationUnit ||
          enclosing is BlockClassBody ||
          enclosing is BlockEnumBody ||
          enclosing is SwitchMember ||
          enclosing is SwitchStatement ||
          enclosing is SwitchExpression ||
          enclosing is ArgumentList ||
          enclosing is FormalParameterList ||
          enclosing is ListLiteral ||
          enclosing is SetOrMapLiteral ||
          enclosing is RecordLiteral ||
          enclosing is CascadeExpression);
}
