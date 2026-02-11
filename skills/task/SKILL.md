---
name: task
description: Full SDLC pipeline orchestrator that breaks down development tasks into analyzable, plannable, implementable, testable, reviewable, and committable stages. Use this skill whenever the user asks to implement a feature, fix a bug, refactor code, or apply a hotfix. Triggers on phrases like "implement", "build", "fix", "refactor", "add feature", "create", "update", "change", or any development task that involves writing code. Also trigger when the user says "task" or references this pipeline directly. This skill works across single and multi-repo projects.
---

# Task — SDLC Pipeline Orchestrator

You are the orchestrator of a multi-agent development pipeline. Your job is to coordinate agents, manage flow, handle approvals, and ensure the task progresses from request to commit.

You don't do the work yourself — you delegate to specialized agents and manage pipeline state.

## Pipeline Overview

```
 1. Analyst       → analyze task, classify, acceptance criteria       [approval]
 2. Researcher    → scan codebase, gather facts                      [approval]
 3. Planner       → decompose into plans by logical modules          [approval]
 3.5 Designer     → extract design from screenshot (if applicable)   [approval]
    ┌─────────────────────────────────────────────────────────┐
    │ 4. Implementer  → write code for one plan                [approval]
    │ 5. Tester       → test the implementation                        │
    │ 6. Debugger     → hypothesis-driven failure analysis             │
    │    └─→ back to Implementer → Tester (max 2 cycles)              │
    └──────── repeat for each plan ───────────────────────────────────┘
 7. Reviewer      → security (plugin) + performance + architecture
 8. Refactorer    → apply minor fixes from review, re-test           [approval]
 9. Documenter    → update docs, changelog, API docs                 [approval]
10. Committer     → prepare commits + PR description per plan per repo
```

## Agent Reference

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Analyst | `agents/analyst.md` | **opus** | user request | `01-analysis.md` |
| 2 | Researcher | `agents/researcher.md` | sonnet | `01-analysis.md` | `02-research.md` |
| 3 | Planner | `agents/planner.md` | **opus** | `02-research.md`, `01-analysis.md` (brief) | `03-plan.md` |
| 3.5 | Designer | `agents/designer.md` | sonnet | screenshot, `03-plan.md` (brief) | `03.5-design.md` |
| 4 | Implementer | `agents/implementer.md` | sonnet | `03-plan.md` (current), `02-research.md` (brief) | `04-impl-{N}.md` + code |
| 5 | Tester | `agents/tester.md` | sonnet | `04-impl-{N}.md`, `01-analysis.md` (criteria) | `05-tests-{N}-{C}.md` + tests |
| 6 | Debugger | `agents/debugger.md` | sonnet | `05-tests-{N}-{C}.md`, source files | `06-debug-{N}-{C}.md` |
| 7 | Reviewer | `agents/reviewer.md` | sonnet | `04-impl-*.md` (briefs), source files | `07-review.md` |
| 8 | Refactorer | `agents/refactorer.md` | haiku | `07-review.md` (minor + suggestions) | `08-refactor.md` + code |
| 9 | Documenter | `agents/documenter.md` | haiku | `00-summary.md` + doc files | `09-docs.md` + docs |
| 10 | Committer | `agents/committer.md` | haiku | `00-summary.md` | `10-commit.md` |

**Model strategy:** Opus — complex reasoning (analysis, planning). Sonnet — execution (code, tests, debug, review). Haiku — mechanical (refactoring, docs, commits).

**Rule**: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Progress Tracker

Every response starts with a compact pipeline status:

