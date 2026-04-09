# Implementation Plan: Pipeline Restructuring

**Spec**: `specs/pipeline-restructuring/spec.md`
**Design Doc**: `docs/superpowers/specs/2026-04-08-pipeline-restructuring-design.md`

## Approach

Pure markdown editing -- no build, no tests, no runtime. All changes are to agent definition files and the SKILL.md orchestrator. The design doc provides exact output formats and constraints for each agent.

Changes are grouped by dependency: new agents first (Scout, Decomposer), then restructured agents (Researcher, Planner), then SKILL.md (central orchestrator), then downstream agents (all reference new file numbering), then the new reference file.

## Module 1: New Agents -- Scout and Decomposer

**Goal**: Create the two new pipeline stages that sit between Analyst and Researcher.

**Files**:
- CREATE `skills/task/agents/scout.md`
- CREATE `skills/task/agents/decomposer.md`

**Steps**:

1. Create `agents/scout.md` following the design doc's Scout section:
   - Model: sonnet
   - Input: `.task/01-analysis.md` (full)
   - Process: 4 steps -- project structure scan, conventions discovery, module boundaries, affected zone scan
   - Output: `.task/02-scout.md` with sections: Brief, Project Structure, Conventions, Module Boundaries, Affected Zone
   - Constraints: max 10-15 files (headers/imports only), no full reads, no approval gate
   - Follow existing agent file conventions: `# Agent Name`, `> **Model**: X`, Role, Inputs, Process, Output, Guidelines

2. Create `agents/decomposer.md` following the design doc's Decomposer section:
   - Model: opus
   - Input: `.task/02-scout.md` (full), `.task/01-analysis.md` (Brief only)
   - Process: 5 steps -- map criteria to modules, group changes, identify dependencies, define execution order, define each module
   - Output: `.task/03-decomposition.md` with sections: Brief, Acceptance Criteria Mapping, Module N (goal, scope, criteria, depends on, research hints, UI flag), Execution Order
   - Constraints: no specific files, no implementation steps, no direct codebase reads, has approval gate
   - Include Step 6: Present for Approval

**Covers**: AC-1 through AC-7

## Module 2: Restructured Agents -- Researcher and Planner

**Goal**: Transform Researcher from global scan to per-module deep research. Transform Planner from decompose+plan to single-module plan only.

**Files**:
- MODIFY `skills/task/agents/researcher.md`
- MODIFY `skills/task/agents/planner.md`

**Steps**:

3. Rewrite `agents/researcher.md`:
   - Change inputs: `03-decomposition.md` (module N section) + `02-scout.md` (Brief only)
   - Change output: `04-research-{N}.md` (one per module)
   - Process: read code within module scope, trace dependencies, find existing tests, search analogous implementations, note area conventions
   - Output sections: Brief, Affected Files, Dependencies, Existing Tests, Analogous Implementations, Area-Specific Conventions
   - Constraints: max 5-7 files full read, one module's scope only, no approval gate
   - Keep context7 integration note
   - Remove: global project structure scan (Scout does this), tech stack discovery (Scout does this), conventions discovery (Scout does this)

4. Rewrite `agents/planner.md`:
   - Change inputs: `04-research-{N}.md` (full) + `03-decomposition.md` (Module N section)
   - Change output: `05-plan-{N}.md` (one per module)
   - Remove: Step 2 (single vs multi-plan estimate), Step 3 (execution order), Step 5 (criteria mapping), Overview section, Acceptance Criteria Mapping section, Execution Flow section
   - Keep: Step to load context, step to write plan (Objective, Files, Steps, Conventions, Verification), step to present for approval
   - Output sections: Brief, Objective, Files, Steps, Conventions, Verification
   - Has approval gate per plan
   - Update guidelines: remove "One plan = one Implementer run" (already guaranteed by Decomposer), update decomposition references

**Covers**: AC-8 through AC-14

## Module 3: SKILL.md Orchestrator Update

**Goal**: Update the central orchestrator with new pipeline, agent table, workspace, adaptive pipeline, progress tracker, and remove TODOs.

