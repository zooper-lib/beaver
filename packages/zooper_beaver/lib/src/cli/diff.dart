/// Minimal unified diff of two texts by line (Myers' algorithm), so the CLI
/// needs no diff dependency.
library;

/// A unified diff from [before] to [after] with [context] lines around each
/// change, or an empty string if they are equal.
String unifiedDiff(
  String before,
  String after, {
  required String fromName,
  required String toName,
  int context = 3,
}) {
  final a = _lines(before);
  final b = _lines(after);
  final ops = _diff(a, b);
  if (ops.every((op) => op.$1 == ' ')) return '';

  final out = StringBuffer('--- $fromName\n+++ $toName\n');
  var i = 0;
  while (i < ops.length) {
    if (ops[i].$1 == ' ') {
      i++;
      continue;
    }
    // A hunk: from `context` lines before this change to `context` lines
    // after the last change closer than 2 * context to the previous one.
    var start = i;
    var back = 0;
    while (start > 0 && back < context && ops[start - 1].$1 == ' ') {
      start--;
      back++;
    }
    var end = i;
    var quiet = 0;
    while (end < ops.length && quiet <= 2 * context) {
      quiet = ops[end].$1 == ' ' ? quiet + 1 : 0;
      end++;
    }
    end -= quiet > context ? quiet - context : 0;

    var aStart = 1, bStart = 1;
    for (var k = 0; k < start; k++) {
      if (ops[k].$1 != '+') aStart++;
      if (ops[k].$1 != '-') bStart++;
    }
    var aCount = 0, bCount = 0;
    for (var k = start; k < end; k++) {
      if (ops[k].$1 != '+') aCount++;
      if (ops[k].$1 != '-') bCount++;
    }
    out.writeln(
      '@@ -${aCount == 0 ? aStart - 1 : aStart},$aCount '
      '+${bCount == 0 ? bStart - 1 : bStart},$bCount @@',
    );
    for (var k = start; k < end; k++) {
      out.writeln('${ops[k].$1}${ops[k].$2}');
    }
    i = end;
  }
  return out.toString();
}

List<String> _lines(String text) {
  final lines = text.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  return lines;
}

/// Edit script as (' ' | '-' | '+', line) pairs.
List<(String, String)> _diff(List<String> a, List<String> b) {
  final n = a.length, m = b.length, max = n + m;
  final v = List<int>.filled(2 * max + 2, 0);
  final trace = <List<int>>[];
  outer:
  for (var d = 0; d <= max; d++) {
    trace.add(List.of(v));
    for (var k = -d; k <= d; k += 2) {
      var x = k == -d || (k != d && v[max + k - 1] < v[max + k + 1])
          ? v[max + k + 1]
          : v[max + k - 1] + 1;
      var y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[max + k] = x;
      if (x >= n && y >= m) break outer;
    }
  }

  // Walk the trace back to build the script.
  final ops = <(String, String)>[];
  var x = n, y = m;
  for (var d = trace.length - 1; d > 0; d--) {
    final vd = trace[d];
    final k = x - y;
    final prevK = k == -d || (k != d && vd[max + k - 1] < vd[max + k + 1])
        ? k + 1
        : k - 1;
    final prevX = vd[max + prevK];
    final prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      ops.add((' ', a[--x]));
      y--;
    }
    if (x == prevX) {
      ops.add(('+', b[--y]));
    } else {
      ops.add(('-', a[--x]));
    }
  }
  while (x > 0 && y > 0) {
    ops.add((' ', a[--x]));
    y--;
  }
  return ops.reversed.toList();
}