```
[✅ Analyze] → [✅ Research] → [▶ Plan] → [ Design] → [ Implement] → [ Test] → [ Debug] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

Icons: `✅` done · `▶` active · ` ` pending · `⭕` skipped · `🔄` re-run · `❌` failed
Multi-plan: `[▶ Implement 2/3]` · Debug cycle: `[▶ Debug 🔄1]`

## Workspace

```
.task/
├── 00-summary.md          ← pipeline summary (updated after each stage)
├── 01-analysis.md
├── 02-research.md
├── 03-plan.md
├── 03.5-design.md          # only if Designer ran
├── 04-impl-{N}.md
├── 05-tests-{N}-{C}.md
├── 06-debug-{N}-{C}.md
├── 07-review.md
├── 08-refactor.md
├── 09-docs.md
└── 10-commit.md
```

**First step**: `mkdir -p .task`

## Pipeline Summary File

After each stage completes, update `.task/00-summary.md` with one line per stage:

```markdown
# Pipeline Summary
- **Task**: [1-sentence description from Analyst]
- **Type**: feature | **Scope**: medium | **Pipeline**: full
- **Stage 1 — Analyst**: ✅ 5 acceptance criteria, medium risk
- **Stage 2 — Researcher**: ✅ MERN stack, 6 affected files, kebab-case conventions
- **Stage 3 — Planner**: ✅ 2 plans (API layer → Frontend)
- **Stage 4.1 — Implementer**: ✅ Plan 1 done, 3 files created, 2 modified
- **Stage 5.1 — Tester**: ✅ 12/12 tests passed
- **Stage 7 — Reviewer**: ✅ PASS WITH MINOR ISSUES (0🔴 1🟡 3🟢 2💡)
```

Terminal agents (Documenter, Committer) read **only this file** instead of all briefs.

## Execution Strategy

### Tier 1: Agent Teams (preferred — parallel execution)

When `agent-teams` plugin is available, use it for stages that benefit from parallelism:

**Multi-plan Implementation:**
```
/team-spawn feature --plan-first
```
Each plan gets its own implementer with file ownership boundaries. Plans still run Implement→Test per plan, but independent plans can run in parallel.

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

For all other stages — use single-agent execution (no parallelism benefit).

### Tier 2: Subagents (fallback — isolated context)

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
Cycle 1: Tester fails → Debugger → Implementer fixes → Tester re-runs
Cycle 2: Still failing → Debugger → Implementer → Tester
Cycle 3: STOP → Escalate to user with full context
```

Maximum 2 debug cycles. Never loop indefinitely.

### Review Issue Routing

| Severity | Action |
|----------|--------|
| 🔴 Critical | **STOP**. Present to user. Wait for decision. |
| 🟡 Major | Route to Debugger → Implementer → Tester. Re-review. |
| 🟢 Minor | Pass to Refactorer. |
| 💡 Suggestion | Note for Refactorer. Not blocking. |

### Plan Deviations

If Implementer detects a flawed plan → STOP, report to user. User decides: adjust, re-plan, or override.

### Adaptive Pipeline

| Task Type | Pipeline |
|-----------|----------|
| **feature** | All stages |
| **feature + design** | All stages including Designer |
| **bugfix** | Analyze → Research → Plan → [Impl→Test⇄Debug] → Commit |
| **refactor** | Analyze → Research → Plan → Refactor → Review → Test → Commit |
| **hotfix** | Analyze → [Impl→Test⇄Debug] → Commit |

Minimum always: Analyze + Test + Commit.

## Context Management

1. **File system as memory** — agents write to `.task/`, downstream read from files
2. **Brief sections** — every output starts with `## Brief` (5-10 lines)
3. **Pipeline summary** — terminal agents read `00-summary.md` instead of individual briefs
4. **Dependency map** — each agent reads only what's in the Reads column
5. **Budget** — `find`/`grep` before reading; never read files >500 lines fully; max 5-7 files in context
6. **One plan at a time** — Implementer and Tester process one plan per run

## Starting the Pipeline

1. `mkdir -p .task`
2. Read `agents/analyst.md`
3. Execute Analyst → present → wait for approval
4. Update `00-summary.md`
5. Continue to next agent, following flow control

If request is ambiguous — ask. Don't trigger full pipeline for simple questions.

## Resuming

1. Check `.task/` for existing artifacts
2. Read `00-summary.md` for quick context rebuild
3. Resume from next incomplete stage

## Cleaning Up

After user commits: `rm -rf .task/` — don't clean up automatically.
