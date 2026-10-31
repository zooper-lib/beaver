# Upstream: dart_style tall-style test corpus

`tall/` is a verbatim copy of `test/tall/` from dart_style. Do not edit it; refresh by copying a newer release over it and re-baselining the match percentage.

| Field | Value |
|---|---|
| Repository | https://github.com/dart-lang/dart_style |
| Release | v3.1.14 (commit `cc806f6461b1407fba0b3c82f8c7aea4b4a90b91`) |
| Language version | 3.13 (newest output section in the corpus; Beaver formats at the latest language version) |
| Imported | 2026-10-28 |
| License | BSD 3-Clause, see `LICENSE` |

`short/` is deliberately not imported.

## Match percentage

Produced by `dart test test/dart_style_corpus_test.dart` under the `dart` preset. A mismatch is any byte difference from dart_style's expected output; safety failures (structural verification or idempotence) must be zero. "Skipped" counts cases with selection markers and cases whose newest output section is marked unsupported at the latest language version.

### Current (2026-10-30, the settings after 0.1.0)

| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |
|---|---:|---:|---:|---:|---:|---:|
| declaration | 466 | 264 | 202 | 0 | 2 | 56.7% |
| expression | 628 | 370 | 258 | 0 | 0 | 58.9% |
| function | 76 | 57 | 19 | 0 | 1 | 75.0% |
| invocation | 394 | 234 | 160 | 0 | 0 | 59.4% |
| other | 54 | 29 | 25 | 0 | 45 | 53.7% |
| pattern | 159 | 65 | 94 | 0 | 0 | 40.9% |
| preserve_trailing_commas | 85 | 55 | 30 | 0 | 0 | 64.7% |
| regression | 622 | 260 | 362 | 0 | 4 | 41.8% |
| statement | 305 | 179 | 126 | 0 | 0 | 58.7% |
| top_level | 100 | 75 | 25 | 0 | 0 | 75.0% |
| type | 143 | 41 | 102 | 0 | 0 | 28.7% |
| variable | 94 | 63 | 31 | 0 | 0 | 67.0% |
| **total** | 3126 | 1692 | 1434 | 0 | 52 | 54.1% |

Comment files (all areas): 253/578 (43.8%)

Two more matches than 0.1.0, both from the two preset changes: `blank_lines.between_comment_and_declaration: preserve` keeps a blank line after a comment, as dart_style does (three more matches), and `wrap.cascades.keep_existing_line_breaks: inherit` keeps a typed break before a one-section cascade, which dart_style joins (one fewer, `regression/0300/0379.stmt`).

### 0.1.0 (2026-10-28, after formatting Beaver's own sources)

| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |
|---|---:|---:|---:|---:|---:|---:|
| declaration | 466 | 264 | 202 | 0 | 2 | 56.7% |
| expression | 628 | 370 | 258 | 0 | 0 | 58.9% |
| function | 76 | 57 | 19 | 0 | 1 | 75.0% |
| invocation | 394 | 234 | 160 | 0 | 0 | 59.4% |
| other | 54 | 29 | 25 | 0 | 45 | 53.7% |
| pattern | 159 | 65 | 94 | 0 | 0 | 40.9% |
| preserve_trailing_commas | 85 | 55 | 30 | 0 | 0 | 64.7% |
| regression | 622 | 260 | 362 | 0 | 4 | 41.8% |
| statement | 305 | 179 | 126 | 0 | 0 | 58.7% |
| top_level | 100 | 73 | 27 | 0 | 0 | 73.0% |
| type | 143 | 41 | 102 | 0 | 0 | 28.7% |
| variable | 94 | 63 | 31 | 0 | 0 | 67.0% |
| **total** | 3126 | 1690 | 1436 | 0 | 52 | 54.1% |

Comment files (all areas): 251/578 (43.4%)

Formatting Beaver's own code with the preset exposed layouts that were worse than dart_style's; fixing them (conditionals after `=`/`=>`, calls after `=>`, adjacent strings, interpolations, `||` patterns, `when` guards, collection `for`/`if` bodies, hugged middle and record arguments, constructor initializers, blank lines in split lists) raised the match from 48.6% to the figure above.

### Previous (2026-10-28, after mixed lists stopped treating a trailing comma as a chop request)

| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |
|---|---:|---:|---:|---:|---:|---:|
| declaration | 466 | 231 | 235 | 0 | 2 | 49.6% |
| expression | 628 | 318 | 310 | 0 | 0 | 50.6% |
| function | 76 | 56 | 20 | 0 | 1 | 73.7% |
| invocation | 394 | 215 | 179 | 0 | 0 | 54.6% |
| other | 54 | 29 | 25 | 0 | 45 | 53.7% |
| pattern | 159 | 64 | 95 | 0 | 0 | 40.3% |
| preserve_trailing_commas | 85 | 53 | 32 | 0 | 0 | 62.4% |
| regression | 622 | 210 | 412 | 0 | 4 | 33.8% |
| statement | 305 | 166 | 139 | 0 | 0 | 54.4% |
| top_level | 100 | 73 | 27 | 0 | 0 | 73.0% |
| type | 143 | 41 | 102 | 0 | 0 | 28.7% |
| variable | 94 | 62 | 32 | 0 | 0 | 66.0% |
| **total** | 3126 | 1518 | 1608 | 0 | 52 | 48.6% |

Comment files (all areas): 227/578 (39.3%)

The 49 cases lost against the previous table are all lists whose source keeps a developer break between items (or a line comment inside an element) where dart_style chops fully; Beaver now keeps those breaks (`wrap.keep_existing_line_breaks`) instead of chopping. No case went from mismatch to safety failure.

### Previous (2026-10-28, all rules implemented; identical at analyzer 14.0.0 and 14.6.0)

| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |
|---|---:|---:|---:|---:|---:|---:|
| declaration | 466 | 232 | 234 | 0 | 2 | 49.8% |
| expression | 628 | 326 | 302 | 0 | 0 | 51.9% |
| function | 76 | 56 | 20 | 0 | 1 | 73.7% |
| invocation | 394 | 218 | 176 | 0 | 0 | 55.3% |
| other | 54 | 29 | 25 | 0 | 45 | 53.7% |
| pattern | 159 | 69 | 90 | 0 | 0 | 43.4% |
| preserve_trailing_commas | 85 | 53 | 32 | 0 | 0 | 62.4% |
| regression | 622 | 242 | 380 | 0 | 4 | 38.9% |
| statement | 305 | 166 | 139 | 0 | 0 | 54.4% |
| top_level | 100 | 73 | 27 | 0 | 0 | 73.0% |
| type | 143 | 41 | 102 | 0 | 0 | 28.7% |
| variable | 94 | 62 | 32 | 0 | 0 | 66.0% |
| **total** | 3126 | 1567 | 1559 | 0 | 52 | 50.1% |

Comment files (all areas): 229/578 (39.6%)

### First baseline (2026-10-28, before the configurable rules of groups 8–9)

| Area | Eligible | Match | Mismatch | Safety failures | Skipped | Match % |
|---|---:|---:|---:|---:|---:|---:|
| declaration | 466 | 232 | 234 | 0 | 2 | 49.8% |
| expression | 628 | 325 | 303 | 0 | 0 | 51.8% |
| function | 76 | 56 | 20 | 0 | 1 | 73.7% |
| invocation | 394 | 209 | 185 | 0 | 0 | 53.0% |
| other | 54 | 30 | 24 | 0 | 45 | 55.6% |
| pattern | 159 | 69 | 90 | 0 | 0 | 43.4% |
| preserve_trailing_commas | 85 | 53 | 32 | 0 | 0 | 62.4% |
| regression | 622 | 240 | 382 | 0 | 4 | 38.6% |
| statement | 305 | 166 | 139 | 0 | 0 | 54.4% |
| top_level | 100 | 73 | 27 | 0 | 0 | 73.0% |
| type | 143 | 41 | 102 | 0 | 0 | 28.7% |
| variable | 94 | 62 | 32 | 0 | 0 | 66.0% |
| **total** | 3126 | 1556 | 1570 | 0 | 52 | 49.8% |

Comment files (all areas): 229/578 (39.6%)

Known structural reasons for the gap, by design: the preset's `chop_on_trailing_comma: true` (dart_style's default is `automate`) and `blank_lines.between_members: 1` (exact around members with a block body, dart_style preserves); kept developer breaks in comma lists stay as typed (a trailing comma in a mixed list is not a chop request) where dart_style chops fully; assert and type-argument trailing commas are kept as in the source because they are not in the optional-comma allowlist of structural verification.
