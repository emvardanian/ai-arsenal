# Ensemble Verification for the `task` SDLC Pipeline — Design

**Date:** 2026-05-13
**Status:** Draft for review
**Scope:** `ai-arsenal/skills/task/`
**Trigger:** PayPath's CTO-driven quality process (separate design at `paypath/thoughts/shared/plans/quality-process/`) uses an ensemble verification pattern — 3 identical reviewers in parallel, then merge. The same pattern is useful upstream in the generic `task` skill: it raises recall on review stages by exploiting model variance, and the synthesizer variant generalizes it to producing stages.

## Problem Statement

The `task` skill currently has single-pass reasoning agents at every stage:

- **Reviewer-Lite** (per module, haiku) — pattern scan for 5 categories
- **Reviewer** (final, sonnet) — cross-cutting semantic review, delegates security
- **Researcher** (per module, sonnet) — deep research into module scope
- **Decomposer** (opus) — single best-effort module split
- **Spec validation** (sonnet/haiku) — single validation pass

A single pass misses what a second independent pass would have caught — model variance is real. Three independent passes catch substantially more, but only if their findings/outputs are merged correctly. Different stage types require different merge semantics.

## Goal

Add ensemble execution to `task` for stages where 3 independent passes raise recall enough to justify the cost. Two ensemble forms:

1. **ensemble-verify** — review stages → union of findings with confidence weighting.
2. **ensemble-produce** — producing stages → 4th synthesizer agent merges into one canonical artefact.

Gate users on the merged/synthesized artefact only. Show divergence summary so the user knows when the three instances disagreed.

## Out of Scope

- Modifying existing per-stage agent files (reviewer.md, researcher.md, etc.) — they stay single-pass; ensemble is an orchestration concern.
- Forcing ensemble unconditionally. Activation is scope-gated (small tasks pay no overhead).
- Hook-based enforcement at the harness level.

---

## 1. Two Ensemble Forms

### 1.1 ensemble-verify (review stages)

Applies to: **Reviewer**, **Reviewer-Lite**, **Spec validation**.

Mechanism:
1. Orchestrator spawns the target reviewer agent three times in parallel via a single `Agent` tool call (multiple invocations in one message). All three receive identical inputs and identical prompts — no role specialization.
2. Each returns a list of findings.
3. Synthesizer (mode=verify) merges:
   - Union of unique findings (paraphrase-detection used to dedupe).
   - Each finding tagged with reviewer count: `[3/3]` (all three), `[2/3]`, `[1/3]`.
   - `[1/3]` items are NOT filtered out — they are exactly what a single pass misses.
   - Sort by severity, then by reviewer count.
4. Verdict: `PASS` only if merged list is empty.
5. Output canonical merged file; raw files retained as audit trail.

### 1.2 ensemble-produce (producing stages)

Applies to: **Researcher** (per module), **Decomposer**.

Mechanism:
1. Orchestrator spawns the target producing agent three times in parallel. Each writes its own raw artefact (suffixed `-a.md`, `-b.md`, `-c.md`).
2. Synthesizer (mode=produce) reads all three raw artefacts and writes one canonical merged artefact (no suffix).
3. Synthesizer is model-matched to the producing agent's tier:
   - Researcher (sonnet) → synthesizer sonnet
   - Decomposer (opus) → synthesizer opus
4. Synthesizer's Brief section records: "Synthesized from 3 instances; merged X references; resolved Y conflicts."
5. If raw outputs diverge semantically beyond `divergence_threshold` (e.g., different module count in Decomposer), synthesizer returns a `divergence-error`. Orchestrator escalates to the user with all three raw outputs side by side.

---

## 2. Activation Matrix (Scope-Gated)

| Scope | Reviewer | Reviewer-Lite | Researcher | Spec validation | Decomposer |
|-------|----------|---------------|------------|-----------------|------------|
| XS    | ensemble | —             | —          | single          | —          |
| S     | ensemble | —             | —          | single          | —          |
| M     | ensemble | single        | ensemble   | single          | single     |
| L     | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |
| XL    | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |

Legend: `ensemble` — 3 parallel + synthesizer; `single` — existing single-pass behavior; `—` — stage does not run at this scope per existing `refs/scope-pipelines.md` (this design does not change which stages run, only whether they ensemble).

Rationale: Reviewer is always ensemble because it's the most semantic and highest-leverage. Researcher/Decomposer activate at M+/L+ because per-module ensemble costs scale with module count. Reviewer-Lite is mechanical pattern matching; ensemble's recall gain on regex matching is modest, so we gate it to L+ where the safety margin matters.

---

## 3. Approval Gates

Existing `task` approval logic (strict / standard / express tiers) is unchanged. Two adjustments for ensemble:

1. **Gate target.** When ensemble is active for a stage, the approval gate fires on the merged/synthesized canonical file only. The three raw files are workspace artefacts (audit trail), not approval objects.

