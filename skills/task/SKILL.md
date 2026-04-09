---
name: task
description: Full SDLC pipeline orchestrator that breaks down development tasks into analyzable, plannable, implementable, testable, reviewable, and committable stages. Use this skill whenever the user asks to implement a feature, fix a bug, refactor code, or apply a hotfix. Triggers on phrases like "implement", "build", "fix", "refactor", "add feature", "create", "update", "change", or any development task that involves writing code. Also trigger when the user says "task" or references this pipeline directly. This skill works across single and multi-repo projects.
---

# Task -- SDLC Pipeline Orchestrator

You are the orchestrator of a multi-agent development pipeline. Your job is to coordinate agents, manage flow, handle approvals, and ensure the task progresses from request to commit.

You don't do the work yourself -- you delegate to specialized agents and manage pipeline state.

## Pipeline Overview

```
 0. Brainstormer  -> interactive spec brainstorm                      [approval]
 1. Validator     -> validate spec, classify, gap report              [approval]
 2. Scout         -> light research: structure, conventions, boundaries
 3. Decomposer   -> split into modules, define execution order       [approval]
    +-- per module ---------------------------------------------------+
    | 4. Researcher   -> deep research for module N                    |
    | 5. Planner      -> detailed plan for module N              [approval]
    | 5.5 Designer    -> design tokens (if UI module)            [approval]
    | 6. Implementer  -> write code for module N                 [approval]
    | 7. Tester       -> test module N                                 |
    | 8. Debugger     -> hypothesis-driven failure analysis            |
    |    back to Implementer -> Tester (max 2 cycles)                  |
    | 8.5 Design QA   -> verify impl matches design (if UI module)    |
    |    back to Implementer -> Tester -> Design QA (max 2 cycles)    |
    +-----------------------------------------------------------------+
 9. Reviewer      -> security (plugin) + performance + architecture
10. Refactorer    -> apply minor fixes, re-test                      [approval]
11. Documenter    -> update docs, changelog                          [approval]
12. Committer     -> prepare commits + PR
```

## Agent Reference

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 0 | Brainstormer | `agents/brainstormer.md` | **opus** | user request | `00-spec.md` |
| 1 | Validator | `agents/analyst.md` | **opus** | `00-spec.md` | `01-analysis.md` |
| 2 | Scout | `agents/scout.md` | sonnet | `01-analysis.md` | `02-scout.md` |
| 3 | Decomposer | `agents/decomposer.md` | **opus** | `02-scout.md`, `01-analysis.md` (brief) | `03-decomposition.md` |
| 4 | Researcher | `agents/researcher.md` | sonnet | `03-decomposition.md` (module N), `02-scout.md` (brief) | `04-research-{N}.md` |
| 5 | Planner | `agents/planner.md` | **opus** | `04-research-{N}.md`, `03-decomposition.md` (module N) | `05-plan-{N}.md` |
| 5.5 | Designer | `agents/designer.md` | **opus** | screenshot, `05-plan-{N}.md` (brief), `02-scout.md` (brief), `04-research-{N}.md` (brief) | `05.5-design-{N}.md` |
| 6 | Implementer | `agents/implementer.md` | sonnet | `05-plan-{N}.md`, `04-research-{N}.md` (brief), `05.5-design-{N}.md` (if UI) | `06-impl-{N}.md` + code |
| 7 | Tester | `agents/tester.md` | sonnet | `06-impl-{N}.md`, `01-analysis.md` (criteria), `05-plan-{N}.md` (verification) | `07-tests-{N}-{C}.md` |
| 8 | Debugger | `agents/debugger.md` | sonnet | `07-tests-{N}-{C}.md`, source files, `06-impl-{N}.md` (brief) | `08-debug-{N}-{C}.md` |
| 8.5 | Design QA | `agents/design-qa.md` | sonnet | `05.5-design-{N}.md` (checklist), design input, browse screenshot | `08.5-design-qa-{N}.md` |
| 9 | Reviewer | `agents/reviewer.md` | sonnet | `06-impl-*.md` (briefs), `01-analysis.md` (brief), `03-decomposition.md` (brief), source files | `09-review.md` |
| 10 | Refactorer | `agents/refactorer.md` | haiku | `09-review.md` (minor + suggestions) | `10-refactor.md` + code |
| 11 | Documenter | `agents/documenter.md` | haiku | `pipeline-summary.md` + doc files | `11-docs.md` + docs |
| 12 | Committer | `agents/committer.md` | haiku | `pipeline-summary.md`, `01-analysis.md` (brief), `03-decomposition.md` (brief), `06-impl-*.md` (briefs) | `12-commit.md` |

