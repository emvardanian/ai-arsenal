# AI Arsenal

A modular toolkit that supercharges Claude Code with reusable skills, sub-agents, and workflows for software development. The centerpiece is the **Task** skill -- an orchestrator that runs 15 specialized agents through a complete development lifecycle.

## What It Does

You give Claude a development task. The Task skill breaks it into modules, delegates each module to specialized agents in a per-module loop, manages approvals, handles test failures, and produces clean commits -- all while keeping context lightweight through file-based communication.

```
You: "Add JWT authentication with refresh tokens"

Task: Brainstormer -> Validator -> Scout -> Decomposer
        -> [per module: Researcher -> Planner -> Implementer -> Tester <-> Debugger]
        -> Reviewer -> Refactorer -> Documenter -> Committer
```

## Architecture

### Pipeline

```
User Request
    |
    v
+--------------+   +------------+   +---------+   +-------------+
| 0.Brainstorm |-->| 1.Validate |-->| 2.Scout |-->| 3.Decompose |
|    [aprv]    |   |   [aprv]   |   |         |   |   [aprv]    |
+--------------+   +------------+   +---------+   +-------------+
                                                        |
                    +-----------------------------------+
                    v
              +=============================================+
              |  For each module (x N):                     |
              |                                             |
              |  +------------+   +--------+                |
              |  |4.Research  |-->|5.Plan  |                |
              |  |            |   | [aprv] |                |
              |  +------------+   +---+----+                |
              |                       |                     |
              |            +----------+----------+          |
              |            v                     v          |
              |  +-----------+         +------------+       |
              |  |5.5 Design |         |6.Implement |       |
              |  |   [aprv]  |         |   [aprv]   |       |
              |  |(UI only)  |         +-----+------+       |
              |  +-----------+               |              |
              |                              v              |
              |                        +---------+          |
              |                        | 7.Test  |          |
              |                        +----+----+          |
              |                             |               |
              |                        pass?|               |
              |                   +----+----+----+          |
              |                   v              v          |
              |              [continue]    +---------+      |
              |                   |        | 8.Debug |      |
              |                   |        +----+----+      |
              |                   |             |           |
              |                   |     fix -> Impl -> Test |
              |                   |        (max 2 cycles)   |
              |                   v                         |
              |           +-------------+                   |
              |           |8.5 Design QA|                   |
              |           | (UI only)   |                   |
              |           +-------------+                   |
              |           (max 2 cycles)                    |
              +=============================================+
                    |
                    v
+-----------+   +------------+   +-------------+   +------------+
| 9.Review  |-->|10.Refactor |-->| 11.Document |-->| 12.Commit  |
|           |   |   [aprv]   |   |    [aprv]   |   |            |
+-----------+   +------------+   +-------------+   +------------+
```

### Agents

| # | Agent | File | Model | What It Does | Approval |
|---|-------|------|-------|-------------|----------|
| 0 | **Brainstormer** | `brainstormer.md` | opus | Interactive spec brainstorm with the user | yes |
| 1 | **Validator** | `analyst.md` | opus | Validate spec, classify task, gap report, pipeline selection | yes |
| 2 | **Scout** | `scout.md` | sonnet | Light research: project structure, conventions, module boundaries | -- |
| 3 | **Decomposer** | `decomposer.md` | opus | Split task into modules, define execution order and dependencies | yes |
| 4 | **Researcher** | `researcher.md` | sonnet | Deep per-module research: affected files, patterns, library docs via `context7` | -- |
| 5 | **Planner** | `planner.md` | opus | Detailed implementation plan for one module | yes |
| 5.5 | **Designer** | `designer.md` | opus | Extract design tokens from screenshots/mockups (UI modules only) | yes |
| 6 | **Implementer** | `implementer.md` | sonnet | Write code for one module following plan and conventions | yes |
| 7 | **Tester** | `tester.md` | sonnet | Write and run tests: unit, integration, endpoint, e2e, performance | -- |
| 8 | **Debugger** | `debugger.md` | sonnet | Hypothesis-driven failure analysis, 3 competing hypotheses per cluster | -- |
| 8.5 | **Design QA** | `design-qa.md` | sonnet | Verify implementation matches design tokens (UI modules only) | -- |
| 9 | **Reviewer** | `reviewer.md` | sonnet | Performance + architecture review. Delegates security to `security-scanning` plugin | -- |
| 10 | **Refactorer** | `refactorer.md` | haiku | Apply minor improvements from review, re-run tests | yes |
| 11 | **Documenter** | `documenter.md` | haiku | Update README, CHANGELOG, API docs, JSDoc, inline comments | yes |
| 12 | **Committer** | `committer.md` | haiku | Conventional commits per module. Delegates PR description to `git-pr-workflows` | -- |

