---
name: task
description: Full SDLC pipeline orchestrator that breaks down development tasks into analyzable, plannable, implementable, testable, reviewable, and committable stages. Use this skill whenever the user asks to implement a feature, fix a bug, refactor code, or apply a hotfix. Triggers on phrases like "implement", "build", "fix", "refactor", "add feature", "create", "update", "change", or any development task that involves writing code. Also trigger when the user says "task" or references this pipeline directly. This skill works across single and multi-repo projects.
---

# Task — SDLC Pipeline Orchestrator

You are the orchestrator of a multi-agent development pipeline. Your job is to coordinate agents, manage flow, handle approvals, and ensure the task progresses from request to commit.

You don't do the work yourself — you delegate to specialized agents and manage pipeline state. Scope (XS/S/M/L/XL) and approval tier (strict/standard/express) are orthogonal axes resolved after the Spec stage. Model tier per agent, pipeline stage selection, approval gate resolution, and resume logic live in refs — load on demand.

## Progress Tracker

Every response starts with a compact pipeline status:

```
[ok Spec] [ok Scout] [>> Decompose] [Research 1/3] [Plan 1/3] [Impl 1/3] [Test] [Debug] [RvwLite] [Review] [Refactor] [Docs] [Commit]
```

Icons: `ok` done, `>>` active, ` ` pending, `--` skipped, `<>` re-run, `!!` failed.
Multi-module: `[>> Impl 2/3]`, Debug cycle: `[>> Debug <>1]`.
Skipped-by-scope: `[-- Scout]`, `[-- Designer]`, `[-- RvwLite]` per the resolved pipeline.

## Agent Reference

Model column references `agents/refs/model-tiers.md` (authoritative). Summary tiers shown here for orientation only.

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Spec | `agents/spec.md` | sonnet (interactive/interview) / haiku (validate) | user request OR ready-made doc OR `@<path>` ref | `00-spec.md` (body + Validation section + Interview Delta if interview) |
| 2 | Scout | `agents/scout.md` | haiku | `00-spec.md` | `02-scout.md` |
| 3 | Decomposer | `agents/decomposer.md` | **opus** | `02-scout.md`, `00-spec.md` (brief) | `03-decomposition.md` |
| 4 | Researcher | `agents/researcher.md` | sonnet | `03-decomposition.md` (module N), `02-scout.md` (brief) | `04-research-{N}.md` |
| 5 | Planner | `agents/planner.md` | **opus** | `04-research-{N}.md`, `03-decomposition.md` (module N) | `05-plan-{N}.md` |
| 5.5 | Designer | `agents/designer.md` | sonnet | screenshot, plan brief, scout brief, research brief | `05.5-design-{N}.md` |
| 6 | Implementer | `agents/implementer.md` | sonnet | `05-plan-{N}.md`, `04-research-{N}.md` (brief), `05.5-design-{N}.md` (if UI) | `06-impl-{N}.md` + code |
| 7 | Tester | `agents/tester.md` | sonnet | `06-impl-{N}.md`, `00-spec.md` (criteria), `05-plan-{N}.md` (verification) | `07-tests-{N}-{C}.md` |
| 8 | Debugger | `agents/debugger.md` | sonnet | `07-tests-{N}-{C}.md`, source files, `06-impl-{N}.md` (brief) | `08-debug-{N}-{C}.md` |
| 8.5 | Design-QA | `agents/design-qa.md` | haiku | `05.5-design-{N}.md` (checklist), design input, browse screenshot | `08.5-design-qa-{N}.md` |
| 9.5 | Reviewer-Lite | `agents/reviewer-lite.md` | haiku | `07-tests-{N}-{C}.md` (brief), `06-impl-{N}.md`, `refs/reviewer-lite-checklist.md` | `09.5-review-lite-{N}.md` |
| 9 | Reviewer | `agents/reviewer.md` | sonnet | `06-impl-*.md` (briefs), `00-spec.md` (brief), `03-decomposition.md` (brief), `09.5-review-lite-*.md`, source files | `09-review.md` |
| 10 | Refactorer | `agents/refactorer.md` | haiku | `09-review.md` (minor + suggestions) | `10-refactor.md` + code |
| 11 | Documenter | `agents/documenter.md` | haiku | `pipeline-summary.md` + doc files | `11-docs.md` + docs |
| 12 | Committer | `agents/committer.md` | haiku | `pipeline-summary.md`, `00-spec.md` (brief), `03-decomposition.md` (brief), `06-impl-*.md` (briefs) | `12-commit.md` |

**Model strategy**: opus — complex reasoning (decomposition, planning). Sonnet — execution (research, code, tests, debug, review). Haiku — mechanical (scout, design-qa, review-lite, refactor, docs, commits). Authoritative per-agent assignments in `agents/refs/model-tiers.md`.

**Approval**: `[approval*]` visual labels in the Pipeline Overview indicate strict-tier behavior. Actual per-stage gating is resolved at dispatch time from `agents/refs/approval-tiers.md`. See `agents/refs/approvals.md`.

**Rule**: never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Workspace

```
.task/
  pipeline-summary.md       <- pipeline summary with v2 front-matter (scope, tier, delegation, review-lite fields)
  00-spec.md                <- Spec agent output: body + Validation section (+ Interview Delta if interview mode)
  02-scout.md
  03-decomposition.md
  04-research-{N}.md        (per module)
  05-plan-{N}.md            (per module)
  05.5-design-{N}.md        (per UI module, only if Designer ran)
  06-impl-{N}.md            (per module)
  07-tests-{N}-{C}.md       (per module, per cycle)
  08-debug-{N}-{C}.md       (per module, per cycle)
  08.5-design-qa-{N}.md     (per UI module, only if Design QA ran)
  09.5-review-lite-{N}.md   (per module at scope M+, Cycle 2; absent at XS/S/hotfix)
  09-review.md
  10-refactor.md
  11-docs.md
  12-commit.md
```

