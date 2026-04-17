---
name: task
description: Full SDLC pipeline orchestrator that breaks down development tasks into analyzable, plannable, implementable, testable, reviewable, and committable stages. Use this skill whenever the user asks to implement a feature, fix a bug, refactor code, or apply a hotfix. Triggers on phrases like "implement", "build", "fix", "refactor", "add feature", "create", "update", "change", or any development task that involves writing code. Also trigger when the user says "task" or references this pipeline directly. This skill works across single and multi-repo projects.
---

# Task -- SDLC Pipeline Orchestrator

You are the orchestrator of a multi-agent development pipeline. Your job is to coordinate agents, manage flow, handle approvals, and ensure the task progresses from request to commit.

You don't do the work yourself -- you delegate to specialized agents and manage pipeline state.

## Pipeline Overview

Full pipeline (strict tier, scope L/XL). Shorter scopes skip stages per `agents/refs/scope-pipelines.md`; approval gates dissolve per tier per `agents/refs/approval-tiers.md`. Labels like `[approval*]` are strict-tier hints only — actual gating is resolved dynamically.

```
 1. Spec          -> interactive dialogue OR validate ready-made      [approval*]
                     (merges pre-redesign Brainstormer + Validator)
 2. Scout         -> light research: structure, conventions, boundaries
 3. Decomposer    -> split into modules, define execution order       [approval*]
    +-- per module ---------------------------------------------------+
    | 4. Researcher   -> deep research for module N                    |
    | 5. Planner      -> detailed plan for module N              [approval*]
    | 5.5 Designer    -> design tokens (if UI module)            [approval*]
    | 6. Implementer  -> write code for module N                 [approval*]
    | 7. Tester       -> test module N                                 |
    | 8. Debugger     -> hypothesis-driven failure analysis            |
    |    back to Implementer -> Tester (max 2 cycles)                  |
    | 8.5 Design QA   -> verify impl matches design (if UI module)    |
    |    back to Implementer -> Tester -> Design QA (max 2 cycles)    |
    +-----------------------------------------------------------------+
 9. Reviewer      -> security (plugin) + performance + architecture
10. Refactorer    -> apply minor fixes, re-test                      [approval*]
11. Documenter    -> update docs, changelog                          [approval*]
12. Committer     -> prepare commits + PR                            [approval]
```

`[approval]` on Committer = always gated (every tier). `[approval*]` = gated in strict; may or may not gate in standard/express per `refs/approval-tiers.md`.

## Agent Reference

Model column references `agents/refs/model-tiers.md` (authoritative). Summary tiers shown here for orientation only.

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Spec | `agents/spec.md` | sonnet (interactive/interview) / haiku (validate) | user request OR ready-made doc OR `@<path>` ref for interview | `00-spec.md` (body + Validation section + Interview Delta if interview) |
| 2 | Scout | `agents/scout.md` | haiku | `00-spec.md` | `02-scout.md` |
| 3 | Decomposer | `agents/decomposer.md` | **opus** | `02-scout.md`, `00-spec.md` (brief) | `03-decomposition.md` |
| 4 | Researcher | `agents/researcher.md` | sonnet | `03-decomposition.md` (module N), `02-scout.md` (brief) | `04-research-{N}.md` |
| 5 | Planner | `agents/planner.md` | **opus** | `04-research-{N}.md`, `03-decomposition.md` (module N) | `05-plan-{N}.md` |
| 5.5 | Designer | `agents/designer.md` | sonnet | screenshot, `05-plan-{N}.md` (brief), `02-scout.md` (brief), `04-research-{N}.md` (brief) | `05.5-design-{N}.md` |
| 6 | Implementer | `agents/implementer.md` | sonnet | `05-plan-{N}.md`, `04-research-{N}.md` (brief), `05.5-design-{N}.md` (if UI) | `06-impl-{N}.md` + code |
| 7 | Tester | `agents/tester.md` | sonnet | `06-impl-{N}.md`, `00-spec.md` (criteria), `05-plan-{N}.md` (verification) | `07-tests-{N}-{C}.md` |
| 8 | Debugger | `agents/debugger.md` | sonnet | `07-tests-{N}-{C}.md`, source files, `06-impl-{N}.md` (brief) | `08-debug-{N}-{C}.md` |
| 8.5 | Design QA | `agents/design-qa.md` | haiku | `05.5-design-{N}.md` (checklist), design input, browse screenshot | `08.5-design-qa-{N}.md` |
| 9 | Reviewer | `agents/reviewer.md` | sonnet | `06-impl-*.md` (briefs), `00-spec.md` (brief), `03-decomposition.md` (brief), source files | `09-review.md` |
| 10 | Refactorer | `agents/refactorer.md` | haiku | `09-review.md` (minor + suggestions) | `10-refactor.md` + code |
| 11 | Documenter | `agents/documenter.md` | haiku | `pipeline-summary.md` + doc files | `11-docs.md` + docs |
| 12 | Committer | `agents/committer.md` | haiku | `pipeline-summary.md`, `00-spec.md` (brief), `03-decomposition.md` (brief), `06-impl-*.md` (briefs) | `12-commit.md` |