**Model strategy:** Opus for complex reasoning (brainstorm, validation, decomposition, planning, design). Sonnet for execution (research, code, tests, debug, review). Haiku for mechanical work (refactoring, docs, commits).

### Plugin Integrations

The pipeline delegates specialized work to external plugins when available, falling back to built-in behavior when not:

| Plugin | Used By | Purpose | Fallback |
|--------|---------|---------|----------|
| `security-scanning` | Reviewer | OWASP-based security audit | Built-in SAST checklist (`refs/security-checklist.md`) |
| `git-pr-workflows` | Committer | PR description generation | Manual summary in commit output |
| `agent-teams` | Orchestrator | Parallel execution for Review, multi-module Implement, Debug | Sequential subagents |
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

- **`.task/` workspace** -- every agent writes output to numbered files (`01-analysis.md`, `02-scout.md`, etc.)
- **Per-module files** -- Research, Plan, Implement, Test, and Debug write per-module outputs (`04-research-{N}.md`, `05-plan-{N}.md`, `06-impl-{N}.md`, `07-tests-{N}-{C}.md`, `08-debug-{N}-{C}.md`) where `{N}` is the module number and `{C}` is the cycle number
- **Brief sections** -- every output starts with a 5-10 line summary. Downstream agents read only briefs when full context isn't needed
- **Pipeline summary** -- `pipeline-summary.md` accumulates one line per completed stage. Terminal agents (Documenter, Committer) read only this file
- **Dependency map** -- each agent reads only its declared inputs (see SKILL.md Agent Reference table)
- **Refs on demand** -- checklists and examples live in `agents/refs/` and load only when needed (Level 3 progressive disclosure)

### Adaptive Pipeline

Not every task uses all 15 agents:

| Task Type | Pipeline |
|-----------|----------|
| Feature | All stages |
| Feature + Design | All stages + Designer (UI modules) + Design QA (UI modules) |
| Bugfix | Validator -> Scout -> Decomposer -> [Research->Plan->Impl->Test<->Debug] -> Commit |
| Refactor | Validator -> Scout -> Decomposer -> [Research->Refactor->Review->Test] -> Commit |
| Hotfix | Validator -> [Impl->Test<->Debug] -> Commit |

Minimum always: Validator + Test + Commit. Hotfix skips Scout/Decomposer -- speed is critical.

### Adaptive Entry

When you provide a ready-made specification (file path, pasted content, or existing spec in `docs/`), the Brainstormer (Stage 0) is skipped. The Validator transforms the input into the standard format and validates it directly.

### Design QA Cycle

For UI modules with Designer output, Design QA runs after the Test/Debug cycle:

```
Design QA fails -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs
(max 2 cycles, then escalate to user)
```

## Repository Structure

