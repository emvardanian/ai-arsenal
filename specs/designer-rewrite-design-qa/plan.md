# Implementation Plan: Designer Agent Rewrite + Design QA Agent

**Branch**: `designer-rewrite-design-qa` | **Date**: 2026-04-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/designer-rewrite-design-qa/spec.md`

## Summary

Rewrite the Designer agent from a minimal 5-step extractor (~94 lines) to a full 8-step Level 3 deep extractor with CONFLICT/MISSING_STATE/INFERRED/DECISION markers, upgrade model to opus. Create a new Design QA agent (sonnet) at step 6.5 for post-implementation visual verification with PASS/FAIL/SKIP checklist evaluation and max 2 fix cycles. Update SKILL.md to integrate Design QA into the pipeline. Expand design tokens reference with responsive, dark mode, and animation examples.

## Technical Context

**Language/Version**: Markdown (agent definition format)
**Primary Dependencies**: Claude Code skill system, Task pipeline (SKILL.md)
**Storage**: File-based (`.task/` workspace)
**Testing**: N/A -- pure markdown/docs project, no automated tests
**Target Platform**: Claude Code CLI
**Project Type**: Toolkit / skill collection
**Performance Goals**: N/A
**Constraints**: Agent definitions must follow existing format conventions; context window kept clean via file-based communication; progressive disclosure (Level 1-3)
**Scale/Scope**: 4 files modified/created

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| File-based communication | PASS | Designer writes to `.task/03.5-design.md`, Design QA writes to `.task/06.5-design-qa-{N}.md` |
| Progressive disclosure (3 levels) | PASS | Designer uses Level 3 for deep extraction; refs loaded on demand |
| Adaptive pipeline | PASS | Designer/Design QA activate only for UI modules with design input |
| Plugin delegation | PASS | No new plugin dependencies; browse capability used by Design QA is environment-provided |
| Brief sections | PASS | Both agents output `## Brief` as first section |
| Skills follow SKILL.md format | PASS | SKILL.md updates follow existing section patterns |
| Agent definitions declare inputs, outputs, model tier | PASS | Both agents specify model, inputs, outputs |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/designer-rewrite-design-qa/
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal -- no unknowns)
├── tasks.md             # Phase 2 output (/trc.tasks command)
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
skills/task/
├── SKILL.md                          # Updated: pipeline overview, agent ref, workspace, adaptive pipeline, flow control
├── agents/
│   ├── designer.md                   # Rewritten: Level 3 deep extractor, 8-step process, opus model
│   ├── design-qa.md                  # NEW: 4-step visual verification, sonnet model
│   └── refs/
│       └── design-tokens-example.md  # Updated: add responsive, dark mode, animation tokens
```

**Structure Decision**: All changes are within the existing `skills/task/` directory. No new directories created except `design-qa.md` as a new file alongside existing agents.

## Research

No unknowns to research. The design specification (`docs/superpowers/specs/2026-04-08-designer-agent-improvement-design.md`) provides complete details for all 4 deliverables. The existing agent format and SKILL.md structure are well-established patterns to follow.

**Decisions**:

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Design QA numbered 6.5 on current main | Pipeline restructuring not merged; user instruction to use current numbering with TODO | Could wait for restructuring merge (delays this work) |
| Designer model upgraded to opus | Level 3 extraction requires deep reasoning per design spec | Keep sonnet (insufficient for 8-step extraction depth) |
| Design QA uses sonnet | Execution-tier model consistent with Tester/Debugger | Haiku too weak for visual comparison; opus overkill for checklist verification |
| Max 2 Design QA cycles | Consistent with existing Test/Debug cycle limit in SKILL.md | Unlimited cycles (risk of infinite loops); 1 cycle (may miss fixes) |

## Data Model

Not applicable -- pure markdown project with no data entities. The "entities" are markdown files in the `.task/` workspace:

- `03.5-design.md` -- Designer output (tokens, components, layout, WCAG, checklist)
- `06.5-design-qa-{N}.md` -- Design QA output (checklist results, visual deviations, verdict)

## Implementation Approach

### Phase 1: Rewrite Designer Agent (designer.md)

Replace the existing ~94-line minimal extractor with the full 8-step Level 3 deep extractor as specified in the design document. Key changes:
- Model: sonnet -> opus
- Activation: `has_design_input: true` -> Decomposer flags `ui: true` + user provides design input
- Process: 5 generic steps -> 8 precise steps (inventory, scan assets, extract tokens, component spec, layout, WCAG, checklist, approval)
- Output: `03.5-design.md` unchanged filename, but structure expanded to include Brief, Design Source Inventory, Project Assets Map, Design Tokens, Component Specifications, Layout & Responsive, WCAG Report, Decisions Required, Verification Checklist, CSS/Tailwind output
- Markers: CONFLICT, MISSING_STATE, INFERRED, DECISION throughout
- Guidelines: expanded from 5 bullets to 8 with stronger "extract don't invent" emphasis
- Failure handling: NO_DESIGN, PARTIAL_DESIGN, UNREADABLE_DESIGN, LIB_VERSION_CONFLICT, TOKEN_CONFLICT

### Phase 2: Create Design QA Agent (design-qa.md)

New agent file following existing agent definition format. Key elements:
- Model: sonnet
- Stage: 6.5 (after Tester/Debugger cycle; TODO: renumber to 8.5 post-restructuring)
- Activation: only when `03.5-design.md` exists for current module
- Process: 4 steps (screenshot, checklist verification, visual comparison, report)
- Output: `06.5-design-qa-{N}.md` with Brief, Checklist Results, Visual Deviations, Required Fixes, Verdict
- Routing: PASS -> Reviewer; PASS WITH NOTES -> Reviewer; FAIL -> Implementer (max 2 cycles)

### Phase 3: Update SKILL.md

Targeted edits to 5 sections of the existing SKILL.md:
1. Pipeline Overview -- add step 6.5 inside per-module loop after Debugger
2. Agent Reference table -- add Design QA row, update Designer model to opus
3. Workspace -- add `06.5-design-qa-{N}.md`
4. Adaptive Pipeline -- update `feature + design` row
5. Flow Control -- add Design QA cycle description

### Phase 4: Update Design Tokens Reference

Expand `agents/refs/design-tokens-example.md` with 3 new sections:
1. Responsive tokens (breakpoint-keyed CSS custom properties + Tailwind screens config)
2. Dark mode tokens (`prefers-color-scheme` media query + Tailwind dark variant)
3. Animation tokens (transitions, keyframes as CSS custom properties + Tailwind extend)