**Files**:
- MODIFY `skills/task/SKILL.md`

**Steps**:

5. Update Pipeline Overview:
   - New pipeline diagram with 0-12 numbering per design doc
   - Per-module loop wraps stages 4-8.5 (Researcher through Design QA)
   - Approval gates on: Brainstormer, Validator, Decomposer, Planner (per plan), Implementer, Refactorer, Documenter

6. Update Agent Reference table:
   - Add Scout (#2) and Decomposer (#3)
   - Renumber: Researcher=#4, Planner=#5, Designer=#5.5, Implementer=#6, Tester=#7, Debugger=#8, Design QA=#8.5, Reviewer=#9, Refactorer=#10, Documenter=#11, Committer=#12
   - Update all Reads/Writes columns to new file numbering

7. Update Workspace section:
   - New file listing with numbering: 02-scout.md, 03-decomposition.md, 04-research-{N}.md, 05-plan-{N}.md, 05.5-design-{N}.md, 06-impl-{N}.md, 07-tests-{N}-{C}.md, 08-debug-{N}-{C}.md, 08.5-design-qa-{N}.md, 09-review.md, 10-refactor.md, 11-docs.md, 12-commit.md
   - Remove TODO comment about renumbering

8. Update Progress Tracker:
   - Add Scout and Decompose stages
   - New format per design doc: `[ok Scout] [>> Decompose] [Research 1/3] ...`

9. Update Adaptive Pipeline table:
   - feature: All stages
   - feature + design: All stages + Designer + Design QA for UI modules
   - bugfix: Analyst -> Scout -> Decomposer -> [Research->Plan->Impl->Test<->Debug] -> Commit
   - refactor: Analyst -> Scout -> Decomposer -> [Research->Refactor->Review->Test] -> Commit
   - hotfix: Analyst -> [Impl->Test<->Debug] -> Commit (no Scout/Decomposer)

10. Update Design QA Cycle section:
    - Change stage number to 8.5
    - Change file refs to `08.5-design-qa-{N}.md`
    - Remove TODO comment

11. Update Pipeline Summary File section if needed (ensure stage numbering matches)

12. Update Adaptive Entry section -- after Validator, continue to Scout (Stage 2), not Researcher

13. Update Starting the Pipeline section -- add Scout and Decomposer steps after Analyst

14. Remove all remaining TODO comments about pipeline restructuring

**Covers**: AC-15 through AC-21

## Module 4: Downstream Agent Updates

**Goal**: Update all remaining agents to reference new file numbering.

**Files**:
- MODIFY `skills/task/agents/implementer.md`
- MODIFY `skills/task/agents/tester.md`
- MODIFY `skills/task/agents/debugger.md`
- MODIFY `skills/task/agents/design-qa.md`
- MODIFY `skills/task/agents/designer.md`
- MODIFY `skills/task/agents/reviewer.md`
- MODIFY `skills/task/agents/refactorer.md`
- MODIFY `skills/task/agents/documenter.md`
- MODIFY `skills/task/agents/committer.md`

**Steps**:

15. Update `implementer.md`:
    - Inputs: `05-plan-{N}.md` (current plan), `04-research-{N}.md` (Brief only), `05.5-design-{N}.md` (if exists)
    - Output: `06-impl-{N}.md`
    - Update all references in text (03-plan.md -> 05-plan-{N}.md, 02-research.md -> 04-research-{N}.md, 03.5-design.md -> 05.5-design-{N}.md, 04-impl -> 06-impl)

16. Update `tester.md`:
    - Inputs: `06-impl-{N}.md`, `01-analysis.md` (criteria), `05-plan-{N}.md` (verification)
    - Output: `07-tests-{N}-{C}.md`
    - Update all references (04-impl -> 06-impl, 03-plan.md -> 05-plan-{N}.md, 05-tests -> 07-tests)

17. Update `debugger.md`:
    - Inputs: `07-tests-{N}-{C}.md`, source files, `06-impl-{N}.md` (Brief only)
    - Output: `08-debug-{N}-{C}.md`
    - Update cycle 2 ref: `08-debug-{N}-1.md`
    - Update all references (05-tests -> 07-tests, 04-impl -> 06-impl, 06-debug -> 08-debug)

18. Update `designer.md`:
    - Inputs: Figma/screenshot, `05-plan-{N}.md` (brief), `02-scout.md` (brief), `04-research-{N}.md` (brief)
    - Output: `05.5-design-{N}.md`
    - Remove all TODO comments
    - Update NO_DESIGN warning file ref

19. Update `design-qa.md`:
    - Stage: 8.5
    - Activation: check `05.5-design-{N}.md`
    - Inputs: `05.5-design-{N}.md` (checklist), design input, browse screenshot
    - Output: `08.5-design-qa-{N}.md`
    - Remove all TODO comments
    - Update FAIL cycle refs

20. Update `reviewer.md`:
    - Inputs: `06-impl-*.md` (briefs), `01-analysis.md` (brief), `03-decomposition.md` (brief), source files
    - Output: `09-review.md`
    - Update all references (04-impl -> 06-impl, 03-plan.md -> 03-decomposition.md, 07-review.md -> 09-review.md)

21. Update `refactorer.md`:
    - Inputs: `09-review.md`
    - Output: `10-refactor.md`
    - Update references (07-review.md -> 09-review.md, 08-refactor.md -> 10-refactor.md)

22. Update `documenter.md`:
    - Output: `11-docs.md`
    - Update reference (09-docs.md -> 11-docs.md)

23. Update `committer.md`:
    - Inputs: pipeline-summary.md, `01-analysis.md` (brief), `03-decomposition.md` (brief), `06-impl-*.md` (briefs)
    - Output: `12-commit.md`
    - Update all references (03-plan.md -> 03-decomposition.md, 04-impl -> 06-impl, 08-refactor.md -> 10-refactor.md, 09-docs.md -> 11-docs.md, 10-commit.md -> 12-commit.md)

**Covers**: AC-22 through AC-30

## Module 5: Commit Conventions Reference

**Goal**: Create a comprehensive conventional commit reference for the Committer agent.

**Files**:
- CREATE `skills/task/agents/refs/commit-conventions.md`

**Steps**:

24. Create `agents/refs/commit-conventions.md`:
    - Type values: feat, fix, refactor, docs, test, chore, perf, ci -- with descriptions
    - Scope naming: lowercase, kebab-case, module/feature name
    - Format: `<type>(<scope>): <description>` + body + footer
    - Body: imperative mood, explain WHY not WHAT, wrap at 72 chars
    - Footer: `Closes #N`, `BREAKING CHANGE: description`
    - Breaking change notation: `!` after type/scope OR `BREAKING CHANGE:` footer
    - Good/bad examples (expand from existing commit-template.md)

25. Update `committer.md` to reference `agents/refs/commit-conventions.md` instead of (or in addition to) `agents/refs/commit-template.md`

**Covers**: AC-31, AC-32

## Execution Order

Module 1 (new agents) and Module 5 (commit conventions) have no dependencies -- can run in parallel.
Module 2 (researcher/planner rewrite) depends on understanding Module 1 outputs but not the files themselves.
Module 3 (SKILL.md) depends on knowing all agent names and numbering.
Module 4 (downstream updates) depends on Module 3 for final numbering.

Recommended: Module 1 -> Module 2 -> Module 3 -> Module 4 -> Module 5

For parallel execution: [Module 1 + Module 5] -> Module 2 -> Module 3 -> Module 4

## Verification

After all modules complete:
- [ ] `grep -r "TODO.*pipeline restructuring" skills/task/` returns no results
- [ ] All file numbers in SKILL.md agent table match the corresponding agent file inputs/outputs
- [ ] Every agent declares model, inputs, outputs
- [ ] Workspace file listing matches agent outputs
- [ ] Adaptive Pipeline table includes Scout and Decomposer for non-hotfix types
- [ ] Progress Tracker format matches new stage names
