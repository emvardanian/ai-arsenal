# Ensemble Verification — Reference

Defines when and how the `task` orchestrator runs stages as 3-parallel ensembles instead of single-pass. Two forms: `verify` (review stages, union of findings) and `produce` (producing stages, synthesizer merge).

This ref is loaded by the orchestrator at startup, alongside the Agent Reference in `SKILL.md`.

## Activation Matrix

Default activation by scope (overridden by `refs/scope-pipelines.md` if present, by preamble `ensemble: off|full`, or by per-prefs setting):

| Scope | Reviewer | Reviewer-Lite | Researcher | Spec validation | Decomposer |
|-------|----------|---------------|------------|-----------------|------------|
| XS    | ensemble | —             | —          | single          | —          |
| S     | ensemble | —             | —          | single          | —          |
| M     | ensemble | single        | ensemble   | single          | single     |
| L     | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |
| XL    | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |

Legend:
- `ensemble` — run as 3 parallel + synthesizer.
- `single` — existing single-pass behavior (this ref does not change which stages run, only whether they ensemble).
- `—` — stage does not run at this scope per existing `refs/scope-pipelines.md`.

## Two Ensemble Forms

### `verify` (review stages)
- Targets: Reviewer, Reviewer-Lite, Spec validation.
- Mechanism: 3 parallel instances of the target reviewer agent run with identical prompts.
- Merge: synthesizer in `verify` mode produces union of unique findings, tagged with reviewer count `[3/3]` / `[2/3]` / `[1/3]`.
- Verdict: `PASS` only if merged list is empty.

### `produce` (producing stages)
- Targets: Researcher (per module), Decomposer.
- Mechanism: 3 parallel instances of the target producing agent run, each writing its own raw artefact (`-a/-b/-c` suffix).
- Merge: synthesizer in `produce` mode reads all 3 raws and writes one canonical merged artefact (no suffix).
- Divergence handling: if outputs diverge beyond `divergence_threshold`, synthesizer returns `divergence-error` instead.

## File Naming Convention

Raw artefacts (3 per ensembled stage):
```
.task/<stage>-<N>-a.md
.task/<stage>-<N>-b.md
.task/<stage>-<N>-c.md
```

Canonical merged artefact (one per stage, gated):
```
.task/<stage>-<N>.md
```

Where:
- `<stage>` matches existing task stage numbering: `00-spec-validation`, `03-decomposition`, `04-research`, `09.5-review-lite`, `09-review`.
- `<N>` is the module index (omitted for non-modular stages like `00-spec-validation`, `03-decomposition`, `09-review`).

Examples:
- `04-research-2-a.md`, `-b.md`, `-c.md` → raw researcher outputs for module 2.
- `04-research-2.md` → synthesized canonical for module 2.
- `09-review-a.md`, `-b.md`, `-c.md` → raw final reviews.
- `09-review.md` → synthesized canonical final review.

## Divergence Thresholds

Per-stage defaults for `produce` mode (tunable):

| Stage | Threshold | Metric |
|-------|-----------|--------|
| researcher | 0.3 | Jaccard distance on referenced file paths + dependency lists |
| decomposer | 0.2 | Module-count delta (strict) + module-boundary overlap (loose) |

A stage exceeds threshold when the synthesizer cannot reconcile the 3 raw outputs into a single coherent canonical. In that case the synthesizer returns:

```
divergence-error: <stage> ensemble produced N modules / X files in raws but cannot be reconciled.
See raw files: <paths>. Awaiting user decision.
```

Orchestrator pauses and presents raw outputs side by side; user picks one or asks for re-run with guidance.

For `verify` mode there is no divergence threshold — findings merge by set union, always succeeds.

## Failure Handling

### One instance times out
- Retry the timed-out instance once.
- If still failing: proceed with the 2 successful instances.
- Synthesizer header records `Instances: 2/3 (one timed out)`.
- Confidence tags adjust to `[2/2]` / `[1/2]` in `verify` mode.

