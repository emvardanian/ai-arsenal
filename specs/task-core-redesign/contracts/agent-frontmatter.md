# Contract: Agent Frontmatter and Model Tier Resolution

**Scope**: How each agent in `skills/task/agents/*.md` declares its model tier, and how the orchestrator resolves the tier at dispatch time.

## Current state (pre-redesign)

Each agent file has a frontmatter-ish declaration near the top:

```markdown
# Scout Agent

> **Model**: sonnet
```

**Problem**: 15 places to keep in sync. Changing one requires hunting all files. No single audit point.

## New state (this cycle, FR-023)

### Authoritative table

Location: `skills/task/agents/refs/model-tiers.md`

Format: markdown table.

```markdown
# Model Tier Assignments

| agent | mode | model | rationale |
|---|---|---|---|
| spec | interactive | sonnet | Structured dialogue; sonnet adequate |
| spec | validate | haiku | Mechanical section checks |
| scout | — | haiku | grep/find + config reads |
| decomposer | — | opus | Architectural DAG construction |
| researcher | — | sonnet | Code tracing |
| planner | — | opus | Multi-step plan with criteria coverage |
| designer | — | sonnet | Token extraction + WCAG math |
| implementer | — | sonnet | Code generation |
| tester | — | sonnet | Test writing + run + report |
| debugger | — | sonnet | Hypothesis generation + scoring |
| design-qa | — | haiku | Checklist + DOM inspection |
| reviewer | — | sonnet | Cross-cutting performance + architecture |
| refactorer | — | haiku | Mechanical rename/extract |
| documenter | — | haiku | README/CHANGELOG/docstring updates |
| committer | — | haiku | Conventional commit formatting |
```

### Agent file declaration

Each agent file replaces its inline model string with a reference:

**Before**:
```markdown
# Scout Agent

> **Model**: sonnet
```

**After**:
```markdown
# Scout Agent

> **Model**: see `agents/refs/model-tiers.md` (entry: `scout`)
```

For Spec agent (two modes):

```markdown
# Spec Agent

> **Model**: mode-dependent — see `agents/refs/model-tiers.md`
> **Interactive mode**: sonnet | **Validate mode**: haiku
```

### Orchestrator resolution logic

At the start of every pipeline run, the orchestrator:

1. Loads `agents/refs/model-tiers.md`.
2. Parses the table into an in-memory map `(agent_name, mode_or_null) -> model`.
3. For each stage dispatched, looks up the agent's row and uses the `model` field.

For Spec agent:
- First detect mode (interactive | validate) per Adaptive Entry rules.
- Look up `(spec, <mode>)` in the table.
- Dispatch Spec with the resolved model.

### Cache and lifecycle

- Table is loaded once per pipeline run and cached.
- If the table changes mid-pipeline (unlikely; out of scope), the cache is stale but pipeline continues with cached values until the next invocation.

## Back-compat

### Legacy per-agent frontmatter

During the transition (this cycle), agent files have both the reference line (new) and the legacy line (deprecated). Example:

```markdown
# Scout Agent

> **Model**: see `agents/refs/model-tiers.md` (entry: `scout`)
> *(legacy: this agent was previously declared as `sonnet`; new tier is haiku)*
```

After this cycle ships and is verified, a follow-up commit removes legacy notes. Not part of this cycle.

### Orchestrator fallback

If `agents/refs/model-tiers.md` is missing or unreadable:
1. Orchestrator logs a degradation warning.
2. Falls back to per-agent `> **Model**: <tier>` line (the pre-redesign behavior).
3. Continues pipeline.

This keeps the skill functional even if a future cycle accidentally removes the refs file.

## Invariants

- **Single source of truth** (FR-023): the only place a model tier is defined is `agents/refs/model-tiers.md`.
- **Every agent has exactly one table row** (Spec has two — one per mode).
- **No agent file hardcodes a model tier** as the primary declaration; agent files may cite the tier in prose for documentation, but orchestrator reads only the table.
- **Table rows are markdown**, not YAML/JSON, consistent with the constitution (markdown-only project).

## Example dispatch

Orchestrator is about to dispatch Stage 2 (Scout) for a scope-M feature task:

```
1. Look up ("scout", null) in model-tiers table.
2. Found: model = haiku.
3. Dispatch Scout agent with:
   - instructions: agents/scout.md
   - model: haiku
   - inputs: .task/01-analysis.md (or .task/00-spec.md after merge)
   - expected output: .task/02-scout.md
```

Scout runs on haiku, completes terrain scan, writes output, returns to orchestrator.

## Reader contract

Readers of the model-tiers table (Orchestrator, debug tooling, audits):

1. Open `agents/refs/model-tiers.md`.
2. Find the `| agent | mode | model | rationale |` header.
3. Parse each subsequent non-separator row:
   - `agent`: lowercase string, trimmed.
   - `mode`: `—` (dash) means null; otherwise string.
   - `model`: lowercase string, one of {opus, sonnet, haiku}.
   - `rationale`: free text, informational only.
4. Key by `(agent, mode)`; mode = null when dash.

If a row is malformed (missing fields, unknown model), log the error and skip the row. Do NOT fail the pipeline on a single bad row.

## Future-proofing

If a future cycle introduces additional model tiers (e.g., opus-fast, sonnet-nano) or per-cycle overrides, the table schema can gain columns without breaking current readers as long as the first four columns remain (`agent`, `mode`, `model`, `rationale`).
