#  AI Arsenal

A personal collection of AI-powered skills, sub-agents, hooks, workflows, and response formats for Claude — your SDLC autopilot.

## Overview

AI Arsenal is a modular toolkit that supercharges Claude with reusable components for software development. The centerpiece is the **Task** skill — an orchestrator that runs 10 specialized sub-agents through a complete development lifecycle.

## Repository Structure

```
ai-arsenal/
├── skills/              # Claude skills (triggers + instructions)
│   └── task/            # 🎯 Master SDLC orchestrator
│       ├── SKILL.md     # Orchestrator — manages pipeline flow
│       └── agents/      # 10 sub-agents, one per stage
├── prompts/             # System prompts & prompt templates
├── workflows/           # Multi-step automation scenarios
├── templates/           # File generation templates (README, PR, commits)
├── evaluations/         # Test cases & quality benchmarks
├── configs/             # MCP servers, model configs, parameters
├── examples/            # Usage examples for each component
└── docs/                # Conventions, guidelines, architecture
```

## 🎯 Task Skill — SDLC Pipeline

The Task skill orchestrates 10 sub-agents through a complete development lifecycle. Each agent runs in an isolated context (via Claude Code subagents) and communicates through files, keeping context lightweight.

### Agents

| # | Agent | Role | Approval |
|---|-------|------|----------|
| 1 | **Analyst** | Task classification, acceptance criteria, risk assessment, pipeline selection | ✅ |
| 2 | **Researcher** | Codebase scanning, structure mapping, conventions discovery | ✅ |
| 3 | **Planner** | Decompose task into implementable plans by logical modules | ✅ |
| 4 | **Implementer** | Execute one plan — write code following conventions | ✅ |
| 5 | **Tester** | Write & run tests: unit, integration, endpoint, e2e, performance | — |
| 6 | **Debugger** | Analyze test failures, localize root causes, create fix report | — |
| 7 | **Reviewer** | Code review: quality, security, performance, SOLID, edge cases | — |
| 8 | **Refactorer** | Apply minor improvements from review, re-run tests | ✅ |
| 9 | **Documenter** | Update README, CHANGELOG, API docs, JSDoc, inline comments | ✅ |
| 10 | **Committer** | Prepare conventional commit messages per plan per repo | — |

### Pipeline Flow

```
User Request
    │
    ▼
┌───────────┐   ┌────────────┐   ┌──────────┐
│ 1.Analyze │──▶│ 2.Research  │──▶│ 3.Plan   │
│  [aprv]   │   │   [aprv]   │   │  [aprv]  │
└───────────┘   └────────────┘   └──────────┘
                                      │
                    ┌─────────────────┘
                    ▼
              ╔═══════════════════════════════╗
              ║  For each plan (× N):         ║
              ║                               ║
              ║  ┌───────────┐   ┌─────────┐  ║
              ║  │4.Implement│──▶│ 5.Test  │  ║
              ║  │  [aprv]   │   │         │  ║
              ║  └───────────┘   └────┬────┘  ║
              ║       ▲               │       ║
              ║       │          pass?│       ║
              ║       │         ┌─────┴────┐  ║
              ║       │    no──▶│ 6.Debug  │  ║
              ║       │         └──────────┘  ║
              ║       └── fix ◀───────┘       ║
              ║       (max 2 cycles)          ║
              ╚═══════════════════════════════╝
                    │
                    ▼
┌───────────┐   ┌────────────┐   ┌───────────┐   ┌───────────┐
│ 7.Review  │──▶│ 8.Refactor │──▶│ 9.Document│──▶│10.Commit  │
│           │   │   [aprv]   │   │   [aprv]  │   │           │
└───────────┘   └────────────┘   └───────────┘   └───────────┘
```

### Key Architecture Decisions

**Context Isolation** — Each agent runs in its own clean context (subagent). Agents communicate through files in `.task/` directory, reading only what they need via a strict dependency map.

**Brief Sections** — Every agent output starts with a compressed summary. Downstream agents that don't need full details read only the Brief.

**Adaptive Pipeline** — Not every task uses all 10 agents. The Analyst determines which stages are needed:

| Task Type | Pipeline |
|-----------|----------|
| Feature | All 10 stages |
| Bugfix | Analyze → Research → Plan → [Impl→Test⇄Debug] → Commit |
| Refactor | Analyze → Research → Plan → Refactor → Review → Test → Commit |
| Hotfix | Analyze → [Impl→Test⇄Debug] → Commit |

**Multi-Plan Decomposition** — Large tasks are split into plans by logical module. Each plan runs its own Implement→Test cycle, keeping context per-agent under control.

**Multi-Repo Support** — The Committer prepares separate conventional commit messages per plan per repository.

**Debug Cycles** — Max 2 Test→Debug→Implement cycles before escalating to the user.

## Getting Started

### Claude Code (recommended)

1. Clone this repo
2. Add the skill to your Claude Code configuration:
   ```bash
   # Copy to your project's skills directory
   cp -r skills/task /path/to/your/project/.claude/skills/
   ```
3. Start a task: *"Implement user authentication with JWT"*

### Fallback (without subagents)

The pipeline works in sequential mode too — the orchestrator executes each agent's instructions inline, using the file system for state management between stages.
