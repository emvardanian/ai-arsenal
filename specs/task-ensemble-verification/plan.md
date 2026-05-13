# Implementation Plan: Ensemble Verification for the `task` Skill

**Branch**: `feature/task-ensemble-verification` | **Date**: 2026-05-13
**Spec**: ./spec.md
**Design source**: `docs/superpowers/specs/2026-05-13-task-ensemble-verification-design.md`

## Summary

Extend the `task` SDLC skill to support two ensemble patterns at selected stages: `verify` (3 parallel reviewers → union of findings) and `produce` (3 parallel producers → 4th synthesizer agent → 1 canonical artefact). Activation is scope-gated. Existing per-stage agents (reviewer, reviewer-lite, researcher, decomposer, spec) are unchanged — ensemble is purely an orchestration concern in `SKILL.md` plus one new generic `synthesizer.md` agent and one new `refs/ensemble.md` reference.

## Technical Context

**Language**: Markdown agent files (no executable code).
**Primary surfaces**: `skills/task/SKILL.md` (orchestrator), `skills/task/agents/synthesizer.md` (new), `skills/task/agents/refs/ensemble.md` (new), `skills/task/agents/refs/scope-pipelines.md` (update), `skills/task/agents/refs/model-tiers.md` (update).
**Storage**: `.task/` workspace per the spec's workspace layout.
**Testing**: Manual dogfooding via `/task-quick` (S scope, Reviewer-only ensemble) and `/task-full` (L scope, full ensemble). No automated tests — task skill is an orchestration layer with no executable runtime.
**Project type**: Toolkit (Claude Code skills).
**Performance goals**: ~2.5x token overhead on L-scope ensembling; prompt caching expected to keep effective overhead lower.
**Constraints**: Existing agent files must remain unchanged. Constitution and other refs must not regress. Approval gate semantics for non-ensembled stages must be preserved.
**Scale/Scope**: 2 new files + 3 updated files. ~400-600 lines of new markdown total.

## Constitution Check

- ✅ Existing single-pass behavior preserved for non-ensembled stages.
- ✅ Approval gates unchanged in their structure; only gate target adjusts (canonical only).
- ✅ Lint/test gates from `task` constitution unaffected (this work has no executable code).
- ✅ Push approval rule preserved.

No violations. No complexity tracking entries needed.

## Relevant App Flow Changes (mirror from design)

### Flow: SKILL.md Step 9 — Dispatch stages
- **Status**: changed
- **Change**: insert ensemble routing logic. For each stage in resolved pipeline, check `should_ensemble(stage, scope, tier)` per `refs/ensemble.md`. If true: spawn 3 parallel instances in one Agent call, write raw `-a/-b/-c.md`, dispatch synthesizer, write canonical, gate on canonical. Otherwise: existing single-pass logic.
- **Affected files**: `skills/task/SKILL.md`

### Flow: SKILL.md pipeline-summary front-matter
- **Status**: changed
- **Change**: add `ensemble` block schema. Record `active`, `active_stages`, `scope_basis`, `override_source`, `divergence_threshold`, and `per_stage` map with instance counts, models, statuses.
- **Affected files**: `skills/task/SKILL.md` (schema description), `skills/task/agents/refs/ensemble.md` (canonical schema definition).

### Flow: refs/scope-pipelines.md — pipeline lookup
- **Status**: changed
- **Change**: add ensemble activation matrix per scope (XS/S/M/L/XL × eligible stages) referenced by orchestrator at dispatch.
- **Affected files**: `skills/task/agents/refs/scope-pipelines.md`

### Flow: refs/model-tiers.md — model lookup
- **Status**: changed
- **Change**: add 5 synthesizer entries (one per ensembled stage type) with appropriate model tier.
- **Affected files**: `skills/task/agents/refs/model-tiers.md`

### Flow: Existing agent files (reviewer, reviewer-lite, researcher, decomposer, spec)
- **Status**: unchanged
- **Change**: none. Per FR-014.
- **Affected files**: none.

