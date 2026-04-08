# Tasks: Task Skill -- Brainstorm Phase (Stage 0)

**Input**: Design documents from `specs/task-brainstorm-phase/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md, research.md

**Tests**: Not applicable -- pure markdown project, no automated tests (per constitution).

**Organization**: Tasks grouped by user story. US1+US4 and US2+US3 are combined because they map to the same files and are inseparable in implementation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Create reference doc and update terminal agents. Blocks all user story work.

- [x] T001 Create dialogue patterns reference doc at skills/task/agents/refs/brainstorm-patterns.md with six patterns: one-question rule, multiple-choice preferred, red flags table, incremental validation, propose approaches (2-3 variants with trade-offs), scope decomposition. Format as markdown reference -- no frontmatter, no output format template. Source patterns from design doc sections on Dialogue Patterns (lines 59-66) and refs/brainstorm-patterns.md description (lines 141-151)
- [x] T002 [P] Update skills/task/agents/documenter.md -- no direct 00-summary.md references found (uses .task/*.md wildcard). Rename handled in SKILL.md (T013)
- [x] T003 [P] Update skills/task/agents/committer.md -- no direct 00-summary.md references found (uses .task/*.md wildcard). Rename handled in SKILL.md (T013)

**Checkpoint**: Reference doc exists, terminal agents reference pipeline-summary.md

---

## Phase 2: US1 + US4 - Brainstormer Agent (Priority: P1 + P2) MVP

**Goal**: Create the new Stage 0 agent that conducts interactive brainstorm dialogue and produces a TRC-format spec. Includes dialogue patterns (US4) which are inseparable from the core brainstorm flow.

**Independent Test**: Invoke `/task` with a brief feature description. Verify Brainstormer starts dialogue, asks structured questions one at a time, presents sections for approval, and produces valid `.task/00-spec.md` with all TRC sections.

### Implementation

- [x] T004 [US1] Create skills/task/agents/brainstormer.md with agent metadata header: Model opus, Reads user_request, Writes .task/00-spec.md, Refs brainstorm-patterns.md. Follow existing agent format from skills/task/agents/analyst.md (current version) as structural reference
- [x] T005 [US1] Add dialogue sequence instructions to skills/task/agents/brainstormer.md: (1) understand context -- what and why, 1-3 questions, (2) user stories -- form one at a time with P1/P2/P3 priorities, (3) acceptance criteria -- per story with IDs AC-1/AC-2, (4) quality gates -- what blocks release, (5) edge cases -- boundary conditions, (6) scope -- explicit IN/OUT lists. Include section-by-section approval loop: present result, ask "approve or revise?", if revise then update and re-present. Include session preservation: write partial progress to 00-spec.md so interrupted sessions can resume
- [x] T006 [US1] Add output format template to skills/task/agents/brainstormer.md matching TRC spec structure from data-model.md: Summary, User Stories (with IDs, priorities, ACs), Quality Gates (with IDs), Edge Cases (with IDs), Scope IN/OUT. Add Brief template (5-10 lines) for downstream consumption by Analyst

**Checkpoint**: brainstormer.md is complete with metadata, dialogue sequence, approval loop, output format, and Brief template. Can be read by SKILL.md orchestrator.

---

## Phase 3: US2 + US3 - Analyst Validation + Adaptive Entry (Priority: P1)

**Goal**: Rewrite the Analyst agent from "analyze raw request" to "validate spec." Add transformation capability for ready-made specs (adaptive entry).

**Independent Test**: Provide a 00-spec.md with a known gap (missing AC). Verify Analyst identifies the gap with correct severity, offers user fix/ignore/return options. Also test with a non-TRC format input and verify transformation to TRC.

### Implementation

- [x] T007 [US3] Rewrite skills/task/agents/analyst.md with updated metadata: Model opus (unchanged), Reads .task/00-spec.md (was user_request), Writes .task/01-analysis.md (unchanged). Replace existing instructions with validation process: (1) completeness check -- every US has ACs, quality gates defined, scope explicit, (2) consistency check -- stories don't contradict, quality gates align, (3) edge case review -- boundary conditions covered, (4) classification -- type (feature/bugfix/refactor/hotfix), scope (small/medium/large/critical), pipeline stages, (5) gap report with severities: Gap/Conflict/Weak/OK. Add flow control: if gaps found offer user 3 options (fix in spec / ignore / return to Brainstormer), if all OK add classification and proceed. Update Brief template to validation summary format
- [x] T008 [US2] Add adaptive entry handling section to skills/task/agents/analyst.md: when Brainstormer was skipped (ready-made spec provided), first transform input document into TRC-format 00-spec.md (map source sections to TRC structure: Summary, User Stories, Quality Gates, Edge Cases, Scope), then run normal validation process. Handle non-TRC formats: infer sections from structure, generate missing section stubs marked for validation

**Checkpoint**: analyst.md validates specs, produces gap reports, handles ready-made spec transformation. Brief format preserved for downstream compatibility.

---

## Phase 4: US5 - Scope Decomposition (Priority: P3)

**Goal**: Add ability for Brainstormer to detect oversized tasks and propose sub-project decomposition.

**Independent Test**: Invoke `/task` with a request spanning multiple independent systems. Verify Brainstormer proposes splitting into sub-projects and proceeds with only the first one.

### Implementation

- [x] T009 [US5] Add scope decomposition section to skills/task/agents/brainstormer.md: after initial context questions, evaluate if request spans multiple independent domains. If too large for single spec: (1) propose sub-project split with clear boundaries, (2) present to user for approval, (3) if approved proceed with first sub-project only, (4) note deferred sub-projects in scope OUT section of 00-spec.md

**Checkpoint**: Brainstormer handles both normal-sized and oversized tasks.

---

## Phase 5: SKILL.md Orchestrator Update

**Purpose**: Update the orchestrator to integrate Stage 0, adaptive entry, and renamed pipeline summary.

- [x] T010 Update skills/task/SKILL.md pipeline overview section: add Stage 0 (Brainstormer) with `[approval]` tag before Stage 1. Rename Stage 1 display from "Analyst" to "Validate"
- [x] T011 Update skills/task/SKILL.md agent reference table: add Brainstormer row (Stage 0, Model opus, File agents/brainstormer.md, Reads user_request, Writes 00-spec.md). Update Analyst row (Reads 00-spec.md, description "validate spec and classify task")
- [x] T012 Update skills/task/SKILL.md progress tracker format: add `[Brainstorm]` as first stage. Example: `[▶ Brainstorm] -> [ Validate] -> [ Research] -> [ Plan] -> ...`
- [x] T013 Update skills/task/SKILL.md workspace section: add `00-spec.md` entry (brainstorm output / spec from adaptive entry). Rename `00-summary.md` to `pipeline-summary.md` in workspace listing and pipeline summary section
- [x] T014 Add new "Adaptive Entry" section to skills/task/SKILL.md: describe skip-Brainstormer logic with detection order (1. explicit file path in user request, 2. fresh spec at docs/superpowers/specs/ within 1 hour by mtime, 3. TRC spec at .trc/ or docs/). Describe what happens when spec detected (skip to Analyst), how Analyst handles transformation

**Checkpoint**: SKILL.md reflects complete updated pipeline with Stage 0, adaptive entry, and pipeline-summary.md naming.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verify consistency across all modified files.

- [x] T015 Cross-reference validation: verify (1) brainstormer.md Refs field matches actual file name in refs/, (2) analyst.md Reads field matches brainstormer.md Writes field (00-spec.md), (3) SKILL.md agent table matches all agent metadata headers, (4) SKILL.md workspace listing includes all .task/ files from all agents, (5) documenter.md and committer.md reference pipeline-summary.md (not 00-summary.md), (6) progress tracker stage count matches pipeline overview stage count
- [x] T016 Verify Brief section format: confirm brainstormer.md and analyst.md Brief templates follow existing convention (5-10 lines, structured for downstream consumption). Compare against researcher.md or planner.md Brief format as baseline

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies -- start immediately
- **US1+US4 (Phase 2)**: Depends on T001 (brainstorm-patterns.md must exist for Refs)
- **US2+US3 (Phase 3)**: Depends on Phase 2 completion (must know 00-spec.md format)
- **US5 (Phase 4)**: Depends on Phase 2 completion (brainstormer.md must exist to extend)
- **SKILL.md (Phase 5)**: Depends on Phases 2 and 3 (both agents must be defined)
- **Polish (Phase 6)**: Depends on all previous phases

### User Story Dependencies

- **US1 + US4 (Brainstormer + Patterns)**: Can start after Foundational. No dependency on other stories.
- **US2 + US3 (Analyst Validation + Adaptive Entry)**: Can start after US1+US4 (needs 00-spec.md format).
- **US5 (Scope Decomposition)**: Can start after US1+US4 (extends brainstormer.md). Independent of US2+US3.

### Within Each Phase

- T002 and T003 can run in parallel (different files)
- T004, T005, T006 are sequential (same file: brainstormer.md)
- T007, T008 are sequential (same file: analyst.md)
- T010-T014 are sequential (same file: SKILL.md)
- T015, T016 can run in parallel (read-only validation)

### Parallel Opportunities

```
Phase 1:  T001 ──────────────────────────
          T002 ─── (parallel) ─── T003

