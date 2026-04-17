# AI Arsenal

A modular toolkit that supercharges Claude Code with reusable skills, sub-agents, and workflows for software development. The centerpiece is the **Task** skill — a scope-adaptive orchestrator that runs up to 15 specialized agents (including per-module Reviewer-Lite) through a complete development lifecycle, with optional delegation to the `superpowers` plugin for Planner/Debugger/Implementer/Tester.

## What It Does

You give Claude a development task. The Task skill classifies it by **scope** (XS/S/M/L/XL), picks the matching pipeline, dispatches the needed agents, gates approvals by the chosen **tier** (strict/standard/express), and produces clean commits — keeping context lightweight through file-based communication.

```
You: "Add JWT authentication with refresh tokens"

Task: Spec → Scout → Decomposer → (Researcher → Planner → Implementer → Tester)×N → Reviewer → Refactorer → Documenter → Committer
      ↑ 1 stage (merged Brainstormer+Validator)      ↑ per-module loops   ↑ security-scanning   ↑ git-pr-workflows
```

### Invocation examples

```
scope: s, tier: express
Rename getUserById to fetchUserById in user-service.

(auto-classified scope-M, default standard tier, 3 approvals)
Add email notifications for password reset.

scope: l, tier: strict
Migrate authentication stack to OAuth2 with refresh tokens.
```

## Architecture

### Pipeline (full — scope L/XL strict tier)

```
User Request
    │
    ▼
┌──────────┐   ┌──────────┐   ┌────────────┐
│ 1.Spec   │──▶│ 2.Scout  │──▶│3.Decompose │
│ [aprv*]  │   │          │   │  [aprv*]   │
└──────────┘   └──────────┘   └────────────┘
                                     │
                    ┌────────────────┘
                    ▼
              ╔═══════════════════════════════════════╗
              ║  For each module (× N):                ║
              ║                                       ║
              ║  ┌──────────┐  ┌──────────┐           ║
              ║  │4.Research│─▶│ 5.Plan   │           ║
              ║  └──────────┘  │ [aprv*]  │           ║
              ║                └────┬─────┘           ║
              ║       ┌─────────────┤ 5.5.Design(UI)  ║
              ║       ▼             ▼ [aprv*]         ║
              ║  ┌──────────┐  ┌──────────┐           ║
              ║  │6.Implmnt │─▶│ 7.Test   │           ║
              ║  │ [aprv*]  │  └────┬─────┘           ║
              ║  └──────────┘       │                 ║
              ║       ▲             │ pass?           ║
              ║       │        ┌────┴─────┐           ║
              ║       │   no──▶│ 8.Debug  │           ║
              ║       └── fix ◀┘          │           ║
              ║       (max 2 cycles)                  ║
              ║                ┌ 8.5.DesignQA(UI)     ║
              ╚═══════════════════════════════════════╝
                    │
                    ▼
┌──────────┐   ┌────────────┐   ┌───────────┐   ┌───────────┐
│ 9.Review │──▶│10.Refactor │──▶│11.Document│──▶│12.Commit  │
│          │   │  [aprv*]   │   │  [aprv*]  │   │  [aprv]   │
└──────────┘   └────────────┘   └───────────┘   └───────────┘
```

`[aprv]` = always gated. `[aprv*]` = gated only in strict tier (see Approval Tiers below).

### Scope-Adaptive Pipeline

Pipeline selection is scope-driven. The skill skips heavyweight stages for smaller tasks:

| Scope | Signals | Pipeline family | Typical approvals |
|---|---|---|---|
| **XS** | 1 file, 1 module | Impl → Test → Commit | 1 (express) |
| **S** | 2-5 files, 1 module | Spec → Plan → Impl → Test → Commit | 1 (express) |
| **M** | 5-15 files, 2-3 modules | Spec → Scout → Decompose → per-module loop → Commit | 3 (standard) |
| **L** | 15-40 files, 3-5 modules | M + Reviewer + Refactorer + Documenter | ~11-13 (strict) |
| **XL** | 40+ files OR UI | L + Designer + Design-QA | pre-redesign behavior |

Full (scope, task_type) matrix in `skills/task/agents/refs/scope-pipelines.md`.

### Approval Tiers

| Tier | When gates fire | Default for |
|---|---|---|
| strict | every pre-redesign gate (Spec, Decompose, Plan×N, Design×N, Impl×N, Refactor, Doc, Commit) | scope L, XL |
| standard | Spec, Decompose, Commit only (3 gates) | scope M |
| express | Commit only (1 gate) | scope XS, S |

Users override tier at invocation with `tier: <strict\|standard\|express>` in the preamble, or mid-flight by replying "approve and switch to <tier>" at any gate. Full rules in `skills/task/agents/refs/approval-tiers.md`.

### Agents (15 total)

