# Contract: Batch Approval Flow

## Eligibility

All conditions must hold:

1. Current pipeline `tier == strict`.
2. Current stage type ∈ {`planner`, `implementer`, `reviewer-lite`}.
3. ≥ 2 modules waiting for approval at this stage type.
4. All waiting modules have `depends_on: []` per `.task/03-decomposition.md`.
5. User has NOT previously selected `individual` for this stage type in the current run.

If any condition fails → fall through to Cycle 2 per-module gating.

## Prompt UX

When eligible:

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

## Response parsing

| User reply (case-insensitive) | Action |
|---|---|
| `approve`, `approve all`, `yes`, `ok`, empty | all approved, continue |
| `approve except 2,3` or `a except 2 3` | approve others; gate 2 and 3 per-module |
| `individual`, `no`, `per-module` | record `approval_mode[stage_type] = per_module`; gate each module individually from now on for this stage type |
| other text | treat as free-form comment; re-prompt with same options |

## State machine per stage type

Per stage type ∈ {planner, implementer, reviewer-lite}:

```
initial: approval_mode = per_module (default)
   ↓
first batch-eligible dispatch
   ↓
if user chose `batch` (approve/approve except) → approval_mode = batch
if user chose `individual` → approval_mode = per_module, sticky
   ↓
subsequent same-type dispatches in same run:
  - if approval_mode == batch: re-offer batch prompt (user may change)
  - if approval_mode == per_module: skip prompt, per-module gating
```

**Sticky individual**: once user chooses `individual` for a stage type, it stays `per_module` for remainder of run. Prevents prompt fatigue.

**Non-sticky batch**: user may re-evaluate batch each time (because new set of modules each stage type).

## Pipeline-summary recording

Front-matter:

```yaml
approval_mode:
  planner: batch
  implementer: per_module   # user chose individual at implementer stage
  reviewer-lite: batch
```

Body line per batch event:

```
- **[Batch approval] Planner**: approved all 4 modules in one gate
- **[Batch approval] Implementer**: user declined batch, per-module gating engaged
- **[Batch approval] Reviewer-Lite**: approved all 4 modules, excluded module 2 (individual)
```

## Back-compat

- If `approval_mode` absent from resumed pipeline summary → all stage types default to `per_module`.
- Standard/express tiers: batch prompt is never offered; pipeline runs as in Cycle 2.
- Users who never encounter batch prompt see no change from Cycle 2.

## User preference integration

If prefs file contains `approval_mode: batch`:
- Orchestrator pre-sets `approval_mode` for all eligible stage types.
- First eligible dispatch still shows the prompt with `approve` pre-highlighted; user just presses enter.
- User may still pick `individual` to override.

If prefs file contains `approval_mode: per_module`:
- Orchestrator skips the batch prompt entirely.
- Pipeline runs as Cycle 2.

## Edge cases

- **Module count drops to 1 mid-run**: batch-eligibility fails (need ≥2). Fall through to per-module automatically.
- **User types nonsense**: re-prompt. Don't assume intent.
- **User `approve except` with module number out of range**: re-prompt with error "module N doesn't exist; modules are 1 to <N>".
- **Orchestrator crashes during batch gate**: resume uses recorded `approval_mode` (if written) or defaults to `per_module`.
