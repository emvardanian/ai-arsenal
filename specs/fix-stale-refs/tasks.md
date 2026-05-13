# Tasks: Fix Stale Doc References in Task Skill

**Feature**: fix-stale-refs
**Branch**: `fix-stale-refs`
**Worktree**: `/Users/emmanuil/work/AI/ai-arsenal-fix-stale-refs`
**Generated**: 2026-04-17

## Inputs

- spec.md — 3 user stories (US1 P1, US2 P1, US3 P2), 11 FRs, 9 SCs
- plan.md — XS scope, documentation-only, 5 files
- research.md — edit strategy and preserved-fallback analysis
- data-model.md — 8 Edit Sites across 5 files
- contracts/ — 5 before/after contracts with grep checks
- quickstart.md — verification command set

## Phase 1: Setup

- [X] T001 Verify working directory is the worktree `/Users/emmanuil/work/AI/ai-arsenal-fix-stale-refs` (run `git branch --show-current`; expect `fix-stale-refs`).

## Phase 2: Foundational

- [X] T002 Capture baseline fallback-reference lines before any edit: `grep -n "01-analysis.md" skills/task/agents/reviewer.md skills/task/agents/tester.md skills/task/agents/refs/resume.md skills/task/SKILL.md > /tmp/fix-stale-refs-baseline.txt`.

## Phase 3: User Story 1 - Downstream agents read the correct spec file (P1)

**Goal**: scout, decomposer, committer reference `.task/00-spec.md` instead of deprecated `.task/01-analysis.md`.

**Independent Test**: `grep -n "01-analysis.md" skills/task/agents/scout.md skills/task/agents/decomposer.md skills/task/agents/committer.md` returns zero matches; `grep -n "00-spec.md" ...` returns at least one per file.

- [X] T003 [P] [US1] Edit `skills/task/agents/scout.md` line 14: change `- **`.task/01-analysis.md`** -- full (task type, scope, acceptance criteria, risks)` to `- **`.task/00-spec.md`** -- full (task type, scope, acceptance criteria, risks)`. See `contracts/scout-input-ref.md`.
- [X] T004 [P] [US1] Edit `skills/task/agents/decomposer.md` line 14: change `- **`.task/01-analysis.md`** -- Brief section only` to `- **`.task/00-spec.md`** -- Brief section only`. See `contracts/decomposer-input-ref.md`.
- [X] T005 [P] [US1] Edit `skills/task/agents/committer.md` line 15: change `- `.task/01-analysis.md` -- task type, determines commit prefix` to `- `.task/00-spec.md` -- task type, determines commit prefix`. See `contracts/committer-input-ref.md`.

## Phase 4: User Story 2 - model-tiers doc consistent with three-mode Spec (P1)

**Goal**: tier-distribution count, reader-contract prose, example block, and invariant reflect Spec's three modes (interactive, validate, interview).

**Independent Test**: see `contracts/model-tiers-three-modes.md` Verification block — all seven grep checks satisfied.

- [X] T006 [US2] Edit `skills/task/agents/refs/model-tiers.md` tier-distribution table: change `| haiku | 8 |` row to `| haiku | 7 |` (agents list unchanged).
- [X] T007 [US2] Edit `skills/task/agents/refs/model-tiers.md` reader-contract step 2 under `### Orchestrator`: change "Spec only: interactive or validate, detected by Spec's Mode Detection step" to "Spec only: interactive, validate, or interview, detected by Spec's Mode Detection step".
- [X] T008 [US2] Edit `skills/task/agents/refs/model-tiers.md` example block: change heading "For Spec (two modes):" to "For Spec (three modes):" and append a third reference line `> **Interview mode**: see `agents/refs/model-tiers.md` (entry: `spec, interview`) — sonnet` under the existing interactive/validate lines.
- [X] T009 [US2] Edit `skills/task/agents/refs/model-tiers.md` Invariants section: change `- Spec has exactly two rows (interactive, validate).` to `- Spec has exactly three rows (interactive, validate, interview).`.

## Phase 5: User Story 3 - Documenter references correct impl filename (P2)

**Goal**: `documenter.md` line 16 references `06-impl-{N}.md` (matching SKILL.md and every other agent).

**Independent Test**: `grep -n "04-impl-" skills/task/agents/documenter.md` returns zero matches; `grep -n "06-impl-" skills/task/agents/documenter.md` returns at least one.

- [X] T010 [P] [US3] Edit `skills/task/agents/documenter.md` line 16: change `04-impl-{N}.md` to `06-impl-{N}.md` in the "Exception — new public APIs" sentence. See `contracts/documenter-impl-filename.md`.

## Phase 6: Polish & Cross-Cutting Verification

- [X] T011 Run all quickstart.md grep checks from the worktree root. All expectations in quickstart.md sections 1-6 MUST hold. Fail the phase if any check deviates.
- [X] T012 Compare fallback references to baseline: `diff <(grep -n "01-analysis.md" skills/task/agents/reviewer.md skills/task/agents/tester.md skills/task/agents/refs/resume.md skills/task/SKILL.md) /tmp/fix-stale-refs-baseline.txt`. Expect empty diff (fallback mentions unchanged per FR-009 / SC-008).
- [X] T013 Confirm diff scope: `git diff --name-only main..HEAD -- skills/` returns exactly `skills/task/agents/scout.md`, `skills/task/agents/decomposer.md`, `skills/task/agents/committer.md`, `skills/task/agents/documenter.md`, `skills/task/agents/refs/model-tiers.md` (5 files).
- [X] T014 Confirm no new/deleted files outside specs/: `git diff --diff-filter=AD --name-only main..HEAD -- ':!specs/'` returns empty.

## Dependencies

```
T001 -> T002
T002 -> (T003, T004, T005, T006, T007, T008, T009, T010) all independent edits
(all edits) -> T011 -> T012 -> T013 -> T014
```

User stories are independent. US1 (T003, T004, T005) and US3 (T010) touch distinct files and can run in parallel. US2 (T006-T009) all touch the same file; serialize to avoid diff conflicts.

## Parallel Execution Examples

### Can run in parallel

Batch A (different files, no order dependency): `T003`, `T004`, `T005`, `T010`.

Batch B (same file, serialize): `T006` → `T007` → `T008` → `T009`.

Batch A and Batch B can overlap in time (different files).

### Must run sequentially

`T011` after all edits. `T012` after T011. `T013` after T012. `T014` after T013.

## Implementation Strategy

### MVP Scope

US1 alone (T003-T005) is a meaningful fix — the three most-misleading stale references in downstream agent input lists. If something forces a stop, commit US1 first.

### Incremental Delivery

1. Complete US1 (3 edits, independent).
2. Complete US3 (1 edit, independent).
3. Complete US2 (4 serialized edits within model-tiers.md).
4. Run verification phase 6.

All 10 edit tasks are low-risk and one commit can bundle them (`docs(task): fix stale references after Cycle 1-3 redesign`).

## Task Count Summary

- Setup: 1
- Foundational: 1
- US1: 3 (all [P])
- US2: 4 (sequential, same file)
- US3: 1 (P)
- Polish: 4
- **Total: 14 tasks**

Parallel opportunities: 4 (T003, T004, T005, T010 can all run simultaneously).

## Format Validation

All 14 tasks use the required format: `- [ ] Txxx [P?] [Story?] Description with file path`. Setup/Foundational/Polish tasks carry no [Story] label. US tasks carry `[US1]`, `[US2]`, or `[US3]`.
