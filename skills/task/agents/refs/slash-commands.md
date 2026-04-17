# Slash Commands

**Load trigger**: on-demand from SKILL.md when users invoke a `/task-*` command or ask about command behavior.

Covers the 4 Cycle-3 slash commands, their defaults, precedence with preamble overrides, and entry-point recording.

## Command Registry

| Command | Default scope | Default tier | Default task_type | Use for |
|---|---|---|---|---|
| `/task-quick` | `s` (capped by classifier) | `express` | auto | One-file renames, trivial edits, 1-approval pipeline |
| `/task-fix` | auto | auto (from scope) | `bugfix` | Bug fixes of any size |
| `/task-feature` | `m` | `standard` | `feature` | Standard new features (3 approvals) |
| `/task-full` | `l` | `strict` | `feature` | Large cross-cutting work with every gate |

**Files**: `.claude/commands/task-quick.md`, `.claude/commands/task-fix.md`, `.claude/commands/task-feature.md`, `.claude/commands/task-full.md`.

## Defaults Mechanism

Each command file emits a preamble for the Task skill:

```
scope: s, tier: express
<user's task description>
```

Preamble is the same grammar as Cycle 1 — command just pre-fills common combinations.

## Preamble Override

User may type their own preamble keys in the command body. Those override the command's defaults.

Example:

```
/task-quick scope: m add retry with exponential backoff
```

Parser sees `scope: m` in user text → effective scope = M (not command's default S).

## Entry-Point Recording

Orchestrator records which command triggered the run:

```yaml
entry_point: /task-quick | /task-fix | /task-feature | /task-full | none
```

`none` when user invoked via bare `task: ...` or natural-language trigger.

Body line:

```
- **[Entry point]**: /task-full
```

## Empty Invocation

If user types slash command with no arguments (e.g., just `/task-quick`):
- Do NOT start an empty pipeline.
- Prompt: "What's the task?"
- Wait for response; then apply command defaults + parse user preamble.

## Precedence Summary

Per-field:

1. Preamble in user invocation (highest)
2. Slash command defaults
3. Project prefs
4. Global prefs
5. Cycle-2 Task skill defaults (lowest)

See `refs/prefs.md` for full precedence rules.

## Installation

Slash commands are shipped in `.claude/commands/` in the ai-arsenal repository. Users copy them when installing the Task skill, or the repo includes them and they come along.

Per-user customization: users may edit their local copies to tune defaults. Commands are plain markdown files; no build step.

## Back-Compat

- Users who never type `/task-*` see Cycle 2 behavior unchanged.
- Removing a slash command file does not break Task skill; skill works without them.
- Adding new `/task-<suffix>` in future cycles: document here; no changes required in Task skill orchestrator (preamble grammar already supports everything).
