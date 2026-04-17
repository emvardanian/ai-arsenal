# Contract: committer.md input reference

**FR**: FR-003
**File**: `skills/task/agents/committer.md`

## Before

```markdown
- `.task/pipeline-summary.md` -- pipeline overview
- `.task/01-analysis.md` -- task type, determines commit prefix
- `.task/03-decomposition.md` -- module structure, one commit per module
```

## After

```markdown
- `.task/pipeline-summary.md` -- pipeline overview
- `.task/00-spec.md` -- task type, determines commit prefix
- `.task/03-decomposition.md` -- module structure, one commit per module
```

## Verification

```bash
grep -n "01-analysis.md" skills/task/agents/committer.md   # expect: no matches
grep -n "00-spec.md"     skills/task/agents/committer.md   # expect: at least one match in Inputs
```