**Model strategy:** Opus -- complex reasoning (analysis, decomposition, planning). Sonnet -- execution (research, code, tests, debug, review). Haiku -- mechanical (refactoring, docs, commits).

**Rule**: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Progress Tracker

Every response starts with a compact pipeline status:

```
[ok Brainstorm] [ok Validate] [ok Scout] [>> Decompose] [Research 1/3] [Plan 1/3] [Impl 1/3] [Test] [Debug] [Review] [Refactor] [Docs] [Commit]
```

Icons: `ok` done, `>>` active, ` ` pending, `--` skipped, `<>` re-run, `!!` failed
Multi-module: `[>> Impl 2/3]`, Debug cycle: `[>> Debug <>1]`

## Workspace

```
.task/
  pipeline-summary.md    <- pipeline summary (updated after each stage)
  00-spec.md             <- brainstorm output (or transformed ready-made spec)
  01-analysis.md
  02-scout.md
  03-decomposition.md
  04-research-{N}.md     (per module)
  05-plan-{N}.md         (per module)
  05.5-design-{N}.md     (per UI module, only if Designer ran)
  06-impl-{N}.md         (per module)
  07-tests-{N}-{C}.md    (per module, per cycle)
  08-debug-{N}-{C}.md    (per module, per cycle)
  08.5-design-qa-{N}.md  (per UI module, only if Design QA ran)
  09-review.md
  10-refactor.md
  11-docs.md
  12-commit.md
```

**First step**: `mkdir -p .task`

## Pipeline Summary File

After each stage completes, update `.task/pipeline-summary.md` with one line per stage:

```markdown
# Pipeline Summary
- **Task**: [1-sentence description from Analyst]
- **Type**: feature | **Scope**: medium | **Pipeline**: full
- **Stage 1 -- Validator**: ok 5 acceptance criteria, medium risk
- **Stage 2 -- Scout**: ok MERN stack, 4 modules identified, kebab-case conventions
- **Stage 3 -- Decomposer**: ok 3 modules (API -> Frontend -> Tests)
- **Stage 4.1 -- Researcher**: ok module 1, 6 affected files
- **Stage 5.1 -- Planner**: ok module 1, 3 files create, 2 modify
- **Stage 6.1 -- Implementer**: ok Plan 1 done, 3 files created, 2 modified
- **Stage 7.1 -- Tester**: ok 12/12 tests passed
- **Stage 9 -- Reviewer**: ok PASS WITH MINOR ISSUES (0R 1Y 3G 2S)
```

Terminal agents (Documenter, Committer) read **only this file** instead of all briefs.

## Adaptive Entry

When the user provides a ready-made specification, the Brainstormer (Stage 0) is skipped and the Validator (Stage 1) handles transformation and validation directly.

**Detection order** (first match wins):
1. User explicitly passes a file path or pastes spec content in their request
2. A fresh spec exists at `docs/superpowers/specs/` (file modification time within the last hour)
3. A TRC spec exists at the project's `.trc/` or `docs/` directory

**When a ready-made spec is detected:**
- Skip Stage 0 (Brainstormer) entirely
- Pass the document to Stage 1 (Validator)
- The Validator transforms the input into TRC-format `00-spec.md`, then validates as normal
- Pipeline continues from Stage 2 (Scout) onward

**When no ready-made spec is detected:**
- Run Stage 0 (Brainstormer) as normal
- After brainstorm completes, proceed to Stage 1 (Validator)

## Execution Strategy

### Tier 1: Agent Teams (preferred -- parallel execution)

When `agent-teams` plugin is available, use it for stages that benefit from parallelism:

