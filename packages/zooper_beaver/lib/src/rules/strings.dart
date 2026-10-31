/// String literals and `strings.quotes` (value-preserving delimiter changes).
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';

extension StringRules on DocBuilder {
  Doc? buildString(AstNode node) => switch (node) {
    SimpleStringLiteral() => _simple(node),
    StringInterpolation() => _interpolation(node),
    InterpolationString() => tok(node.contents),
    // Code inside `${}` never breaks: a split there reads as a broken string.
    InterpolationExpression() => concat([
      tok(node.leftBracket),
      printedFlat(visit(node.expression)),
      tok(node.rightBracket),
    ]),
    // One piece per line; later pieces indent where the string would
    // otherwise blend into its neighbours (dart_style's rule).
    AdjacentStrings() => _indentPieces(node)
        ? cont(join(hardline, [for (final s in node.strings) visit(s)]))
        : join(hardline, [for (final s in node.strings) visit(s)]),
    _ => null,
  };

  /// Whether the pieces after the first indent: next to another string
  /// argument, as a collection element, map key or positional record field,
  /// in a conditional's branch, and after `throw`, `await` or a prefix.
  bool _indentPieces(AdjacentStrings node) => switch (node.parent) {
    ArgumentList(:final arguments) => arguments.any(
      (a) => !identical(a, node) && a is StringLiteral,
    ),
    AssertStatement(:final condition, :final message) ||
    AssertInitializer(:final condition, :final message) =>
      (identical(node, condition) ? message : condition) is StringLiteral,
    ListLiteral() || SetOrMapLiteral() || RecordLiteral() => true,
    MapLiteralEntry(:final key) => identical(key, node),
    ConditionalExpression(:final condition) => !identical(condition, node),
    ThrowExpression() || AwaitExpression() || PrefixExpression() => true,
    _ => false,
  };

  Doc _simple(SimpleStringLiteral node) {
    final lexeme = node.literal.lexeme;
    final target = _target(node);
    if (target == null ||
        !_convertible(lexeme, target, node, start: true, end: true)) {
      return tok(node.literal);
    }
    return tok(
      node.literal,
      _requote(lexeme, target, node, start: true, end: true),
    );
  }

  Doc _interpolation(StringInterpolation node) {
    final target = _target(node);
    final elements = node.elements;
    final strings = elements.whereType<InterpolationString>().toList();
    final convert =
        target != null &&
        strings.every(
          (s) => _convertible(
            s.contents.lexeme,
            target,
            node,
            start: identical(s, strings.first),
            end: identical(s, strings.last),
          ),
        );
    return concat([
      for (final element in elements)
        if (convert && element is InterpolationString)
          tok(
            element.contents,
            _requote(
              element.contents.lexeme,
              target,
              node,
              start: identical(element, strings.first),
              end: identical(element, strings.last),
            ),
          )
        else
          visit(element),
    ]);
  }

  /// The quote character to convert [node] to, or `null` to keep it.
  String? _target(SingleStringLiteral node) {
    if (node.isRaw) return null;
    final want = switch (config.quotes) {
      Quotes.preserve => null,
      Quotes.single => "'",
      Quotes.double => '"',
    };
    final has = node.isSingleQuoted ? "'" : '"';
    return want == has ? null : want;
  }

  /// Whether [text] (a literal's lexeme, or one part of an interpolated
  /// literal, holding the opening delimiter if [start] and the closing one
  /// if [end]) can take [target] delimiters without escaping anything: no
  /// unescaped [target] character inside (for multi-line strings, no
  /// [target] at all, so no run of quotes can close the string early).
  bool _convertible(
    String text,
    String target,
    SingleStringLiteral node, {
    required bool start,
    required bool end,
  }) {
    // `quotes_avoid_escapes: false`: a one-line literal is converted anyway,
    // escaping the new delimiter (see [_requote]).
    if (!node.isMultiline && !config.flag('strings.quotes_avoid_escapes')) {
      return true;
    }
    final length = node.isMultiline ? 3 : 1;
    final from = start ? length : 0;
    final to = end ? text.length - length : text.length;
    for (var i = from; i < to; i++) {
      final c = text[i];
      if (c == r'\') {
        if (node.isMultiline && i + 1 < to && text[i + 1] == target) {
          return false;
        }
        i++;
      } else if (c == target) {
        return false;
      }
    }
    return true;
  }

  /// [text] with the delimiter at the ends marked by [start] and [end]
  /// replaced by [target] quotes, and in a one-line literal any unescaped
  /// [target] inside escaped.
  String _requote(
    String text,
    String target,
    SingleStringLiteral node, {
    required bool start,
    required bool end,
  }) {
    final length = node.isMultiline ? 3 : 1;
    final delimiter = target * length;
    final inner = text.substring(
      start ? length : 0,
      end ? text.length - length : text.length,
    );
    return [
      if (start) delimiter,
      node.isMultiline ? inner : _escape(inner, target),
      if (end) delimiter,
    ].join();
  }

  /// [text] with every unescaped [quote] preceded by a backslash.
  String _escape(String text, String quote) {
    final out = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == r'\' && i + 1 < text.length) {
        out
          ..write(c)
          ..write(text[++i]);
      } else {
        out.write(c == quote ? '\\$quote' : c);
      }
    }
    return out.toString();
  }
}
