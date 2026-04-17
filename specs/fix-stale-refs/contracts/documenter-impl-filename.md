# Contract: documenter.md impl filename

**FR**: FR-008
**File**: `skills/task/agents/documenter.md`

## Before

```markdown
**Exception — new public APIs**: If any `04-impl-{N}.md` mentions new public APIs, endpoints, or exported modules, you MAY read those specific source files.
```

## After

```markdown
**Exception — new public APIs**: If any `06-impl-{N}.md` mentions new public APIs, endpoints, or exported modules, you MAY read those specific source files.
```

## Verification

```bash
grep -n "04-impl-" skills/task/agents/documenter.md   # expect: no matches
grep -n "06-impl-" skills/task/agents/documenter.md   # expect: at least one match
```
