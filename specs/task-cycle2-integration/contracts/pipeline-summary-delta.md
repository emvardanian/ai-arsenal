# Contract: Pipeline Summary Delta (Cycle 2 Additions)

**Scope**: Additive fields in `.task/pipeline-summary.md` introduced by Cycle 2. Backward-compatible with Cycle 1 `v2` schema — readers that don't know these fields ignore them.

## New front-matter fields

```yaml
# Delegation (US3)
delegation_mode: delegate | fallback
delegation_source: default | user | plugin_missing | escalation

# Review-Lite (US1)
review_lite_enabled: true | false
review_lite_findings_total: <int>
review_lite_findings_critical: <int>
review_lite_findings_minor: <int>
```

## Field semantics

### delegation_mode / delegation_source

Set at pipeline startup. Immutable per run (FR-022).

| Value of `delegation_mode` | Source | Meaning |
|---|---|---|
| `delegate` | `default` | Plugin detected + no user override |
| `fallback` | `plugin_missing` | Plugin not installed |
| `fallback` | `user` | User preamble `delegation: disable` |
| `fallback` | `escalation` | 2+ per-call failures in this run |

### review_lite_enabled

`true` if scope ∈ {M, L, XL} AND task_type ≠ hotfix AND user has not set `review_lite: skip`.

If `true`, orchestrator will dispatch Review-Lite after each module's Tester.

### review_lite_findings_*

Incrementally updated as modules complete Review-Lite. Useful at resume time for users to see quickly what was found.

## Body additions

### Per-stage delegation annotation

Stages that wrap superpowers invocations gain an annotation in brackets at the end of their summary line:

**Delegated**:
```
- **Stage 5.1 -- Planner**: ok plan.md written [delegated via superpowers:writing-plans, 1200ms]
```

**Fallback (full-run)**:
```
- **Stage 5.1 -- Planner**: ok plan.md written [fallback — delegation_mode=fallback]
```

**Per-call fallback**:
```
- **Stage 8.2 -- Debugger**: ok cluster analyzed [fallback — plugin_error: "skill crash"]
```

### Review-Lite stage lines

New stage lines for Review-Lite invocations:

```
- **Stage 9.5.1 -- Reviewer-Lite**: ok module 1, verdict PASS (0 findings)
- **Stage 9.5.2 -- Reviewer-Lite**: ok module 2, verdict PASS_WITH_MINOR (2 minor)
- **Stage 9.5.3 -- Reviewer-Lite**: FAIL_CRITICAL module 3 (1 critical) → routing to Debugger
```

## Back-compat

### Pre-Cycle-2 workspace resume

Reader encounters v2 front-matter without Cycle 2 fields:

```yaml
---
scope: M
tier: standard
summary_schema: v2
# ... (no delegation_mode, no review_lite_*)
---
```

Orchestrator defaults:
- Missing `delegation_mode` → treat as `fallback` (safe).
- Missing `review_lite_enabled` → treat as `false` (will not retroactively add Review-Lite to a resumed pipeline).

No prompting; resume proceeds silently with these defaults (FR-024).

### Schema version

**Not bumped**. Cycle 2 changes are additive; `summary_schema` remains `v2`. A future breaking change (e.g., restructuring body format) would bump to `v3`.

## Reader rules

- **Front-matter readers** must tolerate unknown keys.
- **Body readers** (Documenter, Committer) ignore bracket-annotations; they read only stage name + summary text.
- **Orchestrator** reads all fields on startup and during stage dispatch.

## Writer rules

- Orchestrator owns front-matter (writes/updates atomically).
- Each agent appends its own body line after completing (unchanged from Cycle 1).
- Review-Lite appends its stage line AND contributes to `review_lite_findings_*` counters in front-matter (orchestrator updates).
