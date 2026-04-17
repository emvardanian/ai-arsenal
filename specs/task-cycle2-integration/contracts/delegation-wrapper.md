# Contract: Delegation Wrapper Protocol

**Scope**: How Planner, Debugger, Implementer, Tester operate in `delegate` vs `fallback` mode.

## Per-agent mapping

| Wrapper agent | Delegates to | Inline fallback |
|---|---|---|
| `agents/planner.md` | `superpowers:writing-plans` | pre-Cycle-2 inline Planner behavior |
| `agents/debugger.md` | `superpowers:systematic-debugging` | pre-Cycle-2 inline Debugger |
| `agents/implementer.md` | `superpowers:executing-plans` | pre-Cycle-2 inline Implementer |
| `agents/tester.md` | `superpowers:test-driven-development` | pre-Cycle-2 inline Tester |

## Wrapper agent file structure

Each wrapper agent file MUST have two distinct blocks after the standard header:

```markdown
# <Agent> Agent

> **Model**: see `agents/refs/model-tiers.md` (entry: `<agent>`)

<role description — unchanged from Cycle 1>

## Delegation Decision

At dispatch time, read `delegation_mode` from `.task/pipeline-summary.md` front-matter.
- `delegate` → execute `## Delegated Mode` block.
- `fallback` → execute `## Fallback Mode` block.

If `delegate` path fails (plugin error / malformed output / timeout), log the failure
and switch to `## Fallback Mode` for this invocation only.

## Delegated Mode

1. Invoke `superpowers:<skill-name>` with:
   - <list of inputs specific to this agent>
2. Wait for superpowers output.
3. Adapt output to `.task/<artifact>` schema per `agents/refs/delegation-protocol.md` § <agent>.
4. Write `.task/<artifact>` with correct Brief + sections.
5. Log `WrapperInvocationResult` with `mode: delegated, success: true`.

## Fallback Mode

<verbatim copy of pre-Cycle-2 agent behavior>
```

## Input bundling per wrapper

Documented in `refs/delegation-protocol.md`. Summary:

| Wrapper | Superpowers inputs |
|---|---|
| Planner | Module N's research (`.task/04-research-{N}.md`), decomposition (`.task/03-decomposition.md` Module N section), spec acceptance criteria |
| Debugger | Test failure report (`.task/07-tests-{N}-{C}.md`), relevant source files (targeted), prior debug report if cycle ≥ 2 |
| Implementer | Module N's plan (`.task/05-plan-{N}.md`), design tokens (if UI: `.task/05.5-design-{N}.md`), conventions from scout/research |
| Tester | Module N's impl log (`.task/06-impl-{N}.md`), acceptance criteria from spec, verification section from plan |

## Output adapter per wrapper

Each wrapper specifies how to map the superpowers skill's output to the `.task/` contract:

| Wrapper | Output adapter target | Key adapters |
|---|---|---|
| Planner | `.task/05-plan-{N}.md` | Extract: Objective, Files, Steps, Conventions, Verification. Add Brief with file counts. |
| Debugger | `.task/08-debug-{N}-{C}.md` | Extract: Failure clusters, 3 hypotheses each, evidence table, fix instructions, complexity classification. Add Brief with cluster count + root causes. |
| Implementer | `.task/06-impl-{N}.md` + source files | Ensure every plan step maps to a change. Add Brief with counts + deviations. |
| Tester | `.task/07-tests-{N}-{C}.md` | Categorize: Passed / Failed / Regressions / Slow. Add Brief with verdict (proceed/needs debugging). |

## Fallback triggers

### Startup (set once per pipeline)

1. Orchestrator probes `superpowers` plugin availability.
2. If absent → `delegation_mode: fallback, delegation_source: plugin_missing`.
3. If present → `delegation_mode: delegate, delegation_source: default`.
4. User override (`delegation: disable` in preamble) → `delegation_mode: fallback, delegation_source: user`.

### Per-call (within dispatch)

Wrapper catches errors and falls back for that invocation only:
- `plugin_error`: invocation of `superpowers:<skill>` itself errored.
- `malformed_output`: output doesn't match expected schema after adapter attempt.
- `timeout`: invocation exceeded reasonable time budget (orchestrator-set, default 5 min).

Record: `fallback_reason`, `agent`, `cycle`, `module_N`.

### Escalation

If 2+ per-call fallbacks happen within same pipeline → orchestrator elevates to `delegation_mode: fallback` for remainder of run (`delegation_source: escalation`). Prevents repeated plugin issues from costing time.

## Logging format

Per-stage line in pipeline-summary body:

**Delegated success**:
```
- **Stage 5.1 -- Planner**: ok plan.md written, 4 files, 12 steps [delegated via superpowers:writing-plans, 1200ms]
```

**Per-call fallback**:
```
- **Stage 8.1 -- Debugger**: ok cluster analyzed [fallback — plugin_error: "skill crash"]
```

**Full-run fallback (from startup or user override)**:
```
- **Stage 5.1 -- Planner**: ok plan.md written, 4 files, 12 steps [fallback — delegation_mode=fallback]
```

## Invariants

- Output `.task/<artifact>` files have the same schema regardless of mode (FR-018).
- `delegation_mode` is immutable per run (FR-022).
- User override (`delegation: disable`) trumps plugin availability (FR-020).
- Every wrapper invocation records a `WrapperInvocationResult` (FR-027).

## Back-compat

- Agents that existed in Cycle 1 without delegation still work when `delegation_mode: fallback` — their behavior is verbatim the pre-Cycle-2 behavior.
- Pre-Cycle-2 workspaces resuming under Cycle 2 get `delegation_mode: fallback` by default (FR-024).
- When the `superpowers` plugin is not installed, every invocation runs the fallback path with no observable difference from Cycle 1 except the `[fallback — …]` annotation in logs.