| # | Agent | Model | What It Does | Strict-tier approval |
|---|-------|-------|-------------|----------|
| 1 | **Spec** | sonnet (interactive) / haiku (validate) | Dialogue or validate ready-made doc → `00-spec.md` + Validation section | ✅ |
| 2 | **Scout** | haiku | Project structure, conventions, affected zones | — |
| 3 | **Decomposer** | **opus** | Split task into modules with execution order | ✅ |
| 4 | **Researcher** | sonnet | Deep per-module research. Uses `context7` for library docs | — |
| 5 | **Planner** | **opus** | Per-module implementation plan | ✅ |
| 5.5 | **Designer** | sonnet | Extract design tokens. Complements `frontend-design` plugin | ✅ |
| 6 | **Implementer** | sonnet | Execute one plan — write code following conventions | ✅ |
| 7 | **Tester** | sonnet | Write & run tests: unit, integration, endpoint, e2e, performance | — |
| 8 | **Debugger** | sonnet | Hypothesis-driven failure analysis, 3 competing hypotheses | — |
| 8.5 | **Design-QA** | haiku | Verify implementation matches Designer's checklist | — |
| 9.5 | **Reviewer-Lite** | haiku | Per-module critical-issue scan (secrets, N+1, SQLi, unhandled external, unbounded loops). Runs at scope M+ except hotfix. (Cycle 2) | ✅ |
| 9 | **Reviewer** | sonnet | Performance + architecture review. Delegates security to `security-scanning`. Reads Reviewer-Lite output to dedupe. | — |
| 10 | **Refactorer** | haiku | Apply minor improvements from review, re-run tests | ✅ |
| 11 | **Documenter** | haiku | Update README, CHANGELOG, API docs, inline comments | ✅ |
| 12 | **Committer** | haiku | Conventional commits. Delegates PR description to `git-pr-workflows` | ✅ (always) |

Model tiers are authoritative in `skills/task/agents/refs/model-tiers.md` — single source of truth, dispatch-time lookup.

### Plugin Integrations

The pipeline delegates specialized work to external plugins when available, falling back to built-in behavior when not:

| Plugin | Used By | Purpose | Fallback |
|--------|---------|---------|----------|
| `security-scanning` | Reviewer | OWASP-based security audit | Built-in SAST checklist (`refs/security-checklist.md`) |
| `git-pr-workflows` | Committer | PR description generation | Manual summary in commit output |
| `agent-teams` | Orchestrator | Parallel execution for Review, multi-plan Implement, Debug | Sequential subagents |
| `context7` (MCP) | Researcher | Live library documentation lookup | Infer from existing code |
| `frontend-design` | Designer | Production-grade UI code generation | Designer tokens only |

### Execution Modes

The orchestrator picks the best available execution strategy:

| Mode | When | How |
|------|------|-----|
| **Agent Teams** (parallel) | `agent-teams` plugin installed | `/team-spawn review`, `/team-spawn feature --plan-first`, `/team-spawn debug` |
| **Subagents** (isolated) | Claude Code Task tool available | Each agent spawns in clean context |
| **Sequential** (inline) | Fallback | Agents execute one by one in conversation |

### Context Strategy

Agents communicate through files, not conversation history. This keeps each agent's context window clean:

- **`.task/` workspace** — every agent writes output to numbered files (`01-analysis.md`, `02-research.md`, etc.)
- **Brief sections** — every output starts with a 5-10 line summary. Downstream agents read only briefs when full context isn't needed
- **Pipeline summary** — `00-summary.md` accumulates one line per completed stage. Terminal agents (Documenter, Committer) read only this file
- **Dependency map** — each agent reads only its declared inputs (see SKILL.md Agent Reference table)
- **Refs on demand** — checklists and examples live in `agents/refs/` and load only when needed (Level 3 progressive disclosure)

### Adaptive Pipeline

Not every task uses all 10 agents:

| Task Type | Pipeline |
|-----------|----------|
| Feature | All 10 stages |
| Feature + Design | All stages including Designer |
| Bugfix | Analyze → Research → Plan → [Impl→Test⇄Debug] → Commit |
| Refactor | Analyze → Research → Plan → Refactor → Review → Test → Commit |
| Hotfix | Analyze → [Impl→Test⇄Debug] → Commit |

## Repository Structure

