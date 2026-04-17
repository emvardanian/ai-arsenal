# Contract: Slash Commands

**Location**: `.claude/commands/task-<suffix>.md`

## Command files

### `.claude/commands/task-quick.md`

```markdown
---
description: Quick task — scope XS/S, express tier (1 approval at commit)
argument-hint: <task description>
---

Invoke the Task skill with:

```
scope: s, tier: express
$ARGUMENTS
```

If `$ARGUMENTS` is empty, prompt: "What's the quick task?"
```

### `.claude/commands/task-fix.md`

```markdown
---
description: Bugfix — auto-classified scope, tier follows scope
argument-hint: <bug description>
---

Invoke the Task skill with:

```
task_type: bugfix
$ARGUMENTS
```
```

### `.claude/commands/task-feature.md`

```markdown
---
description: Feature — scope M default, standard tier (3 approvals)
argument-hint: <feature description>
---

Invoke the Task skill with:

```
scope: m, tier: standard, task_type: feature
$ARGUMENTS
```
```

### `.claude/commands/task-full.md`

```markdown
---
description: Full ceremony — scope L default, strict tier, every gate
argument-hint: <large feature description>
---

Invoke the Task skill with:

```
scope: l, tier: strict, task_type: feature
$ARGUMENTS
```
```

## Preamble precedence

The preamble emitted by the slash command is a **default**. If the user includes their own preamble in `$ARGUMENTS`, it overrides:

```
/task-quick scope: m add retry logic
```

Parser sees `scope: m` in user text (higher precedence) and uses M instead of the command's default S.

## Entry-point recording

Orchestrator records which slash command (if any) was used:

```yaml
entry_point: /task-quick | /task-fix | /task-feature | /task-full | none
```

## Behavior contract

- Slash command always sets defaults; never forces.
- Empty `$ARGUMENTS` → prompt user (do not start empty pipeline).
- Unknown slash command under `/task-*` → does not exist; Claude Code CLI handles natively.
- Slash commands may be deleted per-user; skill still works without them.
