# Delegation Protocol

**Purpose**: How Planner, Debugger, Implementer, Tester wrapper agents invoke `superpowers` plugin skills or fall back to inline behavior. Loaded once per pipeline when any wrapper first dispatches.

## Delegation Decision (at pipeline startup)

Orchestrator reads the user's invocation + checks environment:

1. Probe `superpowers` plugin availability.
2. Parse preamble `delegation` key (values: `enable`, `disable`, absent).
3. Write `delegation_mode` + `delegation_source` to `.task/pipeline-summary.md` front-matter:

| Plugin | User override | delegation_mode | delegation_source |
|---|---|---|---|
| installed | absent | `delegate` | `default` |
| installed | `disable` | `fallback` | `user` |
| installed | `enable` | `delegate` | `user` |
| missing | absent | `fallback` | `plugin_missing` |
| missing | `disable` | `fallback` | `user` |
| missing | `enable` | error prompt → user chooses fallback or abort | `user` or HALT |

**Immutability**: `delegation_mode` is set once per run (FR-022). Cannot change mid-pipeline except via escalation below.

## Escalation (mid-pipeline)

If 2+ per-call fallbacks happen within the same run (plugin errors, malformed output, timeouts), orchestrator elevates:
- Update `delegation_mode: fallback`.
- Update `delegation_source: escalation`.
- All subsequent wrappers use fallback.

Log the escalation in pipeline-summary body:
```
- **[Escalation]**: delegation_mode elevated to `fallback` after 2 per-call failures.
```

## Per-agent Delegation Contracts

### Planner → superpowers:writing-plans

**Inputs bundled**:
- `.task/04-research-{N}.md` — full research findings for module N
- `.task/03-decomposition.md` Module N section — goal, scope, criteria, research hints
- `.task/00-spec.md` acceptance criteria mapped to module N

**Prompt to superpowers**: "Write an implementation plan for <module goal>. Read the research at <path>. Cover all acceptance criteria listed. Output sections: Objective, Files (create/modify/delete), Steps (ordered concrete actions), Conventions (from research), Verification."

**Output adapter**: map superpowers output to `.task/05-plan-{N}.md` schema:
- Brief (5-10 lines): objective, file count create/modify/delete, steps count, verification approach
- `## Objective` — 1-2 sentences
- `## Files` — list with description of changes
- `## Steps` — ordered concrete actions
- `## Conventions` — patterns from research
- `## Verification` — how to know plan was implemented correctly

Add Brief if superpowers output lacks it. Normalize section order.

### Debugger → superpowers:systematic-debugging

**Inputs bundled**:
- `.task/07-tests-{N}-{C}.md` — test failure report (full)
- Relevant source files (targeted reads based on failure locations)
- `.task/06-impl-{N}.md` Brief — what was implemented
- `.task/08-debug-{N}-{C-1}.md` — prior debug report if cycle ≥ 2

**Prompt to superpowers**: "Debug these test failures systematically. Group into clusters. For each cluster, generate 3 competing hypotheses, gather evidence, score confidence. Classify fix complexity. Output precise fix instructions."

**Output adapter**: map to `.task/08-debug-{N}-{C}.md` schema:
- Brief: failure clusters count, top root cause per cluster, overall fix complexity, escalation needed?
- `## Failure Clusters` — table
- `## Cluster N` sections — hypotheses table (3 rows), evidence, root cause, fix instructions
- `## Escalation Assessment` — if cycle 2 and bugs remain

### Implementer → superpowers:executing-plans

**Inputs bundled**:
- `.task/05-plan-{N}.md` — full plan
- `.task/04-research-{N}.md` Brief — conventions reminder
- `.task/05.5-design-{N}.md` — if UI module with Designer output
- `.task/08.5-design-qa-{N}.md` Required Fixes — if Design-QA flagged issues this cycle

**Prompt to superpowers**: "Execute this plan step by step. Follow conventions. Write working code. Stop and escalate if the plan is flawed. Run sanity check (build/typecheck) after all steps."

**Output adapter**: map to `.task/06-impl-{N}.md`:
- Brief: status, files created/modified/deleted counts, sanity check result, deviations
- `## Changes Made` — per-file list
- `## Steps Executed` — per-step action + result
- `## Sanity Check` — command + result
- `## Notes` — edge cases or "No special notes"

Source code changes happen directly in the repo — no adapter needed there.

### Tester → superpowers:test-driven-development

**Inputs bundled**:
- `.task/06-impl-{N}.md` — impl log
- `.task/00-spec.md` Acceptance Criteria section
- `.task/05-plan-{N}.md` Verification section

**Prompt to superpowers**: "Write and run tests for this module. Priority: smoke, unit, integration, endpoint (if applicable), e2e (if critical). Run full test suite for regression check. Report Pass/Fail/Regression/Slow."

**Output adapter**: map to `.task/07-tests-{N}-{C}.md`:
- Brief: verdict (proceed/needs debugging), passed/total, regressions count, performance
- `## Passed` table
- `## Failed` table — expected/actual/error
- `## Regressions` table
- `## Slow Endpoints` table (if applicable)
- `## Test Files Created`
- `## Notes`

## Fallback Triggers (per invocation)

Wrapper catches and falls back when:
- **plugin_error**: invocation of `superpowers:<skill>` itself returns error or crashes.
- **malformed_output**: output does not match expected structure after best-effort adapter.
- **timeout**: invocation exceeds 5 min (orchestrator-configurable).

Fallback action:
1. Log the failure with `fallback_reason` in `WrapperInvocationResult`.
2. Execute `## Fallback Mode` block of the agent file (inline pre-Cycle-2 behavior).
3. Continue pipeline with correct artifact written.

After 2 per-call fallbacks in same run → escalate (see Escalation section above).

## Logging Format

Orchestrator appends one line per wrapper invocation to `.task/pipeline-summary.md` body:

**Delegated success**:
```
- **Stage 5.2 -- Planner**: ok plan.md written, 4 files, 12 steps [delegated via superpowers:writing-plans, 1200ms]
```

**Delegated failure → per-call fallback**:
```
- **Stage 8.1 -- Debugger**: ok cluster analyzed [fallback — plugin_error: "skill not found"]
```

**Full-run fallback (from startup or escalation)**:
```
- **Stage 5.1 -- Planner**: ok plan.md written [fallback — delegation_mode=fallback]
```

## Invariants

1. Artifact files (`05-plan-{N}.md`, `06-impl-{N}.md`, `07-tests-{N}-{C}.md`, `08-debug-{N}-{C}.md`) have identical schemas regardless of delegation mode (FR-018).
2. Downstream agents do not need to know which mode produced an artifact.
3. `delegation_mode` is immutable per run except via escalation (FR-022).
4. User override via preamble always wins (FR-020).
5. Plugin absence at startup forces `fallback` with source `plugin_missing`; never crashes the pipeline.

## Back-compat

- Pre-Cycle-2 workspaces resume with no `delegation_mode` → orchestrator defaults to `fallback` (FR-024).
- When `superpowers` plugin is uninstalled, every wrapper still works via `## Fallback Mode` verbatim Cycle 1 behavior.
- No agent invocation ever requires the plugin to be present.
