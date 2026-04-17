# Contract: model-tiers.md three-mode Spec

**FR**: FR-004, FR-005, FR-006, FR-007
**File**: `skills/task/agents/refs/model-tiers.md`

## Edit A — Tier distribution (FR-004)

### Before

```markdown
| haiku | 8 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer |
```

### After

```markdown
| haiku | 7 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer |
```

## Edit B — Reader contract step 2 (FR-005)

### Before

```markdown
2. Resolve `mode` if applicable (Spec only: interactive or validate, detected by Spec's Mode Detection step).
```

### After

```markdown
2. Resolve `mode` if applicable (Spec only: interactive, validate, or interview, detected by Spec's Mode Detection step).
```

## Edit C — Example block (FR-006)

### Before

```markdown
For Spec (two modes):

```
> **Interactive mode**: see `agents/refs/model-tiers.md` (entry: `spec, interactive`) — sonnet
> **Validate mode**: see `agents/refs/model-tiers.md` (entry: `spec, validate`) — haiku
```
```

### After

```markdown
For Spec (three modes):

```
> **Interactive mode**: see `agents/refs/model-tiers.md` (entry: `spec, interactive`) — sonnet
> **Validate mode**: see `agents/refs/model-tiers.md` (entry: `spec, validate`) — haiku
> **Interview mode**: see `agents/refs/model-tiers.md` (entry: `spec, interview`) — sonnet
```
```

## Edit D — Invariant (FR-007)

### Before

```markdown
- Spec has exactly two rows (interactive, validate).
```

### After

```markdown
- Spec has exactly three rows (interactive, validate, interview).
```

## Verification

```bash
grep -n "| haiku | 8 |" skills/task/agents/refs/model-tiers.md                      # expect: no matches
grep -n "| haiku | 7 |" skills/task/agents/refs/model-tiers.md                      # expect: one match
grep -n "interactive, validate, or interview" skills/task/agents/refs/model-tiers.md # expect: one match
grep -n "three modes" skills/task/agents/refs/model-tiers.md                         # expect: at least one match
grep -n "exactly three rows" skills/task/agents/refs/model-tiers.md                  # expect: one match
grep -n "exactly two rows" skills/task/agents/refs/model-tiers.md                    # expect: no matches
grep -n "(two modes)" skills/task/agents/refs/model-tiers.md                         # expect: no matches
```
