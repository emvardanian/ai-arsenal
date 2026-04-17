# Phase 0 Research: Cycle 2 — Integration

**Feature**: task-cycle2-integration
**Date**: 2026-04-17

## 1. SKILL.md split boundaries

**Decision**: Four refs, each covering one orchestrator concern.

| Ref | Topics moved from SKILL.md |
|---|---|
| `refs/orchestration.md` | Execution Strategy (Tier 1/2/3), Model Tier Resolution, Context Management |
| `refs/pipelines.md` | Pipeline Overview ASCII diagram, Adaptive Pipeline summary table, Classification & Pipeline Selection (scope classifier + override + upgrade mid-pipeline), Adaptive Entry (Spec Mode Detection) |
| `refs/approvals.md` | Flow Control (Approval Gate resolution algorithm), Approval Tier Selection, Tier Override, Mid-Flight Tier Change, Criticality Detection |
| `refs/resume.md` | Resume Detection, Scope Inference on Resume, Schema Upgrade on Resume, Pre-redesign artifact fallback |

**Stays in SKILL.md**: frontmatter, top description, Progress Tracker, Agent Reference table, Workspace listing, Starting the Pipeline steps, Resuming link, Cleaning Up.

**Rationale**: each ref has a single responsibility; readers load only what they need. Pipelines and approvals are the two hottest loaded refs (consulted every run); resume is cold (only on resume).

**Alternatives rejected**:
- 2-way split (shell + one mega-ref): preserves bloat, each activation still loads the mega-ref.
- 3-way (orchestration + pipelines + approvals, resume folded in): resume is semantically distinct from live-pipeline flow; mixing confuses resume-path readers.

## 2. Review-Lite checklist scope

**Decision**: 5 pattern-matchable categories for haiku-tier execution. Anything requiring cross-file or semantic reasoning stays at final Reviewer.

| Category | Example patterns |
|---|---|
| **Hardcoded secrets** | `AKIA[0-9A-Z]{16}`, `ghp_[A-Za-z0-9]{36}`, `sk-[A-Za-z0-9]{48}`, `-----BEGIN .+PRIVATE KEY` in any changed file |
| **N+1 queries** | ORM `.findOne` / `.get` inside `.map` / `for` / `forEach` loops; raw SQL query inside loop |
| **SQL injection patterns** | string concat in `query(`/`execute(` call; template literal without parameterization for known SQL libs |
| **Unhandled external-call failures** | `await fetch(...)` / `axios(...)` without `.catch` or try/catch; `http.get(...)` callback without error arg |
| **Unbounded loops** | `while(true)` without break-condition; recursion without base-case check |

**Rationale**: all 5 are greppable or match a narrow AST pattern. Haiku can detect them reliably. Broader checks (SRP violations, circular deps, race conditions) require cross-cutting reasoning and stay at final Reviewer (sonnet).

**Alternatives rejected**:
- Same checklist as final Reviewer: defeats the purpose; haiku can't replace sonnet-tier reasoning.
- User-extensible checklist: adds complexity for Cycle 2; users can fork `reviewer-lite-checklist.md` per-project if needed (Cycle 3+ concern).

## 3. Review-Lite severity routing

**Decision**:

- **Critical**: routes to `Debugger → Implementer → Tester → Review-Lite` retry. Same 2-cycle max as Test/Debug loop.
- **Minor**: logged to `09.5-review-lite-{N}.md`, passed to final Reviewer (which deduplicates).

**Rationale**: Critical = we must fix before moving to next module (else module 2 builds on broken module 1). Minor = no urgency; final Reviewer will handle cross-cutting view.

**Edge case**: Review-Lite flags Critical, but Debugger already at cycle-2 max for this module → escalate to user immediately. Do not loop.

## 4. Superpowers delegation scope

**Decision**: Delegate Planner, Debugger, Implementer, Tester only. Keep other agents inline.

| Agent | Delegates to | Rationale |
|---|---|---|
| planner | `superpowers:writing-plans` | Mature plan-writing skill; good match |
| debugger | `superpowers:systematic-debugging` | Hypothesis-driven debugging pattern already proven |
| implementer | `superpowers:executing-plans` | Plan execution is superpowers' strength |
| tester | `superpowers:test-driven-development` | TDD patterns, test structure guidance |
| (others) | — | No superpowers equivalent OR Task skill's version is domain-specific to our pipeline |

**Not delegated**: spec, scout, decomposer, researcher, designer, design-qa, reviewer-lite, reviewer, refactorer, documenter, committer. Most have no superpowers equivalent; reviewer/reviewer-lite and committer use plugin-specific behavior (security-scanning, git-pr-workflows) which is already delegation.

**Alternatives rejected**:
- Delegate all agents: most have no mature superpowers equivalent; forces half-baked wrappers.
- Delegate only Planner: doesn't amortize the fallback-framework cost.

