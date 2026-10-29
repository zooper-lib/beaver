# anatomy.md

> Auto-maintained by OpenWolf. Last scanned: 2026-10-29T04:42:31.326Z
> Files: 898 tracked | Anatomy hits: 0 | Misses: 0

> Project structure index. Auto-maintained by OpenWolf hooks and daemon.
> Run `openwolf scan` to generate, or wait for the first Claude Code session.
> Status: Pending initial scan

## ./

- `AGENTS.md` — OpenWolf (~75 tok)
- `CLAUDE.md` — OpenWolf (~99 tok)
- `DRAFT.md` — Beaver — a configurable Dart formatter (~11634 tok)
- `LICENSE` — Project license (~284 tok)
- `README.md` — Project documentation (~2387 tok)

## .github/workflows/

- `ci.yml` — CI: CI (~2110 tok)
- `release.yml` — CI: Release (~2842 tok)

## docs/

- `cli.md` — Command line (~960 tok)
- `directives.md` — Ignore directives (~606 tok)
- `install.md` — Installing Beaver (~694 tok)
- `performance.md` — Performance (~936 tok)
- `safety-corpus.md` — Safety corpus (~390 tok)
- `stdin-protocol.md` — The stdin protocol (~805 tok)
- `versioning.md` — Versions (~337 tok)

## docs/editors/

- `emacs.md` — Emacs (~160 tok)
- `helix.md` — Helix (~166 tok)
- `intellij.md` — IntelliJ IDEA and Android Studio (~485 tok)
- `neovim.md` — Neovim (~277 tok)
- `sublime.md` — Sublime Text (~122 tok)
- `vscode.md` — VS Code (~502 tok)
- `zed.md` — Zed (~146 tok)

## docs/rules/

- `blank_lines.md` — Blank line rules (~467 tok)
- `braces.md` — Brace rules (~209 tok)
- `indent.md` — Indentation rules (~740 tok)
- `spaces.md` — Space rules (~544 tok)
- `strings.md` — String rules (~206 tok)
- `wrap.md` — Wrapping rules (~2306 tok)

## editors/intellij/

- `.gitignore` — Git ignore rules (~10 tok)
- `build.gradle.kts` — Gradle Kotlin build configuration (~887 tok)
- `gradle.properties` — Plugin version: independent of the formatter version. (~173 tok)
- `gradlew` — you may not use this file except in compliance with the License. (~2292 tok)
- `gradlew.bat` (~773 tok)
- `settings.gradle.kts` — Gradle Kotlin settings (~10 tok)

## editors/intellij/.kotlin/sessions/

- `kotlin-compiler-11211552953999540599.salive` (~0 tok)
- `kotlin-compiler-11388244402809998786.salive` (~0 tok)
- `kotlin-compiler-11504656380341749643.salive` (~0 tok)
- `kotlin-compiler-11738155765955484829.salive` (~0 tok)
- `kotlin-compiler-12648863017526282639.salive` (~0 tok)
- `kotlin-compiler-13070930914694973815.salive` (~0 tok)
- `kotlin-compiler-13757639581876646826.salive` (~0 tok)
- `kotlin-compiler-14887668586889148413.salive` (~0 tok)
- `kotlin-compiler-14937229076618430528.salive` (~0 tok)
- `kotlin-compiler-1506138980457316143.salive` (~0 tok)
- `kotlin-compiler-15864434303860708750.salive` (~0 tok)
- `kotlin-compiler-16230758394065571957.salive` (~0 tok)
- `kotlin-compiler-17814252035007599574.salive` (~0 tok)
- `kotlin-compiler-17852573604591435785.salive` (~0 tok)
- `kotlin-compiler-2278174799909718003.salive` (~0 tok)
- `kotlin-compiler-2459887284804740381.salive` (~0 tok)
- `kotlin-compiler-2706210512951659281.salive` (~0 tok)
- `kotlin-compiler-3270766577368986299.salive` (~0 tok)
- `kotlin-compiler-5443610545001082372.salive` (~0 tok)
- `kotlin-compiler-5536396340374344436.salive` (~0 tok)
- `kotlin-compiler-5562755372379455990.salive` (~0 tok)
- `kotlin-compiler-6466367981397079794.salive` (~0 tok)
- `kotlin-compiler-7041476127320362317.salive` (~0 tok)
- `kotlin-compiler-7420942266414474463.salive` (~0 tok)
- `kotlin-compiler-7485511644421521163.salive` (~0 tok)
- `kotlin-compiler-9236992095175424569.salive` (~0 tok)
- `kotlin-compiler-9300387452934361179.salive` (~0 tok)

## editors/intellij/gradle/wrapper/

- `gradle-wrapper.jar` (~11592 tok)
- `gradle-wrapper.properties` (~68 tok)

## editors/intellij/src/main/kotlin/dev/zooper/beaver/

- `BeaverBinaries.kt` — The plugin's declared versions and embedded manifest. (~524 tok)
- `BeaverFormattingService.kt` — Formats Dart files through `beaver --stdin`. Runs off the UI thread, (~927 tok)
- `BeaverSettings.kt` — Application-level setting: an explicit beaver executable. (~386 tok)
- `BinaryResolver.kt` — Where the binary came from, for the information action. (~1503 tok)
- `Manifest.kt` — The release's platform → file → SHA-256 table, embedded at build time. (~426 tok)
- `Protocol.kt` — The plugin side of the stdin protocol (docs/stdin-protocol.md); IDE-independent. (~354 tok)
- `ShowInformationAction.kt` — "Beaver: Show Formatter Information": versions, binary source and path, (~749 tok)

## editors/intellij/src/main/resources/META-INF/

- `plugin.xml` (~308 tok)

## editors/intellij/src/test/kotlin/dev/zooper/beaver/

- `BeaverFormattingServiceTest.kt` — Runs the platform's reformat entry points against a real beaver (~856 tok)
- `BinaryResolverTest.kt` — BinaryResolverTest: manifest, resolver, read (~1623 tok)
- `DartWorkflowsTest.kt` — Folder reformat and Reformat on Save. The platform skips files of a type (~1330 tok)
- `ZzDiagTest.kt` — ZzDiagTest: createTempDirTestFixture (~249 tok)

## editors/vscode/

