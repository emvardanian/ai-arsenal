---
description: "Dependency-ordered task list for task-cycle2-integration"
---

# Tasks: Task Skill Cycle 2 — Integration

**Input**: Design documents from `/specs/task-cycle2-integration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (5 files), quickstart.md

**Tests**: NOT applicable (constitution: markdown-only, no test runner). Verification is manual per `quickstart.md`.

**Organization**: Tasks grouped by user story. Each story independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks).
- **[Story]**: US1 Review-Lite, US2 SKILL.md split, US3 Superpowers delegation, US4 Backward compat.
- File paths absolute within worktree root.

## Path Conventions

Worktree root: `/Users/emmanuil/work/AI/ai-arsenal-task-cycle2-integration/`

All edits scoped to `skills/task/`.

---

## Phase 1: Setup

- [X] T001 Create baseline snapshot: record `git log -1 main` SHA and size of current `skills/task/SKILL.md` (537 lines) in `specs/task-cycle2-integration/baseline.md`. This is the topic-coverage reference for SC-004.
- [X] T002 [P] Catalog current refs in `skills/task/agents/refs/` (13 files) into `baseline.md` under `## Refs Inventory (pre-Cycle-2)`.
- [X] T003 [P] Extract pre-split SKILL.md H2/H3 heading list from Cycle 1 final state; append to `baseline.md` as `## Pre-Split Topics`. Used later for zero-loss verification.

---

## Phase 2: Foundational

**Purpose**: Reference tables and per-agent refs that every user story depends on. BLOCKS US1, US2, US3.

- [X] T004 [P] Create `skills/task/agents/refs/reviewer-lite-checklist.md` — 5 pattern categories per research §2 (secrets regex, N+1 patterns, SQLi patterns, unhandled external call, unbounded loops). Each category: trigger pattern, severity default, example finding format.
- [X] T005 [P] Create `skills/task/agents/refs/delegation-protocol.md` — wrapper call protocol per `contracts/delegation-wrapper.md`. Sections: per-agent input bundling (Planner/Debugger/Implementer/Tester), per-agent output adapter rules, fallback triggers (startup/per-call/escalation/user), WrapperInvocationResult logging format.
- [X] T006 [P] Update `skills/task/agents/refs/scope-pipelines.md` to add `reviewer-lite` after `tester` within per-module loop for cells: M/feature, M/bugfix, M/refactor, L/feature, L/bugfix, L/refactor, XL/feature, XL/bugfix, XL/refactor. Hotfix cells and all XS/S cells unchanged.
- [X] T007 [P] Update `skills/task/agents/refs/approval-tiers.md` to add `Reviewer-Lite (per UI module)` row between Design-QA and Reviewer in the Gate matrix. Values: `strict=YES`, `standard=no`, `express=no`. Update count summary (e.g., scope-L feature with 4 modules strict tier +4 gates).
- [X] T008 [P] Update `skills/task/agents/refs/model-tiers.md` to add `| reviewer-lite | — | haiku | Pattern-matchable critical checks per refs/reviewer-lite-checklist.md |` row. Update tier distribution summary (haiku 7 → 8).

**Checkpoint**: foundational refs ready. Review-Lite stage declared in pipeline/approval/model tables but no agent file yet.

---

## Phase 3: User Story 1 — Per-Module Review-Lite (Priority: P1) 🎯 MVP

**Goal**: New haiku agent runs after each module's Tester at scope M+, catching Critical issues early.

**Independent Test**: scope-M feature with injected hardcoded secret in module 1 → Review-Lite catches before module 2 (SC-001).

- [X] T009 [US1] Create `skills/task/agents/reviewer-lite.md`:
  - Header + model declaration referencing `refs/model-tiers.md` (entry: `reviewer-lite`)
  - `## Role` — per-module critical-issue scanner
  - `## Inputs` — `.task/07-tests-{N}-{C}.md` (Brief only), `.task/06-impl-{N}.md` (files list), `agents/refs/reviewer-lite-checklist.md`
  - `## Process` — 5 steps per research §2: (1) load checklist, (2) scan changed files per impl log, (3) apply 5 category patterns, (4) dedupe against test failures, (5) classify severity
  - `## Output` — `.task/09.5-review-lite-{N}.md` schema per `contracts/reviewer-lite-output.md`
  - `## Brief` — template with module/files/findings/verdict counts
  - `## Guidelines` — haiku constraints (greppable patterns only, no cross-file reasoning)
