# Baseline: Pre-Redesign State

**Date**: 2026-04-17
**Purpose**: Snapshot of `skills/task/` before the core redesign. Used for backward-compat diff checks in Phase 7/8.

## Base commit

```
0786dee5e8bd143dc464735aebd96f76557a0692 fix(task): quality fixes for documenter, refactorer, reviewer agents
```

## Worktree

- Main: `/Users/emmanuil/work/AI/ai-arsenal` @ 0786dee (main)
- Redesign: `/Users/emmanuil/work/AI/ai-arsenal-task-core-redesign` @ 0786dee (task-core-redesign)

## Agent Inventory

| File | Size (bytes) | Model (inline) | Notes |
|---|---:|---|---|
| analyst.md | 6090 | opus | To be merged into `spec.md` |
| brainstormer.md | 6298 | opus | To be merged into `spec.md` |
| committer.md | 3059 | haiku | Unchanged (haiku kept) |
| debugger.md | 3648 | sonnet | Unchanged (sonnet kept) |
| decomposer.md | 3773 | opus | Unchanged (opus kept) |
| design-qa.md | 6339 | sonnet | Retier to haiku |
| designer.md | 12477 | opus | Retier to sonnet |
| documenter.md | 3589 | haiku | Unchanged (haiku kept) |
| implementer.md | 2962 | sonnet | Unchanged (sonnet kept) |
| planner.md | 2765 | opus | Unchanged (opus kept) |
| refactorer.md | 3630 | haiku | Unchanged (haiku kept) |
| researcher.md | 4085 | sonnet | Unchanged (sonnet kept) |
| reviewer.md | 4579 | sonnet | Unchanged (sonnet kept) |
| scout.md | 3232 | sonnet | Retier to haiku |
| tester.md | 3304 | sonnet | Unchanged (sonnet kept) |

**Total**: 15 agents. Post-redesign: 14 (brainstormer + analyst merged into spec).

## Refs Inventory

| File | Size (bytes) | Notes |
|---|---:|---|
| architecture-checklist.md | 883 | Unchanged |
| brainstorm-patterns.md | 4269 | To be renamed to `spec-dialogue-patterns.md` |
| commit-conventions.md | 6445 | Unchanged |
| commit-template.md | 1223 | Unchanged |
| debug-examples.md | 1693 | Unchanged |
| design-tokens-example.md | 4188 | Unchanged |
| doc-formats.md | 680 | Unchanged |
| performance-checklist.md | 843 | Unchanged |
| security-checklist.md | 1454 | Unchanged |

**Post-redesign additions** (Phase 2):
- `scope-pipelines.md` (new)
- `approval-tiers.md` (new)
- `model-tiers.md` (new)
- `criticality-signals.md` (new)
- `spec-dialogue-patterns.md` (renamed from brainstorm-patterns.md)

## Pipeline Summary Format (pre-redesign)

- File: `.task/pipeline-summary.md`
- No front-matter; body starts with `# Pipeline Summary`
- Body format: bullet list, one line per completed stage
- Read by: Documenter, Committer (body only), Orchestrator (body on resume)

## Approval Gates (pre-redesign, equivalent to strict tier)

For a full scope-L feature pipeline, approvals happen at:
1. Brainstormer completion (per-section + final)
2. Analyst/Validator completion
3. Decomposer completion
4. Per-module Planner
5. Per-module Designer (if ui: true)
6. Per-module Implementer
7. Refactorer
8. Documenter
9. Committer

Per-module stages multiply by module count. A 4-module feature: ~11-12 approvals.

## Model Tier Distribution (pre-redesign)

| Model | Count | Agents |
|---|---:|---|
| opus | 4 | analyst, brainstormer, decomposer, designer, planner |
| sonnet | 7 | debugger, design-qa, implementer, researcher, reviewer, scout, tester |
| haiku | 3 | committer, documenter, refactorer |

(analyst and brainstormer count as 2; planner, decomposer, designer are the 3 others on opus — total 5 on opus pre-redesign. After merge + retier: 2 on opus, 6 on sonnet, 6 on haiku.)