### Flow: refs/approvals.md, refs/approval-tiers.md, refs/batch-approval.md
- **Status**: unchanged (assumed for now; revisit in Open Questions per design)
- **Change**: none in this iteration. Batch approval interaction recorded as open question.
- **Affected files**: none.

## Risk Mitigation (mirror from design)

- **R1 Divergence error rate too high** — synthesizer flags divergence often in produce mode, causing user fatigue. Mitigation: `divergence_threshold` is configurable in `refs/ensemble.md`; defaulted to 0.3 (loose) initially; tune empirically after first 5-10 real runs. Recorded in `pipeline-summary.md` for retrospective analysis.

- **R2 Cache hit rate lower than expected** — three instances with identical prompts may diverge in reasoning paths, reducing cache benefit and pushing cost closer to full 3x. Mitigation: monitor token cost on first L-scope runs; if cache hit rate < 50%, consider lowering ensemble activation (e.g., gate Researcher to L only, not M).

- **R3 Synthesizer becomes bottleneck** — synthesizer reads 3 full raw artefacts. For long research docs, this is slow/expensive. Mitigation: synthesizer reads each raw artefact's Brief section first; falls back to full read only when synthesis requires it. Documented in `agents/synthesizer.md`.

- **R4 Audit-trail noise in `.task/`** — users grepping `.task/` see new `-a/-b/-c` files. Mitigation: file-naming convention is explicit (`<stage>-<N>-<suffix>.md`); canonical files have no suffix; CHANGELOG entry documents the change.

## TDD Strategy

This feature has no executable code, so traditional TDD (RED → GREEN) does not apply. Instead, **dogfooding tests** serve as the verification gate:

1. **Test E1 — Reviewer ensemble at XS scope.** Run `/task-quick "rename a function"` on a trivial codebase. Verify: `.task/09-review-{a,b,c}.md` exist; `.task/09-review.md` is the synthesized canonical with `[N/3]` confidence tags; gate shows divergence summary.

2. **Test E2 — Scope gating at S scope.** Run `/task-quick`. Verify: no `04-research-*.md` raw files; no `03-decomposition-*.md` raw files; only Reviewer is ensembled.

3. **Test E3 — Full ensemble at L scope.** Run `/task-full "add feature across 3 modules"`. Verify: each module has `04-research-{N}-{a,b,c,canonical}.md`; `03-decomposition-{a,b,c,canonical}.md` exist; Reviewer-Lite produces `09.5-review-lite-{N}-{a,b,c,canonical}.md` per module; final Reviewer produces `09-review-{a,b,c,canonical}.md`.

4. **Test E4 — Identical-output short-circuit.** Force mechanical Reviewer-Lite on a clean codebase where all 3 instances should produce empty findings. Verify: synthesizer returns one verbatim with `triple agreement, no merge needed` note.

5. **Test E5 — Divergence-error escalation.** Run on a poorly-defined feature where decomposer outputs may diverge wildly. Verify: synthesizer returns `divergence-error`; orchestrator pauses; raw outputs presented side by side.

6. **Test E6 — Override flag.** Run `/task-full` with preamble `ensemble: off`. Verify: no raw files anywhere; full single-pass behavior.

7. **Test E7 — Front-matter recording.** After any ensembled run, verify `pipeline-summary.md` front-matter includes the `ensemble` block per spec FR-010.

## Post-Release Tasks

- After 5+ real L-scope runs, collect token cost metrics; compare to single-pass baseline; tune `divergence_threshold` and activation matrix if needed.
- Update `task` skill CHANGELOG with the new ensemble concept and migration notes (the new `-a/-b/-c` workspace files are additive — no breakage to existing users).
- Document the synthesizer + ensemble pattern in `task` skill README.
- Consider follow-up RFC: Planner / Designer ensembling at XL scope (deferred per design § 10).
- Backport learnings to PayPath's `pay.*` flow (which uses an identical 3-reviewer pattern but without a generic synthesizer).
