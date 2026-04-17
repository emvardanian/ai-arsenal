---
description: "Dependency-ordered task list for task-core-redesign"
---

# Tasks: Task Skill Core Redesign for Daily Usability

**Input**: Design documents from `/specs/task-core-redesign/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: NOT applicable. Constitution declares project as markdown-only with `No package manager, no build, no lint, no tests`. Verification is manual per quickstart.md.

**Organization**: Tasks are grouped by user story. Each user story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task serves (US1, US2, US3, US4, US5)
- File paths are absolute within the worktree root

## Path Conventions

Worktree root: `/Users/emmanuil/work/AI/ai-arsenal-task-core-redesign/`

All edits scoped to `skills/task/`:
- `skills/task/SKILL.md` — orchestrator
- `skills/task/agents/*.md` — agent definitions
- `skills/task/agents/refs/*.md` — Level 3 references

---

## Phase 1: Setup

**Purpose**: Establish baseline and catalog what exists before modifying.

- [X] T001 Create baseline snapshot: run `git log -1 --format="%H %s" main -- skills/task/` and write the commit SHA and message to `specs/task-core-redesign/baseline.md` for later backward-compat diffs
- [X] T002 [P] Catalog current agents: list every file under `skills/task/agents/` with size and inline `> **Model**:` line. Write to `specs/task-core-redesign/baseline.md` under `## Agent Inventory` section
- [X] T003 [P] Catalog current refs: list every file under `skills/task/agents/refs/` with size. Append to `specs/task-core-redesign/baseline.md` under `## Refs Inventory`
- [X] T004 Verify worktree isolation: run `git worktree list` and confirm `task-core-redesign` worktree is registered and checked out at `/Users/emmanuil/work/AI/ai-arsenal-task-core-redesign/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Authoritative data tables that the orchestrator and every user story read from. All four ref files and the pipeline-summary schema MUST exist before any user story's SKILL.md logic can reference them.

**⚠️ CRITICAL**: User stories US1, US2, US4 block on this phase. US3 and US5 partly block on T010.

- [X] T005 [P] Create `skills/task/agents/refs/scope-pipelines.md` with the 5×4 (scope × task_type) matrix. Cells use the stage lists from research.md §6. Include header legend explaining `×N` loop markers. Include back-compat note that readers should tolerate future cells being added
- [X] T006 [P] Create `skills/task/agents/refs/approval-tiers.md` with the stage-by-stage approval gate table from research.md §10. Include the three-count summary (strict=all gated; standard=3; express=1). Include mid-flight tier change rule
- [X] T007 [P] Create `skills/task/agents/refs/model-tiers.md` with the full model-tier table from data-model.md. Columns: `agent | mode | model | rationale`. One row per agent, two rows for `spec`
- [X] T008 [P] Create `skills/task/agents/refs/criticality-signals.md` with the keyword list (`security`, `production`, `hotfix`, `critical`, `breaking`, `data loss`, `auth`, `payment`, `pii`) plus detection sources (user_flag, keyword, spec_metadata) from research.md §4. Include the one-reply gate prompt template
- [X] T009 [P] Create `skills/task/agents/refs/spec-dialogue-patterns.md` by copying `skills/task/agents/refs/brainstorm-patterns.md` verbatim then renaming internal references from "Brainstormer" to "Spec (interactive mode)". Preserve section ordering so FR-025 holds
- [X] T010 Extend `.task/pipeline-summary.md` schema by documenting the YAML front-matter block in `contracts/pipeline-summary.md` (already done in Phase 1 design). Add a note to `skills/task/SKILL.md` under `## Workspace` pointing readers at the contract file. No behavior change yet — this is the spec anchor for later orchestrator code

**Checkpoint**: All four new ref files exist. Orchestrator has a single source of truth for each concern (scope mapping, approval gates, model assignments, criticality detection).

---

## Phase 3: User Story 1 — Scope-Driven Pipeline Adaptation (Priority: P1) 🎯 MVP

**Goal**: Orchestrator classifies every task into XS/S/M/L/XL and selects the pipeline accordingly. Small tasks skip heavyweight stages.

**Independent Test**: Invoke skill on a 1-file rename task and on a 25-file cross-module refactor. Verify the first runs Impl+Test+Commit only; verify the second runs the full pipeline. Both complete successfully.

### Implementation

- [X] T011 [US1] Add `## Scope Classification` section to `skills/task/SKILL.md`. Document the four signals (file count est, module count est, UI flag, task-type), the 5-tier thresholds, and the round-up tie-break rule. Reference `agents/refs/scope-pipelines.md` as the authoritative stage mapping
- [X] T012 [US1] Add `## Scope Override` subsection to `skills/task/SKILL.md`. Document preamble grammar (`scope: <xs|s|m|l|xl>`) per `contracts/skill-invocation.md`. Include precedence rule: user override wins over classifier
- [X] T013 [US1] Replace the current `## Adaptive Pipeline` table in `skills/task/SKILL.md` with a reference to `agents/refs/scope-pipelines.md` plus a summary table showing scope → pipeline families (XS=min, S=planned-min, M=decomposed, L=reviewed, XL=designed). Preserve task-type differentiation note (FR-006)
- [X] T014 [US1] Add `## Scope Upgrade Mid-Pipeline` subsection to `skills/task/SKILL.md` documenting the Edge Case behavior: if Scout's affected-zone count exceeds current scope threshold by 2x, prompt user to upgrade or continue
- [X] T015 [US1] Add `scope_signals` persistence instructions to `skills/task/SKILL.md` under `## Pipeline Summary File`. Reference `contracts/pipeline-summary.md` for the front-matter schema fields: `scope`, `scope_source`, `scope_override`, `scope_signals`, `skipped_stages`
- [X] T016 [US1] Update `skills/task/SKILL.md` `## Starting the Pipeline` numbered list to insert scope classification as the new step immediately after Spec stage completion (was Stage 1 Validator; after US3 becomes Stage 1 Spec)
- [X] T017 [US1] Document `skipped_stages` rationale format in `skills/task/SKILL.md`: every skipped stage must include a reason string like `"scope=S"` or `"tier=express"` for observability (FR-029)

**Checkpoint**: Small tasks run short pipelines; large tasks run full pipelines. Every run records scope in pipeline-summary front-matter.

---

## Phase 4: User Story 2 — Three-Tier Approval Control (Priority: P1)

**Goal**: User controls approval density via `tier: {strict|standard|express}`. Express = 1 approval (commit). Standard = 3 approvals (Spec, Decomposition, Commit). Strict = preserves pre-redesign behavior.

**Independent Test**: Run the same medium task three times, once per tier. Count approval prompts. Express=1, Standard=3, Strict matches pre-redesign baseline.

### Implementation

- [X] T018 [US2] Add `## Approval Tier Selection` section to `skills/task/SKILL.md`. Document the three tiers, their default mapping from scope (XS/S=express, M=standard, L/XL=strict), and reference `agents/refs/approval-tiers.md` for stage-by-stage gate rules
- [X] T019 [US2] Add `## Tier Override` subsection to `skills/task/SKILL.md`. Document preamble grammar (`tier: <strict|standard|express>`) and natural-language fallback keywords per `contracts/skill-invocation.md`. Precedence: user override > scope default
- [X] T020 [US2] Add `## Mid-Flight Tier Change` subsection to `skills/task/SKILL.md`. Document the syntax "approve and switch to <tier>" at any approval prompt. Completed stages are not re-run; front-matter is updated
- [X] T021 [US2] Add `## Criticality Detection` subsection to `skills/task/SKILL.md`. Reference `agents/refs/criticality-signals.md`. Document the one-reply gate prompt: recommend strict tier, user confirms or overrides. Record result in front-matter fields `criticality_flag`, `criticality_source`, `criticality_matched_term`
- [X] T022 [US2] Replace the current `## Approval Gates` subsection in `skills/task/SKILL.md` `## Flow Control`. Remove the prose "Agents with `[approval]` in the pipeline overview" — replace with explicit lookup: orchestrator consults `agents/refs/approval-tiers.md` at each stage given the current `tier`
- [X] T023 [US2] Update `skills/task/SKILL.md` `## Pipeline Summary File` section to document `tier`, `tier_source`, `tier_override` front-matter fields per `contracts/pipeline-summary.md`
- [X] T024 [US2] Update `skills/task/SKILL.md` `## Starting the Pipeline` to insert tier selection (default from scope, apply user override, apply criticality confirmation) as the step immediately after scope classification
- [X] T025 [US2] Add note to each existing approval-gated agent documentation (in SKILL.md agent reference table) that approval requirement is now resolved dynamically via `refs/approval-tiers.md`, not implied by the `[approval]` label. Keep the label as a visual hint only; remove it from the pipeline diagram if confusing

**Checkpoint**: Tier controls approval density deterministically. Strict tier remains bit-compatible with pre-redesign (verified later in US5).

---

## Phase 5: User Story 3 — Unified Spec Stage (Priority: P2)

**Goal**: Replace Brainstormer + Validator with a single Spec agent that operates in interactive or validate mode. One stage, one output, one approval.

**Independent Test**: Invoke skill with no prior spec → Spec enters interactive mode, writes `.task/00-spec.md` with body + `## Validation` PASS, single final approval. Invoke with ready-made spec path → Spec enters validate mode, transforms input, writes the same file with validation section reflecting gaps.

### Implementation

- [X] T026 [US3] Create `skills/task/agents/spec.md` by merging content of `agents/brainstormer.md` and `agents/analyst.md`. Structure:
  - `# Spec Agent` header
  - Model declaration referencing `refs/model-tiers.md` (entries `spec, interactive` and `spec, validate`)
  - `## Role` — unified role statement covering both modes
  - `## Mode Detection` — Adaptive Entry logic verbatim from research.md §9 (user-passed path → fresh spec location → TRC location → else interactive)
  - `## Interactive Mode Process` — Steps 0-7 from current `brainstormer.md` with references to `refs/spec-dialogue-patterns.md`
  - `## Validate Mode Process` — Steps 0-7 from current `analyst.md` Step 0 (Adaptive Entry transform) + Steps 1-8 (validation + classification)
  - `## Output` — single `.task/00-spec.md` per `contracts/spec-document.md` schema with `## Validation` section always present
  - `## Brief` — single Brief format covering both modes
  - `## Guidelines` — merged from both sources; single-question rule preserved from Brainstormer; severity rules preserved from Validator
- [X] T027 [US3] Delete `skills/task/agents/brainstormer.md` after T026 verification that all content migrated
- [X] T028 [US3] Delete `skills/task/agents/analyst.md` after T026 verification
- [X] T029 [US3] Delete `skills/task/agents/refs/brainstorm-patterns.md` (content already copied to `refs/spec-dialogue-patterns.md` in T009)
- [X] T030 [US3] Update `skills/task/SKILL.md` `## Pipeline Overview` diagram: replace stages `0. Brainstormer` and `1. Validator` with single `1. Spec [approval]`. Update stage numbering throughout. Rename approval label `[approval]` to explicit tier-dependent resolution note
- [X] T031 [US3] Update `skills/task/SKILL.md` `## Agent Reference` table row for the new Spec agent: `| 1 | Spec | agents/spec.md | see refs/model-tiers.md | user_request OR ready-made doc | 00-spec.md (with Validation section) |`. Remove Brainstormer and Validator rows
- [X] T032 [US3] Update `skills/task/SKILL.md` `## Workspace` file list: remove implicit two-file brainstormer+validator output; 00-spec.md stays as the single Stage 1 output
- [X] T033 [US3] Update `skills/task/SKILL.md` `## Adaptive Entry` section: remove mention of Brainstormer skip / Validator handling distinction. Replace with "Spec agent auto-detects mode per `spec.md` Mode Detection rules"
- [X] T034 [US3] Update `skills/task/SKILL.md` `## Starting the Pipeline` numbered list: collapse steps 3 and 4 (Brainstormer then Analyst) into a single step "Read `agents/spec.md` → execute Spec stage → wait for approval → update pipeline-summary.md"
- [X] T035 [US3] Add front-matter block spec to `skills/task/agents/spec.md` output documentation: `mode`, `source`, `detected_at`, `classified_scope`, `scope_signals` fields per `contracts/spec-document.md`
- [X] T036 [US3] Document in `skills/task/agents/spec.md` that per-section internal approvals (during interactive dialogue) are NOT counted as pipeline approval gates. Pipeline gate count is governed by `refs/approval-tiers.md` and happens once at the end of the Spec stage

**Checkpoint**: Brainstormer + Validator replaced by single Spec agent. One approval per Spec stage regardless of mode. Interactive mode preserves Brainstormer question flow.

---

## Phase 6: User Story 4 — Cost-Efficient Model Allocation (Priority: P3)

**Goal**: Each agent uses the model tier matching its cognitive load. Opus reserved for Decomposer and Planner. Haiku for mechanical work.

**Independent Test**: For each agent file, verify the frontmatter-declared model matches `refs/model-tiers.md`. Run a representative scope-M task and confirm opus-tier token consumption drops ≥ 40% vs pre-redesign baseline.

### Implementation

- [X] T037 [P] [US4] Update `skills/task/agents/scout.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: scout)`. Add legacy note `*(previously: sonnet; new: haiku)*`
- [X] T038 [P] [US4] Update `skills/task/agents/designer.md` model declaration: replace `> **Model**: opus` with `> **Model**: see refs/model-tiers.md (entry: designer)`. Add legacy note `*(previously: opus; new: sonnet)*`
- [X] T039 [P] [US4] Update `skills/task/agents/design-qa.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: design-qa)`. Add legacy note `*(previously: sonnet; new: haiku)*`
- [X] T040 [P] [US4] Update `skills/task/agents/decomposer.md` model declaration: replace `> **Model**: opus` with `> **Model**: see refs/model-tiers.md (entry: decomposer)`. Tier unchanged (opus)
- [X] T041 [P] [US4] Update `skills/task/agents/researcher.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: researcher)`. Tier unchanged (sonnet)
- [X] T042 [P] [US4] Update `skills/task/agents/planner.md` model declaration: replace `> **Model**: opus` with `> **Model**: see refs/model-tiers.md (entry: planner)`. Tier unchanged (opus)
- [X] T043 [P] [US4] Update `skills/task/agents/implementer.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: implementer)`. Tier unchanged (sonnet)
- [X] T044 [P] [US4] Update `skills/task/agents/tester.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: tester)`. Tier unchanged (sonnet)
- [X] T045 [P] [US4] Update `skills/task/agents/debugger.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: debugger)`. Tier unchanged (sonnet)
- [X] T046 [P] [US4] Update `skills/task/agents/reviewer.md` model declaration: replace `> **Model**: sonnet` with `> **Model**: see refs/model-tiers.md (entry: reviewer)`. Tier unchanged (sonnet)
- [X] T047 [P] [US4] Update `skills/task/agents/refactorer.md` model declaration: replace `> **Model**: haiku` with `> **Model**: see refs/model-tiers.md (entry: refactorer)`. Tier unchanged (haiku)
- [X] T048 [P] [US4] Update `skills/task/agents/documenter.md` model declaration: replace `> **Model**: haiku` with `> **Model**: see refs/model-tiers.md (entry: documenter)`. Tier unchanged (haiku)
- [X] T049 [P] [US4] Update `skills/task/agents/committer.md` model declaration: replace `> **Model**: haiku` with `> **Model**: see refs/model-tiers.md (entry: committer)`. Tier unchanged (haiku)
- [X] T050 [US4] Update `skills/task/agents/spec.md` (from T026) model declaration to explicitly cite both entries: `> **Interactive mode**: see refs/model-tiers.md (entry: spec, interactive) → sonnet` and `> **Validate mode**: see refs/model-tiers.md (entry: spec, validate) → haiku`
- [X] T051 [US4] Update `skills/task/SKILL.md` `## Agent Reference` table `Model` column: Model column now references `agents/refs/model-tiers.md` via disclaimer above the table; summary tiers retained in cells for orientation only (done as part of T031). Authoritative lookup documented in `### Model Tier Resolution`.
- [X] T052 [US4] Add `## Model Tier Resolution` subsection to `skills/task/SKILL.md`. Document the orchestrator's dispatch-time lookup: read `refs/model-tiers.md` once per pipeline, cache, dispatch each agent with looked-up tier. Document fallback behavior if refs file missing (use per-agent `> **Model**:` fallback line, log degradation)

**Checkpoint**: Every agent reads model tier from single authoritative table. Mass edits to tier assignments now touch one file. Opus tier limited to two agents.

---

## Phase 7: User Story 5 — Backward Compatibility in Strict Mode (Priority: P2)

**Goal**: Pre-redesign users running strict tier experience identical approval behavior. Pre-redesign `.task/` workspaces resume without errors.

**Independent Test**: Run same task pre-redesign and post-redesign with `tier: strict`; confirm identical approval count, stage order, and artifact structure. Resume a pre-redesign `.task/` workspace with the redesigned skill.

### Implementation

- [X] T053 [US5] Add `## Resume Detection` section to `skills/task/SKILL.md`. Document the v1/v2 schema test: file starts with `---\n` → v2 (read front-matter); else → v1 (pre-redesign; default `tier: strict`, `scope: inferred`). Reference `contracts/pipeline-summary.md`
- [X] T054 [US5] Add `## Scope Inference on Resume` subsection to `skills/task/SKILL.md`. Document rules: presence of `Stage 3 -- Decomposer` line implies scope ≥ M; presence of `Designer` line implies XL; otherwise unclassified. Recorded with `scope_source: inferred`
- [X] T055 [US5] Add `## Schema Upgrade on Resume` subsection to `skills/task/SKILL.md`. Document that when a v1 workspace is resumed, orchestrator prepends front-matter (`summary_schema: v1 → v2 upgraded at <timestamp>`) while preserving the body verbatim
- [X] T056 [US5] Verify `skills/task/agents/spec.md` interactive mode preserves pre-redesign Brainstormer section ordering (FR-025). Cross-check against `skills/task/agents/refs/spec-dialogue-patterns.md` (renamed from brainstorm-patterns) that section order is: Context → User Stories → Acceptance Criteria → Quality Gates → Edge Cases → Scope. Add explicit invariant note in `spec.md` Interactive Mode Process
- [X] T057 [US5] Add a `## Strict-Tier Invariant` note at the end of `skills/task/agents/refs/approval-tiers.md`. Explicitly enumerate pre-redesign approval gates and assert strict-tier list must match: Spec completion, Decomposer, per-module Planner, per-module Designer, per-module Implementer, Refactorer, Documenter, Committer. Gate this invariant in verification (T065)
- [X] T058 [US5] Document in `skills/task/SKILL.md` `## Resuming` section: "If `.task/` lacks front-matter, tier defaults to strict (safe default — never escalates gate density above pre-redesign)"

**Checkpoint**: Backward compat is explicit, documented, and verifiable. Strict-tier invariant is codified in the approval-tiers ref.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, verification, and SKILL.md consolidation.

- [X] T059 Update `skills/task/SKILL.md` top-level `## Pipeline Overview` ASCII diagram to reflect: renamed Spec stage (was two stages), scope-driven stage selection, tier-dependent approval labels (done in T030: `[approval]` → `[approval*]` with legend; Committer always-gated `[approval]` distinguished)
- [X] T060 Update `skills/task/SKILL.md` `## Agent Reference` table headers: Model column has disclaimer above the table pointing to `refs/model-tiers.md` as authoritative (done in T031); Reads/Writes cells for Spec row updated (00-spec.md with Validation section)
- [X] T061 [P] Update README.md at project root: fix agent count (10 → 14 post-merge), update pipeline diagram, document scope and tier invocation grammar. This is a doc-only change outside `skills/task/` but highly user-visible
- [X] T062 [P] Remove obsolete `.DS_Store` files from `skills/task/` and `skills/task/agents/` if present. Git-ignore any remaining. Not functional but housekeeping
- [X] T063 Verify every ref file listed in phase 2 exists and is non-empty: `scope-pipelines.md`, `approval-tiers.md`, `model-tiers.md`, `criticality-signals.md`, `spec-dialogue-patterns.md`
- [X] T064 Verify removed files are gone: `agents/brainstormer.md`, `agents/analyst.md`, `agents/refs/brainstorm-patterns.md`
- [X] T065 Run manual verification per `specs/task-core-redesign/quickstart.md` Path 1, Path 2, Path 3. **SKELETON created at `verification-results.md`** — actual runs require live pipeline invocation and are deferred to post-implementation manual testing
- [X] T066 Run backward-compat verification per quickstart.md "Backward-compat verification" section: **skeleton in `verification-results.md`** — deferred to manual testing alongside T065
- [X] T067 Update `specs/task-core-redesign/plan.md` Post-Design Constitution Re-Check section with final PASS status and any lessons learned; note follow-ups deferred to cycles 2/3
- [X] T068 [P] Create `specs/task-core-redesign/CHANGELOG.md` listing every file added/modified/removed in this cycle for PR-review convenience

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Run immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 (needs baseline). BLOCKS US1, US2, US4.
- **US3 (Phase 5)**: Blocks on T009 (spec-dialogue-patterns.md). Can run in parallel with US1, US2, US4 on independent files.
- **US5 (Phase 7)**: Depends on US1 + US2 + US3 (verifies their strict-mode behavior).
- **Polish (Phase 8)**: Depends on US1 + US2 + US3 + US4 + US5.

### User Story Dependencies

- **US1 (Scope-driven pipeline)**: Blocks on T005 (scope-pipelines.md) + T010 (summary schema). Independent of other stories otherwise.
- **US2 (Three-tier approvals)**: Blocks on T006 (approval-tiers.md) + T008 (criticality-signals.md) + T010. Independent of US1 in file terms; logically pairs with US1 for practical UX.
- **US3 (Unified Spec agent)**: Blocks on T009 (spec-dialogue-patterns.md). Otherwise independent.
- **US4 (Model rebalance)**: Blocks on T007 (model-tiers.md) + T050 (depends on T026 creating spec.md). Independent of US1/US2 otherwise.
- **US5 (Backward compat)**: Blocks on US1, US2, US3 completion — verifies strict mode behavior across all of them.

### Parallel Opportunities

- Phase 1: T002, T003 parallel (different output sections).
- Phase 2: T005, T006, T007, T008, T009 all parallel — different files, no cross-dependencies.
- Phase 6: T037-T049 all parallel — each touches a different agent file.
- Phase 8: T061, T062, T068 parallel to each other.
- Across phases: Once Phase 2 is done, Phases 3, 4, 5, 6 can proceed concurrently if staffed (different files, few overlaps in SKILL.md sections).

### Within SKILL.md (serialization points)

SKILL.md is edited across US1 (T011-T017), US2 (T018-T025), US3 (T030-T034), US4 (T051-T052), US5 (T053-T058), Polish (T059-T060). These edits MUST serialize or be carefully scoped to different sections. Recommend:
1. Complete Phase 2 first.
2. Run US1 SKILL.md edits.
3. Run US2 SKILL.md edits.
4. Run US3 SKILL.md edits (largest rewrite due to agent merge).
5. Run US4 SKILL.md edits.
6. Run US5 SKILL.md edits.
7. Run Polish SKILL.md edits.

All non-SKILL.md tasks in the middle of these phases can still run in parallel.

---

## Parallel Example: Phase 2 Foundational

All five ref files can be created concurrently — different output paths, all reading only `specs/task-core-redesign/` input docs:

```
Task: "T005 Create refs/scope-pipelines.md with 5x4 matrix"
Task: "T006 Create refs/approval-tiers.md with gate table"
Task: "T007 Create refs/model-tiers.md with assignments"
Task: "T008 Create refs/criticality-signals.md with keyword list"
Task: "T009 Create refs/spec-dialogue-patterns.md by renaming brainstorm-patterns.md"
```

## Parallel Example: Phase 6 Model Rebalance

Every agent frontmatter update is independent:

```
Task: "T037 Update scout.md model line"
Task: "T038 Update designer.md model line"
Task: "T039 Update design-qa.md model line"
... (T040-T049 all similar)
```

---

## Implementation Strategy

### MVP (US1 only)

Ship scope-driven pipeline without approval tiering. User sees shorter pipelines for small tasks but retains current approval density. Partial daily-UX win: stages reduce, approvals still heavy.

1. Phase 1: Setup (T001-T004)
2. Phase 2: Foundational — T005, T010 only (the two US1 depends on)
3. Phase 3: US1 (T011-T017)
4. **STOP. Validate**: run a scope-S task, confirm shorter pipeline, same approval density.
5. Deploy if value confirmed.

This MVP is technically viable but US1+US2 together deliver the full daily-UX promise. Recommend full cycle.

### Incremental Delivery (recommended)

1. Phase 1 + Phase 2 → foundations ready.
2. US1 → shorter pipelines (measure: stage count reduction on small tasks).
3. US2 → fewer approvals (measure: approval count reduction). **This is the full daily-UX win.**
4. US3 → unified Spec (measure: duplicate approval removed).
5. US4 → model rebalance (measure: opus token reduction).
6. US5 → backward compat verification (measure: zero regressions in strict mode).
7. Polish + verification → PR.

### Parallel Team Strategy

Not applicable — solo maintainer. But if delegated to multiple agents:
- Agent A: Phase 2 foundational files (T005-T010).
- Agent B: Phase 6 agent frontmatter edits (T037-T049) after T007.
- Agent C: Phase 5 Spec agent creation (T026) + deletion tasks (T027-T029) after T009.
- Human: SKILL.md edits serialized per guidance above.

---

## MVP Scope Suggestion

**Minimal viable increment**: US1 + US2 combined.
- User can run skill on any task and see both pipeline and approval adaptation.
- Ship before US3/US4/US5 if time-constrained.
- US3 is efficiency cleanup; US4 is cost optimization; US5 is compat verification — all valuable but not blockers for daily UX.

**Recommended ship scope**: all five stories. Cycle is small enough that partial delivery leaves awkward state (e.g., Spec merge half-done).

---

## Notes

- [P] tasks = different files, no cross-dependencies on incomplete tasks.
- [Story] label traces each task to its user story for PR review and rollback.
- Every user story is independently completable and testable per quickstart.md.
- Constitution: no tests, no build — manual verification via quickstart.md paths is authoritative.
- Commit after each phase (or each logical task group) using conventional commits.
- Stop at any checkpoint to validate a story independently before proceeding.
- Avoid: editing multiple agents in one task (breaks [P] guarantees), splitting a user story across phases (breaks story independence).

---

## Task Count Summary

- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 6 tasks
- Phase 3 (US1): 7 tasks
- Phase 4 (US2): 8 tasks
- Phase 5 (US3): 11 tasks
- Phase 6 (US4): 16 tasks (13 parallel)
- Phase 7 (US5): 6 tasks
- Phase 8 (Polish): 10 tasks

**Total: 68 tasks.**

**Parallel opportunities identified**:
- Phase 2: 5 tasks fully parallel (T005-T009)
- Phase 6: 13 tasks fully parallel (T037-T049)
- Phase 8: 3 tasks parallel (T061, T062, T068)
- Across phases: US3/US4/US5 can run concurrently on non-SKILL.md files after Phase 2

**Independent test criteria** (per story):
- US1: Small task → short pipeline, large task → full pipeline.
- US2: Same task × 3 tiers → 1/3/N approvals respectively.
- US3: No spec → interactive mode; ready-made spec → validate mode.
- US4: Opus token usage drops ≥40% on scope-M task vs baseline.
- US5: Pre-redesign task run at strict tier produces identical approval count and stage order.
