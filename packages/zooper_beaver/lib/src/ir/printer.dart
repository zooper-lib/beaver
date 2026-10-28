/// Prettier's greedy printer: fits each group on the rest of the current line
/// or breaks it, left to right. Output is a list of commands for `emit/`, so
/// indentation style and line endings are decided there.
library;

import 'doc.dart';

/// Indentation of a line: a sequence of indent units and alignment strings.
final class Indentation {
  const Indentation._(this.parts, this.width);

  static const root = Indentation._([], 0);

  /// `null` is one indentation unit; a string is alignment padding.
  final List<String?> parts;

  /// Column the line's content starts at, a unit counting as the indent size.
  final int width;

  Indentation _indent(int size) =>
      Indentation._([...parts, null], width + size);

  Indentation _align(String padding) =>
      Indentation._([...parts, padding], width + padding.length);
}

sealed class PrintCommand {
  const PrintCommand();
}

final class TextCommand extends PrintCommand {
  const TextCommand(this.text);
  final String text;
}

final class NewlineCommand extends PrintCommand {
  const NewlineCommand(this.indentation);
  final Indentation indentation;
}

final class MarkerCommand extends PrintCommand {
  const MarkerCommand(this.marker);
  final Marker marker;
}

enum _Mode { flat, broken }

typedef _Cmd = (Indentation, _Mode, Doc);

/// Marks every group that contains a hard line, a [BreakParent] or a group
/// that must break as broken, so the printer never tries it flat.
void propagateBreaks(Doc doc) => _propagate(doc, Set.identity());

bool _propagate(Doc doc, Set<Group> visited) {
  switch (doc) {
    case Text() || Marker():
      return false;
    case Line():
      return doc.isHard;
    case BreakParent():
      return true;
    case Group():
      if (visited.add(doc) && _propagate(doc.contents, visited)) {
        doc.shouldBreak = true;
      }
      return doc.shouldBreak;
    case ConditionalGroup(:final states):
      var result = false;
      for (final state in states) {
        if (_propagate(state, visited)) result = true;
      }
      return result;
    case Indent(:final contents) ||
        Align(:final contents) ||
        LineSuffix(:final contents):
      return _propagate(contents, visited);
    case IfBreak():
      // Both branches, as Prettier does.
      final broken = _propagate(doc.broken, visited);
      return _propagate(doc.flat, visited) || broken;
    case Fill(:final parts) || Concat(:final parts):
      var result = false;
      for (final part in parts) {
        if (_propagate(part, visited)) result = true;
      }
      return result;
  }
}

