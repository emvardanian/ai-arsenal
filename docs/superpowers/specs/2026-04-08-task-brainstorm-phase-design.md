# Design: Task Skill -- Brainstorm Phase (Phase 0)

## Summary

Add an interactive brainstorming phase (Stage 0) to the task skill pipeline. The Brainstormer agent conducts a structured dialogue with the user to produce a TRC-format spec before any code-level work begins. The existing Analyst agent changes role from "analyze from scratch" to "validate the spec."

This design covers Phase 0 (Brainstormer) and the updated Analyst only. Planner and subsequent stages will be addressed in a separate design.

## New Pipeline Flow

```
 0. Brainstormer    -> interactive spec brainstorm              [approval]
 1. Analyst         -> validate spec, find gaps                 [approval]
 2. Researcher      -> scan codebase (unchanged)
 3. Planner         -> decompose into plans (future redesign)
 ... (rest unchanged for now)
```

### Adaptive Entry

If the user provides a ready-made spec (TRC spec.md, superpowers design doc, or any structured document):
1. Skip Brainstormer
2. Analyst transforms input into TRC-format -> `00-spec.md`
3. Analyst validates
4. Pipeline continues as normal

**Detection**: the orchestrator checks for a ready-made spec in this order:
1. User explicitly passes a file path or pastes spec content in their request
2. A fresh spec exists at `docs/superpowers/specs/` (written by superpowers:brainstorming within the last hour)
3. A TRC spec exists at the project's `.trc/` or `docs/` directory

If none found -- run Brainstormer as normal.

## Brainstormer Agent

**Model**: opus

**File**: `agents/brainstormer.md`

**Reads**: user request

**Writes**: `.task/00-spec.md`

**Refs**: `agents/refs/brainstorm-patterns.md` (dialogue patterns)

### Dialogue Process

1. **Understand context** -- what and why (1-3 questions)
2. **User Stories** -- form one at a time, with priorities (P1/P2/P3)
3. **Acceptance Criteria** -- for each story, testable, with IDs (AC-1, AC-2...)
4. **Quality Gates** -- what blocks release (performance thresholds, security requirements, coverage)
5. **Edge Cases** -- what can go wrong, boundary conditions
6. **Scope** -- explicit IN/OUT to prevent scope creep
7. **Assemble spec** -- merge everything into `.task/00-spec.md`

After each section (2-6): present result, ask "approve or revise?". Do not proceed until approved.

### Dialogue Patterns

Loaded from `agents/refs/brainstorm-patterns.md`:
- One question per message, wait for answer
- Multiple choice (A/B/C/D) where possible, open-ended only when options don't work
- Red flags table -- thoughts like "this is simple" or "let me gather context first" mean STOP, you're skipping the process
- Incremental validation -- show section, wait for "ok" before next
- Propose 2-3 approaches with trade-offs and recommendation before finalizing
- Scope decomposition -- if task is too large for one spec, split into sub-projects, brainstorm the first one

### Output Format

`.task/00-spec.md` in TRC format:

```markdown
# Spec: [name]

## Summary
[1-2 sentences]

## User Stories
- US1 [P1]: As a ... I want ... so that ...
  - AC-1: ...
  - AC-2: ...
- US2 [P2]: ...

## Quality Gates
- QG-1: ...
- QG-2: ...

## Edge Cases
- EC-1: ...

## Scope
### In
- ...
### Out
- ...
```

## Analyst Agent (Updated Role)

**Model**: opus (unchanged)

**File**: `agents/analyst.md` (rewritten)

**Reads**: `.task/00-spec.md`

**Writes**: `.task/01-analysis.md`

### Previous Role
Analyzed raw user request from scratch -- classified task, defined acceptance criteria, assessed risks, determined pipeline stages.

### New Role
Reads the ready-made spec and validates its quality.

### Validation Process

1. **Completeness check** -- does every User Story have acceptance criteria? Are quality gates defined? Is scope explicit?
2. **Consistency check** -- do stories contradict each other? Do quality gates align with criteria?
3. **Edge case review** -- are boundary conditions covered? Any missing "what if..." scenarios?
4. **Classify** -- type (feature/bugfix/refactor/hotfix), scope (small/medium/large/critical), pipeline stages
5. **Gap report** -- findings with severity:
   - **Gap** -- something is missing (missing story, missing criteria)
   - **Conflict** -- contradiction between sections
   - **Weak** -- criteria not testable or too vague
   - **OK** -- all clean

### Flow Control

- If Gap/Conflict/Weak found: return to user with specific notes. User can: fix in spec, ignore, or return to Brainstormer.
- If all OK: add classification (type, scope, pipeline) and proceed.

### Adaptive Entry (No Brainstormer)

When Brainstormer was skipped (user provided ready-made spec):
1. Transform input into TRC-format `00-spec.md`
2. Validate as normal

### Output

`.task/01-analysis.md` -- same structure as before, but Brief now includes a validation summary instead of full from-scratch analysis.

## refs/brainstorm-patterns.md

Dialogue patterns extracted from superpowers:brainstorming. Covers HOW to conduct the dialogue -- no output format, no workspace paths, no transition logic.

Contents:
- **One question rule** -- one question per message, wait for answer
- **Multiple choice preferred** -- options (A/B/C/D) where possible
- **Red flags table** -- list of rationalizing thoughts that mean STOP
- **Incremental validation** -- show section, wait for approval before next
- **Propose approaches** -- before finalizing, offer 2-3 variants with trade-offs and recommendation
- **Scope decomposition** -- if task is too large for one spec, decompose into sub-projects, brainstorm the first one

## Changes to SKILL.md (Orchestrator)

### Pipeline Overview
Add Stage 0 (Brainstormer). Rename Stage 1 display to "Validate" in progress tracker.

### Agent Reference Table
Add Brainstormer row. Update Analyst reads/description.

### Progress Tracker
```
[▶ Brainstorm] -> [ Validate] -> [ Research] -> [ Plan] -> ...
```

### Workspace
- `00-spec.md` -- brainstorm output (new)
- `01-analysis.md` -- validation output (updated role)
- `pipeline-summary.md` -- renamed from `00-summary.md` to avoid numbering conflict

### Adaptive Entry Section
New section describing skip-Brainstormer logic when user provides a ready-made spec.

### Everything Else
Researcher, Implementer, Tester, Debugger, Reviewer, Refactorer, Documenter, Committer -- unchanged in this design. Planner and subsequent stages will be addressed separately.

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `agents/brainstormer.md` | New Stage 0 agent |
| Create | `agents/refs/brainstorm-patterns.md` | Dialogue patterns reference |
| Modify | `agents/analyst.md` | Rewrite to validator role |
| Modify | `SKILL.md` | Add Stage 0, update pipeline, add adaptive entry |
| Modify | `README.md` (root) | Update pipeline diagram and agent table |

## Out of Scope

- Planner redesign (separate future work)
- Stages after Planner (separate future work)
- New plugins or MCP integrations
- Changes to redesign or lander skills
