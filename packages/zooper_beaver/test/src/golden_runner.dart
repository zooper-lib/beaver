/// Runs golden cases: strict for Beaver's suites, scored for the reference
/// corpus.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/config/loader.dart';
import 'package:zooper_beaver/src/format.dart';
import 'package:zooper_beaver/src/verify/verification_failure.dart';

import 'golden_file.dart';

enum Outcome { match, mismatch, safetyFailure, skipped }

final class CaseResult {
  const CaseResult(this.outcome, [this.output, this.detail]);
  final Outcome outcome;
  final String? output;
  final String? detail;
}

typedef CaseFormatter = String Function(
  GoldenFile file,
  GoldenCase c,
  String input,
);

String formatCase(GoldenFile file, GoldenCase c, String input) {
  final config = BeaverConfig.dart.merge({
    if (file.pageWidth != null) 'line_length': file.pageWidth,
    ...file.options.config,
    ...c.options.config,
  });
  final indent = c.options.leadingIndent ?? file.options.leadingIndent ?? 0;
  final experiments = [...file.options.experiments, ...c.options.experiments];
  if (file.isUnit) {
    return format(
      input,
      config: config,
      leadingIndent: indent,
      experiments: experiments,
    );
  }
  final output = formatStatement(
    input,
    config: config,
    leadingIndent: indent,
    experiments: experiments,
  );
  return output.endsWith('\n')
      ? output.substring(0, output.length - 1)
      : output;
}

/// Formats [c], then formats the output again to check idempotence.
CaseResult runCase(
  GoldenFile file,
  GoldenCase c, {
  CaseFormatter formatter = formatCase,
}) {
  final expected = c.expected;
  if (expected == null || c.hasSelectionMarkers) {
    return const CaseResult(Outcome.skipped);
  }
  final String output;
  try {
    output = formatter(file, c, c.input);
  } on VerificationFailure catch (e) {
    return CaseResult(Outcome.safetyFailure, null, '$e');
  } catch (e) {
    return CaseResult(Outcome.mismatch, null, '$e');
  }
  try {
    final again = formatter(file, c, output);
    if (again != output) {
      return CaseResult(
        Outcome.safetyFailure,
        output,
        'Not idempotent. Second pass:\n$again',
      );
    }
  } catch (e) {
    return CaseResult(Outcome.safetyFailure, output, 'Second pass failed: $e');
  }
  return CaseResult(
    output == expected ? Outcome.match : Outcome.mismatch,
    output,
  );
}

/// Golden files under [directory], sorted, optionally skipping a subdirectory.
List<GoldenFile> loadGoldenFiles(String directory, {String? exclude}) {
  final files = Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.stmt') || f.path.endsWith('.unit'))
      .where((f) => exclude == null || !p.isWithin(exclude, f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final f in files) loadGoldenFile(f.path, f.readAsStringSync())];
}

/// Parses a golden file and validates every option against the real
/// configuration schema, so a bad option fails the suite at load time.
GoldenFile loadGoldenFile(String path, String contents) {
  final file = parseGoldenFile(path, contents);
  validateValues(file.options.config, '$path (file options)');
  for (final c in file.cases) {
    validateValues(c.options.config, '$path ${c.label}');
  }
  return file;
}

final class AreaScore {
  int match = 0;
  int mismatch = 0;
  int safety = 0;
  int skipped = 0;

  int get eligible => match + mismatch + safety;

  void add(Outcome outcome) => switch (outcome) {
    Outcome.match => match++,
    Outcome.mismatch => mismatch++,
    Outcome.safetyFailure => safety++,
    Outcome.skipped => skipped++,
  };

  String get percent =>
      eligible == 0 ? '-' : '${(100 * match / eligible).toStringAsFixed(1)}%';
}

/// Markdown table of [scores] by area plus a total row.
String scoreTable(Map<String, AreaScore> scores) {
  final total = AreaScore();
  final rows = <String>[];
  for (final MapEntry(key: area, value: s) in scores.entries) {
    total
      ..match += s.match
      ..mismatch += s.mismatch
      ..safety += s.safety
      ..skipped += s.skipped;
    rows.add(_row(area, s));
  }
  return [
    '| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |',
    '|---|---:|---:|---:|---:|---:|---:|',
    ...rows,
    _row('**total**', total),
  ].join('\n');
}

String _row(String area, AreaScore s) =>
    '| $area | ${s.eligible} | ${s.match} | ${s.mismatch} | ${s.safety} | '
    '${s.skipped} | ${s.percent} |';