/// Lays out [doc] within [lineLength] columns, a unit of indentation counting
/// as [indentSize] columns. Every line, the first included, starts with
/// [leadingLevels] indentation units and then [leadingIndent] spaces.
List<PrintCommand> printDoc(
  Doc doc, {
  required int lineLength,
  required int indentSize,
  int leadingIndent = 0,
  int leadingLevels = 0,
}) {
  propagateBreaks(doc);
  var root = Indentation.root;
  for (var i = 0; i < leadingLevels; i++) {
    root = root._indent(indentSize);
  }
  if (leadingIndent > 0) root = root._align(' ' * leadingIndent);
  final out = <PrintCommand>[if (root.width > 0) NewlineCommand(root)];
  final groupModes = <GroupId, _Mode>{};
  final lineSuffixes = <_Cmd>[];
  final cmds = <_Cmd>[(root, _Mode.broken, doc)];
  var pos = root.width;
  var shouldRemeasure = false;

  bool fits(_Cmd next, List<_Cmd> rest, {bool mustBeFlat = false}) => _fits(
    next,
    rest,
    lineLength - pos,
    groupModes,
    mustBeFlat: mustBeFlat,
    hasLineSuffix: lineSuffixes.isNotEmpty,
  );

  while (cmds.isNotEmpty || lineSuffixes.isNotEmpty) {
    if (cmds.isEmpty) {
      cmds.addAll(lineSuffixes.reversed);
      lineSuffixes.clear();
      continue;
    }
    final (ind, mode, doc) = cmds.removeLast();
    switch (doc) {
      case Text(:final text):
        out.add(TextCommand(text));
        final newline = text.lastIndexOf('\n');
        pos = newline < 0 ? pos + text.length : text.length - newline - 1;
      case Concat(:final parts):
        for (var i = parts.length - 1; i >= 0; i--) {
          cmds.add((ind, mode, parts[i]));
        }
      case Indent(:final contents):
        cmds.add((ind._indent(indentSize), mode, contents));
      case Align(:final contents, :final width, :final string):
        final padding =
            string ?? ' ' * (width ?? (pos - ind.width).clamp(0, pos));
        cmds.add((ind._align(padding), mode, contents));
      case Group():
        final _Mode groupMode;
        if (mode == _Mode.flat && !shouldRemeasure) {
          groupMode = doc.shouldBreak ? _Mode.broken : _Mode.flat;
        } else {
          shouldRemeasure = false;
          final flat = (ind, _Mode.flat, doc.contents);
          groupMode = !doc.shouldBreak && fits(flat, cmds)
              ? _Mode.flat
              : _Mode.broken;
        }
        cmds.add((ind, groupMode, doc.contents));
        if (doc.id case final id?) {
          // A group with no line in it prints the same either way; report
          // it flat, so an IfBreak reading it sees its real shape.
          groupModes[id] = groupMode == _Mode.broken && _hasLine(doc.contents)
              ? _Mode.broken
              : _Mode.flat;
        }
      case ConditionalGroup(:final states, :final firstLineOnly):
        final first = (ind, _Mode.flat, states.first);
        if (mode == _Mode.flat && !shouldRemeasure) {
          cmds.add(first);
          break;
        }
        shouldRemeasure = false;
        if (!_forcesBreak(states.first) && fits(first, cmds)) {
          cmds.add(first);
          break;
        }
        var chosen = states.last;
        for (var i = 1; i < states.length - 1; i++) {
          final state = (ind, _Mode.broken, states[i]);
          if (firstLineOnly.contains(i)
              ? fits(state, cmds)
              : _fitsExpanded(
                  state,
                  cmds,
                  lineLength - pos,
                  lineLength,
                  indentSize,
                  groupModes,
                )) {
            chosen = states[i];
            break;
          }
        }
        cmds.add((ind, _Mode.broken, chosen));
      case Fill():
        _printFill(doc, ind, mode, cmds, fits);
      case IfBreak():
        final groupMode = doc.groupId == null
            ? mode
            : groupModes[doc.groupId] ?? _Mode.flat;
        cmds.add((
          ind,
          mode,
          groupMode == _Mode.broken ? doc.broken : doc.flat,
        ));
      case LineSuffix(:final contents):
        lineSuffixes.add((ind, mode, contents));
      case BreakParent():
        break;
      case Marker():
        out.add(MarkerCommand(doc));
      case Line():
        if (mode == _Mode.flat && !doc.isHard) {
          out.add(TextCommand(doc.flat));
          pos += doc.flat.length;
          break;
        }
        if (mode == _Mode.flat) shouldRemeasure = true;
        if (lineSuffixes.isNotEmpty) {
          cmds.add((ind, mode, doc));
          cmds.addAll(lineSuffixes.reversed);
          lineSuffixes.clear();
          break;
        }
        _trimTrailingWhitespace(out);
        if (doc.kind == LineKind.literal) {
          out.add(const NewlineCommand(Indentation.root));
          pos = 0;
        } else {
          out.add(NewlineCommand(ind));
          pos = ind.width;
        }
    }
  }
  return out;
}