**Multi-module Implementation:**
Independent modules (no dependencies per Decomposer's execution order) can run `[Research->Plan->Impl->Test]` in parallel via agent-teams. Dependent modules run sequentially.

**Review dimensions:**
```
/team-spawn review
```
Performance and Architecture reviewers run in parallel. Security is handled by `security-scanning` plugin separately.

**Debug investigation:**
```
/team-spawn debug --hypotheses 3
```
3 investigators per failure cluster, evidence-based convergence.

For all other stages -- use single-agent execution (no parallelism benefit).

### Tier 2: Subagents (fallback -- isolated context)

When `agent-teams` is unavailable but Task tool exists, spawn each agent as an independent subagent:

```
Spawn subagent:
  - Instructions: Read and follow agents/{agent}.md
  - Input: {only the files listed in Reads column}
  - Output: .task/{output file}
```

### Tier 3: Sequential (last resort)

Execute agents inline, one by one. Use the file system as memory between stages.

## Flow Control

### Approval Gates

Agents with `[approval]` in the pipeline overview present output and wait for explicit user approval before proceeding.

### Test/Debug Cycle

```
Cycle 1: Tester fails -> Debugger -> Implementer fixes -> Tester re-runs
Cycle 2: Still failing -> Debugger -> Implementer -> Tester
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 debug cycles. Never loop indefinitely.

### Design QA Cycle

Runs after Test/Debug cycle completes, only for UI modules with Designer output:

```
Cycle 1: Design QA fails -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs
Cycle 2: Still failing -> Implementer -> Tester -> (Debug) -> Design QA
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 Design QA cycles. Implementer receives `08.5-design-qa-{N}.md` (Required Fixes section) as additional input during fix cycles. Code changes from Design QA fixes must pass through Tester before re-verification.

### Review Issue Routing

| Severity | Action |
|----------|--------|
| Critical | **STOP**. Present to user. Wait for decision. |
| Major | Route to Debugger -> Implementer -> Tester. Re-review. |
| Minor | Pass to Refactorer. |
| Suggestion | Note for Refactorer. Not blocking. |

### Plan Deviations

If Implementer detects a flawed plan -> STOP, report to user. User decides: adjust, re-plan, or override.

### Adaptive Pipeline

| Task Type | Pipeline |
|-----------|----------|
| **feature** | All stages |
| **feature + design** | All stages + Designer (UI modules) + Design QA (UI modules) |
| **bugfix** | Validator -> Scout -> Decomposer -> [Research->Plan->Impl->Test<->Debug] -> Commit |
| **refactor** | Validator -> Scout -> Decomposer -> [Research->Refactor->Review->Test] -> Commit |
| **hotfix** | Validator -> [Impl->Test<->Debug] -> Commit |

Minimum always: Validator + Test + Commit.

Hotfix skips Scout/Decomposer -- speed is critical.

Single-module tasks still go through full flow (Scout -> Decomposer -> Research -> Plan). Consistent and predictable.

## Context Management

1. **File system as memory** -- agents write to `.task/`, downstream read from files
2. **Brief sections** -- every output starts with `## Brief` (5-10 lines)
3. **Pipeline summary** -- terminal agents read `pipeline-summary.md` instead of individual briefs
4. **Dependency map** -- each agent reads only what's in the Reads column
5. **Budget** -- `find`/`grep` before reading; never read files >500 lines fully; max 5-7 files in context
6. **One module at a time** -- Researcher, Planner, Implementer, and Tester process one module per run

## Starting the Pipeline

1. `mkdir -p .task`
2. Check for ready-made spec (see Adaptive Entry above)
3. If no spec found: Read `agents/brainstormer.md` -> execute -> wait for approval -> update `pipeline-summary.md`
4. Read `agents/analyst.md` -> execute validation -> wait for approval -> update `pipeline-summary.md`
5. Read `agents/scout.md` -> execute terrain scan -> update `pipeline-summary.md`
6. Read `agents/decomposer.md` -> execute decomposition -> wait for approval -> update `pipeline-summary.md`
7. For each module (per Decomposer's execution order):
   a. Read `agents/researcher.md` -> execute for module N -> update `pipeline-summary.md`
   b. Read `agents/planner.md` -> execute for module N -> wait for approval -> update `pipeline-summary.md`
   c. If module has `ui: true`: Read `agents/designer.md` -> execute -> wait for approval
   d. Read `agents/implementer.md` -> execute for module N -> wait for approval
   e. Read `agents/tester.md` -> execute -> handle test/debug cycle
   f. If module has `ui: true` and Designer ran: Read `agents/design-qa.md` -> execute -> handle design QA cycle
8. Read `agents/reviewer.md` -> execute -> route issues
9. Read `agents/refactorer.md` -> execute -> wait for approval
10. Read `agents/documenter.md` -> execute -> wait for approval
11. Read `agents/committer.md` -> execute -> present to user

If request is ambiguous -- ask. Don't trigger full pipeline for simple questions.

## Resuming

1. Check `.task/` for existing artifacts
2. Read `pipeline-summary.md` for quick context rebuild
3. Resume from next incomplete stage

## Cleaning Up

After user commits: `rm -rf .task/` -- don't clean up automatically.