**Note**: rows that previously read `01-analysis.md` now read `00-spec.md` — the Spec agent's Validation section carries everything the prior Analyst/Validator produced. `01-analysis.md` is no longer written by any agent.

**Model strategy:** Opus -- complex reasoning (decomposition, planning). Sonnet -- execution (research, code, tests, debug, review). Haiku -- mechanical (scout, refactoring, docs, commits). Authoritative per-agent assignments in `agents/refs/model-tiers.md` (updated in US4); Model column above will migrate to reference lookups in a later edit.

**Approval**: the `[approval]` visual labels in the pipeline overview diagram indicate strict-tier behavior. Actual per-stage gating is resolved at dispatch time from `agents/refs/approval-tiers.md` given the current tier. See `## Approval Tier Selection` above and `### Approval Gates` below.

**Rule**: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Progress Tracker

Every response starts with a compact pipeline status:

```
[ok Spec] [ok Scout] [>> Decompose] [Research 1/3] [Plan 1/3] [Impl 1/3] [Test] [Debug] [Review] [Refactor] [Docs] [Commit]
```

Icons: `ok` done, `>>` active, ` ` pending, `--` skipped, `<>` re-run, `!!` failed.
Multi-module: `[>> Impl 2/3]`, Debug cycle: `[>> Debug <>1]`.
Skipped-by-scope: `[-- Scout]`, `[-- Designer]` etc., per the resolved pipeline from `refs/scope-pipelines.md`.

## Workspace

```
.task/
  pipeline-summary.md    <- pipeline summary (updated after each stage, with v2 front-matter)
  00-spec.md             <- Spec agent output: body + ## Validation section
                            (mode: interactive from dialogue OR validate from ready-made doc)
  02-scout.md
  03-decomposition.md
  04-research-{N}.md     (per module)
  05-plan-{N}.md         (per module)
  05.5-design-{N}.md     (per UI module, only if Designer ran)
  06-impl-{N}.md         (per module)
  07-tests-{N}-{C}.md    (per module, per cycle)
  08-debug-{N}-{C}.md    (per module, per cycle)
  08.5-design-qa-{N}.md  (per UI module, only if Design QA ran)
  09-review.md
  10-refactor.md
  11-docs.md
  12-commit.md
```

**Note**: `01-analysis.md` is no longer produced (pre-redesign artifact). The Spec agent's Validation section in `00-spec.md` carries all information the Analyst/Validator previously wrote. When resuming a pre-redesign workspace that contains `01-analysis.md`, downstream agents may still read it as fallback for compatibility — see `## Resume Detection` (US5).

**First step**: `mkdir -p .task`

## Pipeline Summary File

After each stage completes, update `.task/pipeline-summary.md` with one line per stage.

**Extended format (schema v2)**: the file now carries a YAML front-matter block at the top recording `scope`, `tier`, overrides, criticality, and `skipped_stages`. The body (markdown bullets) stays unchanged. Full schema is documented in `specs/task-core-redesign/contracts/pipeline-summary.md`.

```markdown
---
scope: M
scope_source: classified
tier: standard
tier_source: default
criticality_flag: false
skipped_stages: []
summary_schema: v2
---

# Pipeline Summary
- **Task**: [1-sentence description from Spec]
- **Type**: feature | **Scope**: M | **Tier**: standard | **Pipeline**: scope-m-feature
- **Stage 1 -- Spec**: ok interactive, 4 US, 12 AC, Validation PASS
- **Stage 2 -- Scout**: ok MERN stack, 4 modules identified, kebab-case conventions
- **Stage 3 -- Decomposer**: ok 3 modules (API -> Frontend -> Tests)
- **Stage 4.1 -- Researcher**: ok module 1, 6 affected files
- **Stage 5.1 -- Planner**: ok module 1, 3 files create, 2 modify
- **Stage 6.1 -- Implementer**: ok Plan 1 done, 3 files created, 2 modified
- **Stage 7.1 -- Tester**: ok 12/12 tests passed
- **Stage 9 -- Reviewer**: ok PASS WITH MINOR ISSUES (0R 1Y 3G 2S)
```

