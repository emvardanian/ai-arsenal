# CHANGELOG: Task Skill Cycle 3 — Daily UX

**Branch**: `task-cycle3-daily-ux`
**Base commit**: `4bb7e6d` (main, "feat(task): cycle 2 — ... (#8)")
**Date**: 2026-04-17

## Added

### Slash commands (US1)
- `.claude/commands/task-quick.md` — scope S + express tier defaults.
- `.claude/commands/task-fix.md` — task_type=bugfix default.
- `.claude/commands/task-feature.md` — scope M + standard tier + feature default.
- `.claude/commands/task-full.md` — scope L + strict tier + feature default.

### Refs
- `skills/task/agents/refs/prefs.md` — prefs schema v1, precedence stack, fail-safe rules, source recording, examples.
- `skills/task/agents/refs/slash-commands.md` — command registry, defaults map, preamble override rules, entry-point recording.
- `skills/task/agents/refs/batch-approval.md` — eligibility, prompt UX, response parsing, state machine, prefs integration.

### Scripts
- `scripts/sync-readme.sh` — bash regenerator for README AUTOSYNC regions; 4 generator functions; atomic write; exit codes 0/1/2/3.
- `scripts/install-hooks.sh` — opt-in pre-commit installer for autosync hook; idempotent.

### Spec docs
- `specs/task-cycle3-daily-ux/*` — spec, plan, research, data-model, contracts (4), quickstart, checklists, tasks, baseline, CHANGELOG, verification-results skeleton.

## Modified

- `skills/task/SKILL.md` — added `## Slash Commands` + `## User Preferences` sections; updated Starting the Pipeline step 2/2a/3 to include prefs loading and entry_point recording; Refs Map expanded with Cycle 3 refs.
- `skills/task/agents/refs/approvals.md` — added batch approval invariant + cross-reference to `refs/batch-approval.md`.
- `skills/task/agents/refs/resume.md` — added Cycle 3 fields defaults on resume (`approval_mode: per_module`, `prefs_source: none`, `entry_point: none`).
- `README.md` — added AUTOSYNC markers around 4 regions (agent-count, agent-table, scope-summary, pipeline-diagram); added `### Daily-UX (Cycle 3)` subsection; agent table updated with delegation notes.

## Removed

None. Purely additive cycle.

## Backward Compatibility (US5)

- Users with no prefs files → Cycle 2 behavior unchanged.
- Users who never invoke `/task-*` → Cycle 2 behavior unchanged.
- Batch approval is opt-in per stage type; declining → Cycle 2 per-module gating.
- Pre-commit hook is opt-in via `scripts/install-hooks.sh`; not installed automatically.
- Cycle 2 `.task/` workspaces resume with safe defaults for missing Cycle 3 fields.

## Verification Status

- [X] 4 slash command files present.
- [X] 3 new refs present.
- [X] 2 scripts executable.
- [X] SKILL.md updated with Slash Commands + User Preferences sections.
- [X] README.md has AUTOSYNC markers around 4 regions.
- [ ] Manual verification paths 1-10 per `quickstart.md` — deferred.

## Cycle summary

End of three-cycle Task skill redesign:
- **Cycle 1**: scope-driven pipeline, 3-tier approvals, unified Spec, model rebalance (PR #6).
- **Cycle 2**: Review-Lite per module, SKILL.md split (537→118), superpowers delegation (PR #8).
- **Cycle 3**: slash commands, user preferences, batch approval, README autosync (this PR).

Total transformation: 10-agent heavyweight orchestrator → 15-agent scope/tier-aware daily driver with full backward-compat guarantees.
