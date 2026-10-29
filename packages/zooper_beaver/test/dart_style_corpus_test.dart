/// Scores Beaver against dart_style's tall corpus. Mismatches are reported,
/// never failures; structural or idempotence failures fail the suite.
library;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'src/golden_runner.dart';

const corpus = 'test/golden/dart_style/tall';

void main() {
  test('dart_style tall corpus', () {
    final scores = <String, AreaScore>{};
    final failures = <String>[];
    // Cross-area view of every `*comment*` file.
    final commentScore = AreaScore();
    for (final file in loadGoldenFiles(corpus)) {
      final area = p.split(p.relative(file.path, from: corpus)).first;
      final score = scores.putIfAbsent(area, AreaScore.new);
      final isComment = p.basename(file.path).contains('comment');
      for (final c in file.cases) {
        final result = runCase(file, c);
        score.add(result.outcome);
        if (isComment) commentScore.add(result.outcome);
        if (result.outcome == Outcome.safetyFailure) {
          failures.add('${file.path} ${c.label}: ${result.detail}');
        }
      }
    }
    print(scoreTable(scores));
    print(
      '\nComment files (all areas): ${commentScore.match}/'
      '${commentScore.eligible} (${commentScore.percent})',
    );
    expect(failures, isEmpty, reason: failures.take(20).join('\n\n'));
  });
}
