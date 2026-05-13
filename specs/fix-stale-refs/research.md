# Phase 0 Research: Fix Stale Doc References

**Date**: 2026-04-17
**Feature**: fix-stale-refs

## Unknowns from Technical Context

None. All technical details are known:

- Language: Markdown (no programming).
- Dependencies: none (toolkit project).
- Testing: manual grep verification per spec's Success Criteria.
- Project type: toolkit / markdown docs.

## Research Task 1: Confirm the canonical filenames

**Decision**: Spec stage writes `.task/00-spec.md`; Implementer writes `.task/06-impl-{N}.md`.

**Rationale**: SKILL.md Agent Reference table (lines 28-44) defines the workspace filenames authoritatively:
- Row 1 Spec → writes `00-spec.md`.
- Row 6 Implementer → writes `06-impl-{N}.md + code`.
- SKILL.md line 74 explicitly notes: `01-analysis.md` is no longer produced (pre-redesign artifact).

**Alternatives considered**: none — the canonical filenames are hard-coded in SKILL.md.

## Research Task 2: Which agents must keep `01-analysis.md` references

**Decision**: Preserve `01-analysis.md` references in:

- `agents/reviewer.md:18` — "or `.task/01-analysis.md` on pre-Cycle-2 resume" (explicit fallback clause).
- `agents/tester.md:14` — "or `.task/01-analysis.md` on pre-Cycle-1 resume" (explicit fallback clause).
- `agents/refs/resume.md:83-86` — documents the fallback protocol for v1 workspaces.
- `skills/task/SKILL.md:74` — explanatory note stating the artifact is deprecated.

**Rationale**: These are load-bearing for resume-from-v1-workspace behavior (per `refs/resume.md` Pre-redesign artifact fallback section). Removing them would break resumes.

**Alternatives considered**: stripping all mentions of `01-analysis.md` project-wide — rejected because it would break v1 resume semantics documented in FR-009.

## Research Task 3: Spec modes — how many?

**Decision**: Three modes — `interactive`, `validate`, `interview`.

**Rationale**:
- `agents/spec.md:1-5` declares all three modes with their model-tier references.
- SKILL.md Agent Reference table (row 1, `Model` column) lists "sonnet (interactive/interview) / haiku (validate)".
- `model-tiers.md` table body (lines 15-17) already contains three Spec rows.
- `orchestration.md:68-73` example block correctly shows three reference lines.
- Only the *summary prose* inside `model-tiers.md` (counts, reader contract step 2, example block, invariant) is stale with "two modes" language.

**Alternatives considered**: treating `interview` as experimental and reverting docs to two modes — rejected; spec.md and SKILL.md both treat interview as a permanent mode.

## Research Task 4: Haiku tier count

**Decision**: Haiku tier has exactly 7 agents: spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer.

**Rationale**: enumerated directly from the `model-tiers.md` table body (lines 15-31). Sonnet = 8 rows (includes spec interactive, spec interview), opus = 2 rows, haiku = 7 rows. Total 17 rows consistent with "17" stated at line 41.

**Alternatives considered**: adjusting sonnet or opus counts — rejected, those are already correct.

## Research Task 5: Edit strategy

**Decision**: Use `Edit` tool with unique string matches. Each fix targets a small, surgical substring so no other occurrences collide.

**Rationale**: All five edits are narrow and self-contained. No refactor, no re-ordering, no reformat. Minimal-diff discipline keeps review trivial.

**Alternatives considered**: full-file rewrites via `Write` — rejected, overkill for single-line changes and risks unintended reformatting.

## Integration Patterns

N/A — no external integration points. All changes are in-repo markdown edits.

## Output

research.md ready. No unresolved NEEDS CLARIFICATION. Ready for Phase 1.
