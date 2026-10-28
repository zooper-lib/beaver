/// Beaver's strict golden suites: every case under `test/golden/<area>/` must
/// match, verify and be idempotent.
library;

import 'package:test/test.dart';

import 'src/golden_runner.dart';

void main() {
  for (final file in loadGoldenFiles(
    'test/golden',
    exclude: 'test/golden/dart_style',
  )) {
    group(file.path, () {
      for (final c in file.cases) {
        final skip = c.hasSelectionMarkers ? 'selection markers' : null;
        test(c.label, skip: skip, () {
          final result = runCase(file, c);
          if (result.outcome != Outcome.match) {
            fail(
              '${file.path} ${c.label}: ${result.outcome.name}\n'
              '${result.detail ?? ''}\n'
              '--- expected\n${c.expected}\n'
              '--- actual\n${result.output}',
            );
          }
        });
      }
    });
  }
}
