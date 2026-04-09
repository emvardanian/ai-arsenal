# Implementation Plan: Task Skill -- Brainstorm Phase (Stage 0)

**Branch**: `task-brainstorm-phase` | **Date**: 2026-04-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/task-brainstorm-phase/spec.md`

## Summary

Add an interactive Brainstormer agent (Stage 0) to the task skill pipeline and rewrite the Analyst agent (Stage 1) as a spec validator. The Brainstormer conducts structured dialogue to produce a TRC-format spec before code-level work begins. When a ready-made spec is detected, the Brainstormer is skipped and the Analyst transforms + validates directly.

All deliverables are markdown files -- no code, no build, no tests.

## Technical Context

**Language/Version**: N/A (markdown-based prompt definitions)
**Primary Dependencies**: Claude Code CLI (execution environment)
**Storage**: File system (`.task/` workspace, `skills/task/agents/`, `skills/task/agents/refs/`)
**Testing**: Manual validation (no automated tests -- pure markdown project per constitution)
**Target Platform**: Claude Code CLI
**Project Type**: Toolkit / skill collection (markdown-based)
**Performance Goals**: N/A (interactive dialogue, no latency targets)
**Constraints**: Agent context window budget; progressive disclosure (Level 3 refs loaded on demand)
**Scale/Scope**: 2 files to create, 4 files to modify

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Evidence |
|------|--------|----------|
| Type: toolkit / skill collection | PASS | All deliverables are markdown agent definitions and refs |
| No runtime, no build step | PASS | No code, no package manager, no build artifacts |
| File-based communication | PASS | Brainstormer writes `.task/00-spec.md`, Analyst reads it |
| Progressive disclosure (3 levels) | PASS | Brainstorm patterns loaded on demand from `refs/` (Level 3) |
| Agent definitions: inputs, outputs, model tier | PASS | Both agents declare Model, Reads, Writes, Refs |
| SKILL.md convention | PASS | Orchestrator updates follow existing format |
| Brief sections (5-10 lines) | PASS | Both agents include Brief template in output format |
| Single app, no microservices | PASS | Self-contained within `skills/task/` |

**Post-Phase 1 re-check**: All gates still pass. No violations introduced.

## Project Structure

### Documentation (this feature)

```text
specs/task-brainstorm-phase/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/trc.tasks)
```

### Source (repository root)

```text
skills/task/
├── SKILL.md                          # MODIFY: add Stage 0, adaptive entry, rename summary
├── agents/
│   ├── brainstormer.md               # CREATE: new Stage 0 agent
│   ├── analyst.md                    # MODIFY: rewrite to validator role
│   ├── researcher.md                 # unchanged
│   ├── planner.md                    # unchanged
│   ├── designer.md                   # unchanged
│   ├── implementer.md                # unchanged
│   ├── tester.md                     # unchanged
│   ├── debugger.md                   # unchanged
│   ├── reviewer.md                   # unchanged
│   ├── refactorer.md                 # unchanged
│   ├── documenter.md                 # MODIFY: rename 00-summary.md reference
│   ├── committer.md                  # MODIFY: rename 00-summary.md reference
│   └── refs/
│       ├── brainstorm-patterns.md    # CREATE: dialogue patterns reference
│       ├── architecture-checklist.md # unchanged
│       ├── commit-template.md        # unchanged
│       ├── debug-examples.md         # unchanged
│       ├── design-tokens-example.md  # unchanged
│       ├── doc-formats.md            # unchanged
│       ├── performance-checklist.md  # unchanged
│       └── security-checklist.md     # unchanged
```

**Structure Decision**: No new directories. All files go into existing `skills/task/agents/` and `skills/task/agents/refs/` directories following the established convention.

## Implementation Steps

### Step 1: Create brainstorm-patterns.md

**File**: `skills/task/agents/refs/brainstorm-patterns.md`
**Action**: CREATE
**Dependencies**: None (leaf node)

Create reference document with six dialogue patterns extracted from the design document:
1. One question rule -- one question per message, wait for answer
2. Multiple choice preferred -- A/B/C/D options where answer set is enumerable, open-ended only when options don't work
3. Red flags table -- list of rationalizing thoughts that mean STOP (table format matching superpowers:brainstorming style)
4. Incremental validation -- show completed section, wait for explicit "approve" or "revise"
5. Propose approaches -- 2-3 variants with trade-offs and recommendation before finalizing
6. Scope decomposition -- if task is too large for one spec, split into sub-projects, brainstorm the first one

Format: markdown reference doc, no frontmatter, no output format (this is a patterns reference, not an agent).

### Step 2: Create brainstormer.md

**File**: `skills/task/agents/brainstormer.md`
**Action**: CREATE
**Dependencies**: Step 1 (patterns ref must exist to be referenced)

Create Stage 0 agent definition following existing agent format:
- **Model**: opus
- **Reads**: user_request
- **Writes**: `.task/00-spec.md`
- **Refs**: `brainstorm-patterns.md`

Agent instructions must cover:
- Dialogue sequence: context (what/why, 1-3 questions) -> user stories (one at a time, with P1/P2/P3) -> acceptance criteria (per story, with IDs AC-1, AC-2...) -> quality gates -> edge cases -> scope (IN/OUT)
- Section-by-section approval: present result, ask "approve or revise?"
- Revision loop: if "revise," update section and re-present
- Final assembly: merge all approved sections into 00-spec.md
- Session preservation: write partial progress so interrupted sessions can resume

Output format must match TRC spec structure (Summary, User Stories, Quality Gates, Edge Cases, Scope).

Include Brief template (5-10 lines) for downstream consumption.

### Step 3: Rewrite analyst.md

**File**: `skills/task/agents/analyst.md`
**Action**: MODIFY (full rewrite)
**Dependencies**: Step 2 (must know 00-spec.md format to validate)

Rewrite from "analyze raw request" to "validate spec":
- **Model**: opus (unchanged)
- **Reads**: `.task/00-spec.md` (was: user_request)
- **Writes**: `.task/01-analysis.md` (unchanged)

New validation process:
1. Completeness check -- every User Story has ACs, quality gates defined, scope explicit
2. Consistency check -- stories don't contradict, quality gates align with criteria
3. Edge case review -- boundary conditions covered
4. Classification -- type (feature/bugfix/refactor/hotfix), scope (small/medium/large/critical), pipeline stages
5. Gap report -- findings with severity: Gap, Conflict, Weak, OK

Flow control:
- If gaps found: return to user with options (fix in spec / ignore / return to Brainstormer)
- If all OK: add classification and proceed

Adaptive entry handling:
- When Brainstormer was skipped (ready-made spec provided): transform input into TRC-format 00-spec.md first, then validate

Brief template updated to include validation summary instead of full from-scratch analysis.

### Step 4: Update SKILL.md

**File**: `skills/task/SKILL.md`
**Action**: MODIFY
**Dependencies**: Steps 2 and 3 (both agents must be defined)

Changes:
1. **Pipeline overview**: Add Stage 0 (Brainstormer) with `[approval]` tag. Rename Stage 1 display from "Analyst" to "Validate."
2. **Agent reference table**: Add Brainstormer row (Model: opus, Reads: user_request, Writes: 00-spec.md). Update Analyst row (Reads: 00-spec.md, description: "validate spec").
3. **Progress tracker**: Add `[Brainstorm]` as first stage. Example: `[▶ Brainstorm] -> [ Validate] -> [ Research] -> [ Plan] -> ...`
4. **Workspace section**: Add `00-spec.md` (brainstorm output). Rename `00-summary.md` to `pipeline-summary.md`.
5. **Adaptive entry section** (new): Describe skip-Brainstormer logic -- detection order (explicit path > fresh spec within 1 hour > TRC spec), what happens when spec is detected, how Analyst handles transformation.
6. **Pipeline summary section**: Update file name reference from `00-summary.md` to `pipeline-summary.md`.

### Step 5: Update documenter.md and committer.md

**Files**: `skills/task/agents/documenter.md`, `skills/task/agents/committer.md`
**Action**: MODIFY (minimal)
**Dependencies**: Step 4 (SKILL.md rename must be decided)

Both terminal agents read `00-summary.md` for pipeline context. Update all references to `pipeline-summary.md`.

This is a search-and-replace operation: `00-summary.md` -> `pipeline-summary.md` in both files.

## Complexity Tracking

No constitution violations. No complexity justifications needed.

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Brainstormer prompt too long for context window | Medium | Use progressive disclosure: patterns in refs/ (Level 3), load on demand |
| Analyst rewrite breaks downstream stages | Medium | Brief section format unchanged; downstream agents read only the brief |
| Rename 00-summary.md breaks existing .task/ workspaces | Low | Only affects new pipeline runs; existing completed workspaces are not re-read |
| Adaptive entry detection fails silently | Low | Fall back to running Brainstormer (safe default) |