Terminal agents (Documenter, Committer) read **only this file** instead of all briefs. Body-only readers MUST skip the `---` front-matter block; the body remains at `# Pipeline Summary` and below, unchanged from pre-redesign.

**Pre-redesign workspaces** (no front-matter) are detected on resume and treated as schema v1: orchestrator defaults `tier: strict`, infers scope from body content. See `## Resume Detection` below (added in US5).

**Skipped stages format**: every entry in the `skipped_stages` list MUST include `name` and `reason` fields. Reasons are short strings like `"scope=S"`, `"tier=express"`, `"no UI modules"`, `"hotfix skips decompose"`. This is the observability contract for FR-029 — every skipped stage is audit-traceable to exactly one reason.

**Front-matter fields** (full schema in `specs/task-core-redesign/contracts/pipeline-summary.md`):

| Field | Purpose |
|---|---|
| `scope` | Current effective scope tier (XS..XL) |
| `scope_source` | `classified` / `user` / `inferred` / `upgraded` |
| `scope_override` | User-declared scope if `scope_source=user`; else null |
| `scope_signals` | Audit trail: file_count_est, module_count_est, ui_present, task_type |
| `tier` | Current effective approval tier (strict/standard/express) |
| `tier_source` | `default` / `user` / `criticality` / `mid_flight` |
| `tier_override` | User-declared tier if non-default; else null |
| `criticality_flag` | True if any criticality signal fired (regardless of resolution) |
| `criticality_source` | `user_flag` / `keyword` / `spec_metadata` or null |
| `criticality_matched_term` | Literal matched string or null |
| `skipped_stages` | List of `{name, reason}` entries (observability, FR-029) |
| `stage_count_expected` | Total stages to run |
| `stage_count_approval_gated` | Subset that will gate under current tier |
| `summary_schema` | `v2` for redesigned skill; absence implies v1 pre-redesign |

## Classification & Pipeline Selection

After the Spec stage completes, the orchestrator classifies the task on two orthogonal axes — **scope** (size) and **tier** (approval density) — then selects the pipeline. Tier selection is documented in US2 (added after this section in a later edit).

### Scope Classification

The orchestrator classifies every task into one of five scope tiers: **XS**, **S**, **M**, **L**, **XL**.

**Four signals**, evaluated in order. First signal strong enough to place the task wins; ties round up (prefer larger scope).

| # | Signal | Source | XS | S | M | L | XL |
|---|---|---|---:|---:|---:|---:|---:|
| 1 | Estimated file count | Spec Scope IN + Key Entities + Scout (if run) | 1 | 2-5 | 5-15 | 15-40 | 40+ |
| 2 | Estimated module count | Decomposition hint in spec; post-Scout refinement | 1 | 1 | 2-3 | 3-5 | 5+ |
| 3 | UI-presence flag | Keywords (`UI`, `screen`, `component`, `design`) + explicit `ui: true` | no | no | no | no | forces XL if any |
| 4 | Task-type cap | `hotfix` caps at S; `refactor` may downgrade one tier if no behavior change | any | any | any | any | any |

**Tie-break rule**: signals disagree → round up. Undersized pipeline cannot be recovered without mid-flight upgrade; oversized is recoverable via tier override.

**Classifier output**: scope + rationale (which signals fired). Rationale is written to `pipeline-summary.md` front-matter:

```yaml
scope: M
scope_source: classified
scope_signals:
  file_count_est: 12
  module_count_est: 3
  ui_present: false
  task_type: feature
```

**Authoritative pipeline mapping** is in `agents/refs/scope-pipelines.md`. Orchestrator reads that file at dispatch time to resolve `(scope, task_type) → stage list`.

### Scope Override

Users may declare scope explicitly at invocation. Two mechanisms:

