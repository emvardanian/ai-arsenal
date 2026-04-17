# Phase 0 Research: Task Skill Core Redesign

**Feature**: task-core-redesign
**Date**: 2026-04-17
**Purpose**: Resolve technical unknowns before Phase 1 design. Each decision below is the outcome; rejected alternatives document why we didn't go another way.

## 1. Scope classification: signals and thresholds

**Question**: What signals determine scope, and how do we prevent misclassification when signals disagree?

**Decision**: Four weighted signals, evaluated in order. First signal strong enough to place the task wins; ties round up.

| Signal | Source | Weight | Thresholds |
|---|---|---|---|
| Estimated file count | Spec Scope IN + Key Entities + Scout scan (if available) | Primary | XS:1; S:2-5; M:5-15; L:15-40; XL:40+ |
| Estimated module count | Decomposition hint in spec; post-Scout refinement | Secondary | XS/S:1; M:2-3; L:3-5; XL:5+ |
| UI-presence flag | Keywords in spec ("UI", "screen", "component", "design") + explicit `ui: true` on modules | Modifier | Forces XL when present in any form |
| Task type | Analyst classification (feature/bugfix/refactor/hotfix) | Modifier | Hotfix caps at S; refactor may downgrade one tier if no behavior change |

**Tie-break rule**: When signals disagree by more than one tier, round up. Larger scope is recoverable (pipeline can be shortened by tier override); undersized pipeline cannot be recovered without mid-flight upgrade (Edge Case in spec).

**Early vs refined classification**: Spec agent computes initial scope from its own output (story count, Scope IN size, Key Entities count) at the end of Spec stage. Orchestrator uses this to pick the pipeline. Scout (when present per scope) may flag "scope upgrade needed" if actual file count exceeds threshold by 2x or more — triggers the Edge Case: Scope upgrade mid-pipeline.

**Rationale**: Four signals cover the ways a task can be "large". Single-signal classifications (file count alone) misclassify cross-cutting refactors; task-type alone misclassifies bugfixes that touch 30 files.

**Alternatives considered**:
- **Single signal (file count)**: Rejected — can't distinguish 5-file UI feature from 5-file data migration.
- **LLM-based free-form classification**: Rejected — non-deterministic; violates FR-005 (same scope always produces same stage list).
- **User declares scope always**: Rejected — defeats the purpose (auto-classification is the daily-UX win).

## 2. User invocation grammar for overrides

**Question**: How does the user declare scope, tier, or criticality at invocation time?

**Decision**: Two coexisting mechanisms.

**Mechanism A — YAML-ish preamble** (preferred, machine-parseable):

```
scope: L, tier: strict, critical: true
<rest of user's task request>
```

Orchestrator parses first line if it matches `/^[a-z_]+:\s*\w+(,\s*[a-z_]+:\s*\w+)*$/`. Keys: `scope`, `tier`, `critical`. Values: scope ∈ {xs, s, m, l, xl}; tier ∈ {strict, standard, express}; critical ∈ {true, false}. Unknown keys ignored with a warning in pipeline summary.

**Mechanism B — natural-language keywords** (fallback, inference-based):

- Scope keywords: "small task", "quick", "trivial" → S; "medium", "normal" → M; "large", "big" → L; "huge", "massive" → XL.
- Tier keywords: "fast", "quickly", "just do it" → express; "carefully", "step by step" → strict.
- Criticality keywords: "security", "production", "hotfix", "critical", "breaking", "auth", "payment", "data loss", "pii" → recommend strict; user confirms.

If both A and B are present, A wins (explicit over inferred).

**Rationale**: Preamble gives deterministic control for power users. Natural-language fallback preserves conversational invocation for casual use. No new CLI flags or slash commands (those are explicitly Cycle 3).

**Alternatives considered**:
- **Slash command per combination** (`/task-express`, `/task-strict`): Rejected — Out of Scope for this cycle (Cycle 3).
- **Interactive prompt at start** ("Which tier?"): Rejected — adds friction for the 80% case; defeats express-tier purpose.
- **JSON config file**: Rejected — overkill; one-off per-task decisions don't need persistent config.

## 3. Model tier mapping authoritative location

