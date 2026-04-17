# Data Model: Cycle 2 — Integration

**Feature**: task-cycle2-integration
**Date**: 2026-04-17

## ReviewerLiteFinding

Produced by `agents/reviewer-lite.md` per module.

**Fields**:
- `module_N`: int — module number from Decomposer
- `severity`: `Critical | Minor` — routes finding downstream
- `location`: `file:line` — precise pointer
- `description`: short human-readable finding
- `category`: `secrets | n_plus_one | sql_injection | unhandled_external | unbounded_loop` — from `refs/reviewer-lite-checklist.md`
- `pattern_matched`: string — the actual pattern hit (for audit)

**Persistence**: inside `.task/09.5-review-lite-{N}.md` as Findings table rows.

**Routing**:
- Critical → triggers Debugger (orchestrator control flow).
- Minor → aggregated by final Reviewer.

---

## DelegationMode

Pipeline-level decision, immutable per run (FR-022).

**Values**:
- `delegate` — wrappers invoke superpowers skills.
- `fallback` — wrappers execute inline (pre-Cycle-2) behavior.

**Source**: `delegation_source` field records how it was set:
- `default` — plugin detected at startup, no user override.
- `user` — preamble `delegation: disable` (forces `fallback`).
- `plugin_missing` — plugin absent at startup (forces `fallback`).
- `escalation` — 2+ per-call failures within run escalated to full fallback.

**Persisted**: `.task/pipeline-summary.md` front-matter fields `delegation_mode`, `delegation_source`.

---

## WrapperInvocationResult

One record per Planner/Debugger/Implementer/Tester invocation.

**Fields**:
- `agent`: name
- `cycle`: int (for Debugger/Implementer/Tester cycles)
- `module_N`: int (for per-module agents)
- `mode`: `delegated | fallback` — what actually executed (may differ from pipeline `delegation_mode` if per-call fallback triggered)
- `success`: bool
- `fallback_reason`: optional enum `{ plugin_missing, plugin_error, malformed_output, user_override, timeout }`
- `duration_ms`: int (best-effort)

**Persistence**: aggregated into pipeline-summary.md body lines, e.g.:

```
- **Stage 5.2 -- Planner**: ok plan.md written [delegated via superpowers:writing-plans, 1200ms]
- **Stage 8.1 -- Debugger**: ok cluster analyzed [fallback — plugin_error: "skill not found"]
```

---

## SkillMetadata

Post-split SKILL.md content.

**Includes**:
- YAML frontmatter (`name`, `description`)
- Top-level description prose (≤3 paragraphs)
- Progress Tracker format specimen
- Agent Reference table (full, 15 rows including Reviewer-Lite)
- Workspace file listing
- Starting the Pipeline numbered steps (with refs links)
- Resuming cross-reference line
- Cleaning Up line

**Excluded** (moved to refs):
- Execution Strategy tiers
- Model Tier Resolution
- Context Management
- Classification & Pipeline Selection
- Pipeline Overview ASCII diagram
- Flow Control (approval gates, Test/Debug cycle, Design QA cycle, Review Issue Routing, Plan Deviations, Adaptive Pipeline summary)
- Adaptive Entry
- Resume Detection (and sub-sections)

**Size target**: ≤120 lines.

---

## RefsMap

Authoritative catalog of ref files in `skills/task/agents/refs/` after Cycle 2.

| File | Introduced | Purpose | Load trigger |
|---|---|---|---|
| orchestration.md | Cycle 2 | Execution Strategy + Model Tier Resolution + Context Management | At startup after SKILL.md shell |
| pipelines.md | Cycle 2 | Pipeline Overview + Classification + Adaptive Entry | After Spec completes (scope classification) |
| approvals.md | Cycle 2 | Flow Control + Approval Tiers + Tier Override + Criticality | Per stage dispatch (approval resolution) |
| resume.md | Cycle 2 | Resume Detection + Scope Inference + Schema Upgrade | Only on resume path |
| reviewer-lite-checklist.md | Cycle 2 | 5-category pattern checklist | When reviewer-lite agent runs |
| delegation-protocol.md | Cycle 2 | Wrapper call rules + fallback triggers + logging format | When any wrapper agent runs |
| scope-pipelines.md | Cycle 1 | 5×4 matrix | During pipeline selection |
| approval-tiers.md | Cycle 1 | Tier → gate matrix | Per stage dispatch |
| model-tiers.md | Cycle 1 | Agent → model assignments | At dispatch time |
| criticality-signals.md | Cycle 1 | Keyword list + detection sources | At tier selection |
| spec-dialogue-patterns.md | Cycle 1 | Spec interactive/interview patterns | Only by Spec agent |
| architecture-checklist.md | Cycle 1 | Final Reviewer checklist | By Reviewer |
| performance-checklist.md | Cycle 1 | Final Reviewer perf checklist | By Reviewer |
| security-checklist.md | Cycle 1 | Fallback security checklist | By Reviewer when plugin unavailable |
| debug-examples.md | Cycle 1 | Debugger hypothesis examples | By Debugger |
| design-tokens-example.md | Cycle 1 | Designer token example | By Designer |
| doc-formats.md | Cycle 1 | Documenter format reference | By Documenter |
| commit-conventions.md | Cycle 1 | Committer conventions | By Committer |
| commit-template.md | Cycle 1 | Commit body template | By Committer |

