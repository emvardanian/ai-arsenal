# Pipeline Restructuring: Hybrid Research + Decomposition

**Date:** 2026-04-08
**Status:** Draft
**Scope:** Restructure Task pipeline from global-research-then-plan to decompose-then-research-per-module

---

## Problem

Current pipeline runs one global Researcher pass before Planner decomposes into plans. This means:
- Research output is bloated -- half is irrelevant to any given plan
- Planner decomposes without deep knowledge of each module
- Context window fills with unfocused research data
- Each plan's Implementer gets same broad research instead of targeted context

## Solution: Hybrid Two-Level Research

Split research into two levels with a Decomposer in between:

1. **Scout** (light research) -- project structure, conventions, boundaries, affected zone scan. Enough to decompose.
2. **Decomposer** -- split task into logical modules with execution order.
3. **Researcher** (deep, per module) -- code, dependencies, analogous implementations. Focused on one module's scope.
4. **Planner** (detail, per module) -- concrete implementation steps for one module.

## New Pipeline

```
 0. Brainstormer  -> interactive spec creation (if no ready spec)    [approval]
 1. Analyst       -> validate/analyze spec                           [approval]
 2. Scout         -> light research: structure, conventions, boundaries
 3. Decomposer   -> split into modules, define execution order       [approval]
    +-- per module ---------------------------------------------------+
    | 4. Researcher   -> deep research for module N                    |
    | 5. Planner      -> detailed plan for module N              [approval]
    | 5.5 Designer    -> design tokens (if UI module)                  |
    | 6. Implementer  -> write code for module N                 [approval]
    | 7. Tester       -> test module N                                 |
    | 8. Debugger     -> hypothesis-driven failure analysis            |
    |    back to Implementer -> Tester (max 2 cycles)                  |
    +-----------------------------------------------------------------+
 9. Reviewer      -> security + performance + architecture
10. Refactorer    -> apply minor fixes, re-test                      [approval]
11. Documenter    -> update docs, changelog                          [approval]
12. Committer     -> prepare commits + PR
```

**Agent count:** 10 -> 12 (Scout and Decomposer are new; Researcher and Planner restructured).

**Hotfix exception:** Analyst -> [Impl->Test<->Debug] -> Commit (skips Scout/Decomposer for speed).

## Agent Reference

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 0 | Brainstormer | `brainstormer.md` | opus | user request | `00-spec.md` |
| 1 | Analyst | `analyst.md` | opus | `00-spec.md` or user request | `01-analysis.md` |
| 2 | Scout | `scout.md` | sonnet | `01-analysis.md` | `02-scout.md` |
| 3 | Decomposer | `decomposer.md` | opus | `02-scout.md`, `01-analysis.md` (brief) | `03-decomposition.md` |
| 4 | Researcher | `researcher.md` | sonnet | `03-decomposition.md` (module N), `02-scout.md` (brief) | `04-research-{N}.md` |
| 5 | Planner | `planner.md` | opus | `04-research-{N}.md`, `03-decomposition.md` (module N) | `05-plan-{N}.md` |
| 5.5 | Designer | `designer.md` | sonnet | screenshot, `05-plan-{N}.md` (brief) | `05.5-design-{N}.md` |
| 6 | Implementer | `implementer.md` | sonnet | `05-plan-{N}.md`, `04-research-{N}.md` (brief) | `06-impl-{N}.md` + code |
| 7 | Tester | `tester.md` | sonnet | `06-impl-{N}.md`, `01-analysis.md` (criteria) | `07-tests-{N}-{C}.md` |
| 8 | Debugger | `debugger.md` | sonnet | `07-tests-{N}-{C}.md`, source files | `08-debug-{N}-{C}.md` |
| 9 | Reviewer | `reviewer.md` | sonnet | `06-impl-*.md` (briefs), source files | `09-review.md` |
| 10 | Refactorer | `refactorer.md` | haiku | `09-review.md` | `10-refactor.md` + code |
| 11 | Documenter | `documenter.md` | haiku | `00-summary.md` + doc files | `11-docs.md` |
| 12 | Committer | `committer.md` | haiku | `00-summary.md` | `12-commit.md` |

## Agent Definitions

### Scout (NEW)

**Role:** Quick terrain scan -- enough context to decompose, not enough to plan details.

