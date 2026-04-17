# Contract: Prefs Schema

**Files**: `~/.claude/task-prefs.json` (global), `<project>/.claude/task-prefs.json` (project)

## JSON Schema v1

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "additionalProperties": true,
  "properties": {
    "default_tier": { "enum": ["strict", "standard", "express"] },
    "default_scope": { "enum": ["xs", "s", "m", "l", "xl"] },
    "default_delegation": { "enum": ["enable", "disable"] },
    "skip_stages": {
      "type": "array",
      "items": {
        "enum": ["scout", "decomposer", "researcher", "planner", "designer", "implementer", "tester", "debugger", "design-qa", "reviewer-lite", "reviewer", "refactorer", "documenter"]
      }
    },
    "review_lite": { "enum": ["skip", "default"] },
    "approval_mode": { "enum": ["per_module", "batch"] }
  }
}
```

`additionalProperties: true` — unknown keys allowed for forward compat.

## Example files

### Global minimal

```json
{
  "default_tier": "strict"
}
```

### Global complete

```json
{
  "default_tier": "strict",
  "default_delegation": "disable",
  "skip_stages": ["refactorer"],
  "approval_mode": "batch"
}
```

### Project override

```json
{
  "default_tier": "express",
  "review_lite": "skip"
}
```

## Precedence rules

Evaluated per-field (not per-file):

```
Effective(field) = first non-null from:
  1. Preamble override (highest)
  2. Slash command default
  3. Project prefs (<project>/.claude/task-prefs.json)
  4. Global prefs (~/.claude/task-prefs.json)
  5. Cycle 2 Task skill defaults (lowest)
```

Example: global says `default_tier: strict`, project says `default_tier: express`, user preamble says `tier: standard`. Effective: `standard` (preamble wins). `prefs_source: user`.

Example: global says `default_tier: strict`, no project prefs, no preamble. Effective: `strict`. `prefs_source: global`.

Example: global says `default_tier: strict, skip_stages: [refactorer]`, project says `default_tier: express` (skip_stages not set). Effective: `tier: express` from project, `skip_stages: [refactorer]` from global. `prefs_source: both`.

## Error handling

| Condition | Behavior |
|---|---|
| File does not exist | Skip silently; no warning |
| File exists but is empty | Skip silently |
| File is malformed JSON | Log single warning to pipeline-summary body; ignore file; continue |
| File has unknown top-level key | Log info note (once per run); ignore key |
| File has invalid enum value | Log warning naming the key; ignore that key only |
| `skip_stages` contains unknown stage | Log warning naming the stage; ignore that entry only |

## Source recording

Pipeline-summary front-matter:

```yaml
prefs_source: none | global | project | both | user
prefs_fields_resolved:
  default_tier: { value: strict, source: global }
  default_scope: { value: l, source: user }
  skip_stages: { value: [refactorer], source: global }
```

`prefs_source` aggregates: `none` if no prefs file touched the run; `global` / `project` if only one contributed; `both` if both contributed to different fields; `user` overrides mark as `user`.