**Post-Cycle-2 count**: 19 ref files (was 13; +4 split + 2 new agent refs).

---

## ReviewLiteOutput

Schema of `.task/09.5-review-lite-{N}.md`.

**Front-matter**:
```yaml
---
module_N: 1
cycle: 1
checklist_categories_checked: 5
files_scanned: 8
verdict: PASS | PASS_WITH_MINOR | FAIL_CRITICAL
---
```

**Body**:
- `## Brief` (required)
- `## Findings` (table: severity, location, category, description, pattern_matched)
- `## Routing` (if any Critical): lists which Debugger cycle this triggers

---

## Extended PipelineSummary

Cycle 1 v2 schema + Cycle 2 additive fields.

**Full front-matter**:
```yaml
---
# Cycle 1 fields (unchanged):
scope: M
scope_source: classified
scope_override: null
scope_signals: { ... }
tier: standard
tier_source: default
tier_override: null
criticality_flag: false
criticality_source: null
criticality_matched_term: null
skipped_stages: [...]
stage_count_expected: 15
stage_count_approval_gated: 3
summary_schema: v2

# Cycle 2 additive (backward-compatible — readers ignore unknown):
delegation_mode: delegate | fallback
delegation_source: default | user | plugin_missing | escalation
review_lite_enabled: true | false
review_lite_findings_total: 0
review_lite_findings_critical: 0
review_lite_findings_minor: 0
---
```

**Body additions**: per-stage invocation records embed `[delegated via <skill>]` or `[fallback — <reason>]`; Review-Lite stage lines reference `09.5-review-lite-{N}.md`.

**Back-compat invariants**:
- Absence of `delegation_mode` → treat as `fallback` (safe default for pre-Cycle-2 resumes).
- Absence of `review_lite_*` fields → treat as `review_lite_enabled: false`.

---

## State transitions (summary)

Per-stage dispatch with Cycle 2:

```
1. Orchestrator resolves stage from pipeline (scope, task_type).
2. If stage ∈ {planner, debugger, implementer, tester}:
     a. Look up delegation_mode from pipeline-summary front-matter.
     b. If `delegate`: dispatch wrapper in delegated mode.
        - If superpowers invocation fails → per-call fallback.
        - If 2+ per-call fallbacks in run → escalate to delegation_mode=fallback.
     c. Else: dispatch wrapper in fallback mode (inline behavior).
3. If stage == reviewer-lite (new):
     a. Resolve approval gate from refs/approval-tiers.md.
     b. Dispatch reviewer-lite with 07-tests-{N}-{C}.md as input.
     c. Read output 09.5-review-lite-{N}.md.
     d. If verdict == FAIL_CRITICAL → route to Debugger (cycle++); max 2 cycles.
     e. Else → continue to next module or final Reviewer.
4. If stage == reviewer (existing, now modified):
     a. Read all 09.5-review-lite-*.md Brief + Findings.
     b. Dedupe findings against own scan.
     c. Produce 09-review.md with cross-cutting findings + Review-Lite-originated minor escalations.
```

---

## Reference summary

| Entity | Written to | Written by | Read by |
|---|---|---|---|
| ReviewerLiteFinding | `.task/09.5-review-lite-{N}.md` Findings table | reviewer-lite | reviewer (dedup), orchestrator (routing) |
| DelegationMode | pipeline-summary front-matter | orchestrator (startup) | wrappers (dispatch decision) |
| WrapperInvocationResult | pipeline-summary body | orchestrator (post-dispatch) | audit, user review |
| SkillMetadata | `skills/task/SKILL.md` | cycle 2 author | every skill activation |
| RefsMap | this spec + `skills/task/agents/refs/` | cycle 2 author | orchestrator (on-demand loads) |
| ReviewLiteOutput | `.task/09.5-review-lite-{N}.md` | reviewer-lite | reviewer, orchestrator |
| Extended PipelineSummary | `.task/pipeline-summary.md` | orchestrator | downstream stages, resume logic |