2. **Divergence summary at the gate.** When showing the canonical for approval, also show a short summary:
   ```
   Ensemble: 3 × sonnet
   Reviewer A: 5 findings | Reviewer B: 7 findings | Reviewer C: 4 findings
   Merged: 9 unique findings (4 × [3/3] high-confidence, 3 × [2/3], 2 × [1/3] worth investigating)
   ```
   For produce-mode: "Synthesized from 3 outputs; merged 12 references, resolved 1 module-boundary conflict."

The user can drill into raw files if they want to audit the synthesis.

---

## 4. Workspace Layout

`.task/` extended with raw + canonical files:

```
.task/
  00-spec.md                       <- existing single-pass output
  00-spec-validation-a.md          <- ensemble-verify raw outputs (Spec validation, L+)
  00-spec-validation-b.md
  00-spec-validation-c.md
  00-spec-validation.md            <- synthesized, gated

  02-scout.md

  03-decomposition-a.md            <- ensemble-produce raw outputs (Decomposer, L+)
  03-decomposition-b.md
  03-decomposition-c.md
  03-decomposition.md              <- synthesized, gated

  04-research-1-a.md               <- per module (1..N), ensemble-produce (M+)
  04-research-1-b.md
  04-research-1-c.md
  04-research-1.md                 <- synthesized, gated
  ...

  05-plan-1.md                     <- existing (Planner not ensembled in this design)
  06-impl-1.md
  07-tests-1-1.md
  08-debug-1-1.md

  09.5-review-lite-1-a.md          <- per module, ensemble-verify (L+)
  09.5-review-lite-1-b.md
  09.5-review-lite-1-c.md
  09.5-review-lite-1.md            <- merged, gated
  ...

  09-review-a.md                   <- ensemble-verify (always)
  09-review-b.md
  09-review-c.md
  09-review.md                     <- merged, gated

  10-refactor.md
  11-docs.md
  12-commit.md
```

Approval gate fires on files without the `-a/-b/-c` suffix. Raw files persist for audit.

---

## 5. Implementation Footprint

**New files (2):**

- `agents/synthesizer.md` — generic synthesizer agent.
  - Accepts mode (`verify` or `produce`) and a list of raw artefact paths.
  - In `verify` mode: applies the union-with-confidence merge algorithm.
  - In `produce` mode: reads N raw artefacts, synthesizes one canonical version; detects divergence and returns `divergence-error` when raw outputs disagree beyond threshold.

- `agents/refs/ensemble.md` — ensemble protocol reference.
  - When orchestrator activates ensemble (scope matrix table).
  - File naming convention (`{stage}-{N}-{a,b,c}.md`).
  - Divergence threshold defaults per stage.
  - Failure handling (timeouts, near-identical outputs, divergence).
  - Front-matter additions for `pipeline-summary.md`.

**Updated files (3):**

- `SKILL.md` — Step 9 (Dispatch stages):
  ```
  for each stage in resolved pipeline:
      ensemble_active = should_ensemble(stage, scope, tier)  # from refs/ensemble.md table
      if ensemble_active:
          spawn 3 parallel <stage> agents in one Agent call
          wait for all three (with timeout handling per refs/ensemble.md)
          dispatch synthesizer agent with mode + raw paths
          gate on canonical (show divergence summary)
      else:
          existing single-pass dispatch
  ```
  Add `ensemble` block to pipeline-summary front-matter schema.

- `agents/refs/scope-pipelines.md` — record activation matrix above per scope.

