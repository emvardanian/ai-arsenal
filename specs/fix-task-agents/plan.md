# Implementation Plan: Fix Task Skill Agent Definitions

**Branch**: `fix-task-agents` | **Date**: 2026-04-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/fix-task-agents/spec.md`

## Summary

Add targeted sections to three Task SDLC pipeline agent definitions (documenter.md, refactorer.md, reviewer.md) to address gaps in source-read permissions, model escalation guidance, and security plugin invocation syntax. All changes are additive markdown edits -- no existing behavior is altered.

## Technical Context

**Language/Version**: Markdown (agent definition files)
**Primary Dependencies**: None
**Storage**: N/A
**Testing**: N/A -- pure markdown/docs project, no automated tests
**Target Platform**: Claude Code CLI (agent execution environment)
**Project Type**: Toolkit / skill collection
**Performance Goals**: N/A
**Constraints**: Minimal edits only -- add/clarify sections, do not rewrite agents
**Scale/Scope**: 3 files, ~30-50 lines of additions total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| File-based communication | PASS | No changes to `.task/` file flow |
| Progressive disclosure | PASS | No new reference files needed |
| Adaptive pipeline | PASS | Escalation adds flexibility, not rigidity |
| Plugin delegation | PASS | Reviewer fix clarifies existing plugin delegation |
| Brief sections | PASS | No changes to output formats |

No violations. No complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/fix-task-agents/
├── spec.md
├── plan.md              # This file
├── research.md
└── checklists/
    └── requirements.md
```

### Source Code (files to modify)

```text
skills/task/agents/
├── documenter.md        # Add source-read exception + API docs creation permission
├── refactorer.md        # Add Escalation section
└── reviewer.md          # Clarify security plugin invocation + unified finding format
```

## Implementation Phases

### Phase 1: Documenter -- source-read exception (1 file)

**File**: `skills/task/agents/documenter.md`

**Change 1a** -- Update Inputs section (line 14):
- After "Don't read source code -- use implementation logs" add exception clause
- Exception: when `04-impl-{N}.md` mentions new public APIs/endpoints, Documenter MAY read those specific files for signatures/exports only

**Change 1b** -- Update Step 2 (line 26):
- After "Don't add sections the project didn't have" add exception
- Exception: if new public APIs are introduced, Documenter MAY create a new API documentation section

### Phase 2: Refactorer -- escalation section (1 file)

**File**: `skills/task/agents/refactorer.md`

**Change 2** -- Add new "Escalation" section after Guidelines:
- Trigger: changes touch >3 files OR require cross-module restructuring
- Action: STOP, return item to orchestrator with recommendation to route to Implementer (sonnet)
- Scope preserved: simple refactoring (rename, extract constant, reorder) stays on haiku

### Phase 3: Reviewer -- security scanning clarification (1 file)

**File**: `skills/task/agents/reviewer.md`

**Change 3** -- Rewrite Step 2 security scanning instructions:
- Exact invocation: `/security-scanning:security-sast`
- Fallback: load `refs/security-checklist.md` when plugin unavailable
- Unified finding format for both paths: severity (CRITICAL/HIGH/MEDIUM/LOW), location (file:line), description, recommendation
