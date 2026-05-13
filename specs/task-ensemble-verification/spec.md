# Feature Specification: Ensemble Verification for the `task` Skill

**Feature Branch**: `feature/task-ensemble-verification`
**Created**: 2026-05-13
**Status**: Draft
**Design source**: `docs/superpowers/specs/2026-05-13-task-ensemble-verification-design.md`

## Overview

Add ensemble execution (3 parallel instances + merge) to selected stages of the `task` SDLC pipeline. Two ensemble forms: `verify` (review stages, union of findings) and `produce` (producing stages, 4th synthesizer agent). Activation is scope-gated to balance recall against cost. Existing per-stage agent files remain unchanged; ensemble is an orchestration concern handled by `SKILL.md` and a new generic `synthesizer.md` agent.

## User Scenarios & Testing

### User Story 1 — Reviewer always runs as ensemble (Priority: P1)

As a `task` skill user, when I invoke the pipeline at any scope (XS through XL), I want the final Reviewer stage to run as three parallel instances merged into a single review document, so that more issues are caught than a single pass would find.

**Why this priority**: Reviewer is the highest-leverage review stage. It's the last semantic gate before commit. Ensemble here has the largest recall payoff.

**Independent Test**: Run `/task-quick "rename foo to bar"` (S scope, express tier). Verify `.task/09-review-a.md`, `-b.md`, `-c.md` raw files are produced and `.task/09-review.md` is the merged canonical with `[3/3]`/`[2/3]`/`[1/3]` confidence tags.

**Acceptance Scenarios**:

1. **Given** scope XS invocation, **When** Reviewer stage dispatches, **Then** 3 parallel reviewer instances run in a single Agent tool call with identical prompts and `.task/09-review-{a,b,c}.md` + canonical `09-review.md` are produced.
2. **Given** the merged review list is empty, **When** the gate fires, **Then** verdict is `PASS` and the next stage begins.
3. **Given** the merged review list has any findings, **When** the gate fires, **Then** the user sees the divergence summary and the canonical findings list before approving.

---

### User Story 2 — Scope-gated ensemble for producing stages (Priority: P2)

As a `task` skill user, when I invoke the pipeline at scope M or higher, I want the Researcher stage to run as ensemble-produce (3 parallel researchers + synthesizer), so that no relevant files / dependencies / tests are missed for any module. At scope L+ I additionally want Decomposer and Reviewer-Lite ensembled. At scope XS / S the system must skip producing-stage ensembling so trivial tasks pay no overhead.

**Why this priority**: Scope-aware activation is the cost-control mechanism. Without it, ensemble overhead would be unacceptable on small tasks.

**Independent Test**: Run `/task-quick` (S) — verify only Reviewer ensembles, no `04-research-{N}-{a,b,c}.md` files exist. Then run `/task-full "build foo across 3 modules"` (L) — verify per-module research, Reviewer-Lite, Decomposer all ensembled.

**Acceptance Scenarios**:

1. **Given** scope M invocation, **When** Researcher runs per module, **Then** 3 parallel researchers + synthesizer produce raw + canonical per module.
2. **Given** scope L invocation, **When** Decomposer runs, **Then** 3 parallel opus decomposers + opus synthesizer produce raw + canonical.
3. **Given** scope S invocation, **When** any producing stage would normally run, **Then** only single-pass behavior is used (no raw files produced).
4. **Given** scope L invocation with `ensemble: off` preamble override, **When** any stage runs, **Then** single-pass is used everywhere (override respected).

---

### User Story 3 — Divergence summary at approval gate (Priority: P2)

As a `task` skill user about to approve a stage output, I want to see a short summary of how the 3 ensemble instances diverged, so that I can decide whether to drill into raw files or trust the merged canonical.

**Why this priority**: Transparency. Without it, the user can't audit synthesis decisions.

**Independent Test**: Run any ensembled stage. At the approval prompt, verify the message includes: instance count, per-instance findings count (verify-mode) OR per-instance summary (produce-mode), merged result summary, paths to raw files.

**Acceptance Scenarios**:

1. **Given** an ensembled verify stage just completed, **When** the gate prompt appears, **Then** the user sees `3 × <model>` with per-reviewer finding counts and the merged unique count.
2. **Given** an ensembled produce stage just completed, **When** the gate prompt appears, **Then** the user sees `Synthesized from 3 outputs` with merged-element counts and resolved-conflict counts.

---

### Edge Cases