- `.gitignore` — Git ignore rules (~9 tok)
- `.vscodeignore` — test/** (~19 tok)
- `LICENSE` — Project license (~284 tok)
- `package.json` — Node.js package manifest (~448 tok)
- `README.md` — Project documentation (~170 tok)
- `tsconfig.json` — TypeScript configuration (~83 tok)

## editors/vscode/src/

- `binary.ts` — The executable named [name] on PATH, or null. (~572 tok)
- `extension.ts` — Beaver for VS Code: document and range formatting through `beaver --stdin` (~1611 tok)
- `protocol.ts` — Protocol version this extension speaks; must equal `beaver --version`'s. (~649 tok)
- `run.ts` — Runs [binary] with [args], writing [input] to stdin. [onCancel] receives a (~340 tok)

## editors/vscode/test/

- `protocol.test.ts` — Integration with the real CLI uses BEAVER_BINARY (a built `beaver`). (~1515 tok)

## editors/vscode/test/integration/

- `run.ts` — Launches VS Code with the extension and a scratch workspace, and runs the (~368 tok)
- `suite.ts` — Runs inside VS Code (see run.ts). (~2156 tok)

## example/

- `.beaver.yaml` — Inputs stay as written; every <key>/<value>/ folder has its own config. (~30 tok)
- `analysis_options.yaml` — Formatter input and output, not a program: the names in these files are (~48 tok)
- `README.md` — Project documentation (~3548 tok)

## example/blank_lines.after_imports/

- `before.dart` (~10 tok)

## example/blank_lines.after_imports/1/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~10 tok)

## example/blank_lines.after_imports/2/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~10 tok)

## example/blank_lines.around_class_declarations/

- `before.dart` — Declares A (~7 tok)

## example/blank_lines.around_class_declarations/1/

- `.beaver.yaml` (~13 tok)
- `after.dart` — Declares A (~7 tok)

## example/blank_lines.around_class_declarations/2/

- `.beaver.yaml` (~13 tok)
- `after.dart` — Declares A (~7 tok)

## example/blank_lines.before_first_member/

- `before.dart` — Declares Point (~9 tok)

## example/blank_lines.before_first_member/0/

- `.beaver.yaml` (~11 tok)
- `after.dart` — Declares Point (~9 tok)

## example/blank_lines.before_first_member/1/

- `.beaver.yaml` (~11 tok)
- `after.dart` — Declares Point (~9 tok)

## example/blank_lines.between_members/

- `before.dart` — Point: moveRight, moveDown (~38 tok)

## example/blank_lines.between_members/1/

- `.beaver.yaml` (~10 tok)
- `after.dart` — Point: moveRight, moveDown (~39 tok)

## example/blank_lines.between_members/2/

- `.beaver.yaml` (~10 tok)
- `after.dart` — Point: moveRight, moveDown (~40 tok)

## example/blank_lines.max_consecutive/

- `before.dart` (~13 tok)

## example/blank_lines.max_consecutive/0/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~12 tok)

## example/blank_lines.max_consecutive/1/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~12 tok)

## example/blank_lines.max_consecutive/2/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~13 tok)

## example/braces.else_on_new_line/

- `before.dart` (~45 tok)

## example/braces.else_on_new_line/false/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~45 tok)

## example/braces.else_on_new_line/true/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~47 tok)

## example/exclude/

- `.beaver.yaml` — Added to the dart preset's exclusions (which already skip **/*.g.dart). (~29 tok)

## example/exclude/legacy/

- `old.dart` — pattern, so it keeps its layout. (~28 tok)

## example/exclude/lib/

- `model.dart` — Declares Model (~17 tok)
- `model.g.dart` (~42 tok)

## example/indent.align.arguments/

- `before.dart` (~31 tok)

## example/indent.align.arguments/false/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~37 tok)

## example/indent.align.arguments/true/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~60 tok)

## example/indent.align.chained_calls/

- `before.dart` (~34 tok)

## example/indent.align.chained_calls/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~40 tok)

## example/indent.align.chained_calls/true/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~47 tok)

## example/indent.align.parameters/

- `before.dart` (~27 tok)

## example/indent.align.parameters/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~30 tok)

## example/indent.align.parameters/true/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~48 tok)

## example/indent.continuation/

- `before.dart` (~33 tok)

## example/indent.continuation/2/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~38 tok)

## example/indent.continuation/4/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~40 tok)

## example/indent.continuation/8/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~44 tok)

## example/indent.size/

- `before.dart` — Counter: increment (~30 tok)

## example/indent.size/2/

- `.beaver.yaml` (~6 tok)
- `after.dart` — Counter: increment (~30 tok)

## example/indent.size/4/

- `.beaver.yaml` (~6 tok)
- `after.dart` — Counter: increment (~36 tok)

## example/indent.style/

- `before.dart` — Counter: increment (~30 tok)

## example/indent.style/spaces/

- `.beaver.yaml` (~7 tok)
- `after.dart` — Counter: increment (~30 tok)

## example/indent.style/tabs/

- `.beaver.yaml` (~7 tok)
- `after.dart` — Counter: increment (~27 tok)

## example/indent.switch_cases/

- `before.dart` (~39 tok)

## example/indent.switch_cases/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~36 tok)

## example/indent.switch_cases/true/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~39 tok)

## example/line_length/

- `before.dart` (~51 tok)

## example/line_length/120/

- `.beaver.yaml` (~5 tok)
- `after.dart` (~51 tok)

## example/line_length/40/

- `.beaver.yaml` (~5 tok)
- `after.dart` (~62 tok)

## example/line_length/80/

- `.beaver.yaml` (~5 tok)
- `after.dart` (~57 tok)

## example/spaces.after_cast/

- `before.dart` (~24 tok)

## example/spaces.after_cast/false/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~24 tok)

## example/spaces.after_cast/true/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~24 tok)

## example/spaces.after_colon_in_named_argument/

- `before.dart` (~14 tok)

## example/spaces.after_colon_in_named_argument/false/

- `.beaver.yaml` (~14 tok)
- `after.dart` (~14 tok)

## example/spaces.after_colon_in_named_argument/true/

- `.beaver.yaml` (~14 tok)
- `after.dart` (~14 tok)

## example/spaces.after_comma/

- `before.dart` (~17 tok)

## example/spaces.after_comma/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~16 tok)

## example/spaces.after_comma/true/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~17 tok)

## example/spaces.around_arrow/

- `before.dart` (~8 tok)

## example/spaces.around_arrow/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~8 tok)

## example/spaces.around_arrow/true/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~8 tok)

## example/spaces.around_assignment/

- `before.dart` (~15 tok)

## example/spaces.around_assignment/false/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~14 tok)

## example/spaces.around_assignment/true/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~15 tok)

## example/spaces.around_binary_operators/

- `before.dart` (~17 tok)

## example/spaces.around_binary_operators/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~16 tok)

## example/spaces.around_binary_operators/true/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~17 tok)

## example/spaces.before_comma/

- `before.dart` (~17 tok)

## example/spaces.before_comma/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~17 tok)

## example/spaces.before_comma/true/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~18 tok)