- [X] T010 [US1] Update `skills/task/agents/reviewer.md` to read `.task/09.5-review-lite-*.md` Brief + Findings:
  - Add `## Read Review-Lite` section after `## Inputs`: "Read every `09.5-review-lite-*.md` file in `.task/`, aggregate Findings tables."
  - Add dedupe rule: "If a Reviewer-found issue matches (location, category) from a Review-Lite finding already resolved (not present in current code), exclude from `09-review.md`."
  - Add aggregation rule: "Minor findings from Review-Lite with status=unresolved get section `### Review-Lite Minor` in `09-review.md` with `source: review-lite` annotation."

**Checkpoint**: Review-Lite agent exists, Reviewer deduplicates. Scope M+ now gains new stage.

---

## Phase 4: User Story 2 — Lean SKILL.md with On-Demand Refs (Priority: P2)

**Goal**: 537-line SKILL.md → ≤120-line shell + 4 refs. Zero prose loss. Zero behavior change.

**Independent Test**: topic coverage map per `contracts/refs-layout.md` confirms every pre-split H2/H3 has post-split home; scope-L run through new skill behaves identically.

- [X] T011 [P] [US2] Create `skills/task/agents/refs/orchestration.md` with topics from pre-split: Execution Strategy (Tier 1 Agent Teams / Tier 2 Subagents / Tier 3 Sequential), Model Tier Resolution algorithm, Context Management (6 rules). Load-trigger note at top: "Load at pipeline startup after SKILL.md Agent Reference."
- [X] T012 [P] [US2] Create `skills/task/agents/refs/pipelines.md` with topics from pre-split: Pipeline Overview ASCII diagram, Adaptive Pipeline summary (scope family table), Classification & Pipeline Selection header + Scope Classification + Scope Override + Scope Upgrade Mid-Pipeline, Adaptive Entry (Spec Mode Detection 8 rules), Pipeline Summary File section (extended format + fields table). Load-trigger: "Load after Spec completes, before pipeline dispatch."
- [X] T013 [P] [US2] Create `skills/task/agents/refs/approvals.md` with topics: Flow Control header + Approval Gates (dynamic lookup algorithm) + Test/Debug Cycle + Design QA Cycle + Review Issue Routing + Plan Deviations, Approval Tier Selection + Tier Override + Mid-Flight Tier Change + Criticality Detection. Load-trigger: "Load on first stage dispatch; cache for duration of run."
- [X] T014 [P] [US2] Create `skills/task/agents/refs/resume.md` with topics: Resume Detection (v1/v2 schema test), v1 defaults, Scope Inference on Resume, Schema Upgrade on Resume, Pre-redesign artifact fallback. Load-trigger: "Load only on resume path."
- [X] T015 [US2] Rewrite `skills/task/SKILL.md` to thin shell (≤120 lines) per `contracts/skill-md-shell.md`:
  - Frontmatter (name, description) — unchanged
  - Top description (2-3 paragraphs)
  - `## Progress Tracker` — brief
  - `## Agent Reference` — full 15-row table (add Reviewer-Lite row at position 9.5 between Design-QA and Reviewer)
  - `## Workspace` — update to include `09.5-review-lite-{N}.md`
  - `## Refs Map` — one-line pointer to each ref with load trigger (7 entries: orchestration, pipelines, approvals, resume, reviewer-lite-checklist, delegation-protocol, scope-pipelines/approval-tiers/model-tiers as Cycle 1 carries)
  - `## Starting the Pipeline` — 10 numbered steps terse, each ending with "see refs/<file>.md" where applicable
  - `## Resuming` — 3-line cross-ref to `refs/resume.md`
  - `## Cleaning Up` — 1 line
- [X] T016 [US2] Verify topic coverage: for every H2/H3 in pre-split SKILL.md (from `baseline.md`), record target location in post-split artifacts. Log result in `specs/task-cycle2-integration/topic-coverage.md`. If any heading missing → HALT, restore prose, escalate.
- [X] T017 [US2] Verify SKILL.md line count ≤120 via `wc -l skills/task/SKILL.md`. If >120, identify and move additional prose to refs.

**Checkpoint**: SKILL.md lean. Every pre-split topic accounted for.

---

## Phase 5: User Story 3 — Superpowers Delegation with Fallback (Priority: P3)

**Goal**: Planner/Debugger/Implementer/Tester become thin wrappers. Plugin missing → inline fallback. User override → `delegation: disable`.

**Independent Test**: same task run with and without plugin → artifacts functionally equivalent (SC-005, SC-006).

- [ ] T018 [US3] Update `skills/task/agents/planner.md` to add two-block structure per `contracts/delegation-wrapper.md`:
  - Preserve existing role/inputs/model header
  - Add `## Delegation Decision` section (read `delegation_mode` from pipeline-summary, dispatch one of two blocks below)
  - Add `## Delegated Mode` — invoke `superpowers:writing-plans` with module research + decomposition + acceptance criteria; adapt output to `.task/05-plan-{N}.md` schema (Objective, Files, Steps, Conventions, Verification, Brief)
  - Move existing process/output content into new `## Fallback Mode` section verbatim (this is the pre-Cycle-2 behavior)
  - Add error-catching rule: on delegated failure → switch to fallback for this invocation; log `fallback_reason`