- One of 3 instances times out. System retries once. If still failing: proceeds with the 2 successful instances, marks `Instances: 2/3 (one timed out)`. Confidence tags adjust to `[2/2]` / `[1/2]`.
- Three raw outputs are byte-identical (hash match). Synthesizer short-circuits, returns first as-is with note `triple agreement, no merge needed`.
- Three raw outputs diverge beyond `divergence_threshold` in produce mode (e.g., different module counts in Decomposer). Synthesizer returns `divergence-error`. Orchestrator pauses, shows user all three raw outputs side by side, awaits resolution.
- Synthesizer itself fails. System stops, surfaces raw outputs, awaits manual decision. No automatic retry of synthesizer (loop risk).
- User passes `ensemble: off` in preamble. All stages run as single-pass regardless of scope.

## Requirements

### Functional Requirements

- **FR-001**: Orchestrator MUST consult an ensemble activation matrix (defined in `agents/refs/ensemble.md`) at each stage dispatch to determine whether to run single-pass or ensemble.
- **FR-002**: `ensemble-verify` mode MUST spawn exactly 3 parallel instances of the target reviewer agent in a single Agent tool call with identical prompts.
- **FR-003**: `ensemble-produce` mode MUST spawn exactly 3 parallel instances of the target producing agent in a single Agent tool call; instance outputs MUST be suffixed `-a.md`, `-b.md`, `-c.md`.
- **FR-004**: A generic synthesizer agent (`agents/synthesizer.md`) MUST accept a mode flag (`verify` | `produce`) and a list of raw artefact paths.
- **FR-005**: In `verify` mode the synthesizer MUST produce a union of unique findings, tagged with reviewer count `[N/3]`, sorted by severity then count.
- **FR-006**: In `produce` mode the synthesizer MUST merge raw artefacts into a single canonical version; if raw outputs diverge beyond `divergence_threshold`, MUST return `divergence-error` instead.
- **FR-007**: Synthesizer MUST short-circuit and return one raw artefact verbatim when all three raw outputs hash-match.
- **FR-008**: Approval gates MUST fire on the canonical (no suffix) file only; raw `-a/-b/-c` files MUST NOT trigger gates.
- **FR-009**: At each ensemble-gated approval, the user MUST see a divergence summary including instance count, per-instance summary, and paths to raw files.
- **FR-010**: `pipeline-summary.md` front-matter MUST record an `ensemble` block per `agents/refs/ensemble.md` schema.
- **FR-011**: On instance timeout, system MUST retry the failed instance once; if still failing, proceed with successful instances and adjust confidence tags accordingly.
- **FR-012**: On synthesizer `divergence-error`, orchestrator MUST pause and present raw outputs to the user for manual resolution.
- **FR-013**: User preamble flag `ensemble: off` MUST disable all ensemble activation regardless of scope; `ensemble: full` MUST force ensemble on all eligible stages.
- **FR-014**: Existing per-stage agent files (`reviewer.md`, `reviewer-lite.md`, `researcher.md`, `decomposer.md`, `spec.md`) MUST NOT be modified by this feature.
- **FR-015**: Activation matrix MUST gate by scope per the design document's table (XS/S → Reviewer only; M → +Researcher; L/XL → all five eligible stages).

### Key Entities

- **Raw artefact** — output of a single ensemble instance, stored at `.task/<stage>-<N>-<a|b|c>.md`.
- **Canonical artefact** — merged/synthesized output of the synthesizer, stored at `.task/<stage>-<N>.md`.
- **Divergence summary** — short report shown at the approval gate describing how the 3 instances diverged.
- **Confidence tag** — `[N/3]` annotation on each finding in a `verify`-mode canonical, indicating how many instances surfaced that finding.
- **Activation matrix** — table mapping (scope, stage) → {ensemble, single, n/a}, defined in `agents/refs/ensemble.md`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: After implementation, running `/task-full` (L scope) on a benchmark 3-module feature produces the full set of raw + canonical files per the workspace layout in the design doc.
- **SC-002**: Running `/task-quick` (S scope) produces ONLY `09-review-{a,b,c}.md` + `09-review.md` as ensemble artefacts; no per-module ensemble artefacts exist.
- **SC-003**: Existing single-pass behavior is preserved for stages not covered by ensemble (Scout, Planner, Implementer, Tester, Debugger, Designer, Design-QA, Refactorer, Documenter, Committer) — verified by checking those `.task/` files remain at their existing names.
- **SC-004**: Token cost overhead on L-scope ensembling is within ~2.5x of single-pass baseline (estimate from the design; tuned empirically after first runs).
- **SC-005**: Every ensemble-gated approval prompt includes a divergence summary line; verified by inspection of orchestrator output.
- **SC-006**: `pipeline-summary.md` for an ensembled run contains the `ensemble:` front-matter block with per-stage instance counts and models.