Phase 2:  T004 -> T005 -> T006

Phase 3:  T007 -> T008               (can overlap with Phase 4)

Phase 4:  T009                        (can overlap with Phase 3)

Phase 5:  T010 -> T011 -> T012 -> T013 -> T014

Phase 6:  T015 ─── (parallel) ─── T016
```

Note: Phases 3 and 4 can run in parallel since they modify different files (analyst.md vs brainstormer.md). However, Phase 4 adds to brainstormer.md created in Phase 2, so Phase 2 must complete first.

---

## Parallel Example: Phase 1 (Foundational)

```bash
# These can run in parallel (different files):
Task: "T002 Update documenter.md -- rename 00-summary.md to pipeline-summary.md"
Task: "T003 Update committer.md -- rename 00-summary.md to pipeline-summary.md"

# T001 can also run in parallel with T002/T003 (different file)
```

---

## Implementation Strategy

### MVP First (US1 + US4 Only)

1. Complete Phase 1: Foundational (T001-T003)
2. Complete Phase 2: Brainstormer Agent (T004-T006)
3. **STOP and VALIDATE**: Read brainstormer.md, verify all sections present, verify Refs field points to existing brainstorm-patterns.md
4. The Brainstormer can be manually tested at this point (invoke as subagent)

### Incremental Delivery

1. Phase 1 (Foundational) -> ref doc + terminal agent fixes ready
2. Phase 2 (US1+US4) -> Brainstormer works standalone (MVP!)
3. Phase 3 (US2+US3) -> Analyst validates specs, handles adaptive entry
4. Phase 4 (US5) -> Brainstormer handles oversized tasks
5. Phase 5 (SKILL.md) -> Full pipeline integration
6. Phase 6 (Polish) -> Consistency verified

### Single-Agent Strategy

All tasks are sequential markdown file creation/modification. One agent can complete all 16 tasks in order. No parallel infrastructure needed.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- No test tasks: pure markdown project per constitution (no runtime, no build, no tests)
- All files are within skills/task/ directory (agents/, agents/refs/, SKILL.md)
- Commit after each phase completion
