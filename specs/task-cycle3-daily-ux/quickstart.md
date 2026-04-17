# Quickstart: Cycle 3 Verification Paths

**Feature**: task-cycle3-daily-ux | **Date**: 2026-04-17

## Path 1 — `/task-quick` on simple rename

**Invocation**: `/task-quick rename getUserById to fetchUserById`

**Expected**:
- `entry_point: /task-quick` in front-matter.
- scope: S (auto-classified, capped by slash), tier: express.
- Pipeline: Impl → Test → Commit (via scope-S feature row).
- 1 approval (Committer).

## Path 2 — `/task-full` on large task

**Invocation**: `/task-full migrate auth stack to OAuth2`

**Expected**:
- `entry_point: /task-full`.
- scope: L (default from slash), tier: strict.
- Full pipeline with all strict gates.

## Path 3 — Global prefs applied

**Setup**: `~/.claude/task-prefs.json` contains `{"default_tier": "strict"}`.

**Invocation**: `task: add retry logic to webhook dispatcher`

**Expected**:
- `prefs_source: global` in front-matter.
- tier: strict (from global prefs).
- body line: `- **[Prefs]**: tier=strict [source: global]`.

## Path 4 — Project prefs override global

**Setup**: global `{"default_tier": "strict"}`, project `.claude/task-prefs.json` `{"default_tier": "express"}`.

**Invocation**: `task: rename field`

**Expected**:
- tier: express (project wins).
- `prefs_source: project`.

## Path 5 — Batch approval reduces gates

**Setup**: scope-L feature at strict tier; Decomposer produces 4 modules, all `depends_on: []`.

**Expected** (user accepts batch at all 3 batch-eligible stages):
- Cycle 2 Planner gates: 4 → Cycle 3 batch: 1.
- Cycle 2 Implementer gates: 4 → Cycle 3 batch: 1.
- Cycle 2 Reviewer-Lite gates: 4 → Cycle 3 batch: 1.
- Total per-module gates: 12 → 3.
- Other strict gates unchanged.

**Body records**:
```
- **[Batch approval] Planner**: approved all 4 modules in one gate
- **[Batch approval] Implementer**: approved all 4 modules in one gate
- **[Batch approval] Reviewer-Lite**: approved all 4 modules in one gate
```

## Path 6 — Batch declined at Implementer

**Setup**: same as Path 5; user accepts batch at Planner but picks `individual` at Implementer.

**Expected**:
- Planner: 1 gate (batch).
- Implementer: 4 gates (per-module; sticky after `individual`).
- Reviewer-Lite: batch prompt still shown; user may accept.
- `approval_mode: { planner: batch, implementer: per_module, reviewer-lite: batch|per_module }`.

## Path 7 — README autosync on stale README

**Setup**: add a new agent to `skills/task/agents/` and `refs/model-tiers.md`; do not update README.

**Procedure**:
```
$ scripts/sync-readme.sh
$ git diff README.md
```

**Expected**:
- Agent count sentence regenerated.
- Agent table has new row.
- Exit 0; diff shows only AUTOSYNC-region changes.

**Idempotency check**: run again; `git diff` shows zero lines.

## Path 8 — Backward compat (no Cycle 3 features used)

**Setup**: no prefs files, no slash commands, no hook installed.

**Invocation**: `task: add endpoint` (bare, Cycle 2 style).

**Expected**:
- Pipeline runs identically to Cycle 2.
- `prefs_source: none`, `entry_point: none`, `approval_mode: all per_module (default)`.
- No new prompts, no errors.

## Path 9 — Cycle 2 workspace resume

**Setup**: existing `.task/pipeline-summary.md` from Cycle 2 (no `prefs_source`, `entry_point`, `approval_mode` fields).

**Expected**:
- Cycle 3 resume reads front-matter, fills missing fields with defaults.
- Continues from last incomplete stage.
- No crashes.

## Path 10 — Malformed prefs file

**Setup**: `~/.claude/task-prefs.json` contains invalid JSON (trailing comma).

**Invocation**: any.

**Expected**:
- Single warning line in pipeline-summary body: `[Warning] global prefs malformed; ignoring.`
- Pipeline continues with Cycle 2 defaults.
- `prefs_source: none`.

## Verification procedure

Manual. After implementation:
1. Run each path.
2. Record results in `verification-results.md`.
3. Confirm SC checklist.
