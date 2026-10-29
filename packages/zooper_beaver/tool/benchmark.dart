/// Measures engine time per file: the whole pipeline (format, which always
/// verifies) and the verification share of it. Run AOT-compiled for numbers
/// comparable to the shipped binary:
///
///     dart compile exe tool/benchmark.dart -o /tmp/bench && /tmp/bench <files>
library;

import 'dart:io';

import 'package:zooper_beaver/src/config/config.dart';
import 'package:zooper_beaver/src/format.dart';
import 'package:zooper_beaver/src/parse/parse.dart';
import 'package:zooper_beaver/src/verify/verify.dart';

const _warmup = 5;
const _runs = 20;

void main(List<String> paths) {
  print(
    '| File | Lines | Engine (ms) | Verification (ms) | Without verification (ms) |',
  );
  print('|---|---:|---:|---:|---:|');
  for (final path in paths) {
    final source = File(path).readAsStringSync();
    final output = format(source);
    final parsed = parse(source);
    final total = _median(() => format(source));
    // The pipeline reuses its input parse, so only the output parse and the
    // checks count as verification.
    final verification = _median(
      () => verify(parsed, output, config: BeaverConfig.dart),
    );
    final lines = '\n'.allMatches(source).length;
    print(
      '| ${path.split('/').last} | $lines | ${_ms(total)} | '
      '${_ms(verification)} | ${_ms(total - verification)} |',
    );
  }
}

int _median(void Function() run) {
  for (var i = 0; i < _warmup; i++) {
    run();
  }
  final times = <int>[];
  for (var i = 0; i < _runs; i++) {
    final watch = Stopwatch()..start();
    run();
    times.add(watch.elapsedMicroseconds);
  }
  times.sort();
  return times[times.length ~/ 2];
}

String _ms(int micros) => (micros / 1000).toStringAsFixed(1);
