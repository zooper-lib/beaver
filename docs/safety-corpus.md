# Safety corpus

The safety invariants are checked on real code, not only on test cases: every file must pass structural verification, a second formatting pass must change nothing, and ignored regions must stay byte-identical (part of verification). Run:

```sh
cd packages/zooper_beaver
dart compile exe tool/corpus.dart -o /tmp/beaver-corpus
/tmp/beaver-corpus \
  --config tool/corpus_configs/wide.yaml \
  --config tool/corpus_configs/aligned.yaml \
  --config tool/corpus_configs/loose.yaml \
  <directories...>
```

Without `--config` the `dart` preset is used. The three non-default configurations exercise wider lines with 4-space indent, `remove` commas, single quotes and filled binary expressions (`wide`); tabs, all alignment, named-argument chopping, one-line blocks and lambdas and `min_calls` (`aligned`); and `if_long`/`never` policies, no kept breaks, `preserve` commas, double quotes and inverted spacing (`loose`).

## Last run (2026-10-28)

1,829 files: `analyzer` 14.6.0 `lib/`, Flutter `packages/flutter/lib` and `packages/flutter_test/lib`, `test_core` 0.6.21, `test_api`, `dart_style` 3.1.9, `path`, `args`, `yaml`, `glob`.

| Configuration | Files | Passed | Failures |
|---|---:|---:|---:|
| `dart` preset | 1829 | 1829 | 0 |
| `wide` | 1829 | 1829 | 0 |
| `aligned` | 1829 | 1829 | 0 |
| `loose` | 1829 | 1829 | 0 |

The first run under the non-default configurations found defects in about 60 files; verification caught every one before output. Each was fixed and reduced to a golden case in `test/golden/regressions/corpus.stmt`.
