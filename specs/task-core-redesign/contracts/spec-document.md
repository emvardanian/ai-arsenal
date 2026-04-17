# Contract: Spec Document

**File**: `.task/00-spec.md`
**Producer**: Spec agent (interactive or validate mode).
**Consumers**: Orchestrator (verdict gate), Decomposer, Planner, Tester (AC mapping).

## Structure

### Front-matter (YAML, new in this cycle)

```yaml
---
mode: interactive                     # interactive | validate
source: user_dialogue                 # user_dialogue | ready_made: <path>
detected_at: 2026-04-17T14:30:00Z
classified_scope: M                   # ScopeTier computed post-validation
scope_signals:
  user_story_count: 4
  ac_count: 12
  scope_in_count: 8
  scope_out_count: 3
  ui_keywords_present: false
---
```

### Body (preserves current Brainstormer output)

```markdown
# Spec: [Feature Name]

## Summary
[1-2 sentences describing the feature and its purpose]

## User Stories
- US1 [P1]: As a [actor], I want [action], so that [benefit]
  - AC-1: [testable criterion]
  - AC-2: [testable criterion]
- US2 [P2]: ...

## Quality Gates
- QG-1: [condition that blocks release]
- QG-2: ...

## Edge Cases
- EC-1: [boundary condition]
- EC-2: ...

## Scope
### In
- [included item]
### Out
- [excluded item]

## Validation
**Verdict**: PASS | PASS_WITH_WARNINGS | NEEDS_ATTENTION
**Mode**: interactive | validate
**Findings**: <count> (gaps: <n>, conflicts: <n>, weak: <n>)

| Severity | Location | Description |
|---|---|---|
| Gap | US2 / AC-? | Missing acceptance criterion |
| Weak | QG-1 | Not testable as stated |
| OK | — | All other sections clean |

**Summary**: <one-line overall assessment>
```

## Field semantics

### Front-matter

- `mode`: which Spec mode produced this document.
  - `interactive`: dialogue mode; user collaborated section-by-section.
  - `validate`: validate mode; document was transformed from ready-made input.
- `source`:
  - `user_dialogue`: body was written through interactive dialogue (always when `mode=interactive`).
  - `ready_made: <path>`: document was derived from this file (always when `mode=validate`).
- `detected_at`: ISO-8601 timestamp of Spec stage start.
- `classified_scope`: ScopeTier computed by Spec at end of stage (feeds orchestrator's pipeline selection).
- `scope_signals`: audit trail — the four signals used to classify scope.

### Body — Validation section

**Verdict** — one of:

- `PASS`: no findings or only `OK` findings. Safe to proceed.
- `PASS_WITH_WARNINGS`: only `Weak` findings present. Proceed advised; user may revise before planning.
- `NEEDS_ATTENTION`: any `Gap` or `Conflict` finding. Orchestrator MUST gate: user chooses to fix in spec, ignore, or return to interactive mode (FR-017, spec Edge Case).

**Findings table** — one row per finding:

- `Severity` ∈ {Gap, Conflict, Weak, OK}
  - `Gap`: section missing or empty.
  - `Conflict`: two sections contradict.
  - `Weak`: present but vague, not testable, or ambiguous.
  - `OK`: explicit pass indicator (used sparingly; usually only finding is "No issues").
- `Location`: specific spec location (section or AC/US identifier).
- `Description`: human-readable finding.

**Summary**: one-line overall assessment. Example: "Spec is complete but two ACs lack measurable thresholds."

## Mode-specific behavior

### Interactive mode

- Body is built incrementally through dialogue.
- Each section is presented to user for per-section approval before moving on (unchanged from pre-redesign Brainstormer).
- After all sections are approved, validation runs internally (same checks as validate mode against the just-built body).
- Validation result is appended as `## Validation` section.
- Single final approval gate presents: body + validation. If validation is PASS, user usually approves. If NEEDS_ATTENTION, the gate forces resolution.

**Per-section approvals are internal** to the Spec stage and are NOT counted toward ApprovalTier's gate count. They are part of the interactive dialogue UX and preserved from Brainstormer (FR-025).

### Validate mode

- Body is mapped from ready-made input to the canonical format (section-by-section heuristic matching).
- Missing sections get stubs marked `[GENERATED -- needs validation]`.
- Validation runs on the transformed body.
- No per-section user approval (user already wrote the input).
- Single final approval gate presents: body + validation. Same gate semantics as interactive.

## Resume behavior

If Spec agent is interrupted (user abandons interactive dialogue partway, Edge Case):

1. Body contains only approved sections; unapproved sections are absent or stubs.
2. Front-matter is written with `mode: interactive` and partial signals.
3. No `## Validation` section yet.
4. On resume, orchestrator reads front-matter; if no Validation section present, re-dispatch Spec agent in interactive mode with instruction "Resume from last approved section".

## Invariants

- `## Validation` section is present on every completed Spec stage output (SC-006).
- `mode` front-matter field is always either `interactive` or `validate`.
- `NEEDS_ATTENTION` verdict means orchestrator MUST NOT proceed to Scout/Decomposer without user resolution.
- Body section ordering matches pre-redesign Brainstormer output exactly (FR-025) to preserve downstream readers' assumptions.

## Back-compat

- A pre-redesign `.task/00-spec.md` (no front-matter, no `## Validation` section) is still readable; orchestrator treats it as validated-strict (resume path) and does not require re-validation.
- Adding new front-matter fields in future cycles is allowed if readers ignore unknown keys.