- [ ] T019 [US3] [P] Update `skills/task/agents/debugger.md` with same two-block structure:
  - `## Delegated Mode` — invoke `superpowers:systematic-debugging` with test failure report + cycle number + prior debug report (if cycle 2); adapt output to `.task/08-debug-{N}-{C}.md` (Failure clusters, 3 hypotheses each, evidence, fix instructions, complexity)
  - `## Fallback Mode` — existing Debugger behavior verbatim
- [ ] T020 [US3] [P] Update `skills/task/agents/implementer.md` with same two-block structure:
  - `## Delegated Mode` — invoke `superpowers:executing-plans` with plan, research brief, design tokens (if UI); adapt output to `.task/06-impl-{N}.md` + code changes
  - `## Fallback Mode` — existing Implementer behavior verbatim
- [ ] T021 [US3] [P] Update `skills/task/agents/tester.md` with same two-block structure:
  - `## Delegated Mode` — invoke `superpowers:test-driven-development` with impl log, acceptance criteria, verification section; adapt output to `.task/07-tests-{N}-{C}.md` (Pass/Fail/Regression/Slow categories, Brief)
  - `## Fallback Mode` — existing Tester behavior verbatim
- [ ] T022 [US3] Add orchestrator-level delegation logic to `skills/task/SKILL.md` Starting the Pipeline step list:
  - New step 3 after invocation parse: "Detect `superpowers` plugin availability. Parse `delegation` preamble key. Set `delegation_mode` and `delegation_source` per rules in `refs/delegation-protocol.md`."
  - Write to `.task/pipeline-summary.md` front-matter (new fields per `contracts/pipeline-summary-delta.md`)
- [ ] T023 [US3] Document fallback escalation rule in `skills/task/agents/refs/delegation-protocol.md`: if 2+ per-call fallbacks in same run → orchestrator elevates `delegation_mode` to `fallback` for remainder; `delegation_source: escalation` logged.

**Checkpoint**: Wrappers functional in both modes. Plugin-aware dispatch works. User override respected.

---

## Phase 6: User Story 4 — Backward Compatibility (Priority: P2)

**Goal**: Strict tier adds exactly N Review-Lite gates; everything else preserved. Pre-Cycle-2 workspaces resume cleanly.

**Independent Test**: run identical scope-L feature at strict tier on Cycle 1 vs Cycle 2 → diff = +N Review-Lite approvals.

- [ ] T024 [US4] Update `skills/task/agents/refs/approval-tiers.md` Strict-Tier Invariant section to explicitly list Review-Lite as the one additive gate post-Cycle-2. Assert: "strict = Cycle-1 gates + (N per-module Review-Lite) where N = Decomposer module count."
- [ ] T025 [US4] Update `skills/task/agents/refs/resume.md` (created in T014) to handle Cycle-2 resume:
  - Add section `### v2.1 vs pre-Cycle-2 detection`: if front-matter lacks `delegation_mode` → default `fallback`; lacks `review_lite_enabled` → default `false` (no retroactive Review-Lite on resumed pipelines).
  - Document: "On resume, orchestrator does NOT insert Review-Lite into already-running pipeline. Only new runs get Review-Lite."
- [ ] T026 [US4] Update `skills/task/SKILL.md` Workspace section note about `.task/09.5-review-lite-{N}.md`: "Present only when Review-Lite ran (scope M+, task_type ≠ hotfix, user did not `review_lite: skip`). Cycle-1 workspaces never have these files."
- [ ] T027 [US4] Document `review_lite: skip` preamble key in `skills/task/agents/refs/approvals.md`: "When present, Review-Lite stage still runs but without approval gate in strict tier. Use for power users confident their implementation is clean."

**Checkpoint**: Back-compat explicit, documented, testable.

---

## Phase 7: Polish & Cross-Cutting