/// Prettier's fill: each separator breaks only if the content after it does
/// not fit on the current line.
void _printFill(
  Fill doc,
  Indentation ind,
  _Mode mode,
  List<_Cmd> cmds,
  bool Function(_Cmd, List<_Cmd>, {bool mustBeFlat}) fits,
) {
  final parts = doc.parts;
  final start = doc.start;
  final length = parts.length - start;
  if (length <= 0) return;

  final content = parts[start];
  final contentFlat = (ind, _Mode.flat, content);
  final contentBroken = (ind, _Mode.broken, content);
  // Content holding a forced break (a hard line outside any group, such as
  // a switch body) never prints flat: its groups must be measured.
  final contentFits =
      !_forcesBreak(content) && fits(contentFlat, const [], mustBeFlat: true);
  if (length == 1) {
    cmds.add(contentFits ? contentFlat : contentBroken);
    return;
  }

  final separator = parts[start + 1];
  final separatorFlat = (ind, _Mode.flat, separator);
  final separatorBroken = (ind, _Mode.broken, separator);
  if (length == 2) {
    cmds.addAll(
      contentFits
          ? [separatorFlat, contentFlat]
          : [separatorBroken, contentBroken],
    );
    return;
  }

  final remaining = (ind, mode, doc.rest(2));
  final next = parts[start + 2];
  final pairFlat = (ind, _Mode.flat, Concat([content, separator, next]));
  // Content holding a forced break (a hard line, such as after an own-line
  // comment that leads it) starts on its own line.
  if (!_forcesBreak(next) && fits(pairFlat, const [], mustBeFlat: true)) {
    cmds.addAll([remaining, separatorFlat, contentFlat]);
  } else if (contentFits) {
    cmds.addAll([remaining, separatorBroken, contentFlat]);
  } else {
    cmds.addAll([remaining, separatorBroken, contentBroken]);
  }
}

/// Whether [next], followed by [rest] up to the first line break, fits in
/// [width] columns. Text after a pending line suffix (a `//` comment that
/// must end the line) never fits.
bool _fits(
  _Cmd next,
  List<_Cmd> rest,
  int width,
  Map<GroupId, _Mode> groupModes, {
  required bool mustBeFlat,
  required bool hasLineSuffix,
}) {
  var restIndex = rest.length;
  final cmds = <(_Mode, Doc)>[(next.$2, next.$3)];
  while (width >= 0) {
    if (cmds.isEmpty) {
      if (restIndex == 0) return true;
      final (_, mode, doc) = rest[--restIndex];
      cmds.add((mode, doc));
      continue;
    }
    final (mode, doc) = cmds.removeLast();
    switch (doc) {
      case Text(:final text):
        // A separator may follow a deferred comment (it came before the
        // comment in the source); anything else would end up after it.
        if (hasLineSuffix && text.isNotEmpty && text != ',' && text != ';') {
          return false;
        }
        final newline = text.indexOf('\n');
        if (newline >= 0) return width - newline >= 0;
        width -= text.length;
      case LineSuffix():
        hasLineSuffix = true;
      case Concat(:final parts) || Fill(:final parts):
        final start = doc is Fill ? doc.start : 0;
        for (var i = parts.length - 1; i >= start; i--) {
          cmds.add((mode, parts[i]));
        }
      case Indent(:final contents) || Align(:final contents):
        cmds.add((mode, contents));
      case Group():
        if (mustBeFlat && doc.shouldBreak) return false;
        cmds.add((doc.shouldBreak ? _Mode.broken : mode, doc.contents));
      case ConditionalGroup(:final states):
        cmds.add((mode, mode == _Mode.broken ? states.last : states.first));
      case IfBreak():
        final groupMode = doc.groupId == null
            ? mode
            : groupModes[doc.groupId] ?? _Mode.flat;
        cmds.add((mode, groupMode == _Mode.broken ? doc.broken : doc.flat));
      case Line():
        if (mode == _Mode.broken || doc.isHard) return true;
        if (hasLineSuffix && doc.flat.isNotEmpty) return false;
        width -= doc.flat.length;
      case BreakParent() || Marker():
        break;
    }
  }
  return false;
}

