/// `package:analyzer` wrapper: parse at the latest language version and
/// convert between offsets and 1-based UTF-16 line/column positions.
library;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

/// A successfully parsed source string.
final class ParsedSource {
  ParsedSource._(this.source, this.unit, this.lineInfo);

  final String source;
  final CompilationUnit unit;
  final LineInfo lineInfo;

  /// 1-based line and UTF-16 column of [offset].
  (int line, int column) positionOf(int offset) {
    final location = lineInfo.getLocation(offset);
    return (location.lineNumber, location.columnNumber);
  }

  /// Offset of the 1-based [line] and UTF-16 [column]. Throws [RangeError]
  /// for a position outside the document or between the halves of a
  /// surrogate pair.
  int offsetOf(int line, int column) =>
      offsetOfPosition(source, lineInfo, line, column);
}

/// Offset in [source] of the 1-based [line] and UTF-16 [column]. Throws
/// [RangeError] for a position outside the document or between the halves of
/// a surrogate pair.
int offsetOfPosition(String source, LineInfo lineInfo, int line, int column) {
  if (line < 1 || line > lineInfo.lineCount || column < 1) {
    throw RangeError('Position $line:$column is outside the document.');
  }
  final start = lineInfo.getOffsetOfLine(line - 1);
  final end = line < lineInfo.lineCount
      ? lineInfo.getOffsetOfLine(line)
      : source.length;
  var contentEnd = end;
  while (contentEnd > start &&
      (source.codeUnitAt(contentEnd - 1) == 0x0A ||
          source.codeUnitAt(contentEnd - 1) == 0x0D)) {
    contentEnd--;
  }
  final offset = start + column - 1;
  if (offset > contentEnd) {
    throw RangeError('Position $line:$column is past the end of the line.');
  }
  if (offset > 0 &&
      offset < source.length &&
      _isLowSurrogate(source.codeUnitAt(offset)) &&
      _isHighSurrogate(source.codeUnitAt(offset - 1))) {
    throw RangeError('Position $line:$column splits a surrogate pair.');
  }
  return offset;
}

bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

/// One syntax error, positioned 1-based.
final class SyntaxError {
  const SyntaxError(this.offset, this.line, this.column, this.message);
  final int offset;
  final int line;
  final int column;
  final String message;

  @override
  String toString() => '$line:$column: $message';
}

/// The source does not parse (exit 65).
final class ParseFailure implements Exception {
  const ParseFailure(this.errors);
  final List<SyntaxError> errors;

  @override
  String toString() => errors.join('\n');
}

/// Parses [source] as a compilation unit at the latest language version, with
/// [experiments] enabled. Throws [ParseFailure] on any syntax error.
ParsedSource parse(String source, {List<String> experiments = const []}) {
  final result = parseString(
    content: source,
    featureSet: FeatureSet.latestLanguageVersion(flags: experiments),
    throwIfDiagnostics: false,
  );
  final parsed = ParsedSource._(source, result.unit, result.lineInfo);
  if (result.errors.isNotEmpty) {
    throw ParseFailure([
      for (final error in result.errors)
        if (parsed.positionOf(error.offset) case (final line, final column))
          SyntaxError(error.offset, line, column, error.message),
    ]);
  }
  return parsed;
}
