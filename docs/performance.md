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

Measured by each plugin's test suite on Beaver's own `lib/src/cli/cli.dart` (541 lines), from the save request until the formatted file is on disk: the editor collects the buffer, runs `beaver`, applies the edit and writes the file. Seven saves, each after making the file unformatted again; the first save also locates and checks the binary, so it is listed on its own. The tests print a `BEAVER_LATENCY` line and do not fail on it (machines vary).

| Editor | Machine | First save (ms) | Median of the rest (ms) | Max of the rest (ms) |
|---|---|---:|---:|---:|
| IntelliJ IDEA Community 2024.3.6 | Apple M4 Pro | 286 | 92 | 98 |
| IntelliJ IDEA 2025.3 | Apple M4 Pro | 383 | 72 | 157 |
| VS Code | CI (`ubuntu-latest`, under xvfb) | 213 | 144 | 293 |

The IntelliJ test checks for the formatted file every 20 ms, so its figures can be up to 20 ms high. VS Code's six later saves were 110, 293, 214, 144, 65 and 53 ms: a shared CI runner, with a slower CPU than the machine above, varies a lot from save to save.

Against the 150 ms threshold: the median save is inside it in both editors, in VS Code only just. Single saves exceed it (IntelliJ 2025.3 once at 157 ms, VS Code on CI up to 293 ms), and so does the first save of a session, because the binary is located and checked then. Beaver's own share is small: the CLI round trip for a file this size is about 16 ms on the M4 Pro, so most of the time is the editor's own save and formatting pipeline. No daemon is needed for that share; if save latency becomes a complaint, the editors' overhead is where to look first.
