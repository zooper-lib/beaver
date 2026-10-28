/// Structural verification: the output must be the same program as the
/// input. Runs before any output is returned.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../config/config.dart';
import '../parse/parse.dart';
import 'verification_failure.dart';

export 'verification_failure.dart';

/// Checks [output] against [input]. [regions] are the input's ignored byte
/// ranges, which must appear unchanged in the output, in order. Throws
/// [VerificationFailure] naming the failed stage.
void verify(
  ParsedSource input,
  String output, {
  required BeaverConfig config,
  List<(int, int)> regions = const [],
  List<String> experiments = const [],
}) {
  final ParsedSource formatted;
  try {
    formatted = parse(output, experiments: experiments);
  } on ParseFailure catch (e) {
    throw VerificationFailure('parse', 'Output does not parse: $e');
  }

  final byValue = config.quotes != Quotes.preserve;
  final (before, beforeComments) = _normalize(input.unit, byValue: byValue);
  final (after, afterComments) = _normalize(formatted.unit, byValue: byValue);
  _compareTokens(before, after);
  _compareFingerprints(input.unit, formatted.unit);
  _compareComments(beforeComments, afterComments);
  _compareRegions(input.source, output, regions);
}

/// A non-comment token as compared: its type, its text (or string value),
/// and the comments in front of it.
final class _Token {
  _Token(this.token, this.text);
  final Token token;
  final String text;
}

/// The token stream without comments and without optional trailing commas,
/// and every comment with its position in that stream: the index of the
/// kept token after it (so the kept token before it is one less). A comment
/// in front of a skipped comma counts as in front of the next kept token.
(List<_Token>, List<(String, int)>) _normalize(
  CompilationUnit unit, {
  required bool byValue,
}) {
  final optional = _OptionalCommas();
  unit.accept(optional);
  final values = byValue ? _stringValues(unit) : const <int, String>{};
  final tokens = <_Token>[];
  final comments = <(String, int)>[];
  for (Token? t = unit.beginToken; t != null; t = t.next) {
    for (Token? c = t.precedingComments; c != null; c = c.next) {
      comments.add((c.lexeme, tokens.length));
    }
    if (t.type != TokenType.COMMA || !optional.offsets.contains(t.offset)) {
      tokens.add(_Token(t, values[t.offset] ?? t.lexeme));
    }
    if (t.isEof) break;
  }
  return (tokens, comments);
}

void _compareTokens(List<_Token> before, List<_Token> after) {
  final length = before.length < after.length ? before.length : after.length;
  for (var i = 0; i < length; i++) {
    final a = before[i];
    final b = after[i];
    if (a.token.type != b.token.type || a.text != b.text) {
      throw VerificationFailure(
        'tokens',
        'Token ${i + 1} differs: "${a.token.lexeme}" became '
            '"${b.token.lexeme}".',
      );
    }
  }
  if (before.length != after.length) {
    throw VerificationFailure(
      'tokens',
      'Token count differs: ${before.length} became ${after.length}.',
    );
  }
}

void _compareComments(List<(String, int)> a, List<(String, int)> b) {
  final length = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    if (a[i].$1 != b[i].$1) {
      throw VerificationFailure(
        'comments',
        'Comment ${i + 1} changed: "${a[i].$1}" became "${b[i].$1}".',
      );
    }
    if (a[i].$2 != b[i].$2) {
      throw VerificationFailure(
        'comments',
        'Comment "${a[i].$1}" moved relative to the code around it.',
      );
    }
  }
  if (a.length != b.length) {
    throw VerificationFailure(
      'comments',
      'Comment count differs: ${a.length} became ${b.length}.',
    );
  }
}

void _compareFingerprints(CompilationUnit before, CompilationUnit after) {
  final a = _fingerprint(before);
  final b = _fingerprint(after);
  final length = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    if (a[i] != b[i]) {
      throw VerificationFailure(
        'fingerprint',
        'Syntax node ${i + 1} differs: ${a[i]} became ${b[i]}.',
      );
    }
  }
  if (a.length != b.length) {
    throw VerificationFailure(
      'fingerprint',
      'Syntax node count differs: ${a.length} became ${b.length}.',
    );
  }
}

/// Pre-order node kinds with their child counts, so nesting is compared too.
List<String> _fingerprint(AstNode root) {
  final result = <String>[];
  void walk(AstNode node) {
    final children = node.childEntities.whereType<AstNode>().toList();
    result.add('${node.runtimeType}/${children.length}');
    children.forEach(walk);
  }

  walk(root);
  return result;
}

void _compareRegions(String input, String output, List<(int, int)> regions) {
  var from = 0;
  for (final (start, end) in regions) {
    final region = input.substring(start, end);
    final found = output.indexOf(region, from);
    if (found < 0) {
      throw VerificationFailure(
        'regions',
        'Ignored region at offset $start is not byte-identical in the output.',
      );
    }
    from = found + region.length;
  }
}

/// String token offset → interpreted value, for non-raw string parts.
Map<int, String> _stringValues(CompilationUnit unit) {
  final values = <int, String>{};
  unit.accept(_StringValues(values));
  return values;
}

final class _StringValues extends RecursiveAstVisitor<void> {
  _StringValues(this.values);
  final Map<int, String> values;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!node.isRaw) values[node.literal.offset] = '\u0000${node.value}';
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    final parent = node.parent;
    if (parent is SingleStringLiteral && !parent.isRaw) {
      values[node.contents.offset] = '\u0000${node.value}';
    }
  }
}

/// Offsets of trailing commas that are syntactically optional.
final class _OptionalCommas extends RecursiveAstVisitor<void> {
  final offsets = <int>{};

  void _before(Token close) {
    final previous = close.previous;
    if (previous != null && previous.type == TokenType.COMMA) {
      offsets.add(previous.offset);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    _before(node.rightParenthesis);
    super.visitArgumentList(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    _before(node.rightDelimiter ?? node.rightParenthesis);
    super.visitFormalParameterList(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    _before(node.rightBracket);
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _before(node.rightBracket);
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitBlockEnumBody(BlockEnumBody node) {
    final constants = node.constants;
    if (constants.isNotEmpty) {
      final next = constants.last.endToken.next;
      if (next != null && next.type == TokenType.COMMA) {
        offsets.add(next.offset);
      }
    }
    super.visitBlockEnumBody(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    final fields = node.fields;
    if (fields.length >= 2 || fields.any((f) => f is RecordLiteralNamedField)) {
      _before(node.rightParenthesis);
    }
    super.visitRecordLiteral(node);
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final named = node.namedFields;
    if (named != null) {
      _before(named.rightBracket);
    } else if (node.positionalFields.length >= 2) {
      _before(node.rightParenthesis);
    }
    super.visitRecordTypeAnnotation(node);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    final fields = node.fields;
    if (fields.length >= 2 || fields.any((f) => f.name != null)) {
      _before(node.rightParenthesis);
    }
    super.visitRecordPattern(node);
  }
}
