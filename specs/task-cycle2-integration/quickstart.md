# Quickstart: Cycle 2 Verification Paths

**Feature**: task-cycle2-integration
**Date**: 2026-04-17
**Purpose**: Representative walkthroughs and verification procedures for Cycle 2 SC targets.

## Path 1 — Scope-M feature with delegation=delegate

**Task**: "Add email notifications for password reset."

**Setup**: superpowers plugin installed.

**Expected orchestrator startup**:
- scope: M (classified)
- tier: standard (default)
- `delegation_mode: delegate`, `delegation_source: default`
- `review_lite_enabled: true`

**Expected pipeline** (scope-m feature per `refs/scope-pipelines.md` with Review-Lite):
```
Spec → Scout → Decomposer → (Researcher → Planner[delegated] → Implementer[delegated] → Tester[delegated] ⇄ Debugger[delegated] → Reviewer-Lite)×3 → Reviewer → Committer
```

**Expected approvals** (standard tier): 3 (Spec, Decomposer, Committer). Review-Lite runs but no gate.

**SC checks**:
- [ ] SC-005: Planner wrapper invokes `superpowers:writing-plans`; `05-plan-{N}.md` has valid schema.
- [ ] SC-005: Debugger (if triggered) produces `08-debug-{N}-{C}.md` with hypotheses + evidence.
- [ ] SC-001: if module 1 has injected hardcoded secret, Review-Lite catches before module 2.

## Path 2 — Scope-L feature with intentional Critical bug in module 2

**Task**: "Migrate auth to OAuth2 with refresh tokens." (module 2 code has `const SECRET = "sk-hardcoded"`)

**Expected**:
- scope: L, tier: strict (auto + criticality confirmed via "auth" keyword)
- Review-Lite runs after module 2's Tester → verdict FAIL_CRITICAL
- Routes to Debugger → Implementer → Tester → Review-Lite retry (cycle 2)
- Secret removed, Review-Lite verdict PASS → module 3 begins

**Baseline (Cycle 1)**: same bug reaches final Reviewer after all 4 modules built. Fix forces re-run of modules 2+.

**SC checks**:
- [ ] SC-001: Review-Lite catches secret before module 3 starts.
- [ ] SC-002: wall-clock time ≤ 75% of Cycle 1 baseline on same task.
- [ ] SC-007: approval count = Cycle 1 strict L count + 4 Review-Lite gates (one per module).

## Path 3 — Scope-M with user-forced fallback

**Invocation**:
```
delegation: disable
Add retry logic to webhook dispatcher.
```

**Expected**:
- `delegation_mode: fallback`, `delegation_source: user`
- All Planner/Debugger/Implementer/Tester wrappers execute inline (pre-Cycle-2) behavior.
- Artifacts equivalent to Cycle 1 output on same task.

**SC checks**:
- [ ] SC-006: artifacts functionally equivalent to Cycle 1.
- [ ] SC-010: `delegation_source: user` recorded in front-matter.

## Path 4 — Backward-compat resume (pre-Cycle-2 workspace)

**Setup**: Existing `.task/` workspace from a Cycle 1 run (has v2 front-matter but no `delegation_mode`, no `09.5-*` files).

**Expected**:
- Orchestrator reads front-matter; missing `delegation_mode` → defaults to `fallback`.
- Missing `review_lite_enabled` → defaults to `false` (no retroactive Review-Lite).
- Resume continues from next incomplete stage.
- No errors, no user prompts.

**SC check**:
- [ ] SC-008: resume completes successfully; no crashes on missing fields.

## Path 5 — SKILL.md split verification

**Procedure**:
1. Read pre-split SKILL.md from branch `main` at commit `d1b3f17` (Cycle 1 final).
2. Read post-split SKILL.md + all four new refs on this branch.
3. Run topic-coverage mapping per `contracts/refs-layout.md`.
4. Confirm every H2/H3 heading from pre-split maps to a location post-split.

**SC checks**:
- [ ] SC-003: SKILL.md ≤120 lines.
- [ ] SC-004: zero pre-split topics missing from post-split artifacts.

## Path 6 — Strict-tier approval count diff

**Procedure**: run identical scope-L feature (4 modules) through Cycle 1 and Cycle 2 skills at strict tier.

**Expected diff**:
- Cycle 1 strict L approval count = X (per Cycle 1 baseline).
- Cycle 2 strict L approval count = X + 4 (one Review-Lite gate per module).
- All other approvals identical in count and stage order.

**SC check**:
- [ ] SC-007: Cycle 2 = Cycle 1 + exactly N Review-Lite gates.

## Path 7 — Dedup at final Reviewer

**Setup**: scope-M with 3 modules. Module 2 has Critical finding caught by Review-Lite, fixed in Debug cycle.

**Expected**: final Reviewer reads `09.5-review-lite-*.md`:
- Sees Module 2's Critical (resolved) — excludes.
- Sees any Minor findings — aggregates into `09-review.md` with `source: review-lite`.
- Its own cross-cutting scan does not re-report the already-fixed hardcoded secret.

**SC check**:
- [ ] SC-009: final Reviewer produces zero duplicate findings for resolved Review-Lite issues.

## Running the verification suite (manual)

Constitution: no test runner. Verification is manual.

1. Checkout main at `d1b3f17` (Cycle 1 final).
2. Run Paths 1-7 baseline tasks; record approval counts, wall-clock, artifact shapes.
3. Checkout `task-cycle2-integration` branch.
4. Re-run same tasks; record same metrics.
5. Diff and confirm SC targets met.
6. Log results in `verification-results.md`.

If any SC fails → loop back to tasks revision before PR.
