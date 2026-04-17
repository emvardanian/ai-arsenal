# Implementation Plan: Task Skill Cycle 2 — Integration

**Branch**: `task-cycle2-integration` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)

## Summary

Three integration changes to `skills/task/`:

1. **Per-module Review-Lite** — new haiku agent `agents/reviewer-lite.md` runs after each module's Tester at scope M+, catching critical issues (secrets, N+1, missing error handling) early. Complements, not replaces, the final Reviewer.
2. **SKILL.md split** — 537-line `SKILL.md` → thin ~100-line shell + four refs (`orchestration.md`, `pipelines.md`, `approvals.md`, `resume.md`). Zero behavior change, zero prose loss.
3. **Superpowers delegation** — Planner, Debugger, Implementer, Tester become thin wrappers over `superpowers:writing-plans`, `systematic-debugging`, `executing-plans`, `test-driven-development`. Auto-fallback to inline behavior when plugin missing or call fails. User override via `delegation: disable` preamble.

Backward compat (US4): strict tier adds exactly N Review-Lite gates per module; all other approvals, artifact names, stage order preserved. Pre-Cycle-2 workspaces resume cleanly.

## Technical Context

**Language/Version**: Markdown (CommonMark); YAML frontmatter for skill/agent metadata
**Primary Dependencies**: Claude Code CLI; optional `superpowers` plugin (graceful fallback when missing); existing plugins from Cycle 1
**Storage**: File system only — `skills/task/`, `.task/` workspace
**Testing**: Manual per constitution; verification runs documented in `quickstart.md`
**Target Platform**: Claude Code (CLI), Desktop, Web, IDE extensions
**Project Type**: Toolkit / skill collection (markdown)
**Performance Goals**: SKILL.md ≤120 lines (SC-003); scope-L wall-clock -25% via early bug catching (SC-002); zero prose loss on split (SC-004)
**Constraints**: Strict tier approval count = Cycle 1 + N (Review-Lite); pre-Cycle-2 resume without errors; superpowers fallback preserves Cycle 1 artifacts exactly
**Scale/Scope**: 1 skill (Task), 14 agents (+1 new Review-Lite = 15), ~13 refs → ~19 refs

## Constitution Check

Against `.trc/memory/constitution.md`:

| Mandate | Status | Notes |
|---|---|---|
| Markdown-only, no runtime/build/tests | PASS | All artifacts markdown |
| File-based communication | PASS | `.task/` preserved + new `09.5-review-lite-{N}.md` |
| Progressive disclosure (3 levels) | REINFORCED | SKILL.md shrinks ≥75%; refs load on demand |
| Adaptive pipeline | EXTENDED | Review-Lite is new conditional stage per scope |
| Plugin delegation with fallback | REINFORCED | Superpowers delegation adds fallback at agent-wrapper layer |
| Brief sections | PASS | Review-Lite preserves Brief format |
| Agent declarations | PASS | `reviewer-lite.md` declares inputs/outputs/model tier per pattern |
| Refs on-demand | STRENGTHENED | Four new orchestration refs |
| Git workflow | PASS | Branch `task-cycle2-integration`, worktree isolation |

**Gate outcome**: PASS. Design reinforces several mandates. No violations.

## Project Structure

```text
specs/task-cycle2-integration/
├── spec.md
├── plan.md
├── research.md                          # Phase 0
├── data-model.md                        # Phase 1
├── quickstart.md                        # Phase 1
├── contracts/                           # Phase 1
│   ├── skill-md-shell.md
│   ├── refs-layout.md
│   ├── reviewer-lite-output.md
│   ├── delegation-wrapper.md
│   └── pipeline-summary-delta.md
├── checklists/requirements.md
└── tasks.md                             # Phase 2 (/trc.tasks)
```

### Source changes scoped to `skills/task/`:

