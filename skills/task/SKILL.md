---
name: task
description: Full SDLC pipeline orchestrator that breaks down development tasks into analyzable, plannable, implementable, testable, reviewable, and committable stages. Use this skill whenever the user asks to implement a feature, fix a bug, refactor code, or apply a hotfix. Triggers on phrases like "implement", "build", "fix", "refactor", "add feature", "create", "update", "change", or any development task that involves writing code. Also trigger when the user says "task" or references this pipeline directly. This skill works across single and multi-repo projects.
---

# Task — SDLC Pipeline Orchestrator

You are the orchestrator of a 10-agent development pipeline. Your job is to coordinate agents, manage the flow between them, handle approvals, and ensure the task progresses smoothly from request to commit.

You don't do the work yourself — you delegate to specialized agents and manage the pipeline state.

## Pipeline Overview

```
1. Analyst       → analyze task, classify, acceptance criteria    [wait for approval]
2. Researcher    → scan codebase, gather facts                   [wait for approval]
3. Planner       → decompose into plans by logical modules       [wait for approval]
   ┌──────────────────────────────────────────────────────┐
   │ 4. Implementer  → write code for one plan             [wait for approval]
   │ 5. Tester       → test the implementation                              │
   │ 6. Debugger     → analyze failures (if any)                            │
   │    └─→ back to Implementer → Tester (max 2 cycles)                    │
   └──────── repeat for each plan ────────────────────────┘
7. Reviewer      → code review all plans together
8. Refactorer    → apply minor fixes from review, re-test       [wait for approval]
9. Documenter    → update docs, changelog, API docs             [wait for approval]
10. Committer    → prepare commit messages per plan per repo
```

## Agent Reference

| # | Agent | File | Reads | Writes |
|---|-------|------|-------|--------|
| 1 | Analyst | `agents/analyst.md` | user request | `01-analysis.md` |
| 2 | Researcher | `agents/researcher.md` | `01-analysis.md` (full) | `02-research.md` |
| 3 | Planner | `agents/planner.md` | `02-research.md` (full), `01-analysis.md` (brief) | `03-plan.md` |
| 4 | Implementer | `agents/implementer.md` | `03-plan.md` (current plan only), `02-research.md` (brief) | `04-implementation-{N}.md` + code |
| 5 | Tester | `agents/tester.md` | `04-implementation-{N}.md` (full), `01-analysis.md` (criteria), `03-plan.md` (verification) | `05-tests-{N}-{cycle}.md` + tests |
| 6 | Debugger | `agents/debugger.md` | `05-tests-{N}-{cycle}.md` (full), source files (targeted) | `06-debug-{N}-{cycle}.md` |
| 7 | Reviewer | `agents/reviewer.md` | `04-implementation-*.md` (summaries), source files, `01-analysis.md` (criteria), `03-plan.md` (brief) | `07-review.md` |
| 8 | Refactorer | `agents/refactorer.md` | `07-review.md` (minor + suggestions only), source files | `08-refactor.md` + code |
| 9 | Documenter | `agents/documenter.md` | all `.task/*.md` (briefs only), doc files | `09-docs.md` + docs |
| 10 | Committer | `agents/committer.md` | all `.task/*.md` (briefs only) | `10-commit.md` |

## Progress Tracker

Every time you present output to the user (after each agent completes), include a compact pipeline diagram showing the current position. Use this format:

**For a full feature pipeline:**
```
[✅ Analyze] → [✅ Research] → [▶ Plan] → [ Implement] → [ Test] → [ Debug] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

**Legend:**
- `✅` — completed
- `▶` — current stage (active now)
- ` ` — pending (empty, no icon)
- `⏭` — skipped (determined by Analyst)
- `🔄` — re-running (debug cycle or review fix)

**For adaptive pipelines (e.g., hotfix):**
```
[✅ Analyze] → [⏭ Research] → [⏭ Plan] → [▶ Implement] → [ Test] → [ Debug] → [⏭ Review] → [⏭ Refactor] → [⏭ Document] → [ Commit]
```

**Multi-plan progress — show which plan we're on:**
```
[✅ Analyze] → [✅ Research] → [✅ Plan] → [▶ Implement 2/3] → [ Test] → [ Debug] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

**Debug cycle — show cycle count:**
```
[✅ Analyze] → [✅ Research] → [✅ Plan] → [✅ Implement 1/3] → [✅ Test ❌] → [▶ Debug 🔄1] → [ Implement] → [ Test] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

Place this diagram at the **top** of every response to the user, before any agent output or approval request. Keep it on 1-2 lines — it should be a quick visual glance, not a wall of text.

## Workspace

All pipeline artifacts are stored in a `.task/` directory at the project root:

```
project-root/
└── .task/
    ├── 01-analysis.md
    ├── 02-research.md
    ├── 03-plan.md
    ├── 04-implementation-1.md
    ├── 04-implementation-2.md
    ├── 05-tests-1-1.md
    ├── 05-tests-1-2.md          # cycle 2 after debug
    ├── 06-debug-1-1.md
    ├── 07-review.md
    ├── 08-refactor.md
    ├── 09-docs.md
    └── 10-commit.md
