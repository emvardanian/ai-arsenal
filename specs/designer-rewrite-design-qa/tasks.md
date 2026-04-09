# Tasks: Designer Agent Rewrite + Design QA Agent

**Input**: Design documents from `/specs/designer-rewrite-design-qa/`
**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Not applicable -- pure markdown/docs project.

**Organization**: Tasks grouped by user story. US1 and US2 are both P1 and can run in parallel (different files). US3 depends on US1+US2. US4 is independent.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- All files under `skills/task/` in repository root
- Agent definitions: `skills/task/agents/*.md`
- References: `skills/task/agents/refs/*.md`
- Orchestrator: `skills/task/SKILL.md`

---

## Phase 1: User Story 1 - Designer Extracts Pixel-Perfect Specs (Priority: P1)

**Goal**: Rewrite Designer agent from minimal 5-step extractor to full 8-step Level 3 deep extractor with opus model.

**Independent Test**: Read the rewritten `designer.md` and verify it contains all 8 steps, opus model declaration, CONFLICT/MISSING_STATE/INFERRED/DECISION marker definitions, WCAG audit step, verification checklist generation, expanded output structure, and failure handling.

### Implementation for User Story 1

- [ ] T001 [P] [US1] Rewrite skills/task/agents/designer.md -- replace entire content with Level 3 deep extractor: upgrade model to opus, change activation to Decomposer `ui: true` + design input, implement 8-step process (inventory, scan assets, extract tokens, component spec, layout & responsive, WCAG audit, verification checklist, approval), define output structure with Brief/Design Source Inventory/Project Assets Map/Design Tokens/Component Specifications/Layout & Responsive/WCAG Report/Decisions Required/Verification Checklist/CSS/Tailwind sections, add CONFLICT/MISSING_STATE/INFERRED/DECISION markers throughout, expand guidelines to 8 items, add failure handling (NO_DESIGN/PARTIAL_DESIGN/UNREADABLE_DESIGN/LIB_VERSION_CONFLICT/TOKEN_CONFLICT). Output file: `.task/03.5-design.md`. Add TODO comment about renumbering to `05.5-design-{N}.md` post pipeline restructuring.

**Checkpoint**: Designer agent fully rewritten with all 8 steps and Level 3 depth.

---

## Phase 2: User Story 2 - Design QA Verifies Implementation (Priority: P1)

**Goal**: Create new Design QA agent for post-implementation visual verification with PASS/FAIL/SKIP checklist evaluation.

**Independent Test**: Read the new `design-qa.md` and verify it contains sonnet model, 4-step process, PASS/FAIL/SKIP evaluation format, visual comparison step, verdict types, routing rules, and max 2 cycle limit.

### Implementation for User Story 2

- [ ] T002 [P] [US2] Create skills/task/agents/design-qa.md -- new agent definition: sonnet model, Stage 6.5 (TODO: renumber to 8.5 post restructuring), activation when `03.5-design.md` exists for current module, inputs (Designer verification checklist + original design + browse screenshot), 4-step process (screenshot implementation, checklist verification with PASS/FAIL/SKIP per item with evidence, visual comparison for non-checklist deviations, generate report with verdict), output to `.task/06.5-design-qa-{N}.md` (TODO: renumber to `08.5-design-qa-{N}.md`), output structure with Brief/Checklist Results/Visual Deviations/Required Fixes/Verdict sections, routing (PASS->Reviewer, PASS WITH NOTES->Reviewer, FAIL->Implementer with max 2 cycles then escalate to user).

**Checkpoint**: Design QA agent created with full 4-step verification process.

---

## Phase 3: User Story 3 - Pipeline Integrates Design QA (Priority: P2)

**Goal**: Update SKILL.md so Design QA is a first-class pipeline step for UI modules.

**Independent Test**: Read updated SKILL.md and verify Design QA appears in pipeline overview (step 6.5), agent reference table (new row + Designer model updated to opus), workspace (new file), adaptive pipeline (feature + design row), and flow control (Design QA cycle).

### Implementation for User Story 3

- [ ] T003 [US3] Update skills/task/SKILL.md -- 5 targeted edits: (1) Pipeline Overview: add step 6.5 Design QA inside per-module loop after Debugger line with routing note, (2) Agent Reference table: add Design QA row (6.5, Design QA, agents/design-qa.md, sonnet, reads 03.5-design.md checklist + design input + browse screenshot, writes 06.5-design-qa-{N}.md) AND update Designer row model from sonnet to **opus**, (3) Workspace: add `06.5-design-qa-{N}.md` entry, (4) Adaptive Pipeline table: update `feature + design` row to include Design QA for UI modules, (5) Flow Control: add Design QA Cycle section describing FAIL->Implementer->Tester->Design QA routing with max 2 cycles. Add TODO comments about renumbering post pipeline restructuring.

**Checkpoint**: SKILL.md fully updated with Design QA integration.

---

## Phase 4: User Story 4 - Design Tokens Reference Expansion (Priority: P3)

**Goal**: Expand design tokens reference with responsive, dark mode, and animation token examples.

**Independent Test**: Read updated `design-tokens-example.md` and verify it contains new sections for responsive breakpoint tokens, dark mode tokens, and animation tokens in both CSS Custom Properties and Tailwind config formats.

### Implementation for User Story 4

- [ ] T004 [P] [US4] Update skills/task/agents/refs/design-tokens-example.md -- add 3 new sections after existing content: (1) Responsive Tokens section with CSS custom properties using breakpoint-keyed structure (`@media (min-width)` patterns) and Tailwind `screens` config equivalent, (2) Dark Mode Tokens section with CSS `prefers-color-scheme` media query approach and Tailwind `dark:` variant config, (3) Animation Tokens section with CSS custom properties for transitions/keyframes and Tailwind `extend.animation`/`extend.keyframes` config.

**Checkpoint**: Design tokens reference covers all token categories needed by the Designer agent.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across all files.

- [ ] T005 Verify cross-references: Designer output filename in SKILL.md matches designer.md, Design QA input references match Designer output, agent reference table filenames match actual files
- [ ] T006 Verify TODO comments about pipeline restructuring renumbering are present in all 4 modified files

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (US1)** and **Phase 2 (US2)**: No dependencies on each other -- can run in parallel
- **Phase 3 (US3)**: Depends on Phase 1 and Phase 2 (needs to reference both agents)
- **Phase 4 (US4)**: No dependencies -- can run in parallel with any phase
- **Phase 5 (Polish)**: Depends on all phases complete

### Parallel Opportunities

```
T001 [US1: Designer rewrite]  ─┐
T002 [US2: Design QA create]  ─┼─> T003 [US3: SKILL.md update] ──> T005, T006 [Polish]
T004 [US4: Tokens reference]  ─┘
```

T001, T002, T004 can all run in parallel (different files, no dependencies).

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Rewrite Designer (T001) and create Design QA (T002) in parallel
2. Both agents are independently testable by reading the markdown
3. **STOP and VALIDATE**: Verify agents follow existing format conventions

### Full Delivery

1. T001 + T002 + T004 in parallel (3 different files)
2. T003 after T001 + T002 complete (SKILL.md references both agents)
3. T005 + T006 as final validation

---

## Summary

- **Total tasks**: 6
- **US1**: 1 task (Designer rewrite)
- **US2**: 1 task (Design QA creation)
- **US3**: 1 task (SKILL.md update)
- **US4**: 1 task (tokens reference)
- **Polish**: 2 tasks (cross-reference + TODO verification)
- **Parallel opportunities**: T001, T002, T004 can run simultaneously
- **MVP scope**: US1 + US2 (Designer + Design QA agents)
