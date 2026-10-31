---
description: session handoff, regenerate with /handoff when a quest finishes
budget_tokens: 1000
---
# STATUS — beaver

> Read this FIRST when resuming. Last updated: 2026-10-30

## ✅ Done

- OpenSpec `initial-implementation`: 70/80 tasks ticked; CI green on GitHub (2026-10-28), which verified 14.1, 14.2, 14.5, 15.1, 15.6. Committed on feature/initial-implementation, not pushed by Claude.
- Engine + CLI in `packages/zooper_beaver/` (IR/printer, emit+splicing, parse, D6 comments, rules + generic fallback, D17 verify, config with injected IO, D8 directives, D15 ranges, `lib/src/cli/`). 426 tests, identical at analyzer 14.0.0/14.6.0; dart_style tall corpus 54.1%, 0 safety failures; real-code corpus 1,829 files × 4 configs clean (`tool/corpus.dart`).
- Editors: `editors/vscode` (14 node tests pass, VSIX packaging works), `editors/intellij` (18 tests pass against local Android Studio 2025.2 via `-PlocalPlatformPath`).
- CI/release: `.github/workflows/ci.yml` (dart both bounds, vscode+xvfb, intellij IDE matrix, editor configs), `release.yml` (5 binaries, checksums+manifest via `tool/release/manifest.sh`, signing gated on secrets, VSIX, plugin, pub publish). Never run on GitHub.
- Docs: `docs/{cli,stdin-protocol,directives,install,versioning,performance,safety-corpus}.md`, `docs/rules/*`, `docs/editors/*`.

## add-new-settings (2026-10-30, branch feature/new-settings)

- OpenSpec `add-new-settings`: 45/45 tasks ticked, not committed (user chose no commits). 915 tests pass, `--check .` clean, `openspec validate --strict` passes; corpus 1692/3126 (54.1%), see `test/golden/dart_style/UPSTREAM.md`.
- Config: `schema.dart` builds list keys from `listConstructs`; `BeaverConfig.settings` (raw, may hold `inherit`) vs `.values` (resolved); `ListSettings` per list; `loader.dart` `normalizeAndValidateValues` holds the alias table; `resolve.dart` `Source` provenance + EditorConfig merge; `editorconfig.dart`, `template.dart` (`docs/beaver.template.yaml`, kept in sync by `docs_test`).
- Preset deviations from the proposal: `wrap.initializer_lists` and `wrap.class_header` have `keep_existing_line_breaks: false` (inherit would change 0.1.0 output). Spec scenario "Different caps" can't hold for block-bodied methods (`between_members` is exact); golden uses fields.
- Next: review diff, commit, archive `initial-implementation`, then `/opsx:archive add-new-settings`.

## 🚀 Previous quest

Release prep for 0.1.0 done (DRAFT.md deleted; decisions live in git history and openspec/). VS Code Marketplace trusted publishing set up by the user (variable VSCODE_MARKETPLACE). JetBrains: step in release.yml gated on vars.JETBRAINS_MARKETPLACE + secrets.JETBRAINS_TOKEN; first upload is manual. No Open VSX. Next: push, tag v0.1.0, manual pub.dev publish + enable automated publishing, manual JetBrains upload; then verify 13.3/13.4 and /opsx:archive.

## Design issues: resolved 2026-10-28

- D9 mixed-construct exception (option B): a source trailing comma is not a chop request when the list is already split with adjacent items sharing a line; only list-level gaps count. `lib/src/rules/lists.dart` `delimited`. Corpus 50.1% → 48.6% (kept breaks now stay, as D7 says).
- `remove` + `chop_on_trailing_comma: true` + `keep_existing_line_breaks: false` → exit 78 (`resolve.dart`).

## Dogfooding (2026-10-28)

- The repo's Dart code is formatted by Beaver (dart preset); CI `test` job runs `dart run bin/beaver.dart --check .`. `dart format` now disagrees on ~16 places (switch-expression arms, `=> '''`): don't run it on the repo.
- Layout fixes from self-formatting are pinned in `test/golden/regressions/self_format.unit`; `ConditionalGroup` (Prettier's conditionalGroup, with `firstLineOnly`) was added to the IR for `=>` bodies and hugged arguments.
- Open question for the user: keep a blank line between a standalone comment and the following declaration? The comment-attachment spec currently forbids it ("none after").

## Context

- Branch `feature/initial-implementation`. JDK: use Android Studio's JBR (`JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home`).
