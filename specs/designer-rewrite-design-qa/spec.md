# Feature Specification: Designer Agent Rewrite + Design QA Agent

**Feature Branch**: `designer-rewrite-design-qa`
**Created**: 2026-04-09
**Status**: Draft
**Input**: Rewrite Designer agent from minimal extractor to Level 3 deep extractor; create new Design QA agent for post-implementation visual verification; update SKILL.md pipeline and design tokens reference.

## User Scenarios & Testing

### User Story 1 - Designer Extracts Pixel-Perfect Specs from Design Input (Priority: P1)

When a user provides a Figma export or screenshot for a UI module, the Designer agent must extract every design value precisely -- colors, typography, spacing, component specs, layout, and accessibility data -- so the Implementer can copy-paste values directly into code with zero guesswork.

**Why this priority**: Without precise extraction, the Implementer approximates values, causing design drift. This is the core problem being solved.

**Independent Test**: Provide a screenshot with known color values, font sizes, and spacing. Verify the Designer output contains exact hex codes, px values, and component specs that match the source design.

**Acceptance Scenarios**:

1. **Given** a UI module flagged `ui: true` with a Figma export, **When** Designer runs, **Then** output contains all color hex codes, font specs, spacing values, and component dimensions from the design with source references.
2. **Given** a design with an existing project component library, **When** Designer runs, **Then** existing components are mapped (not re-specified) with override notes, and only truly new components get full Level 3 specs.
3. **Given** a design missing certain states (e.g., no hover shown), **When** Designer runs, **Then** each missing state is explicitly listed as `MISSING_STATE` with optional `[recommended]` defaults clearly separated from extracted facts.
4. **Given** a design with color values conflicting with existing project tokens, **When** Designer runs, **Then** each conflict is flagged as `CONFLICT` with both values shown, marked `DECISION` for user resolution.

---

### User Story 2 - Design QA Verifies Implementation Matches Design (Priority: P1)

After implementation and testing pass, the Design QA agent verifies that the rendered output matches the design specification point-by-point, catching visual regressions before review.

**Why this priority**: Without automated design verification, visual bugs ship undetected. This closes the loop between design and implementation.

**Independent Test**: Implement a UI module with one intentional deviation from the design spec. Verify Design QA catches the deviation and produces a FAIL verdict with specific file:line fix instructions.

**Acceptance Scenarios**:

1. **Given** a completed UI module with a Designer output containing a verification checklist, **When** Design QA runs, **Then** every checklist item is evaluated as PASS, FAIL, or SKIP with evidence.
2. **Given** 3 checklist failures, **When** Design QA generates its report, **Then** the verdict is FAIL with a Required Fixes section listing each failure with severity, expected vs actual values, and file:line locations.
3. **Given** a FAIL verdict, **When** the pipeline routes back to Implementer, **Then** Implementer receives the Design QA report as additional input, fixes the issues, code passes through Tester again, and Design QA re-runs. Maximum 2 full cycles before user escalation.

---

### User Story 3 - Pipeline Integrates Design QA After Test/Debug Cycle (Priority: P2)

The SKILL.md pipeline overview, agent reference, workspace, adaptive pipeline, and flow control sections are updated so Design QA is a first-class pipeline step that runs automatically for UI modules.

**Why this priority**: Without pipeline integration, the new agent is not discoverable or executable within the Task skill orchestration.

**Independent Test**: Read the updated SKILL.md and verify Design QA appears in the pipeline overview, agent reference table, workspace file list, adaptive pipeline, and flow control sections with correct numbering and routing rules.

**Acceptance Scenarios**:

1. **Given** a `feature + design` task type, **When** the adaptive pipeline is consulted, **Then** both Designer and Design QA are listed as active stages for UI modules.
2. **Given** the pipeline overview in SKILL.md, **When** a reader scans the per-module loop, **Then** Design QA appears after the Test/Debug cycle with correct routing back to Implementer on FAIL.

---

### User Story 4 - Design Tokens Reference Covers Responsive, Dark Mode, and Animation (Priority: P3)

The existing `agents/refs/design-tokens-example.md` is expanded from basic CSS/Tailwind tokens to include responsive tokens, dark mode tokens, and animation tokens as reference material for the Designer.

**Why this priority**: Supporting material -- the Designer agent references this file for token format examples. Without responsive/dark/animation examples, those token categories may be extracted in inconsistent formats.

**Independent Test**: Read the updated reference file and verify it contains sections for responsive breakpoint tokens, dark mode color tokens, and animation/transition tokens in both CSS Custom Properties and Tailwind config formats.

**Acceptance Scenarios**:

1. **Given** the updated reference file, **When** Designer needs to format responsive tokens, **Then** a concrete example exists showing breakpoint-keyed token structure.
2. **Given** the updated reference file, **When** Designer needs dark mode tokens, **Then** examples show both `prefers-color-scheme` CSS and Tailwind `dark:` variant approaches.