- `agents/refs/model-tiers.md` — entries for synthesizer roles:
  ```
  synthesizer-verify-reviewer:       sonnet
  synthesizer-verify-reviewer-lite:  haiku
  synthesizer-verify-spec:           sonnet
  synthesizer-produce-research:      sonnet
  synthesizer-produce-decomposer:    opus
  ```
  (The synthesizer agent file is one; the model assignment varies per stage it's synthesizing for.)

**No changes:** `agents/reviewer.md`, `reviewer-lite.md`, `researcher.md`, `decomposer.md`, `spec.md`. Ensemble is purely an orchestration concern.

---

## 6. Cost and Performance

**Cost overhead estimate** (L-task with 5 modules, full ensemble):
- Researcher: 5 modules × 3 sonnet + 5 synth sonnet = 20 sonnet calls (vs. 5 baseline). ~4x.
- Reviewer-Lite: 5 modules × 3 haiku + 5 synth haiku = 20 haiku calls (vs. 5 baseline). Cheap.
- Decomposer: 3 opus + 1 opus synth = 4 opus calls (vs. 1 baseline). ~4x.
- Reviewer: 3 sonnet + 1 sonnet synth = 4 sonnet calls (vs. 1 baseline). ~4x.
- Spec validation: 3 sonnet + 1 synth = 4 (vs. 1). ~4x.

Overall pipeline overhead: ~2.5x total token cost for L-tasks vs. single-pass.

**Mitigations:**
- **Prompt caching.** Three instances with identical system prompt + context get cache hits after the first. Effective overhead lower than 3x on long contexts.
- **Identical-output short-circuit.** Synthesizer detects identical raw outputs (hash compare) and returns the first one as-is, skipping merge work. Common for mechanical Reviewer-Lite passes.
- **Scope gating.** XS/S skip producing-stage ensembles entirely.

---

## 7. Pipeline-Summary Front-Matter Additions

```yaml
ensemble:
  active: true
  active_stages: [reviewer, researcher, reviewer-lite, spec-validation, decomposer]
  scope_basis: l                       # which scope drove the activation
  override_source: scope-pipelines     # or preamble/prefs if user overrode
  divergence_threshold: 0.3            # produce-mode escalation threshold
  per_stage:
    reviewer:        { instances: 3, model: sonnet, status: completed }
    reviewer-lite:   { instances: 3, model: haiku,  status: completed }
    researcher:      { instances: 3, model: sonnet, status: completed }
    decomposer:      { instances: 3, model: opus,   status: completed }
    spec-validation: { instances: 3, model: sonnet, status: completed }
```

Recorded so `refs/resume.md` can detect ensemble state on resume and continue correctly.

---

## 8. Failure Modes

- **Instance timeout.** Retry the single failing instance once. If still timeout: proceed with the two that returned. Synthesizer marks output `Instances: 2/3 (one timed out)`. Confidence tags adjust to `[2/2]`, `[1/2]`.
- **Synthesizer divergence-error in produce mode.** Surface all three raw outputs to the user side-by-side. User resolves manually; canonical is written from user's choice (or by re-running synthesizer with user guidance).
- **Three near-identical outputs.** Synthesizer short-circuits, returns Reviewer-A verbatim with note `triple agreement, no merge needed`. Saves tokens.
- **Synthesizer itself fails.** Orchestrator stops, presents raw outputs to user, awaits manual decision. Synthesizer is not re-run automatically (risk of infinite loop).

---

## 9. Acceptance Criteria

1. Running `/task-full <description>` (L scope, strict tier) on a 3-module feature produces:
   - `00-spec-validation-{a,b,c,merged}.md`
   - `03-decomposition-{a,b,c,merged}.md`
   - `04-research-{N}-{a,b,c,merged}.md` for each module N
   - `09.5-review-lite-{N}-{a,b,c,merged}.md` for each module N
   - `09-review-{a,b,c,merged}.md`
   All canonical files gated; raw files present as audit trail.

2. Running `/task-quick <description>` (S scope, express tier) skips Reviewer-Lite / Researcher / Decomposer entirely (existing behavior) and runs Reviewer as ensemble (3 instances + merge).

3. Pipeline-summary front-matter records the ensemble block with per-stage instance counts and models.

4. Divergence summary appears in approval prompts whenever ensemble was active for the gated stage.

5. Existing single-pass behavior is preserved for stages not covered by ensemble (Scout, Planner, Implementer, Tester, Debugger, Designer, Design-QA, Refactorer, Documenter, Committer).

---

## 10. Open Questions

- **Batch approval interaction.** Strict tier allows batch approval of multiple per-module outputs. Should the batch operate on raw or canonical files? Proposal: batch operates on canonical only (raw files invisible to the batch). To be confirmed in `refs/batch-approval.md` updates if needed.
- **Planner ensembling.** Not included in this design. The Planner is opus, single-pass, with high leverage. Could be an obvious next stage to ensemble at XL scope. Deferred to a follow-up after this design ships.
- **Designer ensembling.** Not included. Visual outputs may not synthesize cleanly. Deferred.

---

## 11. Risks

- **Divergence error rate.** If `produce-mode` synthesizer flags divergence often, user fatigue rises. Tune `divergence_threshold` empirically after first 5-10 real runs.
- **Cache invalidation across instances.** If the three instances are sufficiently different in their reasoning paths, prompt cache won't help and cost approaches full 3x. Monitor empirically.
- **Synthesizer becomes the bottleneck.** Synthesizer reads 3 full raw artefacts + produces one canonical. For very long research docs, this can be slow and expensive. Mitigation: synthesizer reads Briefs first and falls back to full only when needed.
- **Existing task skill users see new files in `.task/`.** Audit-trail files are new artefacts. If users grep `.task/` programmatically, they may need to filter on canonical (no suffix) vs raw (a/b/c suffix). Document in CHANGELOG.

---

## 12. Post-Adoption Tasks

- Run on 3-5 real L-scope tasks; collect cost and recall metrics; tune defaults.
- Update `task` skill CHANGELOG and README with ensemble concept.
- Backport to PayPath's `pay.*` flow if pattern proves out (currently PayPath uses identical 3-reviewer-no-roles pattern but without a generic synthesizer).
- Consider Planner / Designer ensembling as follow-up.
