# Contract: Refs Layout (Split Topic Map)

**Purpose**: Authoritative mapping from every pre-split SKILL.md topic (H2/H3 heading) to its post-split location. Guarantees zero prose loss (FR-013, SC-004).

## Pre-split → Post-split topic map

| Pre-split heading | Post-split location |
|---|---|
| `# Task — SDLC Pipeline Orchestrator` (top description) | SKILL.md top |
| `## Pipeline Overview` (ASCII diagram) | `refs/pipelines.md` `## Pipeline Overview` |
| `## Agent Reference` (table) | SKILL.md (unchanged location) |
| `## Progress Tracker` | SKILL.md (unchanged) |
| `## Workspace` | SKILL.md (unchanged, updated for `09.5-*`) |
| `## Pipeline Summary File` (extended format + fields table) | `refs/pipelines.md` `## Pipeline Summary File` |
| `## Classification & Pipeline Selection` (block) | `refs/pipelines.md` + `refs/approvals.md` split |
| `### Scope Classification` | `refs/pipelines.md` |
| `### Scope Override` | `refs/pipelines.md` |
| `### Scope Upgrade Mid-Pipeline` | `refs/pipelines.md` |
| `### Approval Tier Selection` | `refs/approvals.md` |
| `### Tier Override` | `refs/approvals.md` |
| `### Mid-Flight Tier Change` | `refs/approvals.md` |
| `### Criticality Detection` | `refs/approvals.md` |
| `### Model Tier Resolution` | `refs/orchestration.md` |
| `## Adaptive Entry` | `refs/pipelines.md` |
| `## Execution Strategy` (Tier 1/2/3) | `refs/orchestration.md` |
| `### Tier 1: Agent Teams` | `refs/orchestration.md` |
| `### Tier 2: Subagents` | `refs/orchestration.md` |
| `### Tier 3: Sequential` | `refs/orchestration.md` |
| `## Flow Control` | `refs/approvals.md` |
| `### Approval Gates` | `refs/approvals.md` |
| `### Test/Debug Cycle` | `refs/approvals.md` |
| `### Design QA Cycle` | `refs/approvals.md` |
| `### Review Issue Routing` | `refs/approvals.md` |
| `### Plan Deviations` | `refs/approvals.md` |
| `### Adaptive Pipeline` (summary table) | `refs/pipelines.md` |
| `## Context Management` | `refs/orchestration.md` |
| `## Starting the Pipeline` | SKILL.md (steps), with "see refs" links |
| `## Resuming` | SKILL.md (cross-reference), body in `refs/resume.md` |
| `## Resume Detection` | `refs/resume.md` |
| `### v1 defaults on resume` | `refs/resume.md` |
| `### Scope Inference on Resume` | `refs/resume.md` |
| `### Schema Upgrade on Resume` | `refs/resume.md` |
| `### Pre-redesign artifact fallback` | `refs/resume.md` |
| `## Cleaning Up` | SKILL.md (unchanged) |

## New topics added by Cycle 2

| New heading | Location |
|---|---|
| Review-Lite stage in Agent Reference | SKILL.md (new row in Agent Reference table) |
| `09.5-review-lite-{N}.md` in Workspace listing | SKILL.md Workspace |
| Delegation mode semantics | `refs/orchestration.md` (with wrapper protocol details in `refs/delegation-protocol.md`) |
| Review-Lite per-module approval rule | `refs/approvals.md` (Review-Lite row in gate matrix) |
| Review-Lite scope mapping | `refs/scope-pipelines.md` (update existing file) |

## Verification procedure

After the split implementation:

1. Read pre-split SKILL.md (the Cycle 1 baseline, 537 lines).
2. For each H2 and H3 heading, confirm presence in post-split location per table above.
3. For each pre-split paragraph / list / code block / table, confirm content present (verbatim or re-wrapped) in its target location.
4. Record any gaps in `verification-results.md`; if gaps exist → split rejected.

## Load-trigger documentation

Each ref records (at its top) **when** it is loaded:

- `orchestration.md`: "Load at pipeline startup (after reading SKILL.md Agent Reference table)."
- `pipelines.md`: "Load after Spec completes, before pipeline dispatch."
- `approvals.md`: "Load on first stage dispatch; cache for duration of run."
- `resume.md`: "Load only on resume path (when `.task/pipeline-summary.md` exists at start)."
- `reviewer-lite-checklist.md`: "Load when Review-Lite agent dispatches."
- `delegation-protocol.md`: "Load once per run when any wrapper agent (Planner/Debugger/Implementer/Tester) first dispatches."