## example/spaces.before_control_parentheses/

- `before.dart` (~30 tok)

## example/spaces.before_control_parentheses/false/

- `.beaver.yaml` (~13 tok)
- `after.dart` (~30 tok)

## example/spaces.before_control_parentheses/true/

- `.beaver.yaml` (~13 tok)
- `after.dart` (~30 tok)

## example/spaces.in_empty_braces/

- `before.dart` — Marker: noop (~10 tok)

## example/spaces.in_empty_braces/false/

- `.beaver.yaml` (~10 tok)
- `after.dart` — Marker: noop (~10 tok)

## example/spaces.in_empty_braces/true/

- `.beaver.yaml` (~10 tok)
- `after.dart` — Marker: noop (~10 tok)

## example/spaces.inside_braces/

- `before.dart` (~20 tok)

## example/spaces.inside_braces/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~20 tok)

## example/spaces.inside_braces/true/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~21 tok)

## example/spaces.inside_brackets/

- `before.dart` (~19 tok)

## example/spaces.inside_brackets/false/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~19 tok)

## example/spaces.inside_brackets/true/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~20 tok)

## example/spaces.inside_parentheses/

- `before.dart` (~16 tok)

## example/spaces.inside_parentheses/false/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~16 tok)

## example/spaces.inside_parentheses/true/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~17 tok)

## example/strings.quotes/

- `before.dart` (~22 tok)

## example/strings.quotes/double/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~22 tok)

## example/strings.quotes/preserve/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~22 tok)

## example/strings.quotes/single/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~22 tok)

## example/trailing_commas/

- `before.dart` (~42 tok)

## example/trailing_commas/add_when_wrapped/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~52 tok)

## example/trailing_commas/preserve/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~51 tok)

## example/trailing_commas/remove/

- `.beaver.yaml` (~7 tok)
- `after.dart` (~51 tok)

## example/wrap.arguments/

- `before.dart` (~38 tok)

## example/wrap.arguments/chop_always/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~47 tok)

## example/wrap.arguments/chop_if_long/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~44 tok)

## example/wrap.arguments/if_long/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~40 tok)

## example/wrap.arguments/never/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~38 tok)

## example/wrap.before_operator/

- `before.dart` (~36 tok)

## example/wrap.before_operator/false/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~44 tok)

## example/wrap.before_operator/true/

- `.beaver.yaml` (~9 tok)
- `after.dart` (~44 tok)

## example/wrap.binary_expressions/

- `before.dart` (~41 tok)

## example/wrap.binary_expressions/chop_always/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~53 tok)

## example/wrap.binary_expressions/chop_if_long/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~50 tok)

## example/wrap.binary_expressions/if_long/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~44 tok)

## example/wrap.binary_expressions/never/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~43 tok)

## example/wrap.chained_calls.keep_single_line_if_fits/

- `before.dart` (~18 tok)

## example/wrap.chained_calls.keep_single_line_if_fits/false/

- `.beaver.yaml` (~24 tok)
- `after.dart` (~22 tok)

## example/wrap.chained_calls.keep_single_line_if_fits/true/

- `.beaver.yaml` (~24 tok)
- `after.dart` (~18 tok)

## example/wrap.chained_calls.min_calls/

- `before.dart` (~36 tok)

## example/wrap.chained_calls.min_calls/0/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~36 tok)

## example/wrap.chained_calls.min_calls/3/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~42 tok)

## example/wrap.chained_calls.policy/

- `before.dart` (~46 tok)

## example/wrap.chained_calls.policy/chop_always/

- `.beaver.yaml` (~24 tok)
- `after.dart` (~56 tok)

## example/wrap.chained_calls.policy/chop_if_long/

- `.beaver.yaml` (~24 tok)
- `after.dart` (~52 tok)

## example/wrap.chained_calls.policy/if_long/

- `.beaver.yaml` (~23 tok)
- `after.dart` (~48 tok)

## example/wrap.chained_calls.policy/never/

- `.beaver.yaml` (~22 tok)
- `after.dart` (~48 tok)

## example/wrap.chop_on_named_arguments/

- `before.dart` (~33 tok)

## example/wrap.chop_on_named_arguments/child_children/

- `.beaver.yaml` (~15 tok)
- `after.dart` (~40 tok)

## example/wrap.chop_on_named_arguments/empty/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~37 tok)

## example/wrap.chop_on_trailing_comma/

- `before.dart` (~19 tok)

## example/wrap.chop_on_trailing_comma/false/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~18 tok)

## example/wrap.chop_on_trailing_comma/true/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~26 tok)

## example/wrap.collection_literals/

- `before.dart` (~39 tok)

## example/wrap.collection_literals/chop_always/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~54 tok)

## example/wrap.collection_literals/chop_if_long/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~49 tok)

## example/wrap.collection_literals/if_long/

- `.beaver.yaml` (~11 tok)
- `after.dart` (~41 tok)

## example/wrap.collection_literals/never/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~39 tok)

## example/wrap.conditional_expressions/

- `before.dart` (~41 tok)

## example/wrap.conditional_expressions/chop_always/

- `.beaver.yaml` (~13 tok)
- `after.dart` (~48 tok)

## example/wrap.conditional_expressions/chop_if_long/

- `.beaver.yaml` (~14 tok)
- `after.dart` (~45 tok)

## example/wrap.conditional_expressions/if_long/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~43 tok)

## example/wrap.conditional_expressions/never/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~43 tok)

## example/wrap.keep_existing_line_breaks/

- `before.dart` (~24 tok)

## example/wrap.keep_existing_line_breaks/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~21 tok)

## example/wrap.keep_existing_line_breaks/true/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~28 tok)

## example/wrap.parameters/

- `before.dart` (~35 tok)

## example/wrap.parameters/chop_always/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~40 tok)

## example/wrap.parameters/chop_if_long/

- `.beaver.yaml` (~10 tok)
- `after.dart` (~38 tok)

## example/wrap.parameters/if_long/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~36 tok)

## example/wrap.parameters/never/

- `.beaver.yaml` (~8 tok)
- `after.dart` (~35 tok)

## example/wrap.simple_blocks_on_one_line/

- `before.dart` (~33 tok)

## example/wrap.simple_blocks_on_one_line/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~36 tok)

## example/wrap.simple_blocks_on_one_line/true/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~33 tok)

## example/wrap.simple_lambdas_on_one_line/

- `before.dart` (~18 tok)

## example/wrap.simple_lambdas_on_one_line/false/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~20 tok)

## example/wrap.simple_lambdas_on_one_line/true/

- `.beaver.yaml` (~12 tok)
- `after.dart` (~18 tok)

## openspec/

- `config.yaml` (~286 tok)