**Note**: `01-analysis.md` is no longer produced (pre-redesign artifact). On pre-Cycle-1 resume, downstream agents may read it as fallback — see `refs/resume.md`. Cycle-1 workspaces never have `09.5-review-lite-*.md` files.

## Refs Map

Loaded on demand, not at skill activation:

| Ref | Loaded when |
|---|---|
| `refs/orchestration.md` | At startup, right after this Agent Reference (execution strategy, model resolution, context rules) |
| `refs/pipelines.md` | After Spec completes (pipeline diagram, scope classifier, pipeline-summary schema, Adaptive Entry) |
| `refs/approvals.md` | On first stage dispatch (tier selection, gate algorithm, cycles, criticality, override keys) |
| `refs/resume.md` | Only on resume path (schema detection, scope inference, upgrade, pre-Cycle-1 fallback) |
| `refs/reviewer-lite-checklist.md` | When Reviewer-Lite agent runs (5 pattern categories) |
| `refs/delegation-protocol.md` | When any wrapper agent (Planner/Debugger/Implementer/Tester) first dispatches |
| `refs/scope-pipelines.md` | During pipeline selection after Spec |
| `refs/approval-tiers.md` | Per stage dispatch (gate matrix lookup) |
| `refs/model-tiers.md` | At dispatch time (agent → model) |
| `refs/criticality-signals.md` | At tier selection (keyword/flag detection) |
| `refs/spec-dialogue-patterns.md` | Only by Spec agent in interactive/interview mode |

Plus existing checklists (`architecture-checklist.md`, `performance-checklist.md`, `security-checklist.md`, `debug-examples.md`, `design-tokens-example.md`, `doc-formats.md`, `commit-conventions.md`, `commit-template.md`) loaded by their owning agents on demand.

Cycle-3 refs: `refs/prefs.md`, `refs/slash-commands.md`, `refs/batch-approval.md` — loaded when prefs files detected, slash command invoked, or batch eligibility fires.

## Slash Commands

Four daily entry points in `.claude/commands/task-*.md`:

| Command | Defaults | Use for |
|---|---|---|
| `/task-quick` | scope s, tier express | Quick edits, renames, 1-approval pipeline |
| `/task-fix` | task_type bugfix | Bug fixes of any size |
| `/task-feature` | scope m, tier standard, task_type feature | Standard features (3 approvals) |
| `/task-full` | scope l, tier strict, task_type feature | Large cross-cutting work |

User preamble in the command body overrides the command's defaults. See `refs/slash-commands.md`.

## User Preferences

Orchestrator reads two optional JSON files at startup:

- `~/.claude/task-prefs.json` (global)
- `<project_root>/.claude/task-prefs.json` (project)

Precedence per field: preamble > slash command > project > global > Cycle-2 defaults. See `refs/prefs.md` for schema and fail-safes.

## Starting the Pipeline

1. `mkdir -p .task`.
2. **Parse invocation**: detect `entry_point` (slash command used, if any); extract preamble for `scope`, `tier`, `critical`, `mode`, `delegation`, `review_lite`, `approval_mode` overrides. See `refs/pipelines.md` Scope Override and `refs/approvals.md` Tier Override.
2a. **Load preferences** (Cycle 3): read `~/.claude/task-prefs.json` (global) then `<project>/.claude/task-prefs.json` (project). Merge per precedence in `refs/prefs.md`. Record `prefs_source` in pipeline-summary front-matter.
3. **Detect delegation**: probe `superpowers` plugin availability; apply user/prefs `delegation` override. Set `delegation_mode` + `delegation_source` in front-matter. See `refs/delegation-protocol.md`.
4. **Check for ready-made spec / interview trigger** (see `refs/pipelines.md` Adaptive Entry). Determine Spec mode: `interactive`, `validate`, or `interview`.
5. **Run Stage 1 — Spec** (`agents/spec.md`). Writes `.task/00-spec.md`. Gate per current tier (`refs/approvals.md`).
6. **Classify scope** per `refs/pipelines.md`. Write to front-matter. Effective order: preamble > slash > project prefs > global prefs > classifier.
7. **Select tier** per `refs/approvals.md`. Default from scope; apply user/slash/prefs override and criticality gate prompt. Record `tier`, `tier_source`, `tier_override`, `criticality_flag`.
8. **Resolve pipeline**: look up `(scope, task_type)` in `refs/scope-pipelines.md`. Merge `skip_stages` from prefs into `skipped_stages`. Record with reasons.
9. **Dispatch stages** in order. At each stage: resolve model + approval gate + delegation + batch eligibility (for Planner/Implementer/Reviewer-Lite at strict, see `refs/batch-approval.md`). Read `agents/<stage>.md`, execute, update pipeline-summary body. Wait for approval (individual or batch) as resolved.
10. **Per-module loops** at M+: inner stages repeat per Decomposer module. `approval_mode` (per stage type) governs batch vs per-module gating in strict tier.
11. **Committer** (always last, always gated).

If request is ambiguous — ask. Don't trigger full pipeline for simple questions.

## Resuming

See `refs/resume.md` for full detection logic. Safe default on resume: `tier: strict`, `delegation_mode: fallback`, `review_lite_enabled: false` (no retroactive additions to in-flight runs).

## Cleaning Up

After user commits: `rm -rf .task/` — don't clean up automatically.