```

For multi-repo tasks, each repo gets its own `.task/` directory.

**First step**: always create the `.task/` directory before spawning any agent:

```bash
mkdir -p .task
```

## Execution Strategy

### With Subagents (preferred)

When the `Task` tool is available (Claude Code), spawn each agent as an independent subagent with its own clean context. Pass the agent file and required inputs:

```
Spawn subagent:
  - Instructions: Read and follow agents/analyst.md
  - Input: user_request="...", project_context="..."
  - Output: .task/01-analysis.md
```

Each subagent gets only the files it needs (see dependency map above). This keeps each agent's context clean and focused.

### Without Subagents (fallback)

If subagents are unavailable, execute agents sequentially in your own context. For each agent:

1. Read the agent's `.md` file for instructions
2. Follow the process steps
3. Write the output file
4. Proceed to the next agent

**Important in fallback mode**: Use the file system as your memory. After completing each agent's work, the output file becomes the source of truth. When starting the next agent, read from files rather than relying on your conversation context. This simulates the isolation that subagents provide naturally.

## Flow Control

### Approval Gates

These agents require user approval before the pipeline continues:

| Agent | Approval Point | What user sees |
|-------|---------------|----------------|
| Analyst | After analysis | Task classification, acceptance criteria, pipeline plan |
| Researcher | After research | Codebase findings, affected zone, conventions |
| Planner | After planning | Decomposed plans, execution order |
| Implementer | After each plan | Implementation log, files changed |
| Refactorer | After refactoring | Changes applied, test results |
| Documenter | After docs | Documentation updates |

Present the agent's output to the user and wait for explicit approval before continuing.

### Error Handling — Test/Debug Cycle

When the Tester reports failures:

```
Cycle 1:
  Tester finds failures → Debugger analyzes → Implementer fixes → Tester re-runs

Cycle 2 (if still failing):
  Tester finds failures → Debugger analyzes → Implementer fixes → Tester re-runs

Cycle 3 (if STILL failing):
  STOP → Escalate to user with full context:
    - What was attempted
    - What keeps failing
    - Debugger's analysis
    - Recommendation
```

Maximum 2 debug cycles before escalation. Never loop indefinitely.

### Error Handling — Review Issues

When the Reviewer finds issues:

| Severity | Action |
|----------|--------|
| 🔴 Critical | **STOP** pipeline. Present to user. Wait for decision. |
| 🟡 Major | Route to Debugger → Implementer → Tester. Then re-review affected areas only. |
| 🟢 Minor | Pass to Refactorer. |
| 💡 Suggestion | Note for Refactorer. Not blocking. |

### Error Handling — Plan Deviations

If the Implementer detects that a plan is flawed:

1. Implementer **STOPS** and reports the issue
2. You present the deviation to the user
3. User decides: adjust plan, re-plan, or override
4. If re-plan needed → spawn Planner again with updated context

### Adaptive Pipeline

Not every task needs all 10 agents. The Analyst determines which stages run based on task type:

| Task Type | Default Pipeline |
|-----------|-----------------|
| **feature** | All 10 stages |
| **bugfix** | Analyze → Research → Plan → [Implement → Test ⇄ Debug] → Commit |
| **refactor** | Analyze → Research → Plan → Refactor → Review → Test → Commit |
| **hotfix** | Analyze → [Implement → Test ⇄ Debug] → Commit |

The Analyst can customize this further based on task specifics. Always include at minimum: Analyze, Test, Commit.

## Context Management Rules

These rules keep each agent's context lightweight:

### Rule 1: File System as Memory
Every agent writes its output to a file. Downstream agents read from files, not from conversation history. This is the foundation of context isolation.

### Rule 2: Brief Sections
Every agent output starts with a `## Brief` section — a compressed 5-10 line summary. Agents that don't need full details read only this section.

### Rule 3: Dependency Map
Each agent reads only what it needs. See the Agent Reference table above. Never pass more data than specified.

### Rule 4: Practical Budget Guidelines
Agents should follow these guidelines to stay lightweight:
- Use `find`, `grep`, `tree` to locate files before reading them
- Never read an entire file longer than 500 lines — read only relevant sections
- Don't load more than 5-7 files into context simultaneously
- Extract what you need, write it down, move on
- Short code snippets only in outputs — 10-20 lines max per snippet

### Rule 5: One Plan at a Time
The Implementer and Tester process one plan per run. They never see other plans. This is the key mechanism that keeps large tasks manageable.

## Starting the Pipeline

When the user gives you a task:

1. Create `.task/` directory
2. Read `agents/analyst.md`
3. Spawn (or execute inline) the Analyst with the user's request
4. Present the analysis to the user
5. On approval, continue to the next agent
6. Follow the flow control rules above

If the user's request is ambiguous about whether this is a "task" or just a question — ask. Don't trigger the full pipeline for simple questions that don't involve code changes.

## Resuming an Interrupted Pipeline

If the pipeline was interrupted (context limit, error, user pause):

1. Check `.task/` directory for existing artifacts
2. Find the last completed stage (highest numbered file)
3. Resume from the next stage
4. Read the Brief sections of all completed stages to rebuild context

## Cleaning Up

After the user has committed (or decided not to), the `.task/` directory can be removed:

```bash
rm -rf .task/
```

Don't clean up automatically — let the user decide. The artifacts can be useful for reference.