**Question**: Where does the mapping `(agent, mode) -> model` live such that it's the single source of truth (FR-023)?

**Decision**: `skills/task/agents/refs/model-tiers.md` as an authoritative markdown table. Agent frontmatter references the table rather than declaring a model string directly.

**Before (per-agent frontmatter)**:
```yaml
---
name: scout
model: sonnet  # hardcoded, drift risk
---
```

**After (reference)**:
```yaml
---
name: scout
model: see agents/refs/model-tiers.md
---
```

Orchestrator reads `model-tiers.md` once per pipeline run, caches the table, and dispatches each agent with the table's declared model.

**Why not a YAML/JSON file**: Constitution says markdown-only, no parsers. Markdown table is both human- and orchestrator-readable (orchestrator runs in Claude Code and can parse markdown tables trivially via prompting).

**Rationale**: One file to edit, one file to grep, one file to diff. Prevents the "I changed Scout to haiku but forgot to update SKILL.md's model column" bug class.

**Alternatives considered**:
- **Frontmatter only (status quo)**: Rejected — produced the exact misallocation this cycle corrects.
- **Inline table in SKILL.md**: Rejected — couples model decisions to orchestrator prose; harder to grep.
- **Separate table per tier (opus.md, sonnet.md, haiku.md)**: Rejected — three files to keep in sync; no advantage.

## 4. Criticality detection

**Question**: How does the skill detect that a task is critical enough to recommend strict tier even on small scope (FR-014)?

**Decision**: Three detection sources. First hit wins; the user is shown which source triggered.

1. **Explicit user flag**: `critical: true` in preamble (Mechanism A above).
2. **Keyword match** in task description or spec body: see list in §2 Mechanism B.
3. **Spec metadata**: if spec `## Quality Gates` section contains keywords like "security", "compliance", "data integrity", or a QG references auth/payment/pii/production.

When triggered, orchestrator shows a single prompt:

> **Criticality detected** via `[source]: [term]`. Recommended tier: strict.
> Proceed with strict, or confirm to override with scope-default tier?
> [strict] / [override]

One-reply gate. User's choice is recorded in `pipeline-summary.md` front-matter (`criticality_flag: true`, `tier_override: express` if they chose override).

**Rationale**: Keywords catch the obvious cases (pretty much every production incident has at least one of these words). Spec metadata catches the user who filled QGs but didn't phrase the request as "critical". User flag is the escape hatch both ways.

**Alternatives considered**:
- **LLM judgement ("is this critical?")**: Rejected — non-deterministic, hard to audit, can't explain "why strict" to user.
- **Force strict whenever keyword matches, no override**: Rejected — defeats user control; user may legitimately want express for a "security" refactor that's pure renaming.
- **Ignore criticality entirely**: Rejected — FR-014 requires it; edge case in spec demands it.

## 5. Pipeline-summary.md extension

**Question**: How do we record scope, tier, overrides, skipped stages without breaking downstream agents that read the current `pipeline-summary.md`?

**Decision**: YAML front-matter block at the top of the file. Existing markdown body (stage lines) unchanged.

**New format**:

```markdown
---
scope: M
tier: standard
scope_override: null
tier_override: null
criticality_flag: false
skipped_stages:
  - { name: Designer, reason: "scope=M, no UI modules" }
  - { name: Design-QA, reason: "scope=M, no UI modules" }
  - { name: Refactorer, reason: "tier=express" }
---

# Pipeline Summary
- **Task**: Add email notifications for password reset
- **Type**: feature | **Scope**: M | **Pipeline**: standard
- **Stage 1 -- Spec**: ok 4 user stories, 12 AC, validation PASS
- **Stage 2 -- Scout**: ok 3 modules identified
...
```

**Back-compat contract**: agents that read the body only (Documenter, Committer) see an unchanged document. The YAML block is fenced by `---` markers, which are a standard doc-start convention; text-only readers skip it without error. Orchestrator and Spec agent (on resume) read the front-matter.

**Detection for resume**: Orchestrator checks for `---\n` as the first line. If absent, treats workspace as pre-redesign (Edge Case: Existing pipeline resume across redesign boundary) and defaults to tier=strict, scope=unclassified.

