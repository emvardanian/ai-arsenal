# Batch Approval

**Load trigger**: on first eligible batch-approval dispatch (Planner/Implementer/Reviewer-Lite at strict tier with ≥2 independent modules).

Covers eligibility, prompt UX, response parsing, state machine, and pipeline-summary recording.

## Eligibility

Orchestrator offers batch approval ONLY when ALL hold:

1. Current `tier == strict`.
2. Stage type ∈ `{planner, implementer, reviewer-lite}`.
3. Module count at this stage ≥ 2.
4. All waiting modules have `depends_on: []` per `.task/03-decomposition.md`.
5. User has NOT previously chosen `individual` for this stage type in the current run (sticky).

Fail any condition → per-module gating (Cycle 2 behavior).

## Prompt Template

```
**[Batch approval: <stage_type>]**

<N> modules ready, all independent. Approve all at once?

Modules:
  1. <module 1 brief — 1 line>
  2. <module 2 brief>
  ...
  N. <module N brief>

Options:
  [approve]             → approve all, continue
  [approve except X,Y]  → approve others, gate X and Y individually
  [individual]          → per-module gating for this stage type (Cycle 2)

Respond with one option.
```

## Response Parsing

| User reply (case-insensitive) | Action |
|---|---|
| `approve`, `approve all`, `yes`, `ok`, empty | all approved, continue |
| `approve except 2,3` (comma or space separated) | approve others; gate 2 and 3 individually |
| `individual`, `no`, `per-module` | record `approval_mode[stage_type] = per_module` (sticky); gate each individually |
| free-form text | treat as comment; re-prompt with same options |
| `approve except N` with N out of range | re-prompt with error "module N doesn't exist (1..<max>)" |

## State Machine (per stage type)

```
initial: approval_mode[stage_type] = per_module (Cycle 2 default)
   ↓
first eligible dispatch
   ↓
if user → batch (approve / approve except):
  approval_mode[stage_type] = batch
  continue
if user → individual:
  approval_mode[stage_type] = per_module (sticky — no re-prompt)
  gate per module
   ↓
subsequent same-stage-type dispatches in same run:
  if approval_mode == batch and still eligible: re-offer batch prompt
  if approval_mode == per_module: skip prompt; gate per module
```

**Sticky individual**: prevents prompt fatigue. User who said "no" gets left alone for this stage type.

**Non-sticky batch**: user may re-evaluate each stage type (new module set each time).

## Per-stage-type independence

`approval_mode` is a dict keyed by stage type:

```yaml
approval_mode:
  planner: batch
  implementer: per_module  # user declined batch here
  reviewer-lite: batch
```

User may batch Planners but individually approve Implementers. Decisions are independent.

## Prefs integration

If `~/.claude/task-prefs.json` or project prefs declare `approval_mode: batch`:
- Orchestrator pre-sets `approval_mode[<stage_type>] = batch` for all eligible types.
- First eligible dispatch still shows the prompt with `approve` highlighted; user just presses enter.

If prefs declare `approval_mode: per_module`:
- Orchestrator skips the batch prompt entirely (equivalent to Cycle 2).

## Recording

Front-matter:

```yaml
approval_mode:
  planner: batch
  implementer: per_module
  reviewer-lite: batch
```

Body line per batch event:

```
- **[Batch approval] Planner**: approved all 4 modules in one gate
- **[Batch approval] Implementer**: user declined batch, per-module gating engaged
- **[Batch approval] Reviewer-Lite**: approved all 4 except module 2 (individual)
```

## Invariants

- Batch approval is offered ONLY in strict tier (FR-018).
- Standard/express tiers never see the prompt (those tiers don't gate these stages per-module anyway).
- User decision is logged atomically before first affected stage dispatches.
- Count reduction: scope-L strict with 4 independent modules, all batches accepted → 12 → 3 gates (75%, SC-006).

## Back-Compat

- Missing `approval_mode` in resumed front-matter → all types default to `per_module` (FR-026).
- Users who always pick `individual` see Cycle 2 per-module behavior exactly (FR-025).