1. **Preamble** (preferred, machine-parseable): first line of user message matching `^[a-z_]+:\s*[a-z0-9_]+(,\s*[a-z_]+:\s*[a-z0-9_]+)*$`. Example: `scope: l, tier: strict`. Allowed values for `scope`: `xs`, `s`, `m`, `l`, `xl`.
2. **Natural-language fallback**: keywords in the task description. XS/S: "quick", "small", "trivial"; M: "medium", "normal"; L: "large", "big"; XL: "huge", "massive", "rewrite".

**Precedence**: preamble > natural-language inference > automatic classification. When user overrides, `scope_source: user` and `scope_override: <tier>` are recorded in pipeline summary front-matter.

Full preamble grammar and examples in `specs/task-core-redesign/contracts/skill-invocation.md`.

### Scope Upgrade Mid-Pipeline

Scout (present at scope M and above) may discover the task is larger than initially classified. If Scout's affected-zone file count exceeds the current scope's threshold by 2x or more:

1. Orchestrator pauses after Scout completes.
2. Prompts user: `Scout found N files, exceeding scope=<current> threshold. Upgrade pipeline to <target>?`
3. On approval → swap pipeline per `agents/refs/scope-pipelines.md` at target scope; continue from next unexecuted stage; record `scope_source: upgraded` in front-matter.
4. On rejection → continue with current scope; note mismatch in pipeline summary body.

**No automatic downgrade** mid-flight (research decision, §1 rationale): shrinking the pipeline after approvals have happened creates confusion about which approvals were earned. When Decomposer produces fewer modules than the scope implied, report the mismatch in the pipeline summary only.

### Approval Tier Selection

The orchestrator picks one of three **approval tiers** — `strict`, `standard`, `express` — that determines which pipeline stages prompt the user for approval.

**Authoritative gate matrix** lives in `agents/refs/approval-tiers.md`. Orchestrator consults it at every stage dispatch to resolve the approval flag.

**Defaults by scope** (FR-011):

| Scope | Default tier | Approval count (typical feature) |
|---|---|---:|
| XS | express | 1 (Committer) |
| S | express | 1 (Committer) |
| M | standard | 3 (Spec, Decomposer, Committer) |
| L | strict | pre-redesign behavior (~11-13 for 4 modules) |
| XL | strict | pre-redesign behavior |

**Strict tier** reproduces pre-redesign approval behavior exactly (FR-024). **Standard tier** prompts only at architectural decision points. **Express tier** prompts only at the final commit. See `refs/approval-tiers.md` for the full stage-by-stage matrix.

### Tier Override

Users may override the scope-derived default:

1. **Preamble**: `tier: <strict|standard|express>` at the start of the invocation.
2. **Natural-language fallback**: keywords `"fast"`, `"quickly"`, `"autopilot"` → express; `"carefully"`, `"step by step"` → strict.

**Precedence**: preamble > natural-language inference > scope default. When user overrides, `tier_source: user` and `tier_override: <tier>` are recorded.

### Mid-Flight Tier Change

At any approval prompt, user may respond with:

```
approve and switch to <tier>
```

Where `<tier>` ∈ {strict, standard, express}. The orchestrator:

1. Accepts the current stage's approval (the user said "approve").
2. Updates front-matter: `tier: <new>`, `tier_source: mid_flight`, `tier_override: <new>`.
3. For every subsequent stage, reads the current tier and consults `refs/approval-tiers.md`.
4. Does NOT re-run completed stages. Their approvals stand.

Both upgrades (express → strict) and downgrades (strict → express) are supported. The transition is logged in the pipeline summary body: `**Stage N -- <name>**: ok <details> [tier switched to <new>]`.

### Criticality Detection

Before finalizing tier selection, the orchestrator scans for criticality signals per `agents/refs/criticality-signals.md`. Three sources, first hit wins:

1. **User flag**: preamble `critical: true`.
2. **Keyword match** in task description: `security`, `production`, `hotfix`, `critical`, `breaking`, `data loss`, `auth`, `payment`, `pii` (case-insensitive whole-word).
3. **Spec metadata**: keywords in `## Quality Gates` section of `.task/00-spec.md` (runs post-Spec).

**On detection**, orchestrator shows a one-reply gate:

```
**Criticality detected** via <source>: "<matched_term>".
Recommended tier: strict (scope default would be <default>).
[strict] (proceed with strict)
[override] (proceed with <default>)
```

- User replies `strict` → `tier: strict`, `tier_source: criticality`, `criticality_flag: true`.
- User replies `override` → `tier: <default>`, `tier_source: user`, `criticality_flag: true`, `tier_override: <default>`.

