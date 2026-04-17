# Baseline: Pre-Cycle-2 State

**Date**: 2026-04-17
**Base commit**: `d1b3f17334b514dba4c59be29e6c1e5a0070ee03` (main, "feat(task): add interview mode to Spec agent (#7)")

## SKILL.md metrics

- Size: 537 lines
- Frontmatter + title + desc: ~8 lines
- Progress Tracker: ~11 lines
- Agent Reference table: ~25 lines
- Workspace: ~20 lines
- All other prose: ~470 lines (to be split into refs)

## Refs Inventory (pre-Cycle-2)

| File | Purpose |
|---|---|
| approval-tiers.md | Tier → gate matrix (Cycle 1) |
| architecture-checklist.md | Final Reviewer checklist (Cycle 1) |
| brainstorm-patterns.md | REMOVED in Cycle 1 |
| commit-conventions.md | Committer (Cycle 1) |
| commit-template.md | Committer (Cycle 1) |
| criticality-signals.md | Keyword detection (Cycle 1) |
| debug-examples.md | Debugger patterns (Cycle 1) |
| design-tokens-example.md | Designer (Cycle 1) |
| doc-formats.md | Documenter (Cycle 1) |
| model-tiers.md | Agent → model mapping (Cycle 1) |
| performance-checklist.md | Reviewer (Cycle 1) |
| scope-pipelines.md | 5×4 matrix (Cycle 1) |
| security-checklist.md | Reviewer fallback (Cycle 1) |
| spec-dialogue-patterns.md | Spec interactive/interview (Cycle 1) |

**Total: 13 files.**

## Pre-Split Topics (H2/H3 headings)

```
## Pipeline Overview                    -> refs/pipelines.md
## Agent Reference                      -> SKILL.md (unchanged)
## Progress Tracker                     -> SKILL.md (unchanged)
## Workspace                            -> SKILL.md (unchanged, +09.5-*)
## Pipeline Summary File                -> refs/pipelines.md
## Classification & Pipeline Selection  -> refs/pipelines.md + refs/approvals.md (split)
###   Scope Classification              -> refs/pipelines.md
###   Scope Override                    -> refs/pipelines.md
###   Scope Upgrade Mid-Pipeline        -> refs/pipelines.md
###   Approval Tier Selection           -> refs/approvals.md
###   Tier Override                     -> refs/approvals.md
###   Mid-Flight Tier Change            -> refs/approvals.md
###   Criticality Detection             -> refs/approvals.md
###   Model Tier Resolution             -> refs/orchestration.md
## Adaptive Entry                       -> refs/pipelines.md
## Execution Strategy                   -> refs/orchestration.md
###   Tier 1: Agent Teams               -> refs/orchestration.md
###   Tier 2: Subagents                 -> refs/orchestration.md
###   Tier 3: Sequential                -> refs/orchestration.md
## Flow Control                         -> refs/approvals.md
###   Approval Gates                    -> refs/approvals.md
###   Test/Debug Cycle                  -> refs/approvals.md
###   Design QA Cycle                   -> refs/approvals.md
###   Review Issue Routing              -> refs/approvals.md
###   Plan Deviations                   -> refs/approvals.md
###   Adaptive Pipeline                 -> refs/pipelines.md (summary only)
## Context Management                   -> refs/orchestration.md
## Starting the Pipeline                -> SKILL.md (kept; body in refs via links)
## Resuming                             -> SKILL.md (link-only); body -> refs/resume.md
## Resume Detection                     -> refs/resume.md
###   v1 defaults on resume             -> refs/resume.md
###   Scope Inference on Resume         -> refs/resume.md
###   Schema Upgrade on Resume          -> refs/resume.md
###   Pre-redesign artifact fallback    -> refs/resume.md
## Cleaning Up                          -> SKILL.md (unchanged)
```

**Count: 34 headings total.**

**Target post-split**:
- SKILL.md: 6 headings (Progress Tracker, Agent Reference, Workspace, Refs Map, Starting the Pipeline, Resuming, Cleaning Up).
- refs/orchestration.md: ~6 headings.
- refs/pipelines.md: ~10 headings.
- refs/approvals.md: ~11 headings.
- refs/resume.md: ~5 headings.
