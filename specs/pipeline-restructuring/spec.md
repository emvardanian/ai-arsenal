# Spec: Pipeline Restructuring -- Hybrid Research + Decomposition

**Feature Branch**: `pipeline-restructuring`
**Created**: 2026-04-09
**Status**: Draft
**Design Doc**: `docs/superpowers/specs/2026-04-08-pipeline-restructuring-design.md`

## Summary

Restructure the Task skill pipeline from global-research-then-plan to decompose-then-research-per-module. Add Scout (light recon) and Decomposer (module splitting) agents, restructure Researcher to per-module deep research, restructure Planner to single-module planning, update all downstream agents to new file numbering, and create commit-conventions reference.

## User Stories

- US1 [P1]: As a pipeline orchestrator, I want a Scout agent that scans project structure, conventions, and affected zones, so that the Decomposer has enough context to split the task into modules without reading every file.
  - AC-1: `agents/scout.md` exists with model=sonnet, reads `01-analysis.md`, writes `02-scout.md`
  - AC-2: Scout output has sections: Brief, Project Structure, Conventions, Module Boundaries, Affected Zone
  - AC-3: Scout has constraints: max 10-15 files scanned (headers/imports only), no full file reads, no approval gate

- US2 [P1]: As a pipeline orchestrator, I want a Decomposer agent that splits the task into logical modules with execution order, so that downstream agents (Researcher, Planner, Implementer) work on focused, independent scopes.
  - AC-4: `agents/decomposer.md` exists with model=opus, reads `02-scout.md` (full) + `01-analysis.md` (brief), writes `03-decomposition.md`
  - AC-5: Decomposer output has sections: Brief, Acceptance Criteria Mapping, Module N (goal, scope, criteria, depends on, research hints, UI flag), Execution Order
  - AC-6: Decomposer has approval gate
  - AC-7: Decomposer does NOT list specific files to modify, does NOT define implementation steps, does NOT read codebase directly

- US3 [P1]: As a pipeline orchestrator, I want the Researcher restructured to per-module deep research, so that each module gets focused, relevant research instead of one bloated global pass.
  - AC-8: `agents/researcher.md` reads `03-decomposition.md` (module N section) + `02-scout.md` (brief), writes `04-research-{N}.md`
  - AC-9: Researcher output has sections: Brief, Affected Files, Dependencies, Existing Tests, Analogous Implementations, Area-Specific Conventions
  - AC-10: Researcher constraints: max 5-7 files full read, focused on one module's scope, no approval gate

- US4 [P1]: As a pipeline orchestrator, I want the Planner restructured to single-module detailed planning (no decomposition), so that each plan is concrete and focused on one module's research.
  - AC-11: `agents/planner.md` reads `04-research-{N}.md` (full) + `03-decomposition.md` (module N section), writes `05-plan-{N}.md`
  - AC-12: Planner no longer has decomposition logic (Step 2 estimate, Step 3 execution order, Acceptance Criteria Mapping, Execution Flow -- all removed)
  - AC-13: Planner output: Brief, Objective, Files, Steps, Conventions, Verification
  - AC-14: Planner has approval gate per plan

- US5 [P1]: As a pipeline orchestrator, I want SKILL.md updated with the new pipeline, agent table, workspace numbering, adaptive pipeline, and progress tracker, so that the orchestrator follows the restructured flow.
  - AC-15: SKILL.md pipeline overview shows: 0.Brainstormer, 1.Validator, 2.Scout, 3.Decomposer, 4.Researcher(per-module), 5.Planner(per-module), 5.5.Designer(per-module), 6.Implementer, 7.Tester, 8.Debugger, 8.5.Design QA, 9.Reviewer, 10.Refactorer, 11.Documenter, 12.Committer
  - AC-16: Agent Reference table updated with new numbering, new agents, new file refs
  - AC-17: Workspace section uses new numbering: 02-scout.md, 03-decomposition.md, 04-research-{N}.md, 05-plan-{N}.md, 05.5-design-{N}.md, 06-impl-{N}.md, 07-tests-{N}-{C}.md, 08-debug-{N}-{C}.md, 08.5-design-qa-{N}.md, 09-review.md, 10-refactor.md, 11-docs.md, 12-commit.md
  - AC-18: All TODO comments about "After pipeline restructuring merges" removed
  - AC-19: Adaptive Pipeline table updated with Scout and Decomposer stages
  - AC-20: Progress Tracker updated with new stages
  - AC-21: Design QA Cycle section updated to new numbering (08.5-design-qa-{N}.md)