```text
skills/task/
├── SKILL.md                             # REWRITE: 537 -> ≤120 lines (thin shell)
├── agents/
│   ├── planner.md                       # MODIFY: thin wrapper + inline fallback
│   ├── implementer.md                   # MODIFY: thin wrapper + inline fallback
│   ├── tester.md                        # MODIFY: thin wrapper + inline fallback
│   ├── debugger.md                      # MODIFY: thin wrapper + inline fallback
│   ├── reviewer-lite.md                 # NEW: haiku per-module reviewer
│   ├── reviewer.md                      # MODIFY: read 09.5-* + dedupe
│   ├── (10 other agents unchanged: spec, scout, decomposer, researcher, designer, design-qa, refactorer, documenter, committer)
│   └── refs/
│       ├── orchestration.md             # NEW (extract from SKILL.md)
│       ├── pipelines.md                 # NEW (extract)
│       ├── approvals.md                 # NEW (extract)
│       ├── resume.md                    # NEW (extract)
│       ├── reviewer-lite-checklist.md   # NEW (slim critical-issues checklist)
│       ├── delegation-protocol.md       # NEW (wrapper call rules + fallback)
│       ├── scope-pipelines.md           # MODIFY: add Review-Lite to M/L/XL cells
│       ├── approval-tiers.md            # MODIFY: add reviewer-lite row
│       ├── model-tiers.md               # MODIFY: add reviewer-lite row
│       └── (existing refs unchanged)
```

**Structure Decision**: Single-project toolkit. Changes scoped to `skills/task/`. 4 new orchestration refs (split) + 2 new agent-specific refs (reviewer-lite-checklist, delegation-protocol), 1 new agent (reviewer-lite), 5 modified agents (planner, implementer, tester, debugger, reviewer).

## Complexity Tracking

| Decision | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| 4-way SKILL.md split (not 2 or 3) | Each ref covers a distinct orchestrator concern (execution strategy, pipeline matrix, approval gates, resume). Merging couples unrelated decisions. | 2-way split (shell + mega-ref) preserves bloat; 3-way blurs resume into approvals or pipelines. 4-way keeps refs focused + loadable independently. |
| Review-Lite as separate agent (not extension of Tester or final Reviewer) | Tester is non-blocking by design; adding review logic changes semantics. Final Reviewer is cross-cutting; per-module ≠ cross-cutting. | Bolt-on to Tester makes Tester dual-purpose. Making final Reviewer per-module loses cross-cutting view. |
| Review-Lite per-module approval in strict tier | FR-005 requires strict gate per module. Without per-module gate, strict users lose visibility on critical findings before next module. | Single final Review-Lite gate defeats early-catch purpose. No gate in strict contradicts strict's promise. |
| Superpowers wrappers with inline fallback baked into every wrapper file | Skill must function standalone regardless of plugin state. Fallback logic is per-agent because each invokes a different superpowers skill. | Centralized fallback-dispatcher adds indirection that complicates every invocation. Per-agent fallback is local, testable, obvious. |
| `delegation_mode` immutable per run | Mid-run switching creates ambiguity about which artifacts belong to which mode. Simpler contract: decide at start. | Mid-run switching would require per-stage mode flags in front-matter and reconciliation. Not worth the complexity. |

All decisions tracked here are intentional design choices, not waivers. No constitution violations.

## Phase 0: Outline & Research

See [research.md](./research.md). Key decisions:

1. SKILL.md split boundaries — four refs matching orchestrator concerns.
2. Review-Lite checklist — 5 categories of pattern-matchable critical issues.
3. Review-Lite severity mapping — Critical (Debug cycle), Minor (passed to final Reviewer).
4. Superpowers delegation scope — Planner, Debugger, Implementer, Tester only.
5. Fallback trigger points — startup, per-call, user override.
6. Wrapper contract — per-agent input glue + output adapter, in `refs/delegation-protocol.md`.
7. Pipeline summary additions — `delegation_mode`, per-stage delegation lines.
8. Scope matrix change — Review-Lite added to M/L/XL feature/refactor cells; bugfix M/L; hotfix never.

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](./data-model.md). Entities: ReviewerLiteFinding, DelegationMode, WrapperInvocationResult, SkillMetadata, RefsMap, ReviewLiteOutput, Extended PipelineSummary.

### Contracts

Under `./contracts/`:

1. **skill-md-shell.md** — SKILL.md shell structure, ≤120 lines.
2. **refs-layout.md** — topic mapping from pre-split to post-split (zero-loss proof).
3. **reviewer-lite-output.md** — `.task/09.5-review-lite-{N}.md` schema.
4. **delegation-wrapper.md** — wrapper call protocol, fallback triggers, logging.
5. **pipeline-summary-delta.md** — additive front-matter fields introduced by Cycle 2.

### Quickstart

See [quickstart.md](./quickstart.md). Three paths: scope-M delegated, scope-L with intentional bug (Review-Lite catch), scope-M user-forced fallback. Plus backward-compat resume test and strict-tier approval-count diff.

## Post-Design Constitution Re-Check

To be updated after Phase 1 artifacts; expected PASS unchanged.
