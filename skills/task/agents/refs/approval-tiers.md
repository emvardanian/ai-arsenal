# Approval Tiers

Authoritative mapping from `(tier, stage)` to approval gate. The orchestrator reads this table at every stage dispatch to decide whether to prompt the user for approval.

## Tiers

| Tier | Semantics | Default for |
|---|---|---|
| strict | Every pre-redesign `[approval]` gate prompts. Matches historical behavior exactly (FR-024). | Scope L, XL |
| standard | Only architectural decision points prompt: Spec completion, Decomposition completion, final Committer. | Scope M |
| express | Only the final Committer prompts. Trust the pipeline until the last word. | Scope XS, S |

Default selection is derived from scope (FR-011). User may override via preamble `tier: <strict|standard|express>` (FR-012) or mid-flight at any approval prompt (FR-013).

## Gate matrix

| Stage | strict | standard | express |
|---|:---:|:---:|:---:|
| Spec completion | YES | YES | no |
| Scout | no | no | no |
| Decomposer | YES | YES | no |
| Planner (per module) | YES | no | no |
| Designer (per UI module) | YES | no | no |
| Implementer (per module) | YES | no | no |
| Tester | no | no | no |
| Debugger | no | no | no |
| Design-QA | no | no | no |
| Reviewer-Lite (per module, Cycle 2) | YES | no | no |
| Reviewer | no | no | no |
| Refactorer | YES | no | no |
| Documenter | YES | no | no |
| Committer (always) | YES | YES | YES |

## Counts

For a full scope-L feature pipeline with 4 modules:

| Tier | Total approvals |
|---|---:|
| strict | 17 (Spec + Decomposer + 4×Planner + 4×Implementer + 4×Reviewer-Lite + Refactorer + Documenter + Committer) |
| standard | 3 (Spec + Decomposer + Committer) |
| express | 1 (Committer) |

Cycle 1 strict count was 13; Cycle 2 adds 4 Reviewer-Lite gates (one per module) → 17. Standard/express unchanged.

For a scope-M feature pipeline with 3 modules:

| Tier | Total approvals |
|---|---:|
| strict | 12 (Spec + Decomposer + 3×Planner + 3×Implementer + 3×Reviewer-Lite + Committer) |
| standard | 3 (Spec + Decomposer + Committer) |
| express | 1 (Committer) |

Cycle 1 strict M-3-module count was 9; Cycle 2 adds 3 Reviewer-Lite → 12.

For a scope-S feature (no Decomposer):

| Tier | Total approvals |
|---|---:|
| strict | 4 (Spec + Planner + Implementer + Committer) |
| standard | 2 (Spec + Committer) — Decomposer is absent, so the standard 3-gate rule collapses |
| express | 1 (Committer) |

## Mid-flight tier change

At any approval prompt, the user may respond with:

```
approve and switch to <tier>
```

Where `<tier>` ∈ {strict, standard, express}. Orchestrator:

1. Records the current stage's approval (it is granted).
2. Updates `pipeline-summary.md` front-matter: `tier: <new>`, `tier_source: mid_flight`, `tier_override: <new>`.
3. For every subsequent stage, reads the current tier at dispatch time and consults this table.
4. Does NOT re-run completed stages.

Downgrade (strict → express) and upgrade (express → strict) are both supported. The orchestrator logs the transition in the pipeline summary body: `**Stage N -- <name>**: ok <details> [tier switched to <new>]`.

## Criticality interaction

When criticality is detected (see `criticality-signals.md`), the orchestrator recommends `tier: strict` before finalizing tier selection. User may:

- Confirm strict → `tier: strict`, `tier_source: criticality`, `criticality_flag: true`.
- Override with a lower tier → `tier: <lower>`, `tier_source: user`, `criticality_flag: true` (flag stays true even when overridden for audit).

## Strict-Tier Invariant (FR-024, US5 Cycle 1 + US4 Cycle 2)

The strict-tier column of the gate matrix above MUST reproduce pre-Cycle-1 approval behavior plus exactly the Cycle-2 Reviewer-Lite additions. Pre-Cycle-1 gated stages were:

- Brainstormer → Analyst/Validator → Decomposer → Planner (per module) → Designer (per UI module) → Implementer (per module) → Refactorer → Documenter → Committer

Post-Cycle-1, Brainstormer + Analyst merged into Spec; the single Spec stage's approval represents both historical gates. All other gates persist.

**Cycle 2 addition**: Reviewer-Lite gates per module at scope M+ (for feature/bugfix/refactor, not hotfix). This is the ONLY additive gate in strict tier.

**Invariant**: `strict_tier_gates_count(cycle2) = strict_tier_gates_count(cycle1) + N_review_lite` where `N_review_lite = module_count if scope ∈ {M,L,XL} and task_type ≠ hotfix else 0`.

Backward-compat verification (quickstart.md Path 6) confirms the mapping.

**User override**: `review_lite: skip` preamble key disables the strict gate on Review-Lite. Review-Lite stage still runs; only approval prompt is skipped. Useful for power users.

## Reader contract

Orchestrator at each stage:

1. Read `tier` from `.task/pipeline-summary.md` front-matter (or current memory if mid-pipeline).
2. Look up `(stage_name, tier)` in the matrix above.
3. If YES: prompt user for approval before dispatching the stage.
4. If no: dispatch immediately.

Unknown stage name → default to `no` gate (fail open — don't block); log in pipeline summary.

## Back-compat

- Adding a new stage row: readers that don't recognize it use the fail-open default.
- Adding a new tier column: readers check only columns they understand; default to current tier's column if unknown.
- Removing a row or column is NOT back-compat — requires cycle-boundary migration.