## 5. Fallback trigger points

**Decision**: Three trigger points.

1. **Startup**: orchestrator checks plugin availability once per run; if absent → `delegation_mode: fallback` for whole run.
2. **Per-call**: if wrapper invocation fails (plugin error, malformed output, timeout), wrapper falls back to inline for that one invocation; logs transient failure; `delegation_mode` remains `delegate`.
3. **User override**: preamble `delegation: disable` forces `fallback` regardless of plugin availability.

**Repeat failure escalation**: if 2 per-call fallbacks within same pipeline → orchestrator escalates to `delegation_mode: fallback` for remainder of run; logs escalation reason.

**Rationale**: triple-layer defense. Plugin going missing between invocations is tolerated. User always has escape hatch.

**Alternatives rejected**:
- Startup-only detection: a plugin that crashes mid-run hangs the pipeline.
- Per-call-only (no startup check): pays plugin-probe cost per stage.

## 6. Wrapper contract

**Decision**: Each wrapper agent file has two blocks.

- **Delegated block**: "If `delegation_mode == delegate`, invoke `superpowers:<skill>` with these inputs (list), wait for output, adapt output into `.task/<artifact>` per this schema (rules), write `.task/<artifact>`."
- **Inline block**: the pre-Cycle-2 agent behavior verbatim, executed "If `delegation_mode == fallback` OR delegated invocation fails."

Input glue and output adapter rules are declared per-agent in `refs/delegation-protocol.md` (centralized spec) but referenced from each wrapper.

**Artifacts preserved exactly**: `.task/05-plan-{N}.md`, `.task/08-debug-{N}-{C}.md`, `.task/06-impl-{N}.md`, `.task/07-tests-{N}-{C}.md`. Downstream agents see identical shape regardless of mode.

## 7. Pipeline summary additions

**Decision**: Additive front-matter fields (backward-compatible).

```yaml
# New in v2.1 (Cycle 2):
delegation_mode: delegate | fallback
delegation_source: default | user | plugin_missing | escalation
review_lite_enabled: true | false
review_lite_findings_total: <int, 0 if not run>
```

Body gets per-stage delegation lines:

```
- **Stage 5.1 -- Planner**: ok plan.md written [delegated via superpowers:writing-plans]
- **Stage 8.2 -- Debugger**: ok cluster analyzed [fallback — plugin error 'skill not found']
```

**Rationale**: v2.1 is superset of v2; Cycle 1 readers ignore unknown fields. `summary_schema: v2` is retained (we don't bump schema version for additive fields; bump only on breaking change).

## 8. Scope matrix change

**Decision**: Review-Lite conditional per cell.

| | feature | bugfix | refactor | hotfix |
|---|---|---|---|---|
| XS | — | — | — | — |
| S | — | — | — | — |
| M | **yes** | yes | yes | — |
| L | **yes** | yes | yes | — |
| XL | **yes** | yes | yes | — |

Rules:
- XS/S: never. Modules don't exist; checklist overkill.
- Hotfix: never. Speed is critical.
- M/L/XL (other types): always, per-module after Tester.

**Updates to `refs/scope-pipelines.md`**: insert `-> reviewer-lite` after `tester` in per-module loop for qualifying cells.

## 9. Approval tier gate for Review-Lite

**Decision**:

| Tier | Review-Lite gate |
|---|---|
| strict | YES (per-module) |
| standard | no |
| express | no |

**Rationale**: strict gates everything; standard/express gate only at architectural decisions. Review-Lite's job is to catch things automatically; gating in standard/express defeats express's purpose.

**Override**: `review_lite: skip` preamble disables strict gate for Review-Lite (Review-Lite still runs, just without prompting).

## Summary

| # | Topic | One-line decision |
|---|---|---|
| 1 | SKILL.md split | 4 refs by orchestrator concern (orchestration/pipelines/approvals/resume) |
| 2 | Review-Lite checklist | 5 pattern-matchable categories for haiku |
| 3 | Severity routing | Critical → Debug cycle; Minor → final Reviewer |
| 4 | Delegation scope | Planner, Debugger, Implementer, Tester only |
| 5 | Fallback triggers | Startup + per-call + user override; escalation after 2 per-call fails |
| 6 | Wrapper contract | Delegated block + inline block in each agent; central rules in `refs/delegation-protocol.md` |
| 7 | Summary additions | `delegation_mode`, per-stage lines; v2 schema preserved (additive) |
| 8 | Scope matrix | Review-Lite in M/L/XL feature/bugfix/refactor cells; hotfix never |
| 9 | Approval gate | Strict YES per-module, standard/express no; `review_lite: skip` override |

No remaining NEEDS CLARIFICATION. Ready for Phase 1.
