/// Turns printer commands into the output string.
library;

import '../config/config.dart' show IndentStyle;
import '../ir/printer.dart';

/// `\r\n` if most of the source's line endings are CRLF, else `\n`.
String detectLineEnding(String source) {
  final crlf = '\r\n'.allMatches(source).length;
  final lf = '\n'.allMatches(source).length;
  return crlf > lf - crlf ? '\r\n' : '\n';
}

/// Renders [commands], indenting with spaces or one tab per level per
/// [style]. Alignment padding is always spaces. Ends with exactly one
/// [lineEnding] unless the output is empty.
///
/// Between a start and an end marker, the formatted commands are replaced by
/// the raw bytes of [source] between the two markers' offsets. A start
/// with no end copies the rest of the source verbatim, which then ends the
/// output as is.
String emit(
  List<PrintCommand> commands, {
  IndentStyle style = IndentStyle.spaces,
  int indentSize = 2,
  String lineEnding = '\n',
  String source = '',
}) {
  final unit = style == IndentStyle.tabs ? '\t' : ' ' * indentSize;
  // Drop trailing newlines and separator whitespace; text is never trimmed.
  var end = commands.length;
  while (end > 0) {
    final last = commands[end - 1];
    if (last is NewlineCommand ||
        (last is TextCommand &&
            last.text.trim().isEmpty &&
            !last.text.contains('\n'))) {
      end--;
    } else {
      break;
    }
  }
  commands = commands.sublist(0, end);
  final buffer = StringBuffer();
  // Written lazily so blank lines carry no indentation.
  Indentation? pendingIndent;
  void writeIndent() {
    final indent = pendingIndent;
    if (indent == null) return;
    for (final part in indent.parts) {
      buffer.write(part ?? unit);
    }
    pendingIndent = null;
  }

  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    switch (command) {
      case TextCommand(:final text):
        if (text.isEmpty) break;
        writeIndent();
        buffer.write(text);
      case NewlineCommand(:final indentation):
        // A leading newline command only sets the first line's indentation.
        if (buffer.isNotEmpty || pendingIndent != null)
          buffer.write(lineEnding);
        pendingIndent = indentation;
      case MarkerCommand(:final marker) when marker.isStart:
        writeIndent();
        var end = i + 1;
        while (end < commands.length && !_isEnd(commands[end])) {
          end++;
        }
        if (end == commands.length) {
          return '$buffer${source.substring(marker.offset)}';
        }
        final endMarker = (commands[end] as MarkerCommand).marker;
        buffer.write(source.substring(marker.offset, endMarker.offset));
        i = end;
      case MarkerCommand():
        break;
    }
  }
  final output = buffer.toString();
  return output.isEmpty ? '' : '$output$lineEnding';
}

bool _isEnd(PrintCommand command) =>
    command is MarkerCommand && !command.marker.isStart;
