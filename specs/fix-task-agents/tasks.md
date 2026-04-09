# Tasks: Fix Task Skill Agent Definitions

**Input**: Design documents from `/specs/fix-task-agents/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md

**Tests**: Not applicable -- pure markdown/docs project, no automated tests.

**Organization**: Tasks grouped by user story. All three stories are independent and can execute in parallel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

---

## Phase 1: User Story 1 - Documenter source-read exception (Priority: P1)

**Goal**: Allow Documenter to read source file signatures when implementation logs mention new public APIs, and to create new API docs sections.

**Independent Test**: Read updated documenter.md. Verify it contains: (1) exception clause in Inputs section allowing source reads for new public APIs, (2) exception in Step 2 allowing new API docs sections, (3) all existing content preserved unchanged.

### Implementation for User Story 1

- [x] T001 [P] [US1] Add source-read exception to Inputs section in skills/task/agents/documenter.md
- [x] T002 [P] [US1] Add API docs creation exception to Step 2 in skills/task/agents/documenter.md

**Checkpoint**: Documenter agent definition allows scoped source reads and new API section creation

---

## Phase 2: User Story 2 - Refactorer escalation guidance (Priority: P1)

**Goal**: Add Escalation section so Refactorer knows when to stop and return work to orchestrator for routing to Implementer (sonnet).

**Independent Test**: Read updated refactorer.md. Verify it contains: (1) new Escalation section with >3 files and cross-module restructuring triggers, (2) recommendation to route to Implementer (sonnet), (3) explicit list of simple refactoring that stays on haiku, (4) all existing content preserved unchanged.

### Implementation for User Story 2

- [x] T003 [P] [US2] Add Escalation section after Guidelines in skills/task/agents/refactorer.md

**Checkpoint**: Refactorer agent definition includes clear escalation criteria and routing guidance

---

## Phase 3: User Story 3 - Reviewer security scanning clarity (Priority: P1)

**Goal**: Specify exact security plugin invocation syntax, proper fallback path, and unified finding format.

**Independent Test**: Read updated reviewer.md. Verify it contains: (1) `/security-scanning:security-sast` as exact invocation, (2) fallback to `refs/security-checklist.md`, (3) unified finding format with severity/location/description/recommendation, (4) all existing content preserved unchanged.

### Implementation for User Story 3

- [x] T004 [P] [US3] Rewrite Step 2 security scanning instructions in skills/task/agents/reviewer.md

**Checkpoint**: Reviewer agent definition has unambiguous security scanning invocation and consistent output format

---

## Dependencies & Execution Order

### Phase Dependencies

- All three phases are independent -- no shared infrastructure or foundational work needed
- All tasks are marked [P] -- they can execute in parallel

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies -- edits documenter.md only
- **User Story 2 (P1)**: No dependencies -- edits refactorer.md only
- **User Story 3 (P1)**: No dependencies -- edits reviewer.md only

### Parallel Opportunities

All 4 tasks touch different files and have zero dependencies. Maximum parallelism: all 4 tasks simultaneously.

```bash
# All tasks can run in parallel:
Task: "T001 - Add source-read exception to Inputs in documenter.md"
Task: "T002 - Add API docs creation exception to Step 2 in documenter.md"
Task: "T003 - Add Escalation section in refactorer.md"
Task: "T004 - Rewrite Step 2 security scanning in reviewer.md"
```

Note: T001 and T002 edit the same file but different sections, so they can be applied sequentially within a single edit pass.

---

## Implementation Strategy

### MVP First

All three stories are equally critical (P1) and independent. Implement all three in a single pass.

1. Edit documenter.md (T001 + T002)
2. Edit refactorer.md (T003)
3. Edit reviewer.md (T004)
4. Verify all edits preserve existing content

---

## Summary

- **Total tasks**: 4
- **US1 (Documenter)**: 2 tasks
- **US2 (Refactorer)**: 1 task
- **US3 (Reviewer)**: 1 task
- **Parallel opportunities**: All tasks independent, all can run in parallel
- **MVP scope**: All three stories (minimal scope, all P1)