### Three identical raw outputs (hash match)
- Synthesizer short-circuits: returns raw-a verbatim, marked `triple agreement, no merge needed`.
- Saves tokens. Especially common for mechanical Reviewer-Lite passes.

### Divergence beyond threshold (produce mode)
- Synthesizer returns `divergence-error`.
- Orchestrator pauses.
- User sees raw outputs side by side, picks resolution.

### Synthesizer itself fails
- Orchestrator stops.
- Raw outputs surfaced to user.
- User decides resolution manually. No automatic synthesizer retry (loop risk).

## Pipeline-Summary Front-Matter Schema

When ensemble is active, `pipeline-summary.md` front-matter MUST contain:

```yaml
ensemble:
  active: true
  active_stages: [reviewer, researcher, reviewer-lite]
  scope_basis: l
  override_source: scope-pipelines    # or "preamble" / "prefs"
  divergence_threshold:
    researcher: 0.3
    decomposer: 0.2
  per_stage:
    reviewer:        { instances: 3, model: sonnet, status: completed }
    reviewer-lite:   { instances: 3, model: haiku,  status: completed }
    researcher:      { instances: 3, model: sonnet, status: completed }
    spec-validation: { instances: 1, model: sonnet, status: skipped }
    decomposer:      { instances: 1, model: opus,   status: skipped }
```

Field semantics:
- `active`: false only if user passed `ensemble: off` or scope = XS/S with no Reviewer ensemble flag.
- `active_stages`: list of stages that actually ran as ensemble in this pipeline.
- `scope_basis`: the scope value that drove activation. Allows `refs/resume.md` to verify on resume.
- `override_source`: where the activation decision came from. One of: `scope-pipelines` (default), `preamble`, `prefs`.
- `per_stage`: per-stage record. `instances: 1` means single-pass; `instances: 3` means ensembled.
- `status`: `completed` | `skipped` | `divergence-error` | `partial` (when 2/3 ran).

## Override Hierarchy

Per `refs/prefs.md` precedence:

```
preamble > slash-command > project-prefs > global-prefs > activation-matrix
```

Preamble flags recognised by this ref:
- `ensemble: off` → empty `active_stages` regardless of scope.
- `ensemble: full` → maximum eligible `active_stages` for the resolved scope.
- `ensemble: reviewer-only` → `[reviewer]` only.

## should_ensemble(stage, scope, tier) — Pseudocode

```
function should_ensemble(stage, scope, tier):
    # honor explicit overrides first
    override = read_preamble_or_prefs("ensemble")
    if override == "off":
        return false
    if override == "full":
        return stage in eligible_for_scope(scope)
    if override == "reviewer-only":
        return stage == "reviewer"

    # default: scope-based matrix
    return stage in activation_matrix[scope]

function eligible_for_scope(scope):
    if scope in [XS, S]:
        return [reviewer]
    if scope == M:
        return [reviewer, researcher]
    if scope in [L, XL]:
        return [reviewer, reviewer-lite, researcher, spec-validation, decomposer]
```

## Cost Estimate

| Scope | Ensemble overhead vs single-pass | Reason |
|-------|----------------------------------|--------|
| XS, S | ~1.3x | Only Reviewer ensembled (3 × sonnet for one stage). |
| M     | ~1.8x | Reviewer + per-module Researcher. |
| L, XL | ~2.5x | All 5 eligible stages × N modules where applicable. |

Mitigation: prompt caching across the 3 identical instances brings effective overhead lower (10-30% in practice depending on input length).

## When to update this ref

- Activation matrix changed → update the table at top.
- New ensemble form added (e.g., `vote` for majority verdict on closed-set choices) → add a section.
- Divergence threshold tuning after dogfood data → update the thresholds table.
- New stage made ensemble-eligible (e.g., Planner) → add row to activation matrix.

## See also

- `refs/scope-pipelines.md` — which stages run at which scope (independent of ensemble).
- `refs/model-tiers.md` — model assignments including synthesizer entries.
- `refs/prefs.md` — preamble / prefs precedence.
- `refs/approvals.md` — gate semantics (gates fire on canonical only).
- `agents/synthesizer.md` — the synthesizer agent implementation.
