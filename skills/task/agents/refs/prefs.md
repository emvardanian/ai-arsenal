# User Preferences

**Load trigger**: at pipeline startup, step 2 of Starting the Pipeline.

Covers the two `task-prefs.json` files (global + project), their schema, and precedence rules.

## Files

| Scope | Path | Notes |
|---|---|---|
| Global | `~/.claude/task-prefs.json` | Per-user defaults; follows user across projects |
| Project | `<project_root>/.claude/task-prefs.json` | Per-project overrides; visible in git if committed |

Both optional. Missing file → silently skipped.

## Schema v1

All fields optional. Unknown keys ignored (forward-compat).

```json
{
  "default_tier": "strict | standard | express",
  "default_scope": "xs | s | m | l | xl",
  "default_delegation": "enable | disable",
  "skip_stages": ["refactorer", "documenter", ...],
  "review_lite": "skip | default",
  "approval_mode": "per_module | batch"
}
```

**Valid `skip_stages` values**: any agent name from `refs/model-tiers.md` (scout, decomposer, researcher, planner, designer, implementer, tester, debugger, design-qa, reviewer-lite, reviewer, refactorer, documenter). Spec and Committer cannot be skipped (they are minimum-always stages).

## Precedence Stack

Per-field resolution, first non-null wins:

1. **Preamble** (user typed `tier: X` in invocation) — highest
2. **Slash command** (`/task-quick` etc. defaults)
3. **Project prefs** (`<project>/.claude/task-prefs.json`)
4. **Global prefs** (`~/.claude/task-prefs.json`)
5. **Cycle 2 Task skill defaults** — lowest

Example (global `{default_tier: strict}`, project `{default_tier: express}`, user preamble `tier: standard`):
- Effective `tier = standard` (preamble wins).
- `tier_source: user`.
- `prefs_source: user` (since preamble overrode prefs for this field).

Example (global `{default_tier: strict, skip_stages: [refactorer]}`, project `{default_tier: express}`):
- Effective `tier = express` (project wins for this field).
- Effective `skip_stages = [refactorer]` (only global provides it).
- `prefs_source: both`.

## Fail-Safe Rules

| Condition | Behavior |
|---|---|
| File absent | Skip silently; no log entry |
| File empty | Skip silently |
| Malformed JSON | Single warning in pipeline-summary body; ignore file |
| Unknown top-level key | Info note (once); ignore key |
| Invalid enum value | Warning naming the key; ignore that key only |
| `skip_stages` contains unknown stage | Warning; skip that entry; keep valid ones |
| Prefs file unreadable (permissions) | Warning; treat as absent |

All fail-safes preserve Cycle 2 behavior — prefs are additive, never blocking.

## Source Recording

Pipeline-summary front-matter:

```yaml
prefs_source: none | global | project | both | user
```

Body line per effective pref:

```
- **[Prefs]**: tier=strict [source: global]
- **[Prefs]**: skip_stages=[refactorer] [source: global]
- **[Prefs]**: tier=express [source: project (overrides global)]
```

## Example Files

**Minimal global**:
```json
{ "default_tier": "strict" }
```

**Power-user global**:
```json
{
  "default_tier": "strict",
  "default_delegation": "disable",
  "skip_stages": ["refactorer"],
  "approval_mode": "batch"
}
```

**Project override for a production repo**:
```json
{
  "default_tier": "strict",
  "review_lite": "default"
}
```

## Back-Compat

- Users with no prefs files see Cycle 2 behavior unchanged (FR-025).
- Cycle 2 workspaces resume without `prefs_source` field → defaults to `none` (FR-026).
