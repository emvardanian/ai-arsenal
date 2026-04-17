# Contract: Pipeline Summary

**File**: `.task/pipeline-summary.md`
**Producers**: Orchestrator (initial write and updates), each stage agent (appends its own stage line).
**Consumers**: All agents (body), Orchestrator (front-matter + body), Documenter/Committer (body only).

## Structure

### Front-matter (YAML, new in this cycle)

Appears at the top of the file, delimited by `---` lines.

```yaml
---
# Scope classification
scope: M                              # ScopeTier: xs | s | m | l | xl
scope_source: classified              # classified | user | inferred | upgraded
scope_override: null                  # null or ScopeTier if user declared
scope_signals:                        # audit trail from classifier
  file_count_est: 12
  module_count_est: 3
  ui_present: false
  task_type: feature

# Approval tier
tier: standard                        # ApprovalTier: strict | standard | express
tier_source: default                  # default | user | criticality | mid_flight
tier_override: null

# Criticality
criticality_flag: false               # bool
criticality_source: null              # null | user_flag | keyword | spec_metadata
criticality_matched_term: null        # null or matched string

# Stage bookkeeping
skipped_stages:                       # stages skipped due to scope or tier
  - { name: Designer, reason: "scope=M, no UI modules" }
  - { name: Refactorer, reason: "tier=standard, non-gated and not applicable" }
stage_count_expected: 9
stage_count_approval_gated: 3

# Schema version
summary_schema: v2                    # v1 = pre-redesign (no front-matter)
---
```

### Body (unchanged from current skill)

```markdown
# Pipeline Summary
- **Task**: Add email notifications for password reset
- **Type**: feature | **Scope**: M | **Tier**: standard | **Pipeline**: scope-m-feature
- **Stage 1 -- Spec**: ok interactive mode, 4 US, 12 AC, Validation PASS
- **Stage 2 -- Scout**: ok MERN stack, 3 modules identified, kebab-case
- **Stage 3 -- Decomposer**: ok 3 modules (API -> Frontend -> Tests)
- **Stage 4.1 -- Researcher**: ok module 1, 6 affected files
- **Stage 5.1 -- Planner**: ok module 1, 3 files create, 2 modify
- **Stage 6.1 -- Implementer**: ok Plan 1 done, 3 files created, 2 modified
- **Stage 7.1 -- Tester**: ok 12/12 tests passed
...
- **Stage 12 -- Committer**: ok 3 commits prepared
```

## Field semantics

### scope

- `scope`: current effective scope.
- `scope_source`:
  - `classified` — orchestrator computed from signals.
  - `user` — user declared in preamble.
  - `inferred` — resumed from pre-redesign workspace; inferred from existing stage lines.
  - `upgraded` — Scout flagged larger scope mid-pipeline and user approved upgrade.
- `scope_override`: the user-declared value when `scope_source=user`; null otherwise.
- `scope_signals`: audit trail — the four signal values used by the classifier.

### tier

- `tier`: current effective tier.
- `tier_source`:
  - `default` — derived from scope (XS/S=express, M=standard, L/XL=strict).
  - `user` — user declared in preamble.
  - `criticality` — user confirmed strict after criticality prompt.
  - `mid_flight` — user changed tier at an approval gate.
- `tier_override`: the user-declared value when `tier_source` is not `default`; null otherwise.

### criticality

- `criticality_flag`: true if any criticality signal fired (confirmed or overridden).
- `criticality_source`: which detector fired.
- `criticality_matched_term`: the literal string that matched.

### skipped_stages

List of stages that the scope-pipeline matrix or tier rules skip for this task. Each entry:
- `name`: stage name (e.g., "Designer", "Refactorer").
- `reason`: human-readable justification.

Purpose: observability (FR-029). Readers can understand why the pipeline is shorter than the full 15 stages.

### stage_count_*

- `stage_count_expected`: total number of stages this pipeline will run (sum of loops counted per module).
- `stage_count_approval_gated`: subset that will prompt for approval under the current tier.

Computed after Spec (and re-computed after Decomposer if module count changes).

