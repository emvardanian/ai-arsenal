# Model Tier Assignments

Authoritative mapping from `(agent, mode)` to model tier. The orchestrator reads this table once per pipeline run and dispatches each agent with the resolved model.

## Tiers

- **opus** — deepest reasoning. Architectural DAG construction, multi-step plans with acceptance criteria coverage.
- **sonnet** — standard reasoning. Code generation, test writing, multi-file reasoning, dialogue.
- **haiku** — mechanical work. Pattern matching, checklist-driven verification, filesystem scans, conventional-commit formatting.

## Table

| agent | mode | model | rationale |
|---|---|---|---|
| spec | interactive | sonnet | Structured dialogue with the user; benefits from reasoning but opus is overkill for one-question-at-a-time flow |
| spec | validate | haiku | Section presence + consistency checks are mechanical; template transformation is pattern matching |
| spec | interview | sonnet | Adaptive gap-attack question generation; reads working spec, spots hidden assumptions, constructs non-obvious multi-choice questions with named tradeoffs |
| scout | — | haiku | grep/find/ls + config file reads; no judgment calls beyond listing |
| decomposer | — | opus | Architectural DAG construction; highest-stakes reasoning in the pipeline |
| researcher | — | sonnet | Code tracing and dependency analysis; requires following symbols across files |
| planner | — | opus | Multi-step implementation plan with acceptance criteria coverage; architectural decisions |
| designer | — | sonnet | Token extraction + WCAG math; deterministic once design input is parsed |
| implementer | — | sonnet | Code generation; standard sonnet workload |
| tester | — | sonnet | Test writing, execution, and report formatting |
| debugger | — | sonnet | Hypothesis generation and evidence scoring |
| design-qa | — | haiku | Checklist-driven verification with DOM inspection; comparison is mechanical |
| reviewer-lite | — | haiku | Per-module pattern-matchable critical-issue scan per `refs/reviewer-lite-checklist.md` (Cycle 2) |
| reviewer | — | sonnet | Cross-cutting review across multiple modules; applies performance + architecture checklists |
| refactorer | — | haiku | Mechanical rename/extract/reorder within single files |
| documenter | — | haiku | README/CHANGELOG/docstring updates following existing conventions |
| committer | — | haiku | Conventional commit formatting + staging instructions |

## Tier distribution

| Tier | Count | Agents |
|---|---:|---|
| opus | 2 | decomposer, planner |
| sonnet | 8 | spec (interactive), spec (interview), designer, researcher, implementer, tester, debugger, reviewer |
| haiku | 8 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer |

**Spec counts as one agent with three entries. Reviewer-Lite added in Cycle 2.** Total agent files: 15. Total rows: 17.

## Reader contract

### Orchestrator

At pipeline start:

1. Load this file.
2. Parse the table (columns: `agent`, `mode`, `model`, `rationale`).
3. Build in-memory map: `(agent_name, mode_or_null) → model`. Mode column `—` → null.
4. Cache for the duration of the pipeline run.

At each stage dispatch:

1. Resolve `agent_name` from the pipeline stage.
2. Resolve `mode` if applicable (Spec only: interactive or validate, detected by Spec's Mode Detection step).
3. Look up `(agent_name, mode)` in the map.
4. Dispatch the agent with the resolved model.

### Agent files

Each `agents/*.md` file declares its model tier with a reference line:

```
> **Model**: see `agents/refs/model-tiers.md` (entry: `<agent_name>`)
```

For Spec (two modes):

```
> **Interactive mode**: see `agents/refs/model-tiers.md` (entry: `spec, interactive`) — sonnet
> **Validate mode**: see `agents/refs/model-tiers.md` (entry: `spec, validate`) — haiku
```

The tier name appearing after the reference (e.g., `— sonnet`) is documentation only; the table above is authoritative.

### Fallback

If this file is missing or unreadable:

1. Orchestrator logs a degradation warning to `pipeline-summary.md` body.
2. Falls back to the legacy per-agent `> **Model**:` inline line if present.
3. Continues pipeline.

During the transition cycle, agent files retain a legacy note (`*(previously: <tier>; new: <tier>)*`) to aid review. Legacy notes may be removed in a later commit once this table is verified as sole source of truth.

## Changing a tier

To change any agent's model tier:

1. Edit the row in this file only.
2. Run verification per `quickstart.md` to confirm pipeline still functions.
3. Commit with message `chore(task-skill): retier <agent> to <new-tier>`.

Do NOT edit per-agent frontmatter for tier changes. The frontmatter reference line is stable.

## Invariants

- Every agent in `agents/*.md` has at least one row.
- Spec has exactly two rows (interactive, validate).
- Model column values ∈ {opus, sonnet, haiku}.
- No cell is empty; use `—` for null mode.
- Changes to this file are constitution-level (Quality Standards mandate: "Agent definitions must declare inputs, outputs, and model tier").

## Back-compat

Future cycles may:
- Add new model tiers (opus-fast, sonnet-nano). Readers use the `model` column as-is.
- Add new columns (e.g., `thinking_budget`, `temperature`). Readers check only columns they understand.

Readers MUST NOT hardcode agent names or tiers — always parse this table.
