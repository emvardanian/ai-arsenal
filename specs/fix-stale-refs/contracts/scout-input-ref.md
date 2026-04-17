# Contract: scout.md input reference

**FR**: FR-001
**File**: `skills/task/agents/scout.md`

## Before

```markdown
## Inputs

- **`.task/01-analysis.md`** -- full (task type, scope, acceptance criteria, risks)
```

## After

```markdown
## Inputs

- **`.task/00-spec.md`** -- full (task type, scope, acceptance criteria, risks)
```

## Verification

```bash
grep -n "01-analysis.md" skills/task/agents/scout.md   # expect: no matches
grep -n "00-spec.md"     skills/task/agents/scout.md   # expect: at least one match on line 14
```