### summary_schema

- `v1`: pre-redesign format; no front-matter. File starts with `# Pipeline Summary`.
- `v2`: this cycle. File starts with `---`.

Used by resume logic to detect pre-redesign workspaces (Edge Case, FR-027).

## Reader contracts

### Body-only readers (Documenter, Committer)

These agents read the `# Pipeline Summary` body and its `Stage N -- name: summary` lines. They MUST skip content between the opening `---` and the next `---` if the file starts with `---`. Example implementation (in agent prompt):

> If `.task/pipeline-summary.md` starts with `---`, skip forward to the next `---` line and begin reading the body after it. Otherwise read from the top.

### Orchestrator reader

Parses front-matter as YAML. Falls back to v1 defaults if front-matter is absent:
- `scope: null`, `scope_source: inferred`
- `tier: strict`, `tier_source: default`
- `criticality_flag: false`
- `summary_schema: v1`

### Agent writers

Every stage appends its summary line to the body. Example:

```markdown
- **Stage 5.2 -- Planner**: ok module 2, 4 files create, 1 modify
```

Orchestrator updates front-matter in place (re-writes the YAML block) whenever:
- Scope classification completes (after Spec).
- Tier changes (user override, criticality, mid-flight).
- Scope upgraded (user approval of Scout's mid-flight request).
- `skipped_stages` list grows (pipeline adapts).

## Back-compat invariants

- A pre-redesign `.task/pipeline-summary.md` (no front-matter) is valid input to the redesigned skill; orchestrator defaults `tier: strict`, infers `scope` from body content (FR-027, research §8).
- Body format is bit-compatible with pre-redesign; any agent that understood the old format understands the new body.
- Adding new front-matter fields in future cycles is allowed as long as readers ignore unknown keys.

## Examples

### Fresh scope-S express task

```yaml
---
scope: S
scope_source: classified
scope_override: null
scope_signals: { file_count_est: 3, module_count_est: 1, ui_present: false, task_type: refactor }
tier: express
tier_source: default
tier_override: null
criticality_flag: false
criticality_source: null
criticality_matched_term: null
skipped_stages:
  - { name: Scout, reason: "scope=S" }
  - { name: Decomposer, reason: "scope=S" }
  - { name: Designer, reason: "scope=S" }
  - { name: Design-QA, reason: "scope=S" }
  - { name: Reviewer, reason: "scope=S" }
  - { name: Refactorer, reason: "scope=S" }
  - { name: Documenter, reason: "scope=S" }
stage_count_expected: 4
stage_count_approval_gated: 1
summary_schema: v2
---

# Pipeline Summary
- **Task**: Rename getUserById to fetchUserById
- **Type**: refactor | **Scope**: S | **Tier**: express | **Pipeline**: scope-s-refactor
- **Stage 1 -- Spec**: ok validate mode, no dialogue, Validation PASS
- **Stage 5 -- Planner**: ok 1 file modify
- **Stage 6 -- Implementer**: ok 1 file modified
- **Stage 7 -- Tester**: ok 8/8 tests passed
- **Stage 12 -- Committer**: ok 1 commit prepared
```

### Criticality-overridden express → strict

```yaml
---
scope: S
scope_source: classified
scope_override: null
tier: strict
tier_source: criticality
tier_override: strict
criticality_flag: true
criticality_source: keyword
criticality_matched_term: payment
skipped_stages: []
stage_count_expected: 5
stage_count_approval_gated: 4
summary_schema: v2
---
```

### Mid-flight tier downgrade

```yaml
---
scope: M
scope_source: classified
tier: express                        # user said "switch to express"
tier_source: mid_flight
tier_override: express
# ... rest unchanged
---

# Pipeline Summary
- **Task**: Add retry logic to webhook dispatcher
- **Type**: feature | **Scope**: M | **Tier**: standard -> express (at Decomposer approval)
- **Stage 1 -- Spec**: ok ...
- **Stage 3 -- Decomposer**: ok ... [approved, tier switched to express]
- **Stage 5.1 -- Planner**: ok ...  [no approval — tier is express]
...
```
