# Orchestration

**Load trigger**: at pipeline startup, after SKILL.md Agent Reference table.

Covers execution strategy, model tier resolution, and context management — the orchestrator's core mechanics that apply to every stage dispatch.

## Execution Strategy

The orchestrator picks the best available execution mode per stage, falling back gracefully.

### Tier 1: Agent Teams (preferred — parallel execution)

When `agent-teams` plugin is available, use it for stages that benefit from parallelism.

**Multi-module Implementation**: Independent modules (no dependencies per Decomposer's execution order) can run `[Research→Plan→Impl→Test]` in parallel via agent-teams. Dependent modules run sequentially.

**Review dimensions**:
```
/team-spawn review
```
Performance and Architecture reviewers run in parallel. Security is handled by `security-scanning` plugin separately.

**Debug investigation**:
```
/team-spawn debug --hypotheses 3
```
3 investigators per failure cluster, evidence-based convergence.

For all other stages — use single-agent execution (no parallelism benefit).

### Tier 2: Subagents (fallback — isolated context)

When `agent-teams` is unavailable but the Task tool exists, spawn each agent as an independent subagent:

```
Spawn subagent:
  - Instructions: Read and follow agents/{agent}.md
  - Input: {only the files listed in Reads column}
  - Output: .task/{output file}
```

### Tier 3: Sequential (last resort)

Execute agents inline, one by one. Use the file system as memory between stages.

## Model Tier Resolution

Each agent's model tier is resolved at dispatch time from `agents/refs/model-tiers.md` — the single authoritative table (FR-023).

**Dispatch algorithm**:

1. At pipeline start, load `agents/refs/model-tiers.md`.
2. Parse columns: `agent`, `mode`, `model`, `rationale`. Build map `(agent_name, mode_or_null) → model`.
3. Cache for the run.
4. Before dispatching each stage:
   - Resolve `agent_name` from the stage.
   - Resolve `mode` if applicable (only Spec has modes: `interactive`, `validate`, or `interview`, determined by Spec's Mode Detection at stage entry).
   - Look up `(agent_name, mode)` in the cached map.
   - Dispatch the agent with the resolved model.

**Agent file declarations**: each `agents/*.md` declares its model via reference line only:

```
> **Model**: see `agents/refs/model-tiers.md` (entry: `<agent_name>`)
```

For Spec (three modes):

```
> **Interactive mode**: see `agents/refs/model-tiers.md` (entry: `spec, interactive`) — sonnet
> **Validate mode**: see `agents/refs/model-tiers.md` (entry: `spec, validate`) — haiku
> **Interview mode**: see `agents/refs/model-tiers.md` (entry: `spec, interview`) — sonnet
```

**Fallback**: if `refs/model-tiers.md` is missing or unreadable, log a degradation warning and fall back to the agent's legacy inline `> **Model**:` line (if any) or to the tier shown in the SKILL.md Agent Reference table. Pipeline continues.

**Changing a tier**: edit `refs/model-tiers.md` only. Do NOT edit agent frontmatter for tier changes. Verify with quickstart paths before merging.

## Delegation Mode (Cycle 2)

When Planner/Debugger/Implementer/Tester wrapper agents dispatch, they consult `delegation_mode` from `.task/pipeline-summary.md` front-matter. Full protocol in `refs/delegation-protocol.md`.

- `delegate` → wrapper invokes `superpowers:<skill>`.
- `fallback` → wrapper runs inline pre-Cycle-2 behavior.

Decision made at pipeline startup; immutable per run (except via escalation after 2+ per-call failures).

## Context Management

1. **File system as memory** — agents write to `.task/`, downstream read from files.
2. **Brief sections** — every output starts with `## Brief` (5-10 lines).
3. **Pipeline summary** — terminal agents read `pipeline-summary.md` instead of individual briefs.
4. **Dependency map** — each agent reads only what's in the Reads column.
5. **Budget** — `find`/`grep` before reading; never read files >500 lines fully; max 5-7 files in context.
6. **One module at a time** — Researcher, Planner, Implementer, and Tester process one module per run.