**Rationale**: YAML front-matter is an established markdown pattern (Jekyll, Hugo, frontmatter-parser). Zero risk of breaking existing readers that scan the body. Machine-readable for the orchestrator.

**Alternatives considered**:
- **New file `.task/pipeline-meta.yaml`**: Rejected — scatters state across two files; more sync bugs.
- **HTML comments `<!-- scope: M -->`**: Rejected — less standard; inconsistent with markdown conventions.
- **Inline fields in first line of body**: Rejected — harder to parse reliably; risk of editing collisions with existing summary structure.

## 6. (scope, task_type) → stages mapping

**Question**: What is the concrete matrix of which stages run for each (scope, task_type) pair?

**Decision**: 5×4 matrix defined in `refs/scope-pipelines.md`. Cells annotated with stages in execution order. Summary:

| | **feature** | **bugfix** | **refactor** | **hotfix** |
|---|---|---|---|---|
| **XS** | Impl → Test → Commit | Impl → Test → Commit | Impl → Test → Commit | Impl → Test → Commit |
| **S** | Spec → Plan → Impl → Test → Commit | Spec → Impl → Test → Commit | Spec → Plan → Impl → Test → Commit | Spec → Impl → Test → Commit |
| **M** | Spec → Scout → Decompose → (Research → Plan → Impl → Test)×N → Commit | Spec → Scout → (Impl → Test ⇄ Debug) → Commit | Spec → Scout → (Plan → Impl → Test) → Commit | Spec → (Impl → Test ⇄ Debug) → Commit |
| **L** | M + Reviewer → Refactorer → Documenter | M + Reviewer | M + Reviewer → Refactorer | hotfix (uncapped) + Reviewer |
| **XL** | L + Designer → Design-QA (UI modules) | L | L | L (rare) |

Full table with stage inputs, outputs, and approval flags lives in `data-model.md`. Cells marked `×N` mean per-module repetition under Decomposer's execution order.

**Rationale**: Matches the existing `Adaptive Pipeline` table semantics and preserves task-type differentiation (FR-006). XS collapses everything to the minimum viable pipeline. XL is the only tier that invokes Designer/Design-QA automatically.

**Alternatives considered**:
- **Single pipeline per scope, task-type ignored**: Rejected — loses FR-006; a scope-M bugfix shouldn't run through Decomposer.
- **Per-user custom matrix**: Rejected — Out of Scope (Cycle 3 preferences).

## 7. Mid-pipeline tier change

**Question**: How does tier change mid-pipeline without re-running completed stages or losing approval context (FR-013)?

**Decision**: Tier is orchestrator state, mirrored to `pipeline-summary.md` front-matter on every write. User may declare a new tier in any approval response (e.g., at Spec approval: "approve and switch to strict"). Orchestrator:

1. Parses new tier from response.
2. Writes `tier_override: strict` to front-matter.
3. For each subsequent stage, reads current tier (now updated) at dispatch time.
4. Completed stages remain approved; their approval records are not recomputed.

If user downgrades (e.g., strict → express) mid-pipeline, the orchestrator notes "downgraded mid-flight" in the pipeline summary body. No stages re-run.

**Rationale**: Tier affects gate decisions, not stage outputs. Changing tier after a stage commits affects only future stages. Single source of truth (front-matter) prevents state divergence.

**Alternatives considered**:
- **Disallow mid-flight tier change**: Rejected — FR-013 explicitly requires it; user may realize mid-task that they want more careful review.
- **Restart pipeline on tier change**: Rejected — destroys work; defeats the purpose.

## 8. Pre-redesign workspace detection

**Question**: How does the orchestrator detect a `.task/` workspace from the pre-redesign skill version (FR-026/027)?

**Decision**: Detection test is presence of YAML front-matter in `pipeline-summary.md`.

- **Has front-matter** (starts with `---\n`): redesigned workspace; read scope/tier from front-matter.
- **No front-matter** (starts with `# Pipeline Summary` or equivalent): pre-redesign; default tier=strict; scope=unclassified.

If scope is needed downstream (e.g., for skipped-stage justification), orchestrator infers from existing body: presence of `Stage 3 -- Decomposer` line implies M or higher; presence of `Designer` line implies XL; etc. Inference is recorded with label `inferred` in front-matter and never overrides a user-declared scope.

