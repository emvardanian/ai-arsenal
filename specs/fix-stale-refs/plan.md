# Implementation Plan: Fix Stale Doc References in Task Skill

**Branch**: `fix-stale-refs` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/fix-stale-refs/spec.md`

## Summary

Apply 5 single-line edits across 5 markdown files in `skills/task/` to synchronize stale documentation references with the Cycle 1-3 redesigned pipeline. Three agent files (scout, decomposer, committer) must reference `.task/00-spec.md` instead of the deprecated `.task/01-analysis.md`. `documenter.md` must reference `06-impl-{N}.md` instead of the typo `04-impl-{N}.md`. `refs/model-tiers.md` must reflect Spec's three modes (interactive/validate/interview) in its tier-distribution count, reader-contract prose, example block, and invariants. Fallback references to `01-analysis.md` in `reviewer.md`, `tester.md`, `resume.md`, and `SKILL.md` are explicitly preserved.

## Technical Context

**Language/Version**: Markdown (CommonMark) — no programming language involved.
**Primary Dependencies**: None. Project is a toolkit collection of markdown skills/agent definitions.
**Storage**: Filesystem only (git-tracked markdown files).
**Testing**: Manual `grep` verification against the acceptance criteria in `spec.md`. No test framework.
**Target Platform**: Claude Code CLI skill directory (`~/.claude/skills/` and project `skills/`).
**Project Type**: Toolkit / documentation collection (`tricycle.config.yml` declares `type: toolkit`, `package_manager: none`).
**Performance Goals**: N/A — documentation edits.
**Constraints**: Documentation-only. No behavioral, structural, or runtime change. No new files. Fallback references in reviewer/tester/resume/SKILL untouched.
**Scale/Scope**: 5 files, ~8 line edits total.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution at `.trc/memory/constitution.md` was read during session start. Key gates:

- **Identity** (AI Arsenal = modular markdown toolkit): PASS — edits stay within `skills/task/`, no new stack.
- **Architecture** (markdown files, no build step, no tests): PASS — no runtime or build changes.
- **Patterns** (file-based agent communication, progressive disclosure, brief sections): PASS — edits preserve input/output contracts in every touched agent file; only the *paths* named in Inputs sections change, and only to match the pipeline's actual output filenames.
- **Git Workflow** (base branch `main`, feature branches, conventional commits, squash merge): PASS — branch `fix-stale-refs` created; commit will use `docs(task):` prefix.
- **Service Boundaries** (single app, self-contained skills): PASS — no cross-skill changes.
- **Quality Standards** (SKILL.md format, declared inputs/outputs/model tier, refs load on demand): PASS — the edits *restore* input declarations to their correct state; model-tiers invariants are strengthened.

No gate violations. Complexity Tracking section empty.

## Project Structure

### Documentation (this feature)

```text
specs/fix-stale-refs/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (entity: edit site)
├── quickstart.md        # Phase 1 output (verification commands)
├── contracts/           # Phase 1 output (one contract per edit)
│   ├── scout-input-ref.md
│   ├── decomposer-input-ref.md
│   ├── committer-input-ref.md
│   ├── documenter-impl-filename.md
│   └── model-tiers-three-modes.md
└── tasks.md             # Phase 2 output (/trc.tasks command)
```

### Source Code (repository root)

No source code. Edits target existing markdown files:

```text
skills/task/
├── SKILL.md                            # unchanged (contains explanatory reference, preserved per FR-009)
└── agents/
    ├── scout.md                        # EDIT: Inputs line -> 00-spec.md
    ├── decomposer.md                   # EDIT: Inputs line -> 00-spec.md
    ├── committer.md                    # EDIT: Inputs list item -> 00-spec.md
    ├── documenter.md                   # EDIT: line 16 -> 06-impl-{N}.md
    ├── reviewer.md                     # unchanged (legitimate fallback per FR-009)
    ├── tester.md                       # unchanged (legitimate fallback per FR-009)
    └── refs/
        ├── model-tiers.md              # EDIT: tier count, reader contract, example block, invariant
        └── resume.md                   # unchanged (legitimate fallback per FR-009)
```

**Structure Decision**: Direct in-place edits to the 5 files listed under `skills/task/` above. No new directories, no new files. All edits happen within the `fix-stale-refs` worktree and will be committed as a single `docs(task):` commit on branch `fix-stale-refs`.

## Complexity Tracking

No violations. Table intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| —         | —          | —                                    |