- [ ] T028 [P] Update `README.md` at project root: agent count 14 → 15, add Review-Lite row in agent table, add Cycle 2 items to feature list (Review-Lite, SKILL.md split, delegation).
- [ ] T029 [P] Create `specs/task-cycle2-integration/CHANGELOG.md` listing every file added/modified/removed in Cycle 2.
- [ ] T030 [P] Create `specs/task-cycle2-integration/verification-results.md` (skeleton) per Cycle 1 pattern: 7 paths from quickstart.md, `_pending_` cells, SC checkboxes.
- [ ] T031 Run topic-coverage verification per T016 output. Confirm `topic-coverage.md` shows 100% of pre-split headings accounted for. Update plan.md Post-Design Constitution Re-Check section with PASS status.
- [ ] T032 Run line-count verification: `wc -l skills/task/SKILL.md` ≤ 120; `wc -l skills/task/agents/refs/*.md` reasonable (each ref under ~200 lines).
- [ ] T033 Verify removed files are absent: none in this cycle (purely additive). Confirm no agent file was accidentally deleted.
- [ ] T034 Dry-run: trace through quickstart.md Path 2 (scope-L with Critical bug) against updated refs/agents, confirming orchestrator flow is consistent end-to-end.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Run first.
- **Foundational (Phase 2)**: Depends on Phase 1. BLOCKS US1, US2, US3.
- **US1 (Phase 3)**: Depends on T004 (reviewer-lite-checklist), T006 (scope-pipelines update), T007 (approval-tiers update), T008 (model-tiers update). Independent of US2/US3 on file level.
- **US2 (Phase 4)**: Depends on T003 (pre-split topics) + T007 + T008 (agent table must reflect Review-Lite addition in SKILL.md rewrite).
- **US3 (Phase 5)**: Depends on T005 (delegation-protocol) + agents (T018/T019/T020/T021 are parallel to each other on different files).
- **US4 (Phase 6)**: Verifies US1+US2+US3. Must run after all three.
- **Polish (Phase 7)**: All user stories complete.

### SKILL.md serialization

SKILL.md is touched by T015 (US2 rewrite), T022 (US3 orchestrator logic), T026 (US4 workspace note), T028 (polish README not SKILL.md). Execute in order US2 → US3 → US4.

### Parallel Opportunities

- **Phase 2**: T004-T008 all parallel (5 tasks, different files).
- **Phase 4**: T011-T014 parallel (4 new refs, different files).
- **Phase 5**: T019-T021 parallel after T018 (different agent files; T018 sets pattern first).
- **Phase 7**: T028-T030 parallel.

### Critical serialization

T015 (SKILL.md rewrite) must complete before T022 (SKILL.md edit) and T026 (SKILL.md edit).

---

## Parallel Example: Phase 2 Foundational

```
Task: "T004 create reviewer-lite-checklist.md"
Task: "T005 create delegation-protocol.md"
Task: "T006 update scope-pipelines.md"
Task: "T007 update approval-tiers.md"
Task: "T008 update model-tiers.md"
```

## Parallel Example: Phase 4 Split

```
Task: "T011 create orchestration.md"
Task: "T012 create pipelines.md"
Task: "T013 create approvals.md"
Task: "T014 create resume.md"
```

Then T015 rewrites SKILL.md sequentially.

---

## Implementation Strategy

### MVP (US1 only — Review-Lite)

Ship Review-Lite in isolation. Scope M+ gets early-catch. Users without superpowers plugin or without interest in split still benefit.

1. Phase 1 + Phase 2 (foundational refs).
2. Phase 3 (US1).
3. **STOP. Validate**: inject Critical bug into scope-M feature, confirm catch before module 2.
4. Skip Phase 4, 5, 6, 7 if time-constrained.

### Incremental delivery (recommended)

1. Phase 1 + Phase 2 → foundational.
2. US1 → Review-Lite shipped. Test independently.
3. US2 → SKILL.md split. Cheaper activation, no behavior change.
4. US3 → delegation wrappers. Test with + without plugin.
5. US4 → back-compat verification.
6. Polish → README/CHANGELOG/verification skeleton.

### Solo developer

All phases sequential. Mark each task complete in tasks.md. Commit after each phase (conventional commits: `feat(task)` for US1/US2/US3, `chore(task)` for polish).

---

## Task Count Summary

| Phase | Tasks | Parallel |
|---|---:|---:|
| 1 Setup | 3 | 2 |
| 2 Foundational | 5 | 5 |
| 3 US1 Review-Lite | 2 | 0 |
| 4 US2 SKILL.md split | 7 | 4 |
| 5 US3 Delegation | 6 | 3 |
| 6 US4 Back-compat | 4 | 0 |
| 7 Polish | 7 | 3 |
| **Total** | **34** | **17 parallelizable** |

**Independent test criteria** (per story):
- US1: scope-M task with injected Critical → caught before next module (SC-001).
- US2: SKILL.md ≤120 lines; topic coverage map 100% (SC-003, SC-004).
- US3: same task with/without plugin → functionally equivalent artifacts (SC-005, SC-006).
- US4: scope-L strict Cycle 1 vs Cycle 2 approvals diff = exactly +N (SC-007, SC-008).

**Suggested MVP**: US1 alone. Ship Review-Lite, skip the rest if needed. US2 and US3 are infrastructure; US4 is verification. US1 is the only user-visible win.
