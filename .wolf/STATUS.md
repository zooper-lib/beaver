---
description: session handoff, regenerate with /handoff when a quest finishes
budget_tokens: 1000
---
# STATUS — beaver

> Read this FIRST when resuming. Last updated: 2026-10-28

## ✅ Done

- OpenSpec `initial-implementation`: 65/80 tasks ticked (groups 1–12, 15.2–15.4, 17.1, 17.2). Nothing committed yet.
- Engine + CLI in `packages/zooper_beaver/` (IR/printer, emit+splicing, parse, D6 comments, rules + generic fallback, D17 verify, config with injected IO, D8 directives, D15 ranges, `lib/src/cli/`). 426 tests, identical at analyzer 14.0.0/14.6.0; dart_style tall corpus 54.1%, 0 safety failures; real-code corpus 1,829 files × 4 configs clean (`tool/corpus.dart`).
- Editors: `editors/vscode` (14 node tests pass, VSIX packaging works), `editors/intellij` (18 tests pass against local Android Studio 2025.2 via `-PlocalPlatformPath`).
- CI/release: `.github/workflows/ci.yml` (dart both bounds, vscode+xvfb, intellij IDE matrix, editor configs), `release.yml` (5 binaries, checksums+manifest via `tool/release/manifest.sh`, signing gated on secrets, VSIX, plugin, pub publish). Never run on GitHub.
- Docs: `docs/{cli,stdin-protocol,directives,install,versioning,performance,safety-corpus}.md`, `docs/rules/*`, `docs/editors/*`.

## 🚀 Next quest

Get the 15 open tasks verified; all need things outside this machine:
- Push the branch and run CI (vscode integration under xvfb, IntelliJ on IDEA 2024.3.6/2025.3 with Dart incl. folder reformat + Reformat on Save, Helix/Neovim configs) → 14.x, 15.1/15.5/15.6, 16.x.
- `release.yml` via workflow_dispatch dry_run → 13.1, 14.4. Signing secrets → 13.2. pub.dev automated publishing setup + a real publish (ask first) → 13.3, 13.4.
- 17.3: CLI round trip measured (16 ms / 58 ms); in-editor latency still open.

## Design issues: resolved 2026-10-28

- D9 mixed-construct exception (option B): a source trailing comma is not a chop request when the list is already split with adjacent items sharing a line; only list-level gaps count. `lib/src/rules/lists.dart` `delimited`. Corpus 50.1% → 48.6% (kept breaks now stay, as D7 says).
- `remove` + `chop_on_trailing_comma: true` + `keep_existing_line_breaks: false` → exit 78 (`resolve.dart`).
- Preset values per D3 kept; §5 marked as an example. `Align.toColumn`, field blank-line exception, conservative comma contexts: accepted and written into DRAFT/design/specs.

## Dogfooding (2026-10-28)

- The repo's Dart code is formatted by Beaver (dart preset); CI `test` job runs `dart run bin/beaver.dart --check .`. `dart format` now disagrees on ~16 places (switch-expression arms, `=> '''`): don't run it on the repo.
- Layout fixes from self-formatting are pinned in `test/golden/regressions/self_format.unit`; `ConditionalGroup` (Prettier's conditionalGroup, with `firstLineOnly`) was added to the IR for `=>` bodies and hugged arguments.
- Open question for the user: keep a blank line between a standalone comment and the following declaration? The comment-attachment spec currently forbids it ("none after").

## Context

- Branch `feature/initial-implementation`. JDK: use Android Studio's JBR (`JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home`).