---

### Edge Cases

- UI module without design input: Designer skips, writes `NO_DESIGN` warning to output file. Design QA also skips (no Designer output to verify against).
- Partial design (some screens/states only): Designer extracts what exists, marks gaps as `MISSING_STATE`/`INFERRED`. Design QA marks INFERRED checklist items as SKIP.
- Unreadable design (blurry screenshot): Designer stops and requests better input from user.
- Design QA fails after 2 cycles: Escalate to user with full context rather than looping indefinitely.
- No project component library: Designer treats all components as "new" with full Level 3 specs.
- Token format mismatch (project uses Tailwind but design exports CSS vars): Designer outputs both formats, flags naming convention.

## Requirements

### Functional Requirements

- **FR-001**: Designer agent MUST extract exact hex color codes, pixel spacing values, font specifications, and component dimensions from design input with source references to specific design frames/elements.
- **FR-002**: Designer agent MUST compare extracted tokens against existing project tokens and flag mismatches as `CONFLICT` with both values, marked `DECISION` for user resolution.
- **FR-003**: Designer agent MUST map design components to existing project library components before creating new specifications. Mapped components show variant, size, and any overrides needed.
- **FR-004**: Designer agent MUST record every state not shown in the design as `MISSING_STATE` with optional `[recommended]` defaults clearly distinguished from extracted facts.
- **FR-005**: Designer agent MUST perform a WCAG 2.1 AA accessibility audit on ALL text/background color pairs, showing contrast ratios and flagging failures with adjusted alternatives.
- **FR-006**: Designer agent MUST generate a point-by-point verification checklist with concrete expected values for Design QA to evaluate.
- **FR-007**: Designer agent MUST aggregate all `CONFLICT`, `MISSING_STATE`, `INFERRED`, and `DECISION` items into a dedicated "Decisions Required" section. All `DECISION` items block progress until resolved.
- **FR-008**: Design QA agent MUST walk through the Designer's verification checklist and evaluate each item as PASS, FAIL, or SKIP with evidence (DOM inspection, computed styles, visual comparison).
- **FR-009**: Design QA agent MUST screenshot the implementation at the same viewport sizes shown in the original design for visual comparison.
- **FR-010**: Design QA agent MUST identify visual deviations beyond the checklist (spacing, element order, missing elements) and report them with severity.
- **FR-011**: Design QA agent MUST produce a verdict: PASS, PASS WITH NOTES, or FAIL. FAIL routes back to Implementer with specific fixes.
- **FR-012**: Design QA cycle MUST be limited to 2 full iterations (Design QA -> Implementer -> Tester -> Design QA). After 2 cycles, escalate to user.
- **FR-013**: SKILL.md MUST be updated with Design QA in pipeline overview, agent reference, workspace, adaptive pipeline, and flow control sections.
- **FR-014**: Design tokens reference MUST include responsive, dark mode, and animation token examples in CSS Custom Properties and Tailwind config formats.

### Key Entities

- **Design Specification**: The Designer's output containing tokens, component specs, layout, WCAG audit, and verification checklist (`.task/03.5-design.md` on current pipeline; TODO: renumber to `05.5-design-{N}.md` after pipeline restructuring merges).
- **Design QA Report**: The Design QA agent's output containing checklist results, visual deviations, required fixes, and verdict (`.task/06.5-design-qa-{N}.md` on current pipeline; TODO: renumber to `08.5-design-qa-{N}.md` after pipeline restructuring merges).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Designer output contains zero invented values -- every value traces back to a specific element in the design input or is explicitly marked as INFERRED/MISSING_STATE/recommended.
- **SC-002**: Every text/background color pair in the design is present in the WCAG audit table with calculated contrast ratio and PASS/FAIL status.
- **SC-003**: Design QA checklist covers 100% of the items generated by the Designer's verification checklist section.
- **SC-004**: Design QA FAIL verdict includes specific file:line locations and expected-vs-actual values for every failure, enabling targeted fixes.
- **SC-005**: The full Design QA cycle (FAIL -> fix -> re-test -> re-verify) completes within 2 iterations for straightforward visual mismatches.

## Assumptions

- Pipeline restructuring has NOT been merged to main. Current numbering is used: Designer at step 3.5 (`03.5-design.md`), Design QA at step 6.5 (`06.5-design-qa-{N}.md`). TODO comments note future renumbering to 05.5 and 08.5 when pipeline restructuring merges.
- The Designer model is upgraded from sonnet to opus for Level 3 extraction depth.
- Design QA uses sonnet (execution-tier model, consistent with Tester/Debugger).
- Browse/screenshot capability is available to Design QA via the execution environment.
- The per-module loop on current main is: Implementer (4) -> Tester (5) -> Debugger (6) -> Design QA (6.5).
