# Performance

Budgets: the engine (parse, format, verify) should stay within **30 ms** per file, and format-on-save end to end (process start, config, parse, format, verify) within **150 ms**; above 150 ms a daemon becomes worth considering. Verification is never disabled to meet either budget.

## Engine time

Measured with `tool/benchmark.dart`, AOT-compiled, median of 20 runs after 5 warm-up runs, `dart` preset, on an Apple M4 Pro (Dart 3.13.3), 2026-10-28.

"Verification" is the output parse plus all structural verification checks; the input parse is shared with formatting and counted there.

| File | Lines | Engine (ms) | Verification (ms) | Without verification (ms) |
|---|---:|---:|---:|---:|
| path `style/posix.dart` | 74 | 0.7 | 0.4 | 0.4 |
| Flutter `widgets/container.dart` | 494 | 2.3 | 1.3 | 1.0 |
| path `context.dart` | 1201 | 5.8 | 3.6 | 2.2 |
| Flutter `widgets/framework.dart` | 7468 | 41.4 | 24.1 | 17.2 |

Against the 30 ms engine budget: files up to a few thousand lines are well inside it (a typical 500-line file takes about 2 ms). Only very large files exceed it; `framework.dart`, at 7,468 lines one of the largest files in Flutter, takes 41 ms. Verification is roughly 55–60% of engine time.

Reproduce:

```sh
cd packages/zooper_beaver
dart compile exe tool/benchmark.dart -o /tmp/beaver-bench
/tmp/beaver-bench path/to/file.dart ...
```

## End-to-end format-on-save

### CLI round trip

What both editor integrations do on save: spawn the AOT `beaver --stdin --stdin-name <file>`, pipe the buffer in, read the result. This covers process start, configuration discovery, parse, format and verification. Measured from Python's `subprocess.run` (spawn and pipe overhead included), median of 20 runs after 5 warm-ups, Apple M4 Pro, inside the Flutter repository (so a `pubspec.yaml` is discovered):

| File | Lines | Median (ms) | Max (ms) |
|---|---:|---:|---:|
| Flutter `widgets/container.dart` | 494 | 16.3 | 18.1 |
| Flutter `widgets/framework.dart` | 7468 | 58.2 | 61.5 |

Against the 150 ms threshold: well inside it, also for one of the largest files in Flutter, so no daemon is needed.

### Inside VS Code and IntelliJ

Not yet measured inside the editors themselves (their own overhead of collecting the buffer and applying the edit comes on top of the round trip above).
