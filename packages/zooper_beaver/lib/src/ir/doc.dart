/// The document tree that formatting rules build and the printer lays out.
///
/// Wadler/Prettier instruction set plus [Marker], which is invisible to layout
/// and only tells the emitter where an ignored source region starts or ends.
library;

sealed class Doc {
  const Doc();
}

/// Literal text. Must not contain a newline unless it is source text that
/// spans lines verbatim (multi-line string, block comment).
final class Text extends Doc {
  const Text(this.text);
  final String text;
}

enum LineKind { soft, hard, literal }

/// A possible line break.
///
/// Soft: prints [flat] when its group is flat, a newline when broken.
/// Hard: always a newline, and forces every enclosing group to break.
/// Literal: a hard newline that resets indentation to column zero.
final class Line extends Doc {
  const Line.soft([this.flat = ' ']) : kind = LineKind.soft;
  const Line.hard() : kind = LineKind.hard, flat = '';
  const Line.literal() : kind = LineKind.literal, flat = '';

  final LineKind kind;
  final String flat;

  bool get isHard => kind != LineKind.soft;
}

/// Identity of a group, so an [IfBreak] elsewhere can read its printed mode.
final class GroupId {
  GroupId([this.debugName = '']);
  final String debugName;

  @override
  String toString() => 'GroupId($debugName)';
}

/// Prints [contents] flat if it fits on the rest of the line, else broken.
final class Group extends Doc {
  Group(this.contents, {this.shouldBreak = false, this.id});
  final Doc contents;

  /// Set by the builder to force a break, and by [propagateBreaks] when the
  /// contents hold a hard line or [BreakParent].
  bool shouldBreak;
  final GroupId? id;
}

/// Prettier's conditionalGroup: [states] are layouts of the same content,
/// most preferred first. The first prints flat if it fits; otherwise the
/// first middle state that fits prints broken; otherwise the last does. A
/// middle state fits when every line of it fits with its nested groups
/// flat, or, for the indices in [firstLineOnly], when its first line fits.
final class ConditionalGroup extends Doc {
  const ConditionalGroup(this.states, {this.firstLineOnly = const {}})
    : assert(states.length >= 2);
  final List<Doc> states;
  final Set<int> firstLineOnly;
}

/// Adds one indentation unit to the lines inside [contents].
final class Indent extends Doc {
  const Indent(this.contents);
  final Doc contents;
}

/// Adds [width] spaces, or the literal [string], to the lines inside
/// [contents]. With neither ([Align.toColumn]), the width is the distance
/// from the current indentation to the column where [contents] starts, so
/// wrapped lines line up under its first character (`indent.align.*`).
final class Align extends Doc {
  const Align(this.contents, int this.width) : string = null;
  const Align.string(this.contents, String this.string) : width = null;
  const Align.toColumn(this.contents) : width = null, string = null;
  final Doc contents;
  final int? width;
  final String? string;
}

/// [broken] if the referenced group printed broken, else [flat]. Without a
/// [groupId] the reference is the nearest enclosing group.
final class IfBreak extends Doc {
  const IfBreak(this.broken, [this.flat = const Concat([]), this.groupId]);
  final Doc broken;
  final Doc flat;
  final GroupId? groupId;
}

/// Paragraph layout: [parts] alternate content and separator (normally a soft
/// [Line]); a separator breaks only where the next content would overflow.
final class Fill extends Doc {
  const Fill(this.parts) : start = 0;
  const Fill._(this.parts, this.start);
  final List<Doc> parts;

  /// Index of the first part still to print; lets the printer walk a fill
  /// without copying its parts.
  final int start;

  Fill rest(int skip) => Fill._(parts, start + skip);
}

/// Forces every enclosing group to break.
final class BreakParent extends Doc {
  const BreakParent();
}

/// Deferred to just before the next newline (trailing `//` comments).
final class LineSuffix extends Doc {
  const LineSuffix(this.contents);
  final Doc contents;
}

final class Concat extends Doc {
  const Concat(this.parts);
  final List<Doc> parts;
}

/// Start or end of an ignored region at [offset] in the source. Takes no
/// width; the emitter replaces everything between a start and its end with
/// the raw source bytes.
final class Marker extends Doc {
  const Marker(this.offset, {required this.isStart});
  final int offset;
  final bool isStart;
}

// Builder helpers.
const Doc empty = Concat([]);
const Doc line = Line.soft();
const Doc softline = Line.soft('');
const Doc hardline = Line.hard();
const Doc literalline = Line.literal();
const Doc breakParent = BreakParent();

Doc text(String s) => Text(s);

Doc concat(List<Doc> parts) => parts.length == 1 ? parts.single : Concat(parts);

Doc group(Doc contents, {bool shouldBreak = false, GroupId? id}) =>
    Group(contents, shouldBreak: shouldBreak, id: id);

Doc indent(Doc contents) => Indent(contents);

Doc align(int width, Doc contents) => Align(contents, width);

Doc alignString(String string, Doc contents) => Align.string(contents, string);

Doc alignToColumn(Doc contents) => Align.toColumn(contents);

Doc ifBreak(Doc broken, [Doc flat = empty, GroupId? groupId]) =>
    IfBreak(broken, flat, groupId);

Doc fill(List<Doc> parts) => Fill(parts);

Doc lineSuffix(Doc contents) => LineSuffix(contents);

/// [doc] with every soft line printed flat. Hard lines (comments, block
/// bodies) still break.
Doc printedFlat(Doc doc) => switch (doc) {
  Line(isHard: false) => Text(doc.flat),
  Group(:final contents) => printedFlat(contents),
  ConditionalGroup(:final states) => printedFlat(states.first),
  IfBreak(:final flat) => printedFlat(flat),
  Fill(:final parts) => Concat([
    for (final part in parts.skip(doc.start)) printedFlat(part),
  ]),
  Concat(:final parts) => Concat([for (final part in parts) printedFlat(part)]),
  Indent(:final contents) => Indent(printedFlat(contents)),
  Align(:final contents, :final width, :final string) => width != null
      ? Align(printedFlat(contents), width)
      : string != null
      ? Align.string(printedFlat(contents), string)
      : Align.toColumn(printedFlat(contents)),
  LineSuffix(:final contents) => LineSuffix(printedFlat(contents)),
  Line() || Text() || BreakParent() || Marker() => doc,
};

/// [docs] separated by [separator].
Doc join(Doc separator, Iterable<Doc> docs) {
  final parts = <Doc>[];
  for (final doc in docs) {
    if (parts.isNotEmpty) parts.add(separator);
    parts.add(doc);
  }
  return concat(parts);
}