**Model:** sonnet

**Inputs:**
- `.task/01-analysis.md` -- full (task type, scope, criteria)

**Process:**
1. Project structure scan (tree, key directories)
2. Conventions (naming, patterns, frameworks, config files)
3. Module boundaries (layers, domains, entry points, interfaces between them)
4. Affected zone scan (grep key terms from analysis, identify which modules the task touches)

**Output:** `.task/02-scout.md`

```
## Brief
Project type, main boundaries, affected modules list, conventions summary

## Project Structure
[tree with annotations]

## Conventions
[naming, patterns, frameworks]

## Module Boundaries
[what modules exist, how they communicate]

## Affected Zone
[which modules this task touches, with evidence from grep]
```

**Constraints:**
- Max 10-15 files scanned (headers/imports only), no full file reads
- Does NOT read file contents in depth
- Does NOT analyze dependencies between files
- Does NOT find analogous implementations
- Does NOT make architectural recommendations
- No approval gate -- output is informational

### Decomposer (NEW)

**Role:** Split task into logical modules with execution order. Pure architectural decomposition -- no implementation details.

**Model:** opus

**Inputs:**
- `.task/02-scout.md` -- full
- `.task/01-analysis.md` -- Brief section only

**Process:**
1. Map acceptance criteria to affected modules (from Scout)
2. Group related changes into logical units (by module/layer, not by file count)
3. Identify dependencies between units -- which must go first
4. Define execution order (topological sort by dependencies)
5. For each module: scope boundary, goal, criteria coverage, research hints

**Output:** `.task/03-decomposition.md`

```
## Brief
Module count, execution order, criteria coverage summary

## Acceptance Criteria Mapping
[Table: criterion -> module(s)]

## Module N: [Name]
- Goal: [1-2 sentences -- what this module achieves]
- Scope: [which directories/areas of codebase]
- Criteria: [which acceptance criteria this covers]
- Depends on: [module numbers that must complete first]
- Research hints: [what Deep Research should focus on]
- UI: [true/false -- triggers Designer]

## Execution Order
Module 1 -> Module 2 -> Module 3 (or parallel where no deps)
```

