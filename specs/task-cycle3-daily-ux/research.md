# Phase 0 Research: Cycle 3 — Daily UX

**Feature**: task-cycle3-daily-ux | **Date**: 2026-04-17

## 1. Slash command default mapping

| Command | Defaults |
|---|---|
| `/task-quick` | `scope:s, tier:express` — cap via classifier (prefers XS if signals justify); always express |
| `/task-fix` | `task_type:bugfix` — scope auto; tier auto from scope |
| `/task-feature` | `task_type:feature, scope:m, tier:standard` — user may override scope up to XL |
| `/task-full` | `task_type:feature, scope:l, tier:strict` — full ceremony; scope override allowed |

**Rejected alternatives**: `/task-refactor` / `/task-design` — can be added later, not in MVP set. `/task-hotfix` — covered by `/task-fix` with `hotfix` keyword in body.

## 2. Prefs file location and format

**Decision**: JSON at `~/.claude/task-prefs.json` (global) and `<project>/.claude/task-prefs.json` (project).

JSON chosen because Claude Code's settings.json uses JSON; consistent with ecosystem; parseable via bash + `jq` (optional; fallback to simple grep for key presence if jq missing).

**Schema v1** (allowlist):

```json
{
  "default_tier": "strict | standard | express",
  "default_scope": "xs | s | m | l | xl",
  "default_delegation": "enable | disable",
  "skip_stages": ["refactorer", "documenter", "reviewer-lite", ...],
  "review_lite": "skip | default",
  "approval_mode": "per_module | batch"
}
```

All fields optional. Unknown keys ignored (forward compat).

## 3. Precedence stack

Top-to-bottom; first non-null wins per field:

1. **Preamble** in user invocation.
2. **Slash command** defaults (if entered via slash).
3. **Project prefs** `.claude/task-prefs.json` in project root.
4. **Global prefs** `~/.claude/task-prefs.json`.
5. **Cycle-2 Task skill defaults** (scope → tier derivation, etc.).

Each effective field records its source in `prefs_source`:
- `none` — all defaults (user had no prefs, no preamble, no slash).
- `global` — at least one field came from global prefs.
- `project` — at least one field came from project prefs.
- `both` — mix across fields.
- `user` — preamble override (unchanged from Cycle 2).

## 4. Batch approval eligibility

Offered only when ALL conditions hold:
1. Current tier == `strict` (standard/express don't gate these stages anyway).
2. Current stage type ∈ {planner, implementer, reviewer-lite}.
3. Module count at this stage ≥ 2.
4. All modules at this stage have `depends_on: []` per Decomposer.
5. User hasn't previously chosen `individual` for this stage type in this run.

If any condition fails → per-module gating (Cycle 2 behavior).

## 5. Batch prompt UX

**Prompt format**:

```
Batch approval available for <stage_type>.
N modules ready, all independent. Approve all at once?

Modules:
  1. <module 1 brief>
  2. <module 2 brief>
  ...

Options:
  [approve]           — approve all
  [approve except N]  — approve all except module N (list comma-separated)
  [individual]        — switch to per-module gating (Cycle 2 behavior)
```

**User response parsing**:
- `approve` or empty → all approved, continue.
- `approve except 2,3` → approve 1, 4; gate 2 and 3 individually.
- `individual` → all gated per-module; record `approval_mode: per_module` for this stage type.

## 6. Autosync markers

HTML comments, visible in markdown source, invisible in rendered view, idempotent:

```markdown
<!-- AUTOSYNC:BEGIN:agent-table -->
...regenerated content...
<!-- AUTOSYNC:END -->
```

**4 regions**:
- `agent-count` — the sentence in README intro ("... runs up to N specialized agents ...").
- `agent-table` — the markdown table of agents.
- `scope-summary` — the scope-family table (XS/S/M/L/XL → pipeline family).
- `pipeline-diagram` — the ASCII pipeline ART.

Each region has a dedicated extract+regenerate function in `scripts/sync-readme.sh`.

## 7. Sync script strategy

Bash with optional `jq`; POSIX-compatible fallbacks.

**Steps**:
1. Parse `skills/task/SKILL.md` Agent Reference table (between `## Agent Reference` and next `## `).
2. Parse `skills/task/agents/refs/model-tiers.md` (tier assignments).
3. Parse `skills/task/agents/refs/scope-pipelines.md` (scope-family rows).
4. Parse `skills/task/agents/refs/pipelines.md` (Pipeline Overview ASCII).
5. For each AUTOSYNC region in README, regenerate content from extracted data.
6. Write back atomically (tmpfile + mv).
7. Exit 0 on success, 1 on parse error, 2 on missing source files.

**Idempotency**: running twice with unchanged sources produces byte-identical README.

## 8. Pre-commit hook installer

`scripts/install-hooks.sh`:

```bash
#!/usr/bin/env bash
# Installs .git/hooks/pre-commit that calls scripts/sync-readme.sh
# Idempotent: skips install if hook exists with matching content.
```

Users opt in: one-time invocation per repo. Not installed by default. Uninstall by removing the hook file.

## 9. SKILL.md size impact

SKILL.md grew from 118 (Cycle 2) to ~135-150 post-Cycle-3 (new `## Slash Commands` + `## User Preferences` sections, +~20-30 lines). Stays well under the 200-line soft limit.

## Summary

| # | Topic | Decision |
|---|---|---|
| 1 | Slash command set | 4 commands with explicit defaults |
| 2 | Prefs format | JSON, 2 locations, v1 schema |
| 3 | Precedence | preamble > slash > project > global > Cycle-2 |
| 4 | Batch eligibility | strict + ≥2 independent modules + planner/impl/review-lite |
| 5 | Batch UX | 3 options; per-stage-type memory |
| 6 | Autosync markers | HTML comments, 4 regions |
| 7 | Sync script | bash + optional jq; idempotent; atomic writes |
| 8 | Hook installer | opt-in bash script |
| 9 | SKILL.md size | stays ≤150 after additions |

No NEEDS CLARIFICATION remaining. Ready for Phase 1.
