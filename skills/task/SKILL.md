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
    └──────── repeat for each plan ───────────────────────────┘
 7. Reviewer      → parallel review: security + performance + arch
 8. Refactorer    → apply minor fixes from review, re-test           [approval]
 9. Documenter    → update docs, changelog, API docs                 [approval]
10. Committer     → prepare commits + PR description per plan per repo
```

## Progressive Disclosure

Agents use a 3-level loading strategy to minimize token usage:

**Level 1 — Metadata** (always loaded, ~100 tokens per agent):
The table below. The orchestrator sees all agent names, models, and I/O at a glance.

**Level 2 — Instructions** (loaded when agent activates):
The full agent `.md` file. Read it only when spawning or executing that agent.

**Level 3 — References** (loaded on-demand inside agent):
Examples, templates, checklists embedded in agent files. Agents load these sections only when needed for their current subtask.

**Rule**: Never pre-read all agent files. Read an agent file only at the moment you need to execute it.

## Agent Reference (Level 1)

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Analyst | `agents/analyst.md` | **opus** | user request | `01-analysis.md` |
| 2 | Researcher | `agents/researcher.md` | sonnet | `01-analysis.md` | `02-research.md` |
| 3 | Planner | `agents/planner.md` | **opus** | `02-research.md`, `01-analysis.md` (brief) | `03-plan.md` |
| 3.5 | Designer | `agents/designer.md` | sonnet | screenshot/image, `03-plan.md` (brief) | `03.5-design.md` |
| 4 | Implementer | `agents/implementer.md` | sonnet | `03-plan.md` (current plan), `02-research.md` (brief), `03.5-design.md` (if exists) | `04-impl-{N}.md` + code |
| 5 | Tester | `agents/tester.md` | sonnet | `04-impl-{N}.md`, `01-analysis.md` (criteria) | `05-tests-{N}-{C}.md` + tests |
| 6 | Debugger | `agents/debugger.md` | sonnet | `05-tests-{N}-{C}.md`, source files | `06-debug-{N}-{C}.md` |
| 7 | Reviewer | `agents/reviewer.md` | sonnet | `04-impl-*.md` (summaries), source files, `01-analysis.md` (criteria) | `07-review.md` |
| 8 | Refactorer | `agents/refactorer.md` | haiku | `07-review.md` (minor + suggestions) | `08-refactor.md` + code |
| 9 | Documenter | `agents/documenter.md` | haiku | all `.task/*.md` (briefs only), doc files | `09-docs.md` + docs |
| 10 | Committer | `agents/committer.md` | haiku | all `.task/*.md` (briefs only) | `10-commit.md` |

### Model Strategy

- **Opus** — complex reasoning: task decomposition, architectural decisions
- **Sonnet** — execution: code, tests, debugging, review, design extraction
- **Haiku** — mechanical: applying known fixes, generating docs, formatting commits

When spawning subagents, use the recommended model if runtime supports it. Otherwise fall back to session model.

## Progress Tracker

Every response to the user starts with a compact pipeline status:

```
[✅ Analyze] → [✅ Research] → [▶ Plan] → [ Design] → [ Implement] → [ Test] → [ Debug] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

**Icons**: `✅` done · `▶` active · ` ` pending · `⏭` skipped · `🔄` re-run · `❌` failed

**Multi-plan**: `[▶ Implement 2/3]`
**Debug cycle**: `[▶ Debug 🔄1]`
**Skipped Designer**: `[⏭ Design]`

Keep it on 1-2 lines at the top of every response.

## Workspace

All artifacts live in `.task/` at project root:

```
.task/
├── 01-analysis.md
├── 02-research.md
├── 03-plan.md
├── 03.5-design.md          # only if Designer ran
├── 04-impl-1.md
├── 04-impl-2.md
├── 05-tests-1-1.md
├── 05-tests-1-2.md          # cycle 2
├── 06-debug-1-1.md
├── 07-review.md
├── 08-refactor.md
├── 09-docs.md
└── 10-commit.md
```

Multi-repo: each repo gets its own `.task/`.

**First step**: `mkdir -p .task`

## Execution Strategy

### With Subagents (preferred)

When `Task` tool is available, spawn each agent as an independent subagent:

```
Spawn subagent:
  - Instructions: Read and follow agents/{agent}.md
  - Input: {only the files listed in Reads column}
  - Output: .task/{output file}
```

Each subagent gets only the files it needs. This keeps context clean.

**Parallel subagents** — the Reviewer spawns 3 subagents simultaneously for its review dimensions (security, performance, architecture). See reviewer.md for details.

### Without Subagents (fallback)

Execute agents sequentially. For each agent:
1. Read the agent's `.md` file
2. Follow the process steps
3. Write the output file
4. Proceed to next agent

Use the file system as memory — read from `.task/` files, not conversation history.

## Flow Control

### Approval Gates

| Agent | What user sees |
|-------|----------------|
| Analyst | Task classification, acceptance criteria, pipeline stages |
| Researcher | Codebase findings, conventions, affected zone |
| Planner | Decomposed plans, execution order |
| Designer | Extracted design tokens, component map |
| Implementer | Implementation log per plan, files changed |
| Refactorer | Changes applied, test results |
| Documenter | Documentation updates |

Present output and wait for explicit approval.

### Test/Debug Cycle

```
Cycle 1: Tester fails → Debugger (3 hypotheses) → Implementer fixes → Tester re-runs
Cycle 2: Still failing → Debugger → Implementer → Tester
Cycle 3: STOP → Escalate to user with full context
```

Maximum 2 debug cycles. Never loop indefinitely.

### Review Issue Routing

| Severity | Action |
|----------|--------|
| 🔴 Critical | **STOP**. Present to user. Wait for decision. |
| 🟡 Major | Route to Debugger → Implementer → Tester. Re-review affected areas. |
| 🟢 Minor | Pass to Refactorer. |
| 💡 Suggestion | Note for Refactorer. Not blocking. |

### Plan Deviations

If Implementer detects a flawed plan:
1. Implementer **STOPS** and reports
2. Present deviation to user
3. User decides: adjust, re-plan, or override
4. If re-plan → spawn Planner with updated context

### Adaptive Pipeline

The Analyst determines which stages run:

| Task Type | Pipeline |
|-----------|----------|
| **feature** | All stages |
| **feature + design** | All stages including Designer |
| **bugfix** | Analyze → Research → Plan → [Impl → Test ⇄ Debug] → Commit |
| **refactor** | Analyze → Research → Plan → Refactor → Review → Test → Commit |
| **hotfix** | Analyze → [Impl → Test ⇄ Debug] → Commit |

Minimum always: Analyze + Test + Commit.

Designer activates only when `has_design_input: true` in analysis.

## Context Management

### Rule 1: File System as Memory
Every agent writes output to `.task/`. Downstream agents read from files, not conversation.

### Rule 2: Brief Sections
Every output starts with `## Brief` — a 5-10 line summary. Agents needing only context read this section.

### Rule 3: Dependency Map
Each agent reads only what's in the Reads column. Never pass more.

### Rule 4: Budget Guidelines
- Use `find`, `grep`, `tree` before reading files
- Never read files longer than 500 lines fully — read relevant sections
- Max 5-7 files in context simultaneously
- Short code snippets in outputs — 10-20 lines max

### Rule 5: One Plan at a Time
Implementer and Tester process one plan per run. Never see other plans.

## Starting the Pipeline

1. Create `.task/` directory
2. Read `agents/analyst.md`
3. Execute Analyst with user's request
4. Present analysis to user
5. On approval, continue to next agent
6. Follow flow control rules

If request is ambiguous — ask. Don't trigger full pipeline for simple questions.

## Resuming an Interrupted Pipeline

1. Check `.task/` for existing artifacts
2. Find last completed stage (highest numbered file)
3. Resume from next stage
4. Read Brief sections of completed stages to rebuild context

## Cleaning Up

After user commits (or decides not to):
```bash
rm -rf .task/
```
Don't clean up automatically — let user decide.
