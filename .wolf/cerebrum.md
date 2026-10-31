---
description: learned preferences, project conventions, and Do-Not-Repeat rules
budget_tokens: 2000
---
# Cerebrum

> OpenWolf's learning memory. Updated automatically as the AI learns from interactions.
> Do not edit manually unless correcting an error.
> Last updated: 2026-10-28

## User Preferences

<!-- How the user likes things done. Code style, tools, patterns, communication. -->

## Key Learnings

- **Project:** beaver

## Do-Not-Repeat

<!-- Mistakes made and corrected. Each entry prevents the same mistake recurring. -->
<!-- Format: [YYYY-MM-DD] Description of what went wrong and what to do instead. -->

- [2026-10-30] `git stash` + test run + `git stash pop` fails here: OpenWolf hooks rewrite `.wolf/anatomy*.json|md` while commands run, so the pop aborts. For a before/after baseline use `git worktree add` on HEAD instead of stashing.

## Decision Log

<!-- Significant technical decisions with rationale. Why X was chosen over Y. -->
