# Quickstart: Task Skill -- Brainstorm Phase

**Branch**: `task-brainstorm-phase` | **Date**: 2026-04-08

## What Changes

The task skill pipeline gains a new Stage 0 (Brainstormer) and the Analyst (Stage 1) switches from "analyze from scratch" to "validate spec."

## Files to Create

| File | Purpose |
|------|---------|
| `skills/task/agents/brainstormer.md` | New Stage 0 agent definition |
| `skills/task/agents/refs/brainstorm-patterns.md` | Dialogue patterns reference (Level 3) |

## Files to Modify

| File | Change |
|------|--------|
| `skills/task/agents/analyst.md` | Rewrite: validator role, reads 00-spec.md, gap report output |
| `skills/task/SKILL.md` | Add Stage 0, rename 00-summary.md, update agent table, add adaptive entry section |
| `skills/task/agents/documenter.md` | Update reference: `00-summary.md` -> `pipeline-summary.md` |
| `skills/task/agents/committer.md` | Update reference: `00-summary.md` -> `pipeline-summary.md` |

## Implementation Order

1. **brainstorm-patterns.md** (ref doc, no dependencies)
2. **brainstormer.md** (depends on patterns ref)
3. **analyst.md** (rewrite, depends on 00-spec.md format from brainstormer)
4. **SKILL.md** (orchestrator updates, depends on both agents being defined)
5. **documenter.md + committer.md** (rename reference, depends on SKILL.md rename)

## Verification

After implementation, verify by reading each file and checking:
- brainstormer.md declares: Model opus, Reads user_request, Writes .task/00-spec.md, Refs brainstorm-patterns.md
- analyst.md declares: Model opus, Reads .task/00-spec.md, Writes .task/01-analysis.md
- SKILL.md pipeline shows Stage 0 (Brainstorm) before Stage 1 (Validate)
- SKILL.md workspace section lists 00-spec.md and pipeline-summary.md (not 00-summary.md)
- documenter.md and committer.md reference pipeline-summary.md
