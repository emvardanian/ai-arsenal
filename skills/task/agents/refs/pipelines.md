# Pipelines

**Load trigger**: after Spec completes, before the orchestrator dispatches any stage.

Covers the pipeline diagram, scope/tier-based stage selection, Adaptive Entry (Spec Mode Detection), and the extended pipeline-summary.md format.

## Pipeline Overview

Full pipeline (strict tier, scope L/XL). Shorter scopes skip stages per `agents/refs/scope-pipelines.md`; approval gates dissolve per tier per `agents/refs/approval-tiers.md`. Labels like `[approval*]` are strict-tier hints only — actual gating is resolved dynamically.

```
 1. Spec          -> interactive dialogue OR validate ready-made OR interview  [approval*]
                     (merges pre-redesign Brainstormer + Validator)
 2. Scout         -> light research: structure, conventions, boundaries
 3. Decomposer    -> split into modules, define execution order                [approval*]
    +-- per module ---------------------------------------------------+
    | 4. Researcher   -> deep research for module N                    |
    | 5. Planner      -> detailed plan for module N             [approval*]
    | 5.5 Designer    -> design tokens (if UI module)           [approval*]
    | 6. Implementer  -> write code for module N                [approval*]
    | 7. Tester       -> test module N                                 |
    | 8. Debugger     -> hypothesis-driven failure analysis            |
    |    back to Implementer -> Tester (max 2 cycles)                  |
    | 8.5 Design QA   -> verify impl matches design (if UI module)    |
    |    back to Implementer -> Tester -> Design QA (max 2 cycles)    |
    | 9.5 Reviewer-Lite -> per-module critical-issue scan (Cycle 2) [approval*]
    +-----------------------------------------------------------------+
 9. Reviewer      -> security (plugin) + performance + architecture
10. Refactorer    -> apply minor fixes, re-test                               [approval*]
11. Documenter    -> update docs, changelog                                   [approval*]
12. Committer     -> prepare commits + PR                                     [approval]
```

`[approval]` on Committer = always gated (every tier). `[approval*]` = gated in strict; may or may not gate in standard/express per `refs/approval-tiers.md`.

## Adaptive Pipeline

Pipeline selection is scope-driven. Authoritative `(scope, task_type) → stage list` matrix lives in `agents/refs/scope-pipelines.md`. Summary below — consult the ref for exact cell contents.

| Scope | Family | Includes |
|---|---|---|
| **XS** | minimum | Impl -> Test -> Commit (no Spec; user request is spec) |
| **S** | planned-min | Spec -> Planner -> Impl -> Test -> Commit |
| **M** | decomposed | Spec -> Scout -> Decomposer -> (Research -> Plan -> Impl -> Test -> Reviewer-Lite)×N -> Commit |
| **L** | reviewed | M + Reviewer -> Refactorer -> Documenter |
| **XL** | designed | L + Designer -> Design-QA -> Reviewer-Lite for UI modules |

**Task-type differentiation is preserved at every scope**: a scope-M bugfix produces a different pipeline from a scope-M feature (bugfix skips Decomposer when failure locus is known; refactor skips Debugger). See `refs/scope-pipelines.md` for the full 5×4 matrix.

**Minimum always**: Tester + Committer (every scope). Spec is skipped only at XS.

**Reviewer-Lite** (Cycle 2) runs per-module at M+ for feature/bugfix/refactor. Hotfix and XS/S never include it.

Hotfix caps at scope S — speed is critical; never escalates to decomposed pipeline even if file count would suggest M.

## Pipeline Summary File

After each stage completes, update `.task/pipeline-summary.md` with one line per stage.

**Extended format (schema v2)**: the file carries a YAML front-matter block at the top recording `scope`, `tier`, overrides, criticality, `skipped_stages`, and Cycle-2 delegation/review-lite fields. The body (markdown bullets) stays unchanged.

```markdown
---
scope: M
scope_source: classified
tier: standard
tier_source: default
criticality_flag: false
skipped_stages: []
# Cycle 2 additive:
delegation_mode: delegate
delegation_source: default
review_lite_enabled: true
review_lite_findings_total: 0
summary_schema: v2
---

# Pipeline Summary
- **Task**: [1-sentence description from Spec]
- **Type**: feature | **Scope**: M | **Tier**: standard | **Pipeline**: scope-m-feature
- **Stage 1 -- Spec**: ok interactive, 4 US, 12 AC, Validation PASS
- **Stage 2 -- Scout**: ok MERN stack, 4 modules identified, kebab-case conventions
- **Stage 3 -- Decomposer**: ok 3 modules (API -> Frontend -> Tests)
- **Stage 4.1 -- Researcher**: ok module 1, 6 affected files
- **Stage 5.1 -- Planner**: ok module 1, 3 files create, 2 modify [delegated via superpowers:writing-plans, 1100ms]
- **Stage 6.1 -- Implementer**: ok Plan 1 done, 3 files created, 2 modified [delegated via superpowers:executing-plans, 3400ms]
- **Stage 7.1 -- Tester**: ok 12/12 tests passed [delegated via superpowers:test-driven-development, 2100ms]
- **Stage 9.5.1 -- Reviewer-Lite**: ok module 1, verdict PASS (0 findings)
- **Stage 9 -- Reviewer**: ok PASS WITH MINOR ISSUES (0R 1Y 3G 2S)
```

Terminal agents (Documenter, Committer) read **only this file** instead of all briefs. Body-only readers MUST skip the `---` front-matter block; the body remains at `# Pipeline Summary` and below, unchanged from pre-redesign.

**Pre-redesign workspaces** (no front-matter) are detected on resume and treated as schema v1. See `refs/resume.md`.

**Skipped stages format**: every entry in the `skipped_stages` list MUST include `name` and `reason` fields. Reasons: `"scope=S"`, `"tier=express"`, `"no UI modules"`, `"hotfix skips decompose"`. This is the observability contract for FR-029.

**Front-matter fields** (full schema in `specs/task-core-redesign/contracts/pipeline-summary.md` and Cycle 2 additions in `specs/task-cycle2-integration/contracts/pipeline-summary-delta.md`):

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
| `delegation_mode` (Cycle 2) | `delegate` or `fallback` |
| `delegation_source` (Cycle 2) | `default` / `user` / `plugin_missing` / `escalation` |
| `review_lite_enabled` (Cycle 2) | Bool; true when scope ∈ {M,L,XL} ∧ task_type ≠ hotfix |
| `review_lite_findings_total` (Cycle 2) | Running total across modules |

## Classification & Pipeline Selection

After the Spec stage completes, the orchestrator classifies the task on two orthogonal axes — **scope** (size) and **tier** (approval density) — then selects the pipeline. Tier selection lives in `refs/approvals.md`.

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
3. On approval → swap pipeline per `agents/refs/scope-pipelines.md` at target scope; continue from next unexecuted stage in the new pipeline; record `scope_source: upgraded` in front-matter.
4. On rejection → continue with current scope; note mismatch in pipeline summary body.

**No automatic downgrade** mid-flight: shrinking the pipeline after approvals have happened creates confusion about which approvals were earned. When Decomposer produces fewer modules than the scope implied, report the mismatch in the pipeline summary only.

## Adaptive Entry (Spec Mode Detection)

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