```
ai-arsenal/
├── skills/
│   ├── task/                              # SDLC pipeline orchestrator
│   │   ├── SKILL.md                       # Orchestrator -- manages pipeline flow
│   │   └── agents/                        # 15 specialized agents
│   │       ├── analyst.md                 # Validator (Stage 1, opus)
│   │       ├── brainstormer.md            # Spec brainstorm (Stage 0, opus)
│   │       ├── committer.md               # Commit preparation (Stage 12, haiku)
│   │       ├── debugger.md                # Failure diagnosis (Stage 8, sonnet)
│   │       ├── decomposer.md              # Module decomposition (Stage 3, opus)
│   │       ├── design-qa.md               # Design verification (Stage 8.5, sonnet)
│   │       ├── designer.md                # Design extraction (Stage 5.5, opus)
│   │       ├── documenter.md              # Documentation updates (Stage 11, haiku)
│   │       ├── implementer.md             # Code writing (Stage 6, sonnet)
│   │       ├── planner.md                 # Plan creation (Stage 5, opus)
│   │       ├── refactorer.md              # Minor improvements (Stage 10, haiku)
│   │       ├── researcher.md              # Deep research (Stage 4, sonnet)
│   │       ├── reviewer.md                # Code review (Stage 9, sonnet)
│   │       ├── scout.md                   # Light research (Stage 2, sonnet)
│   │       ├── tester.md                  # Test writing & running (Stage 7, sonnet)
│   │       └── refs/                      # On-demand references (Level 3)
│   │           ├── architecture-checklist.md
│   │           ├── brainstorm-patterns.md
│   │           ├── commit-conventions.md
│   │           ├── commit-template.md
│   │           ├── debug-examples.md
│   │           ├── design-tokens-example.md
│   │           ├── doc-formats.md
│   │           ├── performance-checklist.md
│   │           └── security-checklist.md
│   ├── lander/                            # Landing page brainstorm orchestrator
│   │   ├── SKILL.md
│   │   └── agents/
│   └── redesign/                          # Pixel-perfect UI redesign skill
│       ├── SKILL.md
│       └── agents/
├── docs/                                  # Conventions, guidelines
├── files/                                 # Supporting files
└── specs/                                 # Feature specifications
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

These plugins are optional but recommended -- the pipeline uses them when available and falls back gracefully when not.

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
# context7 -- live library documentation lookup (used by Researcher)
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
# Should trigger the pipeline: Brainstormer -> Validator -> Scout -> ...
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

Without this, the pipeline falls back to sequential subagents -- everything works, just not in parallel.

## Usage

### Start a Task

Just describe what you need:

```
> Implement user authentication with JWT and refresh tokens
> Fix the race condition in the payment processing queue
> Refactor the notification service to use the event bus pattern
> Hotfix: API returns 500 on empty cart checkout
```

The Brainstormer will help you flesh out the spec interactively, then the Validator classifies it and selects the pipeline.

If you already have a specification ready, pass it directly -- the Brainstormer step is skipped automatically:

```
> Implement the feature described in docs/specs/auth-feature.md
```

### During the Pipeline

The orchestrator shows progress at the top of every response:

```
[ok Brainstorm] [ok Validate] [ok Scout] [>> Decompose] [Research 1/3] [Plan 1/3] [Impl 1/3] [Test] [Debug] [Review] [Refactor] [Docs] [Commit]
```

Icons: `ok` done, `>>` active, `--` skipped, `<>` re-run, `!!` failed. Multi-module stages show progress as `[>> Impl 2/3]`.

At approval gates, review the output and:
- **Approve** -- pipeline continues
- **Adjust** -- modify the output, re-present
- **Add context** -- incorporate new information

### After Completion

The Committer produces conventional commits per module:

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

**Why file-based communication?** Each agent runs in its own context window. Files in `.task/` act as shared memory -- agents write structured outputs and downstream agents read only what they need. This prevents context window exhaustion on large tasks.

**Why progressive disclosure?** Agent prompts use 3 levels: metadata (~100 tokens, always loaded), instructions (loaded when agent activates), and references (loaded on-demand from `refs/`). This keeps the orchestrator lightweight -- it sees all agents at a glance without loading their full instructions.

**Why plugin delegation?** Instead of embedding 60+ line security checklists in the Reviewer, we delegate to `security-scanning` which is purpose-built and community-maintained. The pipeline keeps a fallback for when plugins aren't installed.

**Why adaptive pipeline?** A simple hotfix doesn't need documentation and review stages. The Validator determines which stages run based on task type and scope, saving time and tokens.

**Why per-module execution?** The Decomposer splits the task into independent modules. Each module goes through its own Research -> Plan -> Implement -> Test -> Debug loop. This keeps each agent's context focused on one module at a time, and independent modules can run in parallel when Agent Teams is available.

**Why Brainstormer + Adaptive Entry?** Most tasks start vague. The Brainstormer helps the user flesh out a proper spec interactively. But when a ready-made spec exists (from a planning tool, a ticket, or a prior session), skipping the brainstorm saves time without losing quality.
