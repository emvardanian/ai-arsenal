# CHANGELOG: Task Skill Cycle 2 — Integration

**Branch**: `task-cycle2-integration`
**Base commit**: `d1b3f17` (main, "feat(task): add interview mode to Spec agent (#7)")
**Date**: 2026-04-17

## Added

### New agent
- `skills/task/agents/reviewer-lite.md` — haiku-tier per-module critical-issue scanner (Cycle 2, US1). Runs after Tester at scope M+ for feature/bugfix/refactor (not hotfix). 5 pattern categories: secrets, N+1, SQLi, unhandled external calls, unbounded loops.

### New refs (SKILL.md split — US2)
- `skills/task/agents/refs/orchestration.md` (95 lines) — Execution Strategy (Tier 1/2/3), Model Tier Resolution, Delegation Mode overview, Context Management.
- `skills/task/agents/refs/pipelines.md` (195 lines) — Pipeline Overview ASCII diagram, Adaptive Pipeline, Pipeline Summary File format, Classification & Pipeline Selection, Adaptive Entry (Spec Mode Detection).
- `skills/task/agents/refs/approvals.md` (150 lines) — Approval Tier Selection + Override + Mid-Flight + Criticality, Flow Control (Approval Gates algorithm, Test/Debug/Design-QA/Review-Lite cycles, Review Issue Routing, Plan Deviations), review_lite override.
- `skills/task/agents/refs/resume.md` (83 lines) — Resume Detection v1/v2, v2.1 vs pre-Cycle-2, Scope Inference, Schema Upgrade, Pre-redesign fallback, Safe Default Invariant.

### New agent refs
- `skills/task/agents/refs/reviewer-lite-checklist.md` — 5 pattern categories with trigger regexes/structural patterns, severity defaults, deduplication rules, output format, haiku constraints.
- `skills/task/agents/refs/delegation-protocol.md` — Cycle 2 wrapper call protocol: delegation decision, escalation, per-agent input bundling (Planner/Debugger/Implementer/Tester), per-agent output adapter rules, fallback triggers, logging format, invariants, back-compat.

### Spec docs
- `specs/task-cycle2-integration/*` — spec, plan, research, data-model, contracts (5 files: skill-md-shell, refs-layout, reviewer-lite-output, delegation-wrapper, pipeline-summary-delta), quickstart, checklists, baseline, topic-coverage, this CHANGELOG, verification-results skeleton.

## Modified

- `skills/task/SKILL.md` — rewritten as thin shell: **537 → 118 lines** (78% reduction, SC-003 ✓). Contains: frontmatter, top description, Progress Tracker, Agent Reference (15 rows including Reviewer-Lite), Workspace (+ 09.5-review-lite-{N}.md), Refs Map, Starting the Pipeline (11 steps with refs links), Resuming cross-ref, Cleaning Up.
- `skills/task/agents/reviewer.md` — new `### Step 1.5: Read Review-Lite` section; new `## Review-Lite Minor Issues` output section; dedupe guideline for resolved Critical findings.
- `skills/task/agents/planner.md` — two-block structure: `## Delegation Decision` + `## Delegated Mode` (invoke `superpowers:writing-plans`) + `## Fallback Mode` (verbatim pre-Cycle-2 behavior).
- `skills/task/agents/debugger.md` — two-block structure delegating to `superpowers:systematic-debugging`.
- `skills/task/agents/implementer.md` — two-block structure delegating to `superpowers:executing-plans`. Also added Required Fixes input from Design-QA.
- `skills/task/agents/tester.md` — two-block structure delegating to `superpowers:test-driven-development`. Spec input path updated from `01-analysis.md` to `00-spec.md` (with pre-Cycle-1 fallback note).
- `skills/task/agents/refs/scope-pipelines.md` — added `reviewer-lite` stage in per-module loop for 9 cells (M/L/XL × feature/bugfix/refactor). Hotfix and XS/S untouched.
- `skills/task/agents/refs/approval-tiers.md` — new `Reviewer-Lite (per module)` row in gate matrix (strict=YES, standard/express=no). Updated count summaries: scope-L 4-module strict = 13 → 17, scope-M 3-module strict = 9 → 12. Strict-Tier Invariant now asserts `cycle1_gates + N_review_lite`.
- `skills/task/agents/refs/model-tiers.md` — new `reviewer-lite | — | haiku` row. Haiku count 7 → 8. Total agent files 14 → 15, total rows 16 → 17.
- `README.md` — updated top description (14 → 15 agents, mention delegation), added Reviewer-Lite row in agent table, header "Agents (14 total)" → "Agents (15 total)".

## Removed

None. Cycle 2 is purely additive (beyond the SKILL.md content reorganization, which preserves all prose via refs).

## Backward Compatibility (US4)

- Pre-Cycle-2 `.task/` workspaces resume cleanly. Missing `delegation_mode` → default `fallback`. Missing `review_lite_enabled` → default `false` (no retroactive Review-Lite).
- Strict tier: Cycle-1 approval set + exactly N Reviewer-Lite gates per module at scope M+ (FR-023).
- Scope XS/S and hotfix task_type: no new gates vs Cycle 1.
- Users who install `superpowers` plugin get delegation automatically. Users without it use inline fallback — artifacts functionally equivalent.
- User override keys added:
  - `delegation: disable` — force fallback.
  - `delegation: enable` — force delegate (or error prompt if plugin missing).
  - `review_lite: skip` — skip the strict-tier approval gate on Review-Lite (stage still runs).

## Verification Status

- [X] 4 refs created, SKILL.md ≤120 lines (SC-003).
- [X] Topic coverage 36/36 pre-split topics accounted for (SC-004) — see `topic-coverage.md`.
- [X] Reviewer-Lite agent declares haiku tier, reads Tester output + impl log, writes `09.5-review-lite-{N}.md`.
- [X] 4 wrappers (Planner/Debugger/Implementer/Tester) have two-block structure with explicit delegation decision.
- [X] Final Reviewer reads `09.5-review-lite-*.md` with dedupe rule.
- [X] Scope matrix, approval matrix, model matrix all updated for Review-Lite.
- [ ] Manual verification runs (quickstart.md Paths 1-7) — deferred; see `verification-results.md`.