The flag stays `true` for audit in both cases. Criticality never forces strict without user confirmation (FR-014 + Edge Case: user's explicit declarations win).

**Gate is skipped** when the user already declared `tier: strict` in the preamble (nothing to recommend) or when they declared `critical: false` explicitly alongside a non-strict tier.

### Model Tier Resolution

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

For Spec:

```
> **Interactive mode**: see `agents/refs/model-tiers.md` (entry: `spec, interactive`) — sonnet
> **Validate mode**: see `agents/refs/model-tiers.md` (entry: `spec, validate`) — haiku
> **Interview mode**: see `agents/refs/model-tiers.md` (entry: `spec, interview`) — sonnet
```

**Fallback**: if `refs/model-tiers.md` is missing or unreadable, log a degradation warning and fall back to the agent's legacy inline `> **Model**:` line (if any) or to the tier shown in the SKILL.md Agent Reference table. Pipeline continues.

**Changing a tier**: edit `refs/model-tiers.md` only. Do NOT edit agent frontmatter for tier changes. Verify with quickstart paths before merging.

## Adaptive Entry

The unified Spec agent (Stage 1) auto-detects mode per its `## Mode Detection` rules in `agents/spec.md`. Three modes — `interactive`, `validate`, `interview` — one stage, one approval.

**Detection order** (first match wins, from `agents/spec.md`):
1. User preamble declares `mode: interview` → **interview** mode.
2. User invocation contains `@<path>` reference AND interview keywords ("interview", "ask me", "deep dive", "grill me") → **interview** mode.
3. User explicitly passes a file path or pastes full spec content → **validate** mode.
4. A fresh spec exists at `docs/superpowers/specs/` (mtime within last hour) → **validate** mode.
5. A TRC spec exists at `specs/<branch>/spec.md` → **validate** mode.
6. User preamble declares `mode: validate` → **validate** mode.
7. User preamble declares `mode: interactive` → **interactive** mode.
8. Otherwise → **interactive** mode.

**Mode semantics**:
- `interactive`: structured linear dialogue from scratch (Brainstormer-equivalent behavior).
- `validate`: transform a ready-made doc to canonical format + run gap/consistency/testability checks.
- `interview`: read a starting doc (or rough idea), attack hidden assumptions and tradeoffs via adaptive AskUserQuestionTool rounds, produce a sharpened spec + `## Interview Delta` showing what changed.

All modes write `.task/00-spec.md` with body + `## Validation` section. Interview mode additionally appends `## Interview Delta`. One pipeline stage, one approval (per current tier).

## Execution Strategy

### Tier 1: Agent Teams (preferred -- parallel execution)

When `agent-teams` plugin is available, use it for stages that benefit from parallelism:

**Multi-module Implementation:**
Independent modules (no dependencies per Decomposer's execution order) can run `[Research->Plan->Impl->Test]` in parallel via agent-teams. Dependent modules run sequentially.

**Review dimensions:**
```
/team-spawn review
```
Performance and Architecture reviewers run in parallel. Security is handled by `security-scanning` plugin separately.

**Debug investigation:**
```
/team-spawn debug --hypotheses 3
```
3 investigators per failure cluster, evidence-based convergence.

For all other stages -- use single-agent execution (no parallelism benefit).

### Tier 2: Subagents (fallback -- isolated context)

When `agent-teams` is unavailable but Task tool exists, spawn each agent as an independent subagent:

```
Spawn subagent:
  - Instructions: Read and follow agents/{agent}.md
  - Input: {only the files listed in Reads column}
  - Output: .task/{output file}
```

### Tier 3: Sequential (last resort)

Execute agents inline, one by one. Use the file system as memory between stages.

## Flow Control

### Approval Gates

Approval is **resolved dynamically per stage** based on the current tier. The `[approval]` label in the pipeline overview diagram is a visual hint for strict-tier behavior only — it is NOT the source of truth.

**Resolution algorithm** (applied at every stage dispatch):

1. Read current `tier` from `.task/pipeline-summary.md` front-matter (or in-memory state if updated mid-flight).
2. Look up `(stage_name, tier)` in `agents/refs/approval-tiers.md`.
3. If matrix cell = YES → present stage output, wait for explicit approval, accept mid-flight tier change if user declares it.
4. If matrix cell = no → dispatch immediately without prompting.

**Invariants**:
- **Committer always gated** (all tiers).
- **Spec completion and Decomposer completion gated** in strict and standard tiers.
- **Strict tier matches pre-redesign behavior exactly** (FR-024). Any change to strict-tier gate set is a constitution-level modification.
- **Per-section internal approvals** during Spec interactive dialogue are NOT counted as pipeline gates — they are part of the Spec stage's internal flow.

### Test/Debug Cycle

```
Cycle 1: Tester fails -> Debugger -> Implementer fixes -> Tester re-runs
Cycle 2: Still failing -> Debugger -> Implementer -> Tester
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 debug cycles. Never loop indefinitely.

### Design QA Cycle

Runs after Test/Debug cycle completes, only for UI modules with Designer output:

```
Cycle 1: Design QA fails -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs
Cycle 2: Still failing -> Implementer -> Tester -> (Debug) -> Design QA
Cycle 3: STOP -> Escalate to user with full context
```

Maximum 2 Design QA cycles. Implementer receives `08.5-design-qa-{N}.md` (Required Fixes section) as additional input during fix cycles. Code changes from Design QA fixes must pass through Tester before re-verification.

### Review Issue Routing

| Severity | Action |
|----------|--------|
| Critical | **STOP**. Present to user. Wait for decision. |
| Major | Route to Debugger -> Implementer -> Tester. Re-review. |
| Minor | Pass to Refactorer. |
| Suggestion | Note for Refactorer. Not blocking. |

### Plan Deviations

If Implementer detects a flawed plan -> STOP, report to user. User decides: adjust, re-plan, or override.

### Adaptive Pipeline

Pipeline selection is scope-driven. Authoritative `(scope, task_type) → stage list` matrix lives in `agents/refs/scope-pipelines.md`. Summary below — consult the ref for exact cell contents.

| Scope | Family | Includes |
|---|---|---|
| **XS** | minimum | Impl -> Test -> Commit (no Spec; user request is spec) |
| **S** | planned-min | Spec -> Planner -> Impl -> Test -> Commit |
| **M** | decomposed | Spec -> Scout -> Decomposer -> (Research -> Plan -> Impl -> Test)×N -> Commit |
| **L** | reviewed | M + Reviewer -> Refactorer -> Documenter |
| **XL** | designed | L + Designer -> Design-QA for UI modules |

**Task-type differentiation is preserved at every scope**: a scope-M bugfix produces a different pipeline from a scope-M feature (bugfix skips Decomposer when failure locus is known; refactor skips Debugger). See `refs/scope-pipelines.md` for the full 5×4 matrix.

**Minimum always**: Tester + Committer (every scope). Spec is skipped only at XS.

Hotfix caps at scope S — speed is critical; never escalates to decomposed pipeline even if file count would suggest M.

## Context Management

1. **File system as memory** -- agents write to `.task/`, downstream read from files
2. **Brief sections** -- every output starts with `## Brief` (5-10 lines)
3. **Pipeline summary** -- terminal agents read `pipeline-summary.md` instead of individual briefs
4. **Dependency map** -- each agent reads only what's in the Reads column
5. **Budget** -- `find`/`grep` before reading; never read files >500 lines fully; max 5-7 files in context
6. **One module at a time** -- Researcher, Planner, Implementer, and Tester process one module per run

## Starting the Pipeline

1. `mkdir -p .task`
2. **Parse invocation**: extract preamble (if present) for `scope`, `tier`, `critical`, `mode` overrides. See `## Scope Override` and (later) `## Tier Override`. Scan task description for natural-language keywords and criticality signals.
3. **Check for ready-made spec** (see Adaptive Entry). Determine initial Spec mode: `interactive` if no spec detected, `validate` otherwise.
4. Run **Stage 1 -- Spec** (`agents/spec.md`). Mode auto-detected per `## Adaptive Entry`. Writes `.task/00-spec.md` with body + `## Validation` section + `classified_scope` in front-matter. Gate per current tier (see `### Approval Tier Selection`).
5. **Classify scope** per `## Scope Classification`. Inputs: Spec Scope IN count, Key Entities count, story count, UI keywords. Compute scope and write `scope`, `scope_source`, `scope_signals` to `pipeline-summary.md` front-matter. If user override present: use it, set `scope_source: user`, `scope_override: <value>`.
6. **Select tier** per `## Approval Tier Selection` (US2). Default from scope: XS/S=express, M=standard, L/XL=strict. Apply user override and criticality gate prompt. Write `tier`, `tier_source`, `tier_override`, `criticality_flag` to front-matter.
7. **Resolve pipeline**: look up `(scope, task_type)` in `agents/refs/scope-pipelines.md`. Record `skipped_stages` list in front-matter — every stage not in the resolved pipeline gets an entry with `reason: "scope=<X>"` or `reason: "tier=<T>"`.
8. **Dispatch stages** in order from the resolved pipeline. At each stage:
   a. Resolve model tier via `agents/refs/model-tiers.md`.
   b. Resolve approval gate via `agents/refs/approval-tiers.md` for current tier.
   c. Read `agents/<stage>.md` → execute → update `pipeline-summary.md` body.
   d. If gate = YES: present output, wait for approval, accept mid-flight tier change if user declares it.
9. **Per-module loops** (M and above): inner stages (Research → Plan → Impl → Test ⇄ Debug, plus Designer/Design-QA for UI) repeat per Decomposer module, in execution order.
10. **Committer** (always last, always gated).

If request is ambiguous -- ask. Don't trigger full pipeline for simple questions.

## Resuming

1. Check `.task/` for existing artifacts.
2. Read `pipeline-summary.md` for quick context rebuild. Detect schema per `## Resume Detection` below.
3. Resume from next incomplete stage using the detected/inferred `tier` and `scope`.

**Safe default on resume**: if `.task/pipeline-summary.md` lacks front-matter, default `tier: strict`. This guarantees that a resumed pre-redesign workspace never escalates approval density above what the user had before (FR-027, SC-008).

## Resume Detection

The orchestrator detects pre-redesign (`v1`) vs redesigned (`v2`) workspaces by inspecting the first line of `.task/pipeline-summary.md`:

- First line is `---\n` → **v2 schema**. Parse YAML front-matter; read `scope`, `tier`, `scope_source`, `tier_source`, etc. Resume using stored state.
- First line is NOT `---\n` (typically `# Pipeline Summary` or empty file) → **v1 schema** (pre-redesign). Apply v1 defaults and infer where needed.

### v1 defaults on resume

| Field | Default |
|---|---|
| `tier` | `strict` (safe default — preserves pre-redesign approval density) |
| `tier_source` | `default (resume from v1)` |
| `scope` | inferred per `### Scope Inference on Resume` below |
| `scope_source` | `inferred` |
| `criticality_flag` | `false` |
| `summary_schema` | `v1` (to be upgraded per `### Schema Upgrade on Resume` below) |

### Scope Inference on Resume

If `scope` is unknown (resume from v1, or front-matter field missing), orchestrator infers from the existing body of `pipeline-summary.md`:

| Body contains line for stage | Implied scope |
|---|---|
| `Designer` or `Design-QA` | **XL** |
| `Reviewer` | **L** |
| `Decomposer` | **M** |
| `Planner` (but not Decomposer) | **S** |
| None of the above | **XS** |

Inferred scope is recorded with `scope_source: inferred`. It never overrides a user-declared scope — if the user provides a preamble on resume, their declaration wins.

### Schema Upgrade on Resume

When a v1 workspace is resumed, orchestrator prepends the YAML front-matter block to `pipeline-summary.md`:

1. Compute `tier` (default strict), `scope` (inferred), `tier_source` (`default (resume from v1)`), `scope_source` (`inferred`).
2. Compute `stage_count_expected` and `stage_count_approval_gated` based on resolved pipeline.
3. Write front-matter with `summary_schema: v1 → v2 upgraded at <ISO-8601 timestamp>`.
4. Preserve the existing body verbatim (no line changed, no stage re-ordered).

The upgrade is irreversible in-place — subsequent stages read and write v2 format. The v1 body still satisfies body-only readers (Documenter, Committer).

### Pre-redesign artifact fallback

Some pre-redesign artifacts (e.g., `.task/01-analysis.md`) are no longer produced. When resuming a v1 workspace:

- Downstream stages that previously read `01-analysis.md` (Scout, Decomposer, Tester, Committer) MAY read it as fallback when `00-spec.md` lacks the expected content (e.g., no `## Validation` section, no `classified_scope` front-matter).
- The Spec stage is NOT re-run on resume unless `00-spec.md` is missing or malformed. The pre-redesign spec body is acceptable input to Scout.

## Cleaning Up

After user commits: `rm -rf .task/` -- don't clean up automatically.
