# Contract: Review-Lite Output

**File**: `.task/09.5-review-lite-{N}.md` (per module)
**Producer**: `agents/reviewer-lite.md` (haiku)
**Consumers**: Orchestrator (routing on Critical), final Reviewer (deduplication + aggregation)

## Structure

### Front-matter (YAML)

```yaml
---
module_N: 1
cycle: 1                      # Debug cycle this run belongs to (typically 1 unless retrying)
checklist_categories_checked: 5
files_scanned: 8
files_with_findings: 2
verdict: PASS | PASS_WITH_MINOR | FAIL_CRITICAL
elapsed_ms: 850
---
```

### Body

```markdown
## Brief
Module: 1 — auth/session handling
Checklist: 5 categories run, 8 files scanned, 2 with findings.
Findings: 1 Critical (hardcoded secret), 2 Minor (unhandled external, unbounded retry).
Verdict: FAIL_CRITICAL — routes to Debugger (cycle 2).

## Findings

| # | Severity | Location | Category | Description | Pattern |
|---|---|---|---|---|---|
| 1 | Critical | src/auth/jwt.ts:14 | secrets | Hardcoded JWT secret | `const SECRET = "sk-..."` |
| 2 | Minor | src/auth/refresh.ts:42 | unhandled_external | `await fetchRefreshToken(...)` without try/catch | — |
| 3 | Minor | src/auth/retry.ts:28 | unbounded_loop | `while(true)` without break condition | — |

## Routing

Critical findings trigger Debugger → Implementer → Tester → Review-Lite retry (cycle 2).
Cycle max: 2. After cycle 2, any remaining Critical escalates to user.

## Notes

- Checklist source: `agents/refs/reviewer-lite-checklist.md`
- Deduplication: findings already in `.task/07-tests-{N}-{C}.md` (test failures) are skipped.
```

## Verdict semantics

- **PASS**: zero findings across all categories.
- **PASS_WITH_MINOR**: only Minor findings. Pipeline continues; Minor findings passed to final Reviewer.
- **FAIL_CRITICAL**: at least one Critical finding. Pipeline routes back to Debugger. Max 2 cycles.

## Routing rules (for orchestrator)

1. Read verdict from front-matter.
2. If `PASS`, `PASS_WITH_MINOR` → continue to next module (or final Reviewer if last module).
3. If `FAIL_CRITICAL`:
   - If current Debug cycle < 2: route to Debugger with this file + relevant test report.
   - If current Debug cycle ≥ 2: escalate to user, halt pipeline.

## Deduplication rules (for final Reviewer)

Final Reviewer reads every `09.5-review-lite-*.md`:

1. Concatenate all Findings tables.
2. Group by (location, category).
3. If group also matches Reviewer's own finding → use Review-Lite's description; do not double-report.
4. If group was `Critical` and was resolved (not present in final code) → exclude (prevents stale findings).
5. Aggregate remaining Minor findings into `09-review.md` Minor Issues section with `source: review-lite` annotation.

## Model tier: haiku

Haiku is sufficient because checklist patterns are regex/AST-matchable. Semantic judgment is deferred to final Reviewer (sonnet).

## Back-compat

`09.5-*` is a new artifact. Cycle 1 workspaces never have these files; Cycle 2 resume of pre-Cycle-2 workspace → no `09.5-*` files exist, final Reviewer reads empty set, proceeds normally.