```
ai-arsenal/
├── skills/
│   └── task/                          # SDLC pipeline orchestrator
│       ├── SKILL.md                   # Orchestrator — manages pipeline flow
│       └── agents/                    # 10 specialized agents + Designer
│           ├── analyst.md             # Task analysis (opus)
│           ├── researcher.md          # Codebase investigation (sonnet)
│           ├── planner.md             # Plan decomposition (opus)
│           ├── designer.md            # Design extraction (sonnet)
│           ├── implementer.md         # Code writing (sonnet)
│           ├── tester.md              # Test writing & running (sonnet)
│           ├── debugger.md            # Failure diagnosis (sonnet)
│           ├── reviewer.md            # Code review (sonnet)
│           ├── refactorer.md          # Minor improvements (haiku)
│           ├── documenter.md          # Documentation updates (haiku)
│           ├── committer.md           # Commit preparation (haiku)
│           └── refs/                  # On-demand references (Level 3)
│               ├── security-checklist.md
│               ├── performance-checklist.md
│               ├── architecture-checklist.md
│               ├── debug-examples.md
│               ├── design-tokens-example.md
│               ├── doc-formats.md
│               └── commit-template.md
├── prompts/                           # System prompts & prompt templates
├── workflows/                         # Multi-step automation scenarios
├── templates/                         # File generation templates
├── evaluations/                       # Test cases & quality benchmarks
├── configs/                           # MCP servers, model configs
├── examples/                          # Usage examples
└── docs/                              # Conventions, guidelines
```

## Setup

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured
- A project repository to work on

### Step 1: Install the Skill

```bash
# Clone ai-arsenal
git clone https://github.com/emvardanian/ai-arsenal.git

# Copy the task skill to your project
cp -r ai-arsenal/skills/task /path/to/your/project/.claude/skills/
```

Or symlink for all projects:

```bash
# Global skills directory
mkdir -p ~/.claude/skills
ln -s /path/to/ai-arsenal/skills/task ~/.claude/skills/task
```

### Step 2: Install Plugins

These plugins are optional but recommended — the pipeline uses them when available and falls back gracefully when not.

```bash
# Open Claude Code in your project
cd /path/to/your/project
claude

# Security scanning (used by Reviewer for OWASP-based audits)
/plugin install security-scanning@claude-code-workflows

# Git PR workflows (used by Committer for PR descriptions)
/plugin install git-pr-workflows@claude-code-workflows

# Agent Teams (parallel execution for Review, Implement, Debug)
/plugin install agent-teams@claude-code-workflows

# Frontend design (enhances Designer output for UI work)
/plugin install frontend-design@claude-plugins-official
```

### Step 3: Connect MCP Servers

```bash
# context7 — live library documentation lookup (used by Researcher)
# Add to your .mcp.json or configure through Claude Code settings:
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

### Step 4: Verify Installation

```bash
# Start Claude Code
claude

# Check skill is loaded
> What skills do you have?
# Should list "task" among available skills

# Check plugins
> /plugins
# Should show security-scanning, git-pr-workflows, agent-teams, frontend-design

# Quick test
> Implement a health check endpoint that returns { status: "ok", timestamp: ... }
# Should trigger the pipeline: Analyst → Researcher → ...
```

### Step 5 (Optional): Enable Agent Teams

Agent Teams is an experimental Claude Code feature. To enable parallel execution:

```bash
# In your shell
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Or in Claude Code settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Without this, the pipeline falls back to sequential subagents — everything works, just not in parallel.

## Usage

### Start a Task

Just describe what you need:

```
> Implement user authentication with JWT and refresh tokens
> Fix the race condition in the payment processing queue
> Refactor the notification service to use the event bus pattern
> Hotfix: API returns 500 on empty cart checkout
```

The Analyst will classify your request, determine the pipeline, and present an analysis for approval.

### During the Pipeline

The orchestrator shows progress at the top of every response:

```
[✅ Analyze] → [✅ Research] → [▶ Plan] → [ Design] → [ Implement] → [ Test] → [ Debug] → [ Review] → [ Refactor] → [ Document] → [ Commit]
```

At approval gates, review the output and:
- **Approve** → pipeline continues
- **Adjust** → modify the output, re-present
- **Add context** → incorporate new information

### After Completion

The Committer provides ready-to-paste git commands:

```bash
git add src/auth/jwt.ts src/auth/middleware.ts src/models/user.ts
git commit -m "feat(auth): add JWT-based user authentication

Implement token generation, validation middleware, and refresh logic."
```

Clean up when done:

```bash
rm -rf .task/
```

## Design Decisions

**Why file-based communication?** Each agent runs in its own context window. Files in `.task/` act as shared memory — agents write structured outputs and downstream agents read only what they need. This prevents context window exhaustion on large tasks.

**Why progressive disclosure?** Agent prompts use 3 levels: metadata (~100 tokens, always loaded), instructions (loaded when agent activates), and references (loaded on-demand from `refs/`). This keeps the orchestrator lightweight — it sees all agents at a glance without loading their full instructions.

**Why plugin delegation?** Instead of embedding 60+ line security checklists in the Reviewer, we delegate to `security-scanning` which is purpose-built and community-maintained. The pipeline keeps a fallback for when plugins aren't installed.

**Why adaptive pipeline?** A simple hotfix doesn't need documentation and review stages. The Analyst determines which stages run based on task type and scope, saving time and tokens.