- US6 [P2]: As a pipeline orchestrator, I want all downstream agents updated to reference new file numbering, so that the full pipeline is internally consistent.
  - AC-22: `implementer.md` reads `05-plan-{N}.md` (current plan), `04-research-{N}.md` (brief), `05.5-design-{N}.md` (if UI), writes `06-impl-{N}.md`
  - AC-23: `tester.md` reads `06-impl-{N}.md`, `01-analysis.md` (criteria), `05-plan-{N}.md` (verification), writes `07-tests-{N}-{C}.md`
  - AC-24: `debugger.md` reads `07-tests-{N}-{C}.md`, source files, `06-impl-{N}.md` (brief), writes `08-debug-{N}-{C}.md`
  - AC-25: `design-qa.md` updated: Stage 8.5, checks `05.5-design-{N}.md`, writes `08.5-design-qa-{N}.md`, all TODO comments removed
  - AC-26: `designer.md` updated: reads `05-plan-{N}.md` (brief), `02-scout.md` (brief), `04-research-{N}.md` (brief), writes `05.5-design-{N}.md`, all TODO comments removed
  - AC-27: `reviewer.md` reads `06-impl-*.md` (briefs), `01-analysis.md` (brief), `03-decomposition.md` (brief), source files, writes `09-review.md`
  - AC-28: `refactorer.md` reads `09-review.md`, writes `10-refactor.md`
  - AC-29: `documenter.md` reads `pipeline-summary.md` + doc files, writes `11-docs.md`
  - AC-30: `committer.md` reads `pipeline-summary.md`, `01-analysis.md` (brief), `03-decomposition.md` (brief), `06-impl-*.md` (briefs), writes `12-commit.md`

- US7 [P2]: As a Committer agent, I want a `refs/commit-conventions.md` reference doc with complete conventional commit rules, so that I produce correct commit messages without guessing.
  - AC-31: `agents/refs/commit-conventions.md` exists with: type values (feat, fix, refactor, docs, test, chore, perf, ci), scope naming rules, body/footer format, breaking change notation (BREAKING CHANGE footer, ! after type)
  - AC-32: Committer agent references `agents/refs/commit-conventions.md` (replaces current `refs/commit-template.md` reference)

## Quality Gates

- QG-1: Every agent file declares inputs, outputs, and model tier
- QG-2: No agent reads files outside its declared inputs
- QG-3: All TODO comments about pipeline restructuring are removed from all files
- QG-4: SKILL.md pipeline overview, Agent Reference table, Workspace section, Adaptive Pipeline, and Progress Tracker are all internally consistent with each other
- QG-5: File numbering is consistent across SKILL.md and all agent files

## Edge Cases

- EC-1: Single-module tasks still go through full flow (Scout -> Decomposer -> Research -> Plan) per design doc -- Decomposer produces 1 module
- EC-2: Hotfix exception: Analyst -> [Impl->Test<->Debug] -> Commit (skips Scout/Decomposer for speed)
- EC-3: Designer activation uses `ui: true` flag from Decomposer, not a separate detection mechanism
- EC-4: Design QA checks for `05.5-design-{N}.md` (not old `03.5-design.md`) to determine if it should run

## Scope

### In
- Create `agents/scout.md` and `agents/decomposer.md`
- Rewrite `agents/researcher.md` and `agents/planner.md`
- Update `SKILL.md` pipeline, agent table, workspace, adaptive pipeline, progress tracker
- Update all downstream agent input/output refs
- Create `agents/refs/commit-conventions.md`
- Remove all pipeline-restructuring TODO comments

### Out
- No changes to `agents/brainstormer.md` or `agents/analyst.md`
- No changes to ref files other than creating `commit-conventions.md`
- No runtime or build changes (pure markdown project)
- No changes to other skills (lander, redesign)
- No implementation of Tier 1 parallel execution (agent-teams integration) -- that's a separate feature
