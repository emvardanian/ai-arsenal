# Phase 1 Data Model: Fix Stale Doc References

**Date**: 2026-04-17
**Feature**: fix-stale-refs

Since this is a documentation-only change, the "data model" is the set of edit sites — each one a tuple of `(file, locator, current_content, target_content, rule_id)`.

## Entity: Edit Site

| Field | Type | Description |
|---|---|---|
| `file` | path (relative to repo root) | The markdown file to modify |
| `locator` | line number OR unique substring | Where in the file the edit applies |
| `current` | string | The stale text to replace |
| `target` | string | The corrected text |
| `rule` | FR id from spec | Which Functional Requirement this edit satisfies |

## Instances

### Edit 1 (FR-001)

| Field | Value |
|---|---|
| file | `skills/task/agents/scout.md` |
| locator | line 14 |
| current | `- **`.task/01-analysis.md`** -- full (task type, scope, acceptance criteria, risks)` |
| target | `- **`.task/00-spec.md`** -- full (task type, scope, acceptance criteria, risks)` |
| rule | FR-001 |

### Edit 2 (FR-002)

| Field | Value |
|---|---|
| file | `skills/task/agents/decomposer.md` |
| locator | line 14 |
| current | `- **`.task/01-analysis.md`** -- Brief section only` |
| target | `- **`.task/00-spec.md`** -- Brief section only` |
| rule | FR-002 |

### Edit 3 (FR-003)

| Field | Value |
|---|---|
| file | `skills/task/agents/committer.md` |
| locator | line 15 |
| current | `- `.task/01-analysis.md` -- task type, determines commit prefix` |
| target | `- `.task/00-spec.md` -- task type, determines commit prefix` |
| rule | FR-003 |

### Edit 4 (FR-008)

| Field | Value |
|---|---|
| file | `skills/task/agents/documenter.md` |
| locator | line 16 |
| current | `**Exception — new public APIs**: If any `04-impl-{N}.md` mentions new public APIs, endpoints, or exported modules, you MAY read those specific source files.` |
| target | `**Exception — new public APIs**: If any `06-impl-{N}.md` mentions new public APIs, endpoints, or exported modules, you MAY read those specific source files.` |
| rule | FR-008 |

### Edit 5 (FR-004)

| Field | Value |
|---|---|
| file | `skills/task/agents/refs/model-tiers.md` |
| locator | tier-distribution table, haiku row |
| current | `| haiku | 8 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer |` |
| target | `| haiku | 7 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer |` |
| rule | FR-004 |

### Edit 6 (FR-005)

| Field | Value |
|---|---|
| file | `skills/task/agents/refs/model-tiers.md` |
| locator | reader contract step 2 under "### Orchestrator" |
| current | `2. Resolve `mode` if applicable (Spec only: interactive or validate, detected by Spec's Mode Detection step).` |
| target | `2. Resolve `mode` if applicable (Spec only: interactive, validate, or interview, detected by Spec's Mode Detection step).` |
| rule | FR-005 |

### Edit 7 (FR-006)

| Field | Value |
|---|---|
| file | `skills/task/agents/refs/model-tiers.md` |
| locator | example block titled "For Spec (two modes):" |
| current | Block heading `For Spec (two modes):` followed by fenced code block with only two reference lines (interactive, validate). |
| target | Block heading `For Spec (three modes):` followed by a fenced code block with three reference lines (interactive, validate, interview) matching `spec.md:1-5`. |
| rule | FR-006 |

### Edit 8 (FR-007)

| Field | Value |
|---|---|
| file | `skills/task/agents/refs/model-tiers.md` |
| locator | Invariants section, row-count bullet |
| current | `- Spec has exactly two rows (interactive, validate).` |
| target | `- Spec has exactly three rows (interactive, validate, interview).` |
| rule | FR-007 |

## Validation rules

- Every Edit Site MUST be applied exactly once. Re-running the edit on already-corrected content is a no-op and flagged as error (caught by `Edit` tool when old_string not found).
- No Edit Site modifies code semantics or workflow logic.
- Files listed in FR-009 (reviewer.md, tester.md, resume.md, SKILL.md) are NOT Edit Sites and MUST remain `git diff`-clean.

## State transitions

Each Edit Site transitions from `stale` → `applied` exactly once.

```
stale -> applied
```

No rollback state needed — `git restore` reverts everything; the worktree is the rollback mechanism.

## Relationships

Edits 5-8 all target the same file (`refs/model-tiers.md`) but disjoint regions. They can be applied in any order.

Edits 1-4 each touch a unique file. Independent.
