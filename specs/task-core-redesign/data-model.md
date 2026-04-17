# Data Model: Task Skill Core Redesign

**Feature**: task-core-redesign
**Date**: 2026-04-17
**Purpose**: Define every entity the redesigned skill reads, writes, or dispatches on. "Data model" here is the schema of markdown/YAML state, not a database schema — there is no database.

---

## ScopeTier

**What**: A five-level enum classifying task size.

**Values**: `XS`, `S`, `M`, `L`, `XL`.

**Classification thresholds** (see research.md §1 for full rationale):

| Tier | File count | Module count | UI flag | Task-type cap |
|---|---|---|---|---|
| XS | 1 | 1 | no | any |
| S | 2-5 | 1 | no | any |
| M | 5-15 | 2-3 | no | any except hotfix (hotfix caps at S) |
| L | 15-40 | 3-5 | no | any |
| XL | 40+ or any UI | 5+ | yes OR 40+ files | any |

**Tie-break**: round up. Signals disagree → choose the larger tier.

**Relationships**:
- ScopeTier × TaskType → PipelineDefinition (lookup in `refs/scope-pipelines.md`).
- ScopeTier → default ApprovalTier (XS/S=express, M=standard, L/XL=strict).

**Mutations**: set once at Spec stage from classification; may be upgraded mid-flight after Scout (Edge Case in spec); never downgraded automatically.

---

## ApprovalTier

**What**: A three-level enum governing approval density.

**Values**: `strict`, `standard`, `express`.

**Gate rules** (see research.md §10 for full matrix):

| Tier | Stages requiring approval |
|---|---|
| strict | Spec, Decomposer, Planner×N, Designer×N, Implementer×N, Refactorer, Documenter, Committer |
| standard | Spec, Decomposer, Committer |
| express | Committer |

**Relationships**:
- Derived from ScopeTier by default (FR-011).
- Overridable by user (FR-012).
- Mutable mid-flight (FR-013).
- Overridden to strict by criticality confirmation (FR-014).

**Invariants**:
- Committer stage always requires approval in every tier.
- strict in redesigned skill matches pre-redesign behavior exactly (FR-024).
- Per-section internal approvals within Spec interactive mode are not counted as pipeline gates.

---

## PipelineDefinition

**What**: Ordered list of stages for a given `(scope, task_type)` pair.

**Source of truth**: `skills/task/agents/refs/scope-pipelines.md` as a 5×4 matrix of stage lists.

**Fields** (per cell in the matrix):
- `scope`: ScopeTier
- `task_type`: `feature | bugfix | refactor | hotfix`
- `stages`: ordered list of Stage references
- `loops`: per-module repetition annotations (e.g., "Planner×N through Tester")

**Example cell** (scope=M, task_type=feature):

```yaml
scope: M
task_type: feature
stages:
  - spec
  - scout
  - decomposer
  - { loop: per_module, order_from: decomposer, stages: [researcher, planner, implementer, tester, debugger_if_fail] }
  - committer
```