**Rationale**: Front-matter is a binary signal; zero false positives. Defaulting to strict protects user from accidentally running express on a legacy task they expected to run with current behavior.

**Alternatives considered**:
- **Version tag in workspace**: Rejected — adds another metadata concept; front-matter presence/absence is sufficient.
- **Ask user on resume**: Rejected — interrupts resume flow; strict-default is the safe, backward-compatible choice.

## 9. Spec agent mode detection

**Question**: How does the Spec agent decide between interactive and validate mode (FR-020)?

**Decision**: Match current `Adaptive Entry` logic verbatim to preserve behavior.

1. If user explicitly passes a file path or pastes full spec content in the request → validate mode.
2. Else, if a fresh spec exists at `docs/superpowers/specs/` with mtime within the last hour → validate mode.
3. Else, if a TRC spec exists at `specs/<branch>/spec.md` in the current project → validate mode.
4. Else → interactive mode.

Mode is logged in `.task/00-spec.md` front-matter (`mode: interactive|validate`) and in pipeline summary.

**Rationale**: Preserves existing behavior; no new detection logic to debug. User can force a mode with preamble `mode: interactive` or `mode: validate` if detection is wrong.

**Alternatives considered**:
- **Always interactive, ask user if they have a spec**: Rejected — adds friction; breaks "ready-made spec" path.
- **Always validate, fall through to interactive if no content**: Rejected — ambiguous when user description is brief; interactive mode should be the default for "describe a new feature".

## 10. Approval gate mechanics per tier

**Question**: Which specific stages gate on approval in each tier (FR-008/009/010)?

**Decision**: Deterministic rules per tier. Spec agent's per-section internal approvals during interactive dialogue are not counted as pipeline approval gates (they are part of Stage 1's internal loop).

| Stage | strict | standard | express |
|---|---|---|---|
| Spec (end of stage) | YES | YES | NO |
| Scout | NO | NO | NO |
| Decomposer | YES | YES | NO |
| Planner (per module) | YES | NO | NO |
| Designer (per UI module) | YES | NO | NO |
| Implementer (per module) | YES | NO | NO |
| Tester | NO | NO | NO |
| Debugger | NO | NO | NO |
| Design-QA | NO | NO | NO |
| Reviewer | NO | NO | NO |
| Refactorer | YES | NO | NO |
| Documenter | YES | NO | NO |
| Committer (always, end of pipeline) | YES | YES | YES |

Counts: strict = 6 approvals for full feature pipeline; standard = 3; express = 1. Matches SC-001, SC-002, SC-003.

**Rationale**: Strict = pre-redesign behavior, unchanged. Standard = only architectural decision points (Spec is "what are we building", Decomposition is "how are we splitting it", Commit is "is this the right final state"). Express = trust the system until the last word.

**Alternatives considered**:
- **Standard also approves per-module Planner**: Rejected — in a 3-module task that's 4 extra approvals; defeats standard's purpose.
- **Strict adds Tester approval**: Rejected — Tester is non-blocking by design; adding approval changes semantics.

## Summary of decisions

| # | Topic | Decision one-liner |
|---|---|---|
| 1 | Scope classification | Four weighted signals; round up on ties; refined post-Scout |
| 2 | Invocation grammar | YAML preamble + natural-language fallback; no new slash commands |
| 3 | Model tier location | Single `refs/model-tiers.md` table; agent frontmatter references it |
| 4 | Criticality | Keywords + QG metadata + user flag; one-reply gate prompt |
| 5 | Pipeline summary | YAML front-matter + unchanged markdown body |
| 6 | (scope × task_type) matrix | 5×4 table in `refs/scope-pipelines.md` |
| 7 | Mid-flight tier change | User declares in approval reply; orchestrator updates front-matter |
| 8 | Pre-redesign detect | Front-matter presence; default strict on absence |
| 9 | Spec mode detect | Preserve current Adaptive Entry logic verbatim |
| 10 | Approval gates per tier | Deterministic table; strict=6/standard=3/express=1 on full feature |

All NEEDS CLARIFICATION markers resolved. Ready for Phase 1.