**Constraints:**
- Does NOT list specific files to modify (Planner's job)
- Does NOT define implementation steps
- Does NOT read codebase directly (works only from Scout output)
- Has approval gate -- defines structure of all subsequent work

### Researcher (RESTRUCTURED)

**Role:** Deep, focused research for one specific module. Runs once per module inside the loop.

**Model:** sonnet

**Inputs:**
- `.task/03-decomposition.md` -- full Module N section (goal, scope, criteria, research hints)
- `.task/02-scout.md` -- Brief section only (conventions reference)

**Output:** `.task/04-research-{N}.md` (one per module)

**Process:**
1. Read code of files within module's scope boundary (full content)
2. Trace dependencies -- who imports these files, who they import
3. Find existing tests for affected code
4. Search for analogous implementations in the project
5. Note conventions specific to this area

```
## Brief
Files analyzed, key findings, patterns found, risk areas

## Affected Files
[file path, current purpose, what needs to change]

## Dependencies
[who depends on these files, what breaks if we change them]

## Existing Tests
[which tests cover this area, gaps]

## Analogous Implementations
[similar patterns found elsewhere in project, with file refs]

## Area-Specific Conventions
[any local conventions that differ from project-wide]
```

**Constraints:**
- Max 5-7 files full read, unlimited grep/glob
- Focused on one module's scope boundary only
- No approval gate -- feeds directly into Planner

**vs old Researcher:** Old = one global pass. New = runs N times, each time focused on one module's scope. Deeper per module, less noise.

### Planner (RESTRUCTURED)

**Role:** Detailed implementation plan for one module. No longer decomposes.

**Model:** opus

**Inputs:**
- `.task/04-research-{N}.md` -- full
- `.task/03-decomposition.md` -- Module N section (goal, scope, criteria)

**Output:** `.task/05-plan-{N}.md` (one per module)

```
## Brief
Objective, file count (create/modify/delete), steps count, verification approach

## Objective
[1-2 sentences, refined with research context]

## Files
[modify/create/delete with description of changes]

## Steps
[ordered, concrete actions: "Add X to Y at line Z"]

## Conventions
[relevant patterns from research]

## Verification
[how to know this plan was implemented correctly]
```

**What changed vs old Planner:**
- No longer estimates single vs multi-plan (Decomposer does that)
- No longer maps acceptance criteria (Decomposer does that)
- No Execution Flow section (Decomposer defines order)
- Receives deeper, more focused research per module
- Simpler output -- one module, one plan
- Has approval gate per plan

### Designer (MOVED)

**Role:** Unchanged -- extract design tokens from screenshot.

**Trigger:** Decomposer marks module as `ui: true`.

**New position:** Inside per-module loop, between Planner and Implementer (Stage 5.5).

**Inputs:** screenshot + `05-plan-{N}.md` (brief)
**Output:** `05.5-design-{N}.md`

Runs only for UI modules. Non-UI modules skip directly to Implementer.

## Workspace

```
.task/
  00-summary.md
  00-spec.md              (if Brainstormer ran)
  01-analysis.md
  02-scout.md
  03-decomposition.md
  04-research-{N}.md      (per module)
  05-plan-{N}.md          (per module)
  05.5-design-{N}.md      (per UI module)
  06-impl-{N}.md          (per module)
  07-tests-{N}-{C}.md     (per module, per cycle)
  08-debug-{N}-{C}.md     (per module, per cycle)
  09-review.md
  10-refactor.md
  11-docs.md
  12-commit.md
```

## Progress Tracker

```
[ok Analyst] [ok Scout] [>> Decompose] [Research 1/3] [Plan 1/3] [Impl 1/3] [Test] [Debug] [Review] [Refactor] [Docs] [Commit]
```

Icons: `ok` done, `>>` active, ` ` pending, `--` skipped, `<>` re-run, `!!` failed
Multi-module: `[>> Impl 2/3]`, Debug cycle: `[>> Debug <>1]`

## Adaptive Pipeline

| Task Type | Pipeline |
|-----------|----------|
| **feature** | All stages |
| **feature + design** | All stages + Designer for UI modules |
| **bugfix** | Analyst -> Scout -> Decomposer -> [Research->Plan->Impl->Test<->Debug] -> Commit |
| **refactor** | Analyst -> Scout -> Decomposer -> [Research->Refactor->Review->Test] -> Commit |
| **hotfix** | Analyst -> [Impl->Test<->Debug] -> Commit |

Hotfix skips Scout/Decomposer -- speed is critical.

Single-plan tasks still go through full flow (Scout -> Decomposer -> Research -> Plan). Consistent and predictable.

## Execution Strategy

### Tier 1: Agent Teams (parallel)
- Independent modules can run `[Research->Plan->Impl->Test]` in parallel via agent-teams
- Dependent modules run sequentially per Decomposer's execution order
- Review dimensions (security, performance, architecture) run in parallel as before

### Tier 2: Subagents (isolated context)
- Each stage spawned as independent subagent with declared inputs only

### Tier 3: Sequential (fallback)
- Execute inline, file system as memory between stages

## Brainstorm Phase Compatibility

Brainstorm phase (Stage 0) and this restructuring are orthogonal changes:
- Brainstormer feeds Analyst (Stage 0 -> Stage 1)
- Scout reads Analyst output (Stage 1 -> Stage 2)
- No conflicts -- can be implemented independently

Workspace numbering for `00-spec.md` vs `00-summary.md` to be resolved during implementation.

## Files to Change

### New files:
- `agents/scout.md` -- Scout agent definition
- `agents/decomposer.md` -- Decomposer agent definition

### Modified files:
- `agents/researcher.md` -- restructure to per-module deep research
- `agents/planner.md` -- remove decomposition, single-module focus
- `SKILL.md` -- new pipeline, agent table, workspace, adaptive pipeline, execution strategy
- `agents/implementer.md` -- update input refs (new numbering)
- `agents/tester.md` -- update input refs
- `agents/debugger.md` -- update input refs
- `agents/reviewer.md` -- update input refs
- `agents/refactorer.md` -- update input refs
- `agents/documenter.md` -- update input refs
- `agents/committer.md` -- update input refs
- `agents/designer.md` -- update position and input refs

### Reference files (no change expected):
- `agents/refs/*` -- content unchanged, only referenced by agents