## openspec/changes/archive/

- `.gitkeep` (~0 tok)

## openspec/changes/initial-implementation/

- `.openspec.yaml` (~12 tok)
- `design.md` — Design (~3807 tok)
- `proposal.md` — Proposal (~1879 tok)
- `tasks.md` — Tasks (~5612 tok)

## openspec/changes/initial-implementation/specs/cli/

- `spec.md` — Spec Delta (~1514 tok)

## openspec/changes/initial-implementation/specs/comment-attachment/

- `spec.md` — Spec Delta (~1001 tok)

## openspec/changes/initial-implementation/specs/config-resolution/

- `spec.md` — Spec Delta (~2069 tok)

## openspec/changes/initial-implementation/specs/formatting-rules/

- `spec.md` — Spec Delta (~4232 tok)

## openspec/changes/initial-implementation/specs/golden-test-harness/

- `spec.md` — Spec Delta (~1307 tok)

## openspec/changes/initial-implementation/specs/ignore-directives/

- `spec.md` — Spec Delta (~1071 tok)

## openspec/changes/initial-implementation/specs/intellij-plugin/

- `spec.md` — Spec Delta (~1315 tok)

## openspec/changes/initial-implementation/specs/layout-printer/

- `spec.md` — Spec Delta (~1387 tok)

## openspec/changes/initial-implementation/specs/release-distribution/

- `spec.md` — Spec Delta (~940 tok)

## openspec/changes/initial-implementation/specs/stdin-protocol/

- `spec.md` — Spec Delta (~1268 tok)

## openspec/changes/initial-implementation/specs/structural-verification/

- `spec.md` — Spec Delta (~1222 tok)

## openspec/changes/initial-implementation/specs/vscode-extension/

- `spec.md` — Spec Delta (~1184 tok)

## openspec/specs/

- `.gitkeep` (~0 tok)

## packages/zooper_beaver/

- `.gitignore` — Git ignore rules (~7 tok)
- `analysis_options.yaml` (~21 tok)
- `CHANGELOG.md` — Change log (~226 tok)
- `dart_test.yaml` — The CLI tests change the working directory, which is process-wide. (~24 tok)
- `LICENSE` — Project license (~284 tok)
- `pubspec.yaml` — Dart/Flutter package manifest (~119 tok)
- `README.md` — Project documentation (~951 tok)
- `tool_attach.dart` (~174 tok)
- `tool_bisect.dart` — Dev tool: finds the smallest class member / top-level declaration of a file that fails under a config. (~475 tok)
- `tool_cat.dart` (~198 tok)
- `tool_cfgtry.dart` (~160 tok)
- `tool_corpus.dart` — Dev tool: lists corpus cases by outcome. `dart run tool_corpus.dart safety|mismatch [filter]` (~261 tok)
- `tool_diff.dart` (~252 tok)
- `tool_gen.dart` — Dev tool: prints golden cases: for each (options, input) runs the engine at the given width. (~378 tok)
- `tool_generic.dart` (~112 tok)
- `tool_idem.dart` (~212 tok)
- `tool_raw.dart` (~100 tok)
- `tool_real.dart` — Dev tool: format every .dart file under the given directories, report failures and idempotence. (~314 tok)
- `tool_try.dart` (~44 tok)
- `tool_yaml.dart` (~64 tok)

## packages/zooper_beaver/bin/

- `beaver.dart` (~66 tok)

## packages/zooper_beaver/example/

- `zooper_beaver_example.dart` — Formatting from Dart code. Most projects use the `beaver` command instead: (~151 tok)

## packages/zooper_beaver/lib/

- `beaver.dart` — / Beaver: a configurable, line-width-aware Dart formatter. (~49 tok)
- `zooper_beaver.dart` — / Beaver: a configurable, line-width-aware Dart formatter. (~84 tok)

## packages/zooper_beaver/lib/src/

- `format.dart` — / The formatting pipeline. The only place verification runs. (~1487 tok)
- `version.dart` — / The formatter version; must equal `version:` in pubspec.yaml. (~71 tok)

## packages/zooper_beaver/lib/src/cli/