/// Whether [next] prints within [lineLength] on every line it spans, its
/// own lines broken and every group inside it flat, and then [rest] fits up
/// to its first line break. [width] is what is left of the current line.
bool _fitsExpanded(
  _Cmd next,
  List<_Cmd> rest,
  int width,
  int lineLength,
  int indentSize,
  Map<GroupId, _Mode> groupModes,
) {
  var restIndex = rest.length;
  var inRest = false;
  final cmds = <_Cmd>[next];
  while (width >= 0) {
    if (cmds.isEmpty) {
      if (restIndex == 0) return true;
      cmds.add(rest[--restIndex]);
      inRest = true;
      continue;
    }
    final (ind, mode, doc) = cmds.removeLast();
    switch (doc) {
      case Text(:final text):
        final newline = text.indexOf('\n');
        if (newline >= 0) return width - newline >= 0;
        width -= text.length;
      case Concat(:final parts) || Fill(:final parts):
        final start = doc is Fill ? doc.start : 0;
        for (var i = parts.length - 1; i >= start; i--) {
          cmds.add((ind, mode, parts[i]));
        }
      case Indent(:final contents):
        cmds.add((ind._indent(indentSize), mode, contents));
      case Align(:final contents, width: final w, :final string):
        final column = lineLength - width;
        final padding =
            string ?? ' ' * (w ?? (column - ind.width).clamp(0, column));
        cmds.add((ind._align(padding), mode, contents));
      case Group():
        if (!inRest && doc.shouldBreak) return false;
        // Groups inside [next] print flat; in [rest] they keep their mode.
        final groupMode = doc.shouldBreak
            ? _Mode.broken
            : inRest
            ? mode
            : _Mode.flat;
        cmds.add((ind, groupMode, doc.contents));
      case ConditionalGroup(:final states):
        cmds.add((ind, _Mode.flat, states.first));
      case IfBreak():
        final groupMode = doc.groupId == null
            ? mode
            : groupModes[doc.groupId] ?? _Mode.flat;
        cmds.add((
          ind,
          mode,
          groupMode == _Mode.broken ? doc.broken : doc.flat,
        ));
      case Line():
        if (mode == _Mode.flat && !doc.isHard) {
          width -= doc.flat.length;
        } else if (inRest) {
          return true;
        } else if (doc.isHard) {
          return false;
        } else {
          width = lineLength - ind.width;
        }
      case LineSuffix() || BreakParent():
        if (!inRest) return false;
      case Marker():
        break;
    }
  }
  return false;
}

/// Whether [doc] contains a hard line or a group marked broken.
bool _forcesBreak(Doc doc) => switch (doc) {
  Line() => doc.isHard,
  BreakParent() => true,
  Group() => doc.shouldBreak,
  ConditionalGroup(:final states) => _forcesBreak(states.first),
  Indent(:final contents) || Align(:final contents) => _forcesBreak(contents),
  Fill(:final parts) || Concat(:final parts) => parts.any(_forcesBreak),
  IfBreak() || Text() || LineSuffix() || Marker() => false,
};

bool _hasLine(Doc doc) => switch (doc) {
  Line() => true,
  Group(:final contents) || Indent(:final contents) || Align(:final contents) =>
    _hasLine(contents),
  IfBreak() => _hasLine(doc.broken) || _hasLine(doc.flat),
  ConditionalGroup(:final states) => states.any(_hasLine),
  Fill(:final parts) || Concat(:final parts) => parts.any(_hasLine),
  Text() || LineSuffix() || BreakParent() || Marker() => false,
};

final _blank = RegExp(r'^[ \t]*$');

/// Drops separator whitespace before a newline. Text with content (a
/// comment with trailing spaces) is never edited.
void _trimTrailingWhitespace(List<PrintCommand> out) {
  while (out.isNotEmpty) {
    final last = out.last;
    if (last is! TextCommand || !_blank.hasMatch(last.text)) return;
    out.removeLast();
  }
}
