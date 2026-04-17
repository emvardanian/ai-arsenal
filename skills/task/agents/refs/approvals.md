# Approvals & Flow Control

**Load trigger**: on first stage dispatch; cache for duration of run.

Covers tier selection, per-stage gate resolution, mid-flight tier change, criticality detection, and the Test/Debug, Design-QA, Review-Lite, and Plan Deviation cycles.

## Approval Tier Selection

The orchestrator picks one of three **approval tiers** — `strict`, `standard`, `express` — that determines which pipeline stages prompt the user for approval.

**Authoritative gate matrix** lives in `agents/refs/approval-tiers.md`. Orchestrator consults it at every stage dispatch to resolve the approval flag.

**Defaults by scope** (FR-011):

| Scope | Default tier | Approval count (typical feature) |
|---|---|---:|
| XS | express | 1 (Committer) |
| S | express | 1 (Committer) |
| M | standard | 3 (Spec, Decomposer, Committer) |
| L | strict | pre-redesign behavior + Cycle 2 Reviewer-Lite gates |
| XL | strict | pre-redesign behavior + Cycle 2 Reviewer-Lite gates |

**Strict tier** reproduces pre-Cycle-1 approval behavior plus N Reviewer-Lite gates (FR-024 + Cycle 2 FR-023). **Standard tier** prompts only at architectural decision points. **Express tier** prompts only at the final commit.

### Tier Override

Users may override the scope-derived default:

1. **Preamble**: `tier: <strict|standard|express>` at the start of the invocation.
2. **Natural-language fallback**: keywords `"fast"`, `"quickly"`, `"autopilot"` → express; `"carefully"`, `"step by step"` → strict.

**Precedence**: preamble > natural-language inference > scope default. When user overrides, `tier_source: user` and `tier_override: <tier>` are recorded.

### Mid-Flight Tier Change

At any approval prompt, user may respond with:

```
approve and switch to <tier>
```

Where `<tier>` ∈ {strict, standard, express}. The orchestrator:

1. Accepts the current stage's approval (the user said "approve").
2. Updates front-matter: `tier: <new>`, `tier_source: mid_flight`, `tier_override: <new>`.
3. For every subsequent stage, reads the current tier and consults `refs/approval-tiers.md`.
4. Does NOT re-run completed stages. Their approvals stand.

Both upgrades (express → strict) and downgrades (strict → express) are supported. The transition is logged in the pipeline summary body: `**Stage N -- <name>**: ok <details> [tier switched to <new>]`.

### Criticality Detection

Before finalizing tier selection, the orchestrator scans for criticality signals per `agents/refs/criticality-signals.md`. Three sources, first hit wins:

1. **User flag**: preamble `critical: true`.
2. **Keyword match** in task description: `security`, `production`, `hotfix`, `critical`, `breaking`, `data loss`, `auth`, `payment`, `pii` (case-insensitive whole-word).
3. **Spec metadata**: keywords in `## Quality Gates` section of `.task/00-spec.md` (runs post-Spec).

**On detection**, orchestrator shows a one-reply gate:

```
**Criticality detected** via <source>: "<matched_term>".
Recommended tier: strict (scope default would be <default>).
[strict] (proceed with strict)
[override] (proceed with <default>)
```

- User replies `strict` → `tier: strict`, `tier_source: criticality`, `criticality_flag: true`.
- User replies `override` → `tier: <default>`, `tier_source: user`, `criticality_flag: true`, `tier_override: <default>`.

The flag stays `true` for audit in both cases. Criticality never forces strict without user confirmation (FR-014 + Edge Case: user's explicit declarations win).

**Gate is skipped** when the user already declared `tier: strict` in the preamble (nothing to recommend) or when they declared `critical: false` explicitly alongside a non-strict tier.

## Flow Control

### Approval Gates

Approval is **resolved dynamically per stage** based on the current tier. The `[approval]` label in the pipeline overview diagram is a visual hint for strict-tier behavior only — it is NOT the source of truth.

**Resolution algorithm** (applied at every stage dispatch):

1. Read current `tier` from `.task/pipeline-summary.md` front-matter (or in-memory state if updated mid-flight).
2. Look up `(stage_name, tier)` in `agents/refs/approval-tiers.md`.
3. If matrix cell = YES → present stage output, wait for explicit approval, accept mid-flight tier change if user declares it.
4. If matrix cell = no → dispatch immediately without prompting.

**Invariants**:
- **Committer always gated** (all tiers).
- **Spec completion and Decomposer completion gated** in strict and standard tiers.
- **Reviewer-Lite (Cycle 2) gated per-module in strict tier only.** User may declare `review_lite: skip` preamble key to run Review-Lite without approval gate (stage still runs).
- **Strict tier matches pre-Cycle-1 behavior exactly plus N additional Reviewer-Lite gates** (where N = module count). Any change to strict-tier gate set is a constitution-level modification.
- **Per-section internal approvals** during Spec interactive/interview dialogue are NOT counted as pipeline gates — they are part of the Spec stage's internal flow.

### Test/Debug Cycle

```
Cycle 1: Tester fails -> Debugger -> Implementer fixes -> Tester re-runs
Cycle 2: Still failing -> Debugger -> Implementer -> Tester
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 debug cycles. Never loop indefinitely.

### Design QA Cycle

Runs after Test/Debug cycle completes, only for UI modules with Designer output:

```
Cycle 1: Design QA fails -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs
Cycle 2: Still failing -> Implementer -> Tester -> (Debug) -> Design QA
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 Design QA cycles. Implementer receives `08.5-design-qa-{N}.md` (Required Fixes section) as additional input during fix cycles. Code changes from Design QA fixes must pass through Tester before re-verification.

### Review-Lite Cycle (Cycle 2)

Runs after Tester (and after Design-QA if that ran), at scope M+ for feature/bugfix/refactor. Skipped at hotfix and XS/S.

```
Cycle 1: Review-Lite FAIL_CRITICAL -> Debugger -> Implementer -> Tester -> Review-Lite re-runs
Cycle 2: Still FAIL_CRITICAL -> Debugger -> Implementer -> Tester -> Review-Lite
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 Review-Lite cycles. Uses the existing Test/Debug cycle counter; a single module shares its cycle budget across test failures and Review-Lite failures.

### Review Issue Routing

| Severity | Action |
|----------|--------|
| Critical | **STOP**. Present to user. Wait for decision. |
| Major | Route to Debugger -> Implementer -> Tester. Re-review. |
| Minor | Pass to Refactorer. |
| Suggestion | Note for Refactorer. Not blocking. |

### Plan Deviations

If Implementer detects a flawed plan -> STOP, report to user. User decides: adjust, re-plan, or override.

## review_lite Override Key

Users may declare `review_lite: skip` in the preamble to disable the strict-tier approval gate on Review-Lite. Review-Lite **still runs** (findings still detected and routed) — only the approval prompt is skipped. Useful for power users confident in their implementation.

Allowed values: `skip` (disables strict gate), absent (default: strict gate applies at strict tier).

## Delegation Gate

Cycle-2 wrapper agents (Planner, Debugger, Implementer, Tester) consult `delegation_mode` to decide between superpowers invocation and inline fallback. This is NOT an approval gate — it does not prompt the user. Full rules in `refs/delegation-protocol.md`.
