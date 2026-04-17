---
description: "Dependency-ordered task list for task-cycle3-daily-ux"
---

# Tasks: Task Skill Cycle 3 — Daily UX

**Input**: Design documents from `/specs/task-cycle3-daily-ux/`
**Prerequisites**: spec, plan, research, data-model, contracts (4), quickstart

**Tests**: N/A (constitution: markdown-only, manual verification per `quickstart.md`).

**Organization**: Tasks grouped by user story.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [X] T001 Create baseline snapshot in `specs/task-cycle3-daily-ux/baseline.md` (main SHA, SKILL.md size, ref count).

## Phase 2: Foundational

- [X] T002 [P] Create `skills/task/agents/refs/prefs.md` with precedence rules, schema v1, example files, fail-safe rules.
- [X] T003 [P] Create `skills/task/agents/refs/batch-approval.md` with eligibility, prompt UX, state machine, response parsing.
- [X] T004 [P] Create `skills/task/agents/refs/slash-commands.md` with 4 command registry + entry-point recording.
- [X] T005 Update `skills/task/agents/refs/approvals.md` with batch approval cross-reference + `approval_mode` field note.

## Phase 3: User Story 1 — Slash Commands (P1)

- [X] T006 [P] [US1] Create `.claude/commands/task-quick.md` per `contracts/slash-commands.md`.
- [X] T007 [P] [US1] Create `.claude/commands/task-fix.md`.
- [X] T008 [P] [US1] Create `.claude/commands/task-feature.md`.
- [X] T009 [P] [US1] Create `.claude/commands/task-full.md`.
- [X] T010 [US1] Update `skills/task/SKILL.md`: add `## Slash Commands` section (4 commands, entry-point recording); update Starting the Pipeline step 2 to parse slash entry_point.

## Phase 4: US2 — Preferences Persistence (P2)

- [X] T011 [US2] Update `skills/task/SKILL.md`: add `## User Preferences` section referencing `refs/prefs.md` with precedence summary; update Starting the Pipeline step 2b to load prefs (global first, project second).

## Phase 5: US3 — Batch Approval (P2)

- [X] T012 [US3] Update `skills/task/agents/refs/approvals.md` Flow Control section with batch approval prompt + state machine; cross-reference `refs/batch-approval.md`.

## Phase 6: US4 — README Autosync (P3)

- [X] T013 [P] [US4] Create `scripts/sync-readme.sh` — bash + optional jq; 4 generator functions (agent-count, agent-table, scope-summary, pipeline-diagram); atomic write; exit codes 0/1/2/3.
- [X] T014 [P] [US4] Create `scripts/install-hooks.sh` — opt-in pre-commit installer.
- [X] T015 [US4] Add AUTOSYNC markers to `README.md` around 4 regions (agent-count, agent-table, scope-summary, pipeline-diagram).

## Phase 7: US5 — Back-compat Verification

- [X] T016 [US5] Update `skills/task/agents/refs/resume.md` with v2.1 defaults for missing Cycle 3 fields (`approval_mode: per_module`, `prefs_source: none`, `entry_point: none`).

## Phase 8: Polish

- [X] T017 [P] Update `README.md` top description to reflect 15 agents + daily-UX (post autosync region insertion).
- [X] T018 [P] Create `specs/task-cycle3-daily-ux/CHANGELOG.md`.
- [X] T019 [P] Create `specs/task-cycle3-daily-ux/verification-results.md` skeleton.
- [X] T020 Update `specs/task-cycle3-daily-ux/plan.md` Post-Design Constitution Re-Check.

## Dependencies

Phase 1 → Phase 2 → Phases 3-7 (mostly parallel at file level) → Phase 8.

SKILL.md serialization: T010 (US1) → T011 (US2).
