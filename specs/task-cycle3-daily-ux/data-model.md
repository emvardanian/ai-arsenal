# Data Model: Cycle 3 — Daily UX

**Feature**: task-cycle3-daily-ux | **Date**: 2026-04-17

## SlashCommand

**Values**: 4 instances (task-quick, task-fix, task-feature, task-full).

**Schema**:
- `name` — `task-quick` / `task-fix` / `task-feature` / `task-full`
- `default_scope` — optional ScopeTier enum
- `default_tier` — optional ApprovalTier enum
- `default_task_type` — optional `feature | bugfix | refactor | hotfix`
- `body_template` — markdown prose + preamble line

**Persistence**: `.claude/commands/<name>.md` with YAML frontmatter declaring `argument-hint` and optional `description`, body with Task skill invocation.

## UserPreferences

**Schema v1** (JSON):

```json
{
  "default_tier": "strict | standard | express",
  "default_scope": "xs | s | m | l | xl",
  "default_delegation": "enable | disable",
  "skip_stages": ["<stage_name>", ...],
  "review_lite": "skip | default",
  "approval_mode": "per_module | batch"
}
```

All fields optional. Unknown keys ignored.

**Persistence**: 
- Global: `~/.claude/task-prefs.json`.
- Project: `<project_root>/.claude/task-prefs.json`.

Both optional. Malformed file → single warning, ignored.

## PrefsSource

Enum recorded in pipeline-summary front-matter.

**Values**: `none`, `global`, `project`, `both`, `user` (existing preamble override).

Indicates where the effective preferences came from.

## ApprovalMode

Enum, per-stage-type.

**Values**: `per_module`, `batch`.

**Persistence**: `.task/pipeline-summary.md` front-matter:

```yaml
approval_mode:
  planner: batch
  implementer: batch
  reviewer-lite: per_module
```

Default per stage type: `per_module` (Cycle 2 behavior). Updated when user accepts batch prompt for that stage type.

## BatchApprovalContext

One per eligible stage-type invocation.

**Fields**:
- `stage_type` — `planner | implementer | reviewer-lite`
- `modules_independent` — bool (are all modules at this stage `depends_on: []`?)
- `batch_offered` — bool (did orchestrator show batch prompt?)
- `user_choice` — enum `{approve_all, approve_except, individual, n/a}`
- `excluded_modules` — list of int (for `approve_except`)

**Persistence**: logged in pipeline-summary body per batch-eligible stage-type dispatch.

## AutosyncRegion

Maps a README region to its regeneration source.

**Fields**:
- `section_name` — `agent-count | agent-table | scope-summary | pipeline-diagram`
- `begin_marker` — `<!-- AUTOSYNC:BEGIN:<section_name> -->`
- `end_marker` — `<!-- AUTOSYNC:END -->`
- `source_files` — list of paths (SKILL.md + refs files)
- `generator_function` — bash function in sync-readme.sh that produces the region content

**Persistence**: defined in `scripts/sync-readme.sh` as internal constants; reflected in README via marker comments.

## Extended PipelineSummary

Cycle 2 v2 schema + Cycle 3 additive fields.

```yaml
---
# Cycle 1/2 fields (unchanged)
scope: M
tier: strict
delegation_mode: delegate
review_lite_enabled: true
summary_schema: v2

# Cycle 3 additive
prefs_source: none | global | project | both | user
entry_point: none | /task-quick | /task-fix | /task-feature | /task-full
approval_mode:
  planner: per_module | batch
  implementer: per_module | batch
  reviewer-lite: per_module | batch
---
```

**Back-compat**:
- Absence of `prefs_source` → treat as `none`.
- Absence of `entry_point` → treat as `none` (bare invocation).
- Absence of `approval_mode` → treat all as `per_module` (Cycle 2 default).

## Body additions

Per-stage line augmentation:

```
- **Stage 5.2 -- Planner**: ok plan.md written [delegated via superpowers:writing-plans; approval_mode: batch]
```

Batch approval prompt results recorded as body line:

```
- **[Batch approval] Planner**: approved all 4 modules in one gate
- **[Batch approval] Implementer**: individual (user opted per-module)
```

## State transitions

```
Pipeline start
  → Parse slash command entry (if any) → set entry_point, defaults
  → Load global prefs (if file exists) → merge into effective config
  → Load project prefs (if file exists) → merge, project overrides global
  → Parse preamble → preamble overrides all
  → Record prefs_source in pipeline-summary front-matter
  → Proceed with Cycle 2 pipeline dispatch
  → At each batch-eligible stage type:
    → Check eligibility (strict + ≥2 modules + all independent + user not previously individual)
    → If eligible: show batch prompt, record BatchApprovalContext
    → If individual: Cycle 2 per-module gating
  → Record approval_mode per stage type in front-matter
```

## Reference summary

| Entity | Persisted where | Written by | Read by |
|---|---|---|---|
| SlashCommand | `.claude/commands/<name>.md` | Cycle 3 author | Claude Code CLI |
| UserPreferences | `~/.claude/task-prefs.json` + `<project>/.claude/task-prefs.json` | User (hand-edit) | Orchestrator (startup) |
| PrefsSource | pipeline-summary front-matter | Orchestrator | Audit, downstream |
| ApprovalMode | pipeline-summary front-matter | Orchestrator (per stage type) | Orchestrator (subsequent same-type dispatch) |
| BatchApprovalContext | pipeline-summary body | Orchestrator | Audit |
| AutosyncRegion | README body (markers) | `scripts/sync-readme.sh` | Hook + manual invocation |
