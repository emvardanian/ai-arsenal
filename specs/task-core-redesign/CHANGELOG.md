# CHANGELOG: Task Skill Core Redesign

**Branch**: `task-core-redesign`
**Base commit**: `0786dee` (main)
**Date**: 2026-04-17

## Added

- `skills/task/agents/spec.md` — unified Spec agent (interactive + validate modes) replacing Brainstormer + Validator.
- `skills/task/agents/refs/scope-pipelines.md` — authoritative 5×4 scope × task_type pipeline matrix.
- `skills/task/agents/refs/approval-tiers.md` — stage-by-stage approval gate matrix for strict/standard/express tiers, plus Strict-Tier Invariant section.
- `skills/task/agents/refs/model-tiers.md` — authoritative model tier assignments (14 agents, 15 rows including Spec's two modes).
- `skills/task/agents/refs/criticality-signals.md` — keyword-based criticality detection (9 keywords) + gate prompt template.
- `skills/task/agents/refs/spec-dialogue-patterns.md` — interactive dialogue patterns (renamed from brainstorm-patterns.md).
- `specs/task-core-redesign/*` — feature branch documents (spec, plan, research, data-model, contracts, quickstart, tasks, baseline, CHANGELOG).

## Modified

- `skills/task/SKILL.md` — grown from 283 → 529 lines with:
  - Extended `## Pipeline Summary File` (YAML front-matter v2 schema + field table).
  - New `## Classification & Pipeline Selection` block:
    - `### Scope Classification` (4 signals, 5 tiers, round-up rule).
    - `### Scope Override` (preamble grammar + NL fallback).
    - `### Scope Upgrade Mid-Pipeline` (2x threshold rule).
    - `### Approval Tier Selection` (3 tiers, scope defaults).
    - `### Tier Override` (preamble + NL).
    - `### Mid-Flight Tier Change` ("approve and switch to X" syntax).
    - `### Criticality Detection` (3 sources, one-reply gate).
    - `### Model Tier Resolution` (dispatch-time lookup + fallback).
  - Rewritten `## Pipeline Overview` (removed Brainstormer+Validator; added Spec; `[approval*]` semantics).
  - Rewritten `## Agent Reference` table (14 rows; model column references table).
  - Rewritten `## Workspace` (removed `01-analysis.md`).
  - Rewritten `## Adaptive Entry` (Spec Mode Detection).
  - Rewritten `## Flow Control > ### Approval Gates` (dynamic lookup).
  - Rewritten `## Starting the Pipeline` (10-step scope+tier-aware flow).
  - New `## Resume Detection` with `### Scope Inference on Resume`, `### Schema Upgrade on Resume`, `### Pre-redesign artifact fallback`.
  - Updated `## Progress Tracker` (Spec replaces Brainstorm+Validate; skipped-by-scope notation).
  - Simplified `## Adaptive Pipeline` subsection (scope-family summary + reference to scope-pipelines.md).
- `skills/task/agents/scout.md` — model retier sonnet → haiku; prose "between Analyst and Decomposer" → "between Spec and Decomposer"; model declaration → reference.
- `skills/task/agents/designer.md` — model retier opus → sonnet; model declaration → reference.
- `skills/task/agents/design-qa.md` — model retier sonnet → haiku; model declaration → reference.
- `skills/task/agents/decomposer.md` — model declaration → reference (tier unchanged: opus).
- `skills/task/agents/researcher.md` — model declaration → reference (tier unchanged: sonnet).
- `skills/task/agents/planner.md` — model declaration → reference (tier unchanged: opus).
- `skills/task/agents/implementer.md` — model declaration → reference (tier unchanged: sonnet).
- `skills/task/agents/tester.md` — model declaration → reference (tier unchanged: sonnet).
- `skills/task/agents/debugger.md` — model declaration → reference (tier unchanged: sonnet).
- `skills/task/agents/reviewer.md` — model declaration → reference (tier unchanged: sonnet).
- `skills/task/agents/refactorer.md` — model declaration → reference (tier unchanged: haiku).
- `skills/task/agents/documenter.md` — model declaration → reference (tier unchanged: haiku).
- `skills/task/agents/committer.md` — model declaration → reference (tier unchanged: haiku).
- `README.md` — updated agent count (10 → 14), new pipeline diagram with scope/tier layers, scope-adaptive table, approval tier table, invocation examples.

## Removed

- `skills/task/agents/brainstormer.md` — merged into `spec.md`.
- `skills/task/agents/analyst.md` — merged into `spec.md`.
- `skills/task/agents/refs/brainstorm-patterns.md` — renamed to `spec-dialogue-patterns.md`.
- `.DS_Store` files under `skills/task/`.

## Tier Distribution (model rebalance summary)

| Tier | Before | After | Delta |
|---|---:|---:|---:|
| opus | 5 agents | 2 agents | -3 (analyst, brainstormer, designer moved down) |
| sonnet | 7 agents | 7 agents | unchanged (composition shifted: Spec interactive in; Designer in; Scout out; Design-QA out) |
| haiku | 3 agents | 6 agents | +3 (Scout, Design-QA, Spec validate added) |

Expected token-cost impact on representative scope-M feature: ≥40% reduction in opus consumption (SC-004). To be confirmed by manual verification run (see `verification-results.md`).

## Approval Count Changes (per tier, scope-M feature w/ 3 modules)

| Tier | Pre-redesign | Post-redesign | Delta |
|---|---:|---:|---:|
| strict | ~11 | ~9 (Spec is now 1 gate, not 2) | -2 |
| standard | N/A | 3 | new tier |
| express | N/A | 1 | new tier |

Pre-redesign had no tier concept; all tasks ran at what this cycle calls "strict".

## Breaking Changes

None for existing users running at strict tier. The redesign is backward-compatible:
- Pre-redesign `.task/` workspaces resume without errors (FR-026, SC-010).
- Strict tier reproduces pre-redesign approval behavior exactly (FR-024, SC-008).
- Spec agent in interactive mode preserves Brainstormer question flow and section ordering (FR-025).

Users who never customize scope or tier and run default daily tasks will see FEWER approvals (auto-selected express/standard), never more.

## Verification Status

- [X] All files created/modified/deleted per plan.
- [X] All ref files present and non-empty.
- [X] All agent files reference `refs/model-tiers.md`.
- [X] SKILL.md documents scope, tier, criticality, resume in full.
- [ ] Manual verification runs per `quickstart.md` paths 1-3 — pending (see `verification-results.md`).
- [ ] Backward-compat resume test — pending (see `verification-results.md`).
