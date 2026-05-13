# Contract: decomposer.md input reference

**FR**: FR-002
**File**: `skills/task/agents/decomposer.md`

## Before

```markdown
## Inputs

- **`.task/02-scout.md`** -- full
- **`.task/01-analysis.md`** -- Brief section only
```

## After

```markdown
## Inputs

- **`.task/02-scout.md`** -- full
- **`.task/00-spec.md`** -- Brief section only
```

## Verification

```bash
grep -n "01-analysis.md" skills/task/agents/decomposer.md   # expect: no matches
grep -n "00-spec.md"     skills/task/agents/decomposer.md   # expect: at least one match on line 14
```