**Invariants**:
- Every cell includes `committer` as the last stage.
- XS cells never include `spec` (direct invocation to Impl; the skill assumes the user's one-line request is the spec).
- XL cells include `designer` and `design-qa` only when module `ui: true`.

---

## Stage

**What**: A single pipeline step, referencing an agent file.

**Fields**:
- `name`: stable identifier (e.g., `spec`, `scout`, `planner`)
- `agent_file`: path relative to `skills/task/agents/` (e.g., `spec.md`)
- `mode`: optional, only Spec uses it (`interactive | validate`)
- `approval`: boolean, resolved at dispatch time from ApprovalTier + stage
- `inputs`: list of file refs (e.g., `.task/00-spec.md`, `.task/03-decomposition.md#module-N`)
- `outputs`: list of file refs (e.g., `.task/04-research-{N}.md`)
- `depends_on`: list of stage names that must complete first
- `loop_scope`: `global | per_module | per_cycle`

**Notes**:
- Tester and Debugger form a loop (max 2 cycles, FR-unchanged from current skill).
- Design-QA loop (max 2 cycles) is preserved from current skill.

---

## ModelTierAssignment

**What**: Authoritative mapping from agent (and mode, if applicable) to model tier.

**Source of truth**: `skills/task/agents/refs/model-tiers.md`.

**Schema**: markdown table with columns `agent`, `mode`, `model`, `rationale`.

**Full table**:

| agent | mode | model | rationale |
|---|---|---|---|
| spec | interactive | sonnet | Structured dialogue; benefits from reasoning but opus is overkill |
| spec | validate | haiku | Section presence + consistency checks are mechanical |
| scout | — | haiku | grep/find/ls + config reads; no reasoning |
| decomposer | — | opus | Architectural DAG construction; highest-stakes reasoning |
| researcher | — | sonnet | Code tracing and dependency analysis |
| planner | — | opus | Multi-step implementation plan with criteria coverage |
| designer | — | sonnet | Token extraction + WCAG math; deterministic once design is in hand |
| implementer | — | sonnet | Code generation; standard sonnet workload |
| tester | — | sonnet | Test writing + run + report; standard sonnet |
| debugger | — | sonnet | Hypothesis generation + evidence scoring |
| design-qa | — | haiku | Checklist-driven verification with DOM inspection |
| reviewer | — | sonnet | Cross-cutting review; performance + architecture checklists |
| refactorer | — | haiku | Mechanical rename/extract/reorder |
| documenter | — | haiku | README/CHANGELOG/docstring updates |
| committer | — | haiku | Conventional commit formatting + staging |

**Readers**:
- Orchestrator (reads at dispatch time to pass correct model to agent).
- Agents themselves (frontmatter references the table).

**Invariants**:
- Every agent file in `agents/*.md` has exactly one row in this table (Spec has two for its two modes).
- Changes to model tier require editing this table and nothing else.

---

## CriticalitySignal

**What**: A detected indicator that a task should default to strict tier regardless of scope.

**Fields**:
- `source`: `user_flag | keyword | spec_metadata`
- `matched_term`: the specific flag or keyword that fired (e.g., `"production"`)
- `context`: one-line quote of the matching text
- `resolution`: `confirmed_strict | overridden_to: <tier>`

**Detection logic** (see research.md §4):

1. Check user preamble for `critical: true`.
2. Scan user task request for keyword list: `security`, `production`, `hotfix`, `critical`, `breaking`, `data loss`, `auth`, `payment`, `pii`.
3. Scan spec `## Quality Gates` section (when present) for same keywords.

**First-hit wins**. Orchestrator prompts user for confirmation; resolution is recorded in PipelineSummary.

---

## PipelineSummary (extended)

**What**: The `.task/pipeline-summary.md` file, extended with a front-matter block.

**Full structure**:

```markdown
---
scope: M                              # ScopeTier
scope_source: classified | user | inferred | upgraded
scope_override: null | <ScopeTier>    # null if auto-classified and not overridden
tier: standard                        # ApprovalTier
tier_source: default | user | criticality | mid_flight
tier_override: null | <ApprovalTier>
criticality_flag: false | true
criticality_source: null | user_flag | keyword | spec_metadata
criticality_matched_term: null | <string>
skipped_stages:
  - { name: <stage>, reason: <string> }
stage_count_expected: <int>
stage_count_approval_gated: <int>
---

# Pipeline Summary
- **Task**: <one-line description from Spec>
- **Type**: <task_type> | **Scope**: <ScopeTier> | **Tier**: <ApprovalTier> | **Pipeline**: <pipeline_id>
- **Stage N -- <name>**: ok <brief details>
...
```

**Back-compat**:
- Readers that only parse the body (Documenter, Committer) are unaffected by the front-matter block.
- A reader that doesn't understand YAML-fenced content skips the `---` block and starts at `# Pipeline Summary`.

**Resume detection**:
- File starts with `---\n` → redesigned workspace; parse front-matter.
- File starts with `# Pipeline Summary` (or empty) → pre-redesign workspace; default tier=strict.

---

## SpecValidationResult

**What**: The outcome of the Spec agent's validation phase (in either mode).

**Fields**:
- `verdict`: `PASS | PASS_WITH_WARNINGS | NEEDS_ATTENTION`
- `findings`: list of Finding
- `spec_mode`: `interactive | validate`

**Finding**:
- `severity`: `Gap | Conflict | Weak | OK`
- `location`: spec section reference (e.g., `User Story 2 / AC-1`)
- `description`: human-readable summary
- `suggestion`: optional fix hint

**Mapping to verdict**:
- Any `Gap` or `Conflict` → `NEEDS_ATTENTION`
- Only `Weak` findings → `PASS_WITH_WARNINGS`
- No findings or only `OK` → `PASS`

**Written to**: `.task/00-spec.md` under a `## Validation` section at the bottom of the file.

---

## SpecDocument

**What**: The `.task/00-spec.md` file produced by the Spec agent in either mode.

**Front-matter**:

```yaml
---
mode: interactive | validate
source: user_dialogue | ready_made: <path>
detected_at: <timestamp>
---
```

**Body** (unchanged from current Brainstormer output format):

```markdown
# Spec: <Feature Name>

## Summary
<1-2 sentences>

## User Stories
- US1 [P1]: As a <actor>, I want <action>, so that <benefit>
  - AC-1: <testable criterion>
  ...

## Quality Gates
- QG-1: ...

## Edge Cases
- EC-1: ...

## Scope
### In
- ...
### Out
- ...

## Validation
**Verdict**: PASS | PASS_WITH_WARNINGS | NEEDS_ATTENTION
**Findings**:
| Severity | Location | Description |
|---|---|---|
| Gap | US2 / AC-? | Missing acceptance criterion |
...
```

**Invariants**:
- Validation section always present (FR-018, SC-006).
- Interactive mode preserves pre-redesign Brainstormer section ordering (FR-025).

---

## Invocation inputs

**What**: Everything the orchestrator consumes at the start of a pipeline.

**Sources**:
- User message (raw text).
- Optional preamble (first line matching YAML-ish grammar; see research §2).
- Existing `.task/` workspace (if present, triggers resume).
- Existing spec artifacts (Adaptive Entry detection; see research §9).

**Parsed fields**:
- `scope_override`: ScopeTier or null
- `tier_override`: ApprovalTier or null
- `critical_flag`: bool
- `spec_mode_override`: `interactive | validate | null`
- `raw_request`: user text minus preamble

---

## State transitions

**Pipeline lifecycle**:

```
invocation
  → parse preamble + detect workspace
  → [resume path] load PipelineSummary front-matter, continue from last stage
  | [fresh path] dispatch Spec stage
      → Spec decides mode (interactive | validate)
      → Spec produces SpecDocument + SpecValidationResult
      → Classify ScopeTier (end of Spec stage)
      → Select ApprovalTier (default from scope, override from user, strict if criticality confirmed)
      → Write PipelineSummary front-matter with scope, tier, overrides, skipped_stages
  → Dispatch stages per PipelineDefinition[scope, task_type]
      → Each stage reads ApprovalTier at dispatch time
      → If user changes tier in approval reply: update PipelineSummary front-matter
      → If Scout flags scope upgrade: prompt user; on approval, swap PipelineDefinition and record "upgraded" in scope_source
  → Committer (always gated)
  → End
```

**Failure paths**:
- Spec validate mode on malformed input → offer fallback to interactive (Edge Case).
- Classification low-confidence → round up + surface rationale (FR-003, Edge Case).
- Resume on pre-redesign workspace → tier=strict default, scope inferred (§8).

---

## Reference summary

| Entity | Persisted where | Written by | Read by |
|---|---|---|---|
| ScopeTier | PipelineSummary front-matter | Orchestrator (post-Spec) | Orchestrator (stage selection) |
| ApprovalTier | PipelineSummary front-matter | Orchestrator (post-Spec or at preamble parse) | Orchestrator (gate decisions) |
| PipelineDefinition | `refs/scope-pipelines.md` | Author (this cycle) | Orchestrator |
| ModelTierAssignment | `refs/model-tiers.md` | Author (this cycle) | Orchestrator + all agents |
| CriticalitySignal | PipelineSummary front-matter | Orchestrator (at preamble/detection) | User (prompt) + audit |
| PipelineSummary | `.task/pipeline-summary.md` | Orchestrator + each stage | Downstream stages + resume logic |
| SpecValidationResult | Inside `.task/00-spec.md` | Spec agent | Orchestrator (verdict gate) |
| SpecDocument | `.task/00-spec.md` | Spec agent | All downstream agents |