- `cli.dart` — / The `beaver` command line: file selection, modes, the stdin (~4434 tok)
- `diff.dart` — / Minimal unified diff of two texts by line (Myers' algorithm), so the CLI (~922 tok)

## packages/zooper_beaver/lib/src/comments/

- `attach.dart` — / Comment attachment: every comment gets its enclosing, preceding and (~2693 tok)

## packages/zooper_beaver/lib/src/config/

- `config.dart` — / The resolved configuration the engine formats with. (~1435 tok)
- `dart_preset.dart` — / The built-in `dart` preset: dart_style 3.x conventions. Embedded as a (~419 tok)
- `loader.dart` — / Parses and validates one `.beaver.yaml`. (~768 tok)
- `resolve.dart` — / Configuration resolution: discovery, the `extends` chain, the (~1574 tok)
- `schema.dart` — / The `.beaver.yaml` schema: every key, its type and its allowed values. (~932 tok)

## packages/zooper_beaver/lib/src/directives/

- `directives.dart` — / Ignore directives: recognition, the region table and its validation. (~1074 tok)

## packages/zooper_beaver/lib/src/emit/

- `emit.dart` — / Turns printer commands into the output string. (~846 tok)

## packages/zooper_beaver/lib/src/ir/

- `doc.dart` — / The document tree that formatting rules build and the printer lays out. (~1875 tok)
- `printer.dart` — / Prettier's greedy printer: fits each group on the rest of the current line (~4336 tok)

## packages/zooper_beaver/lib/src/parse/

- `parse.dart` — / `package:analyzer` wrapper: parse at the latest language version and (~1014 tok)

## packages/zooper_beaver/lib/src/range/

- `range.dart` — / Range formatting: expand a selection along the ladder statement → (~1395 tok)

## packages/zooper_beaver/lib/src/rules/

- `builder.dart` — / AST → Doc. One builder per format call; the syntax areas live in (~4051 tok)
- `chains.dart` — / Method chains and cascades. (~2706 tok)
- `collections.dart` — / Collection literals and their elements. (~911 tok)
- `declarations.dart` — / Declarations: compilation unit, directives, classes and other type (~5354 tok)
- `expressions.dart` — / Expressions: operators, assignments, invocations and arguments, access, (~7907 tok)
- `lists.dart` — / The shared wrappable-construct helper: argument and parameter lists, (~3050 tok)
- `statements.dart` — / Statements: blocks, control flow, switch, try, jumps. (~3065 tok)
- `strings.dart` — / String literals and `strings.quotes` (value-preserving delimiter changes). (~1444 tok)

## packages/zooper_beaver/lib/src/verify/

- `verification_failure.dart` — / Formatted output is not the same program as the input (exit 70). (~107 tok)
- `verify.dart` — / Structural verification: the output must be the same program as the (~2294 tok)

## packages/zooper_beaver/test/

- `cli_test.dart` — _Capture: toString, main (~2758 tok)
- `comments_test.dart` — A: main, init, f (~846 tok)
- `config_resolve_test.dart` (~1964 tok)
- `config_schema_test.dart` (~350 tok)
- `dart_style_corpus_test.dart` — / Scores Beaver against dart_style's tall corpus. Mismatches are reported, (~383 tok)
- `directives_test.dart` — Declares source (~655 tok)
- `docs_test.dart` — / Every example in the rule and directive docs is a golden test case. (~254 tok)
- `example_test.dart` — / The rule showcase in `example/` is real formatter output: every (~493 tok)
- `format_test.dart` (~104 tok)
- `golden_file_test.dart` — Declares FormatException (~913 tok)
- `golden_runner_test.dart` — Declares VerificationFailure (~753 tok)
- `golden_test.dart` — / Beaver's strict golden suites: every case under `test/golden/<area>/` must (~245 tok)
- `ir_test.dart` — Declares Marker (~1997 tok)
- `parse_test.dart` (~400 tok)
- `range_test.dart` — / Formats [source] for the range `l1:c1-l2:c2`. (~912 tok)
- `verify_test.dart` — A: check, main, f, f (~1158 tok)
- `zz_dump_test.dart` (~125 tok)
- `zz_regold_test.dart` (~139 tok)
- `zz_regold.dart` (~139 tok)

## packages/zooper_beaver/test/golden/blank_lines/

- `blank_lines.unit` — Declares A (~334 tok)

## packages/zooper_beaver/test/golden/braces/

- `braces.stmt` (~156 tok)

## packages/zooper_beaver/test/golden/collections/

- `kinds.unit` (~414 tok)

## packages/zooper_beaver/test/golden/comments/

- `attachment.stmt` (~237 tok)
- `attachment.unit` — Declares A (~98 tok)

## packages/zooper_beaver/test/golden/dart_style/

- `LICENSE` — Project license (~402 tok)
- `UPSTREAM.md` — Upstream: dart_style tall-style test corpus (~1407 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/declaration/

- `class_clause.unit` — Declares A (~1900 tok)
- `class_comment.unit` — / class Bar {} (~482 tok)
- `class_type_parameter.unit` — Declares parameter (~307 tok)
- `class.unit` — Declares A (~375 tok)
- `constructor_assert.unit` — Declares Foo (~505 tok)
- `constructor_comment.unit` — Declares A (~754 tok)
- `constructor_factory.unit` — Declares C (~170 tok)
- `constructor_initializer.unit` — Declares Foo (~1317 tok)
- `constructor_new.unit` — Declares C (~360 tok)
- `constructor_parameter.unit` — Declares Foo (~1231 tok)
- `constructor_primary.unit` — Declares header (~2534 tok)
- `constructor.unit` — Declares A (~663 tok)
- `enum_clause.unit` — Declares E (~492 tok)
- `enum_comment.unit` — Declares A (~1024 tok)
- `enum_member_comment.unit` — Declares A (~1034 tok)
- `enum_member.unit` — E: f, g, f, g (~205 tok)
- `enum_metadata.unit` — Declares Primate (~142 tok)
- `enum.unit` — Declares Unity (~961 tok)
- `extension_comment.unit` (~102 tok)
- `extension_type_comment.unit` — Declares I (~607 tok)
- `extension_type.unit` — A: g, pr, g, pr (~933 tok)
- `extension.unit` — Declares parameters (~738 tok)
- `external.unit` — C: setter, setter, setter + 3 more (~591 tok)
- `field.unit` — Declares Foo (~444 tok)
- `member_comment.unit` — Declares Foo (~275 tok)
- `member_metadata.unit` — Declares X (~321 tok)
- `member.unit` — Foo: f, g, f + 5 more (~206 tok)
- `metadata_comment.unit` — Declares C (~345 tok)
- `metadata.unit` — Declares A (~292 tok)
- `method.unit` — declarations: instanceProperty, classProperty, instanceProperty, classProperty (~668 tok)
- `mixin_application_class.unit` — Declares SomeClass (~794 tok)
- `mixin_clause.unit` — Declares with (~1774 tok)
- `mixin_comment.unit` (~93 tok)
- `mixin.unit` — int: g, pr, g, pr (~531 tok)
- `native.unit` — Declares Foo (~112 tok)
- `this_block.unit` — Declares body (~554 tok)
- `typedef_comment.unit` (~138 tok)
- `typedef.unit` — Declares type (~1294 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/expression/

- `assignment_comment.stmt` (~70 tok)
- `assignment_pattern.stmt` (~824 tok)
- `assignment.stmt` — Declares calls (~787 tok)
- `binary_comment.stmt` (~577 tok)
- `binary.stmt` (~1149 tok)
- `collection_for_comment.stmt` (~506 tok)
- `collection_for_in.stmt` — Declares annotation (~205 tok)
- `collection_for_metadata.stmt` (~471 tok)
- `collection_for_spread_list.stmt` (~301 tok)
- `collection_for_spread_map.stmt` (~235 tok)
- `collection_for_spread_set.stmt` (~298 tok)
- `collection_for.stmt` — Declares with (~947 tok)
- `collection_if_case.stmt` (~246 tok)
- `collection_if_comment.stmt` (~490 tok)
- `collection_if_spread_list.stmt` (~1038 tok)
- `collection_if_spread_map.stmt` (~1071 tok)
- `collection_if_spread_set.stmt` (~1027 tok)
- `collection_if.stmt` (~1358 tok)
- `collection_null_aware_comment.stmt` (~256 tok)
- `collection_null_aware.stmt` (~334 tok)
- `collection_spread.stmt` — Declares expression (~317 tok)
- `condition_comment.stmt` (~415 tok)
- `condition.stmt` (~1469 tok)
- `function_reference.stmt` — Declares arguments (~320 tok)
- `interpolation.stmt` — Declares inside (~538 tok)
- `list_comment.stmt` (~624 tok)
- `list_nested.stmt` (~402 tok)
- `list_preserve_newlines.stmt` (~323 tok)
- `list.stmt` — Declares argument (~584 tok)
- `logical.stmt` (~294 tok)
- `map_comment.stmt` (~358 tok)
- `map_nested.stmt` (~295 tok)
- `map_preserve_newlines.stmt` (~258 tok)
- `map.stmt` — Declares arguments (~763 tok)
- `other.stmt` (~460 tok)
- `postfix.stmt` (~424 tok)
- `prefix.stmt` (~174 tok)
- `record_comment.stmt` (~586 tok)
- `record_nested.stmt` (~187 tok)
- `record_preserve_newlines.stmt` (~227 tok)
- `record.stmt` (~847 tok)
- `set_comment.stmt` (~162 tok)
- `set_nested.stmt` (~361 tok)
- `set_preserve_newlines.stmt` (~227 tok)
- `set.stmt` — Declares argument (~228 tok)
- `string_adjacent_comment.stmt` (~318 tok)
- `string_adjacent.stmt` — Declares expression (~1517 tok)
- `string_comment.stmt` (~252 tok)
- `string.stmt` (~283 tok)
- `switch_comment.stmt` (~483 tok)
- `switch_guard.stmt` (~1092 tok)
- `switch.stmt` (~927 tok)
- `type_test_comment.stmt` (~952 tok)
- `type_test.stmt` — Declares after (~796 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/function/

- `block_body.unit` (~119 tok)
- `comment.unit` — Declares if (~143 tok)
- `default_value.unit` — Declares typed (~581 tok)
- `expression_body.unit` — Declares declarations (~560 tok)
- `expression.stmt` — Declares expressions (~265 tok)
- `generic.unit` — Declares parameters (~384 tok)
- `getter.unit` (~47 tok)
- `local.stmt` — Declares declarations (~247 tok)
- `metadata.unit` — Declares A (~555 tok)
- `operator.unit` — Declares A (~116 tok)
- `other.unit` (~142 tok)
- `parameter.unit` — Declares typed (~337 tok)
- `setter.unit` (~46 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/invocation/

- `block_argument_comment.stmt` (~574 tok)
- `block_argument_description.stmt` — Declares expression (~607 tok)
- `block_argument_kind.stmt` — Declares expression (~2089 tok)
- `block_argument_multiple.stmt` — Declares expressions (~1048 tok)
- `block_argument_named.stmt` — Declares block (~276 tok)
- `block_argument_other.stmt` (~360 tok)
- `block_argument_string.stmt` (~517 tok)
- `cascade_comment.stmt` (~268 tok)
- `cascade_mixed.stmt` (~394 tok)
- `cascade.stmt` — Declares call (~1304 tok)
- `chain_block.stmt` — Declares argument (~1234 tok)
- `chain_comment.stmt` (~474 tok)
- `chain_postfix.stmt` — Declares arguments (~1063 tok)
- `chain_property.stmt` (~599 tok)
- `chain_single_element_target.stmt` (~1314 tok)
- `chain_target.stmt` — Declares call (~1023 tok)
- `chain.stmt` — Declares arguments (~955 tok)
- `comma_comment.stmt` (~894 tok)
- `comment.stmt` (~494 tok)
- `constructor.stmt` — Declares calls (~416 tok)
- `dot_shorthand_comment.stmt` (~153 tok)
- `dot_shorthand.stmt` (~458 tok)
- `function.stmt` — Declares arguments (~559 tok)
- `invocation_expression.stmt` — Declares call (~214 tok)
- `named_argument.stmt` — Declares with (~629 tok)
- `nested.stmt` — Declares Outer (~1700 tok)
- `null_aware.stmt` (~73 tok)
- `other.stmt` (~248 tok)
- `super.stmt` — Declares arguments (~446 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/other/

- `format_off_selection.unit` (~383 tok)
- `format_off.unit` (~1622 tok)
- `format_width.unit` (~603 tok)
- `overflow.stmt` (~1433 tok)
- `selection_comma.stmt` (~264 tok)
- `selection_comment.stmt` (~194 tok)
- `selection.stmt` (~317 tok)
- `selection.unit` — Declares Foo (~373 tok)
- `trailing_whitespace.unit` (~152 tok)
- `unicode.unit` (~674 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/pattern/

- `cast_comment.stmt` (~174 tok)
- `cast.stmt` — Declares annotation (~207 tok)
- `constant.stmt` — Declares record (~547 tok)
- `declared_variable_comment.stmt` (~240 tok)
- `declared_variable.stmt` — Declares and (~282 tok)
- `list_comment.stmt` (~171 tok)
- `list.stmt` — Declares argument (~789 tok)
- `logic_comment.stmt` (~242 tok)
- `logic.stmt` (~465 tok)
- `map_comment.stmt` (~174 tok)
- `map.stmt` (~654 tok)
- `object_comment.stmt` (~188 tok)
- `object.stmt` — Declares record (~1280 tok)
- `other_comment.stmt` — Declares constructor (~480 tok)
- `other.stmt` — Declares Foo (~639 tok)
- `record_comment.stmt` (~117 tok)
- `record.stmt` (~1086 tok)
- `relational_comment.stmt` (~105 tok)
- `relational.stmt` (~178 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/preserve_trailing_commas/

- `collection_for.stmt` (~130 tok)
- `constructor.unit` — Declares A (~480 tok)
- `enum.unit` — Declares E (~444 tok)
- `extension_type.unit` — Declares Foo (~172 tok)
- `for.stmt` (~116 tok)
- `function_call.stmt` (~128 tok)
- `list_literal.stmt` (~99 tok)
- `list_pattern.stmt` (~116 tok)
- `map_literal.stmt` (~116 tok)
- `map_pattern.stmt` (~119 tok)
- `member.unit` — Foo: setter, setter, setter, setter (~180 tok)
- `metadata.unit` — Declares A (~122 tok)
- `object_pattern.stmt` (~121 tok)
- `parameter.unit` — Declares expression (~295 tok)
- `record_literal.stmt` (~150 tok)
- `record_pattern.stmt` (~178 tok)
- `record_type.unit` (~246 tok)
- `set_literal.stmt` (~108 tok)
- `super_call.stmt` (~127 tok)
- `switch_expression.stmt` (~98 tok)
- `typedef.unit` (~124 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0000/

- `0000.stmt` (~832 tok)
- `0005.stmt` (~217 tok)
- `0006.stmt` (~166 tok)
- `0009.unit` (~66 tok)
- `0013.unit` — Declares A (~142 tok)
- `0014.unit` — Declares A (~74 tok)
- `0019.stmt` (~293 tok)
- `0021.stmt` (~371 tok)
- `0022.stmt` (~179 tok)
- `0023.stmt` (~193 tok)
- `0025.stmt` (~262 tok)
- `0026.stmt` (~107 tok)
- `0027.stmt` (~111 tok)
- `0028.unit` (~94 tok)
- `0029.stmt` — Declares _urlAttributes (~300 tok)
- `0031.stmt` (~1056 tok)
- `0033.stmt` (~122 tok)
- `0036.unit` — DO NOT EDIT. This is code generated via pkg/intl/generate_localized.dart (~168 tok)
- `0037.stmt` (~234 tok)
- `0038.stmt` — Declares hmac_sha1_inputs (~27678 tok)
- `0039.stmt` (~55 tok)
- `0040.stmt` (~253 tok)
- `0041.stmt` (~57 tok)
- `0042.unit` (~64 tok)
- `0043.stmt` (~166 tok)
- `0044.stmt` (~481 tok)
- `0045.stmt` (~90 tok)
- `0046.stmt` (~31 tok)
- `0047.unit` (~54 tok)
- `0049.stmt` (~89 tok)
- `0050.stmt` (~171 tok)
- `0054.stmt` (~103 tok)
- `0055.unit` — ## TODO(rnystrom): These would all look better if the constructor arguments (~489 tok)
- `0056.stmt` (~87 tok)
- `0057.stmt` (~102 tok)
- `0058.unit` (~91 tok)
- `0060.stmt` (~93 tok)
- `0061.unit` — Declares Foo (~103 tok)
- `0066.stmt` (~70 tok)
- `0068.stmt` — Date/time formatting symbols for locale en_ISO. (~1412 tok)
- `0069.stmt` (~125 tok)
- `0070.stmt` (~180 tok)
- `0071.unit` (~73 tok)
- `0072.unit` — Declares A (~99 tok)
- `0075.unit` — Declares AstComparator (~495 tok)
- `0076.unit` — Declares TokenType (~332 tok)
- `0077.stmt` (~104 tok)
- `0080.unit` (~1396 tok)
- `0081.unit` (~117 tok)
- `0082.stmt` (~101 tok)
- `0083.unit` (~155 tok)
- `0084.unit` — Declares SoundSprite (~460 tok)
- `0085.unit` (~21 tok)
- `0086.unit` (~57 tok)
- `0087.unit` (~212 tok)
- `0089.unit` (~130 tok)
- `0090.stmt` (~265 tok)
- `0091.stmt` (~63 tok)
- `0095.unit` (~234 tok)
- `0096.unit` — Returns a Map from locale names to another Map that goes from skeletons (~190 tok)
- `0098.stmt` (~62 tok)
- `0099.stmt` (~52 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0100/

- `0100.stmt` (~115 tok)
- `0102.stmt` (~157 tok)
- `0108.unit` — Declares ResolutionCopier (~4118 tok)
- `0109.unit` (~12 tok)
- `0110.stmt` — Declares Foo (~96 tok)
- `0111.unit` — Declares MyClassLongName (~240 tok)
- `0112.stmt` (~387 tok)
- `0113.unit` (~22 tok)
- `0114.unit` (~767 tok)
- `0115.stmt` (~310 tok)
- `0119.stmt` (~136 tok)
- `0121.stmt` (~183 tok)
- `0122.unit` — Declares _Streams (~323 tok)
- `0130.unit` (~78 tok)
- `0132.stmt` (~47 tok)
- `0133.stmt` (~93 tok)
- `0135.stmt` (~137 tok)
- `0137.stmt` (~268 tok)
- `0139.unit` — Declares Foo (~734 tok)
- `0140.stmt` (~72 tok)
- `0141.unit` (~131 tok)
- `0142.stmt` (~414 tok)
- `0144.unit` — Declares Selector (~183 tok)
- `0146.unit` (~62 tok)
- `0151.unit` — Declares Foo (~88 tok)
- `0152.unit` (~87 tok)
- `0154.stmt` (~28 tok)
- `0155.stmt` (~31 tok)
- `0156.unit` — Declares Foo (~43 tok)
- `0158.unit` — Declares Foo (~332 tok)
- `0161.stmt` (~64 tok)
- `0162.stmt` (~590 tok)
- `0168.unit` — Declares Foo (~18 tok)
- `0170.unit` (~36 tok)
- `0171.unit` — Declares enum (~185 tok)
- `0176.unit` (~69 tok)
- `0177.stmt` (~29 tok)
- `0178.unit` (~47 tok)
- `0184.unit` — Declares Connection (~157 tok)
- `0185.stmt` — Declares NO_DART_SCRIPT_AND_EXPERIMENTAL (~170 tok)
- `0186.stmt` (~358 tok)
- `0187.stmt` (~338 tok)
- `0188.stmt` (~223 tok)
- `0189.stmt` (~260 tok)
- `0192.unit` — Declares Foo (~21 tok)
- `0197.unit` — Declares FormatterBugTest (~54 tok)
- `0198.stmt` (~502 tok)
- `0199.stmt` (~76 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0200/

- `0200.stmt` (~144 tok)
- `0201.stmt` (~100 tok)
- `0203.stmt` (~228 tok)
- `0204.stmt` (~282 tok)
- `0205.stmt` (~114 tok)
- `0206.stmt` (~121 tok)
- `0211.unit` (~772 tok)
- `0212.stmt` (~466 tok)
- `0217.stmt` (~204 tok)
- `0218.stmt` (~70 tok)
- `0220.stmt` (~257 tok)
- `0221.unit` — Declares Foo (~1005 tok)
- `0222.stmt` (~112 tok)
- `0223.stmt` (~125 tok)
- `0224.stmt` (~933 tok)
- `0226.stmt` (~34 tok)
- `0228.unit` — Declares SomeLongNameForAComponent (~92 tok)
- `0229.unit` — Declares SomeLongNameForAComponent (~111 tok)
- `0232.unit` — Declares Foo (~142 tok)
- `0235.unit` — Declares _MultiSelectionModelImpl (~79 tok)
- `0236.unit` — Declares Foo (~172 tok)
- `0237.unit` — Declares Bar (~191 tok)
- `0238.unit` — Declares ObjectBenchmark (~143 tok)
- `0241.unit` — Declares DynamicChangeDetection (~589 tok)
- `0242.unit` — Declares PartyOrganizerInterviewer (~165 tok)
- `0243.stmt` (~259 tok)
- `0247.unit` (~176 tok)
- `0249.stmt` (~97 tok)
- `0250.unit` — Declares VeryInterestingThing (~124 tok)
- `0255.stmt` (~164 tok)
- `0256.unit` — Declares Foo (~98 tok)
- `0257.unit` — Declares FooConstructor (~154 tok)
- `0258.unit` — Declares FakeFFFFFFFConfigurationStore (~322 tok)
- `0259.unit` — Declares TypingCapability (~184 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0300/

- `0357.stmt` (~82 tok)
- `0360.stmt` (~647 tok)
- `0361.unit` — Basic one-byte 608 CC char set, mostly ASCII. (~896 tok)
- `0364.unit` — Declares Foo (~107 tok)
- `0366.stmt` (~53 tok)
- `0367.stmt` (~409 tok)
- `0368.unit` — Declares Compiler (~2540 tok)
- `0369.stmt` (~276 tok)
- `0370.stmt` (~768 tok)
- `0373.unit` (~89 tok)
- `0374.stmt` (~54 tok)
- `0375.stmt` (~70 tok)
- `0377.stmt` (~67 tok)
- `0378.stmt` (~111 tok)
- `0379.stmt` (~130 tok)
- `0380.unit` (~202 tok)
- `0381.unit` (~62 tok)
- `0382.unit` (~34 tok)
- `0383.unit` — Declares MummyMatchers (~160 tok)
- `0384.stmt` (~65 tok)
- `0387.unit` (~202 tok)
- `0388.unit` — Declares _SimpleNodeValidator (~269 tok)
- `0389.unit` — Declares SpongePublishers (~186 tok)
- `0391.stmt` (~1446 tok)
- `0394.stmt` (~430 tok)
- `0398.stmt` (~125 tok)
- `0399.unit` (~102 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0400/

- `0404.stmt` — Declares Timeout (~103 tok)
- `0407.unit` (~697 tok)
- `0409.stmt` (~78 tok)
- `0410.stmt` (~460 tok)
- `0413.unit` — Declares StaticFilePath (~110 tok)
- `0420.unit` (~236 tok)
- `0421.unit` — Declares MyAmazingComponent (~615 tok)
- `0422.unit` (~136 tok)
- `0424.stmt` (~120 tok)
- `0429.stmt` (~164 tok)
- `0434.unit` (~159 tok)
- `0436.unit` — Declares Foo (~170 tok)
- `0437.unit` — Declares Foo (~180 tok)
- `0438.stmt` (~56 tok)
- `0439.stmt` (~198 tok)
- `0441.unit` (~67 tok)
- `0443.unit` (~47 tok)
- `0444.unit` — Declares MyComponent (~191 tok)
- `0448.stmt` (~327 tok)
- `0449.stmt` (~57 tok)
- `0454.unit` — Declares F (~123 tok)
- `0456.unit` (~62672 tok)
- `0461.stmt` (~131 tok)
- `0462.unit` — Declares Foo (~225 tok)
- `0463.unit` — Declares FilterBarTest (~185 tok)
- `0465.stmt` (~381 tok)
- `0466.unit` (~164 tok)
- `0467.unit` — Declares MyElement (~214 tok)
- `0474.unit` (~12500 tok)
- `0475.unit` — Declares ListResultDescriptor (~106 tok)
- `0478.stmt` (~415 tok)
- `0479.stmt` (~54 tok)
- `0480.unit` — Declares XXXElement (~243 tok)
- `0481.unit` — Declares Car (~101 tok)
- `0484.stmt` (~329 tok)
- `0488.stmt` (~26 tok)
- `0489.stmt` (~57 tok)
- `0494.unit` (~77 tok)
- `0496.stmt` (~267 tok)
- `0497.unit` — Declares Foo (~101 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0500/

- `0500.unit` (~698 tok)
- `0503.unit` — Declares Foo (~104 tok)
- `0506.unit` — Declares Foo (~1040 tok)
- `0511.unit` — Declares Foo (~136 tok)
- `0513.unit` (~30 tok)
- `0514.unit` (~73 tok)
- `0519.stmt` (~47 tok)
- `0520.unit` — Declares Foo (~56 tok)
- `0527.stmt` (~56 tok)
- `0529.unit` — Declares _ElementLifecycle (~39 tok)
- `0541.unit` (~14 tok)
- `0543.unit` (~181 tok)
- `0548.stmt` (~310 tok)
- `0557.unit` — Declares PublicType (~376 tok)
- `0558.unit` — Declares RouteDefinition (~526 tok)
- `0566.unit` (~375 tok)
- `0568.unit` (~98 tok)
- `0571.unit` — Declares Duration (~41 tok)
- `0581.stmt` (~107 tok)
- `0582.unit` (~73 tok)
- `0584.unit` — Declares ListEquality (~50 tok)
- `0585.unit` (~159 tok)
- `0589.unit` (~455 tok)
- `0591.unit` (~874 tok)
- `0594.stmt` (~99 tok)
- `0596.stmt` (~53 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0600/

- `0606.unit` — Declares ErrorKind (~687 tok)
- `0613.unit` (~27 tok)
- `0616.unit` (~122 tok)
- `0619.unit` (~21 tok)
- `0620.unit` (~485 tok)
- `0621.stmt` (~49 tok)
- `0624.unit` — Declares C (~340 tok)
- `0648.stmt` (~25 tok)
- `0658.unit` — Declares A (~76 tok)
- `0665.stmt` (~119 tok)
- `0679.unit` — UnitConverterApp: build, build, build (~241 tok)
- `0680.stmt` (~234 tok)
- `0684.stmt` (~122 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0700/

- `0704.unit` (~330 tok)
- `0705.stmt` (~167 tok)
- `0711.stmt` (~34 tok)
- `0713.stmt` (~113 tok)
- `0721.unit` — Declares C (~228 tok)
- `0722.stmt` (~314 tok)
- `0731.stmt` (~1070 tok)
- `0755.unit` (~357 tok)
- `0760.stmt` (~58 tok)
- `0765.stmt` (~735 tok)
- `0771.unit` — Declares C (~113 tok)
- `0782.unit` (~154 tok)
- `0785.unit` — Declares C (~204 tok)
- `0792.unit` — Declares PestoStyle (~259 tok)
- `0796.unit` — Declares C (~363 tok)
- `0798.stmt` (~348 tok)
- `0799.unit` — Declares C (~102 tok)

## packages/zooper_beaver/test/golden/dart_style/tall/regression/0800/

- `0802.unit` — Declares C (~206 tok)
- `0809.unit` — MyApp: build, buildRow, buildColumn + 9 more (~788 tok)
- `0831.unit` (~95 tok)
- `0837.unit` (~707 tok)
- `0843.stmt` (~51 tok)
- `0855.unit` (~990 tok)
- `0860.unit` — Declares SomeClassName (~432 tok)
- `0861.unit` (~90 tok)
- `0862.unit` — Declares JsonCodec (~363 tok)
- `0869.stmt` (~48 tok)
- `0881.unit` (~3503 tok)
- `0888.unit` (~747 tok)

## packages/zooper_beaver/test/src/

- `golden_file.dart` — / Parser for golden test files in dart_style's `.stmt`/`.unit` grammar, (~2306 tok)

## tool/editors/

- `helix_format.py` — Formats a file in Helix, which has no batch mode, by driving it in a pseudo (~383 tok)
