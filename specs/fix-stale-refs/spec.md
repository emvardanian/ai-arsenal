# Feature Specification: Fix Stale Doc References in Task Skill

**Feature Branch**: `fix-stale-refs`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Fix stale documentation references in skills/task/ after Cycle 1-3 redesign. Four documentation-only defects (plus one bonus) across 5 files."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Downstream agents read the correct spec file (Priority: P1)

Scout, Decomposer, and Committer agents currently document `.task/01-analysis.md` as an input, but the redesigned pipeline produces `.task/00-spec.md` instead (`01-analysis.md` is no longer generated; SKILL.md line 74 confirms). A new maintainer reading these agent files would follow stale input paths.

**Why this priority**: Three agent files mislead readers about what the Spec stage produces. Fixing them restores documentation parity with the actual pipeline.

**Independent Test**: Search `skills/task/agents/{scout,decomposer,committer}.md` for `01-analysis.md`. Expect zero hits. Search for `00-spec.md`. Expect one hit in each file's Inputs section.

**Acceptance Scenarios**:

1. **Given** the redesigned pipeline produces `00-spec.md`, **When** a reader opens `scout.md`, **Then** the Inputs section references `.task/00-spec.md` (full).
2. **Given** the redesigned pipeline produces `00-spec.md`, **When** a reader opens `decomposer.md`, **Then** the Inputs section references `.task/00-spec.md -- Brief section only`.
3. **Given** the redesigned pipeline produces `00-spec.md`, **When** a reader opens `committer.md`, **Then** the Inputs list references `.task/00-spec.md -- task type, determines commit prefix`.

---

### User Story 2 - model-tiers doc is consistent with the three-mode Spec (Priority: P1)

`agents/refs/model-tiers.md` still describes Spec as having two modes (interactive, validate). Cycle 1 added a third mode (interview). The table body already has three rows for Spec, but the summary count, reader contract prose, example block, and invariant are stale.

**Why this priority**: A reader comparing the summary prose to the table finds contradictions, eroding trust in the canonical mapping.

**Independent Test**: Open `model-tiers.md`. Confirm tier-distribution row for haiku shows 7 (not 8). Confirm reader-contract prose enumerates all three spec modes. Confirm the "For Spec" example block shows interactive, validate, and interview lines. Confirm the invariant says Spec has exactly three rows.

**Acceptance Scenarios**:

1. **Given** the table body lists 7 haiku agents, **When** a reader checks the tier-distribution summary, **Then** it reports haiku count = 7.
2. **Given** Spec has three modes per `spec.md`, **When** a reader reads the reader-contract step for mode resolution, **Then** interactive, validate, and interview are all listed.
3. **Given** Spec has three modes, **When** a reader reads the "For Spec" example block, **Then** three reference lines (interactive/validate/interview) appear.
4. **Given** Spec has three modes, **When** a reader reads the Invariants section, **Then** the row-count invariant states three rows (interactive, validate, interview).

---

### User Story 3 - Documenter points to the correct implementation log filename (Priority: P2)

`documenter.md` line 16 references `04-impl-{N}.md`, but the Implementer writes to `06-impl-{N}.md` per SKILL.md and every other agent.

**Why this priority**: One-line inconsistency. Fixing it avoids reader confusion and prevents the Documenter agent from guessing at the wrong filename if it ever follows this reference literally.

**Independent Test**: Search `documenter.md` for `04-impl-`. Expect zero hits. Search for `06-impl-`. Expect at least one hit in the "new public APIs" clause.

**Acceptance Scenarios**:

1. **Given** the pipeline writes `06-impl-{N}.md`, **When** a reader reads `documenter.md` line 16, **Then** the filename reference reads `06-impl-{N}.md`.

### Edge Cases

- `reviewer.md` and `tester.md` legitimately reference `01-analysis.md` in a "or ... on pre-Cycle-X resume" fallback clause. These references MUST stay; they carry the correct fallback semantics for v1 workspaces (see `refs/resume.md:83-86`).
- `SKILL.md:74` contains the string `01-analysis.md` in a prose note explaining the artifact is deprecated. This reference MUST stay — it is explanatory documentation, not an input.
- `resume.md` contains `01-analysis.md` in fallback rules for v1 workspaces. This reference MUST stay.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `skills/task/agents/scout.md` Inputs section MUST reference `.task/00-spec.md` (not `.task/01-analysis.md`) as the full input from the Spec stage.
- **FR-002**: `skills/task/agents/decomposer.md` Inputs section MUST reference `.task/00-spec.md -- Brief section only` (not `.task/01-analysis.md`).
- **FR-003**: `skills/task/agents/committer.md` Inputs list MUST reference `.task/00-spec.md -- task type, determines commit prefix` (not `.task/01-analysis.md`).
- **FR-004**: `skills/task/agents/refs/model-tiers.md` tier-distribution table MUST show `haiku | 7 | spec (validate), scout, design-qa, reviewer-lite (Cycle 2), refactorer, documenter, committer`.
- **FR-005**: `skills/task/agents/refs/model-tiers.md` reader-contract step 2 MUST enumerate Spec's three modes (interactive, validate, interview) when describing mode resolution.
- **FR-006**: `skills/task/agents/refs/model-tiers.md` example block currently titled "For Spec (two modes)" MUST be retitled and contain three reference lines (one per Spec mode).
- **FR-007**: `skills/task/agents/refs/model-tiers.md` invariant MUST state "Spec has exactly three rows (interactive, validate, interview)".
- **FR-008**: `skills/task/agents/documenter.md` line 16 MUST reference `06-impl-{N}.md` (not `04-impl-{N}.md`).
- **FR-009**: Legitimate fallback references to `01-analysis.md` in `reviewer.md`, `tester.md`, `resume.md`, and the explanatory note in `SKILL.md` MUST NOT be modified.
- **FR-010**: No runtime behavior of any agent or orchestrator step MUST change as a result of these edits. This is a documentation-only fix.
- **FR-011**: No new files MUST be created by this change. All edits are in-place modifications of existing files.

### Key Entities

- **Agent file**: markdown file under `skills/task/agents/` describing one pipeline stage (inputs, process, outputs). Subject to FR-001, FR-002, FR-003, FR-008.
- **Model-tiers ref**: `skills/task/agents/refs/model-tiers.md`, the authoritative `(agent, mode) -> model` map. Subject to FR-004 through FR-007.
- **Fallback reference**: prose mention of `01-analysis.md` as a v1-workspace fallback input. Subject to FR-009 (must not change).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `grep -n "01-analysis.md" skills/task/agents/{scout,decomposer,committer,documenter}.md` returns zero matches.
- **SC-002**: `grep -n "00-spec.md" skills/task/agents/{scout,decomposer,committer}.md` returns at least one match in each file's Inputs block.
- **SC-003**: `grep -n "04-impl-" skills/task/agents/documenter.md` returns zero matches; `grep -n "06-impl-" skills/task/agents/documenter.md` returns at least one match.
- **SC-004**: In `model-tiers.md`, the haiku row of the tier-distribution table shows count `7`, and the list of haiku agents contains exactly: spec (validate), scout, design-qa, reviewer-lite, refactorer, documenter, committer.
- **SC-005**: In `model-tiers.md`, the reader-contract step mentioning mode resolution names interactive, validate, AND interview.
- **SC-006**: In `model-tiers.md`, the "For Spec" example block contains three reference lines, one per mode.
- **SC-007**: In `model-tiers.md`, the invariants section states Spec has exactly three rows.
- **SC-008**: `reviewer.md`, `tester.md`, `resume.md`, and `SKILL.md` are unchanged (`git diff --stat` confirms).
- **SC-009**: Total files modified = 5 (scout.md, decomposer.md, committer.md, documenter.md, model-tiers.md). No files created, no files deleted.

## Assumptions

- The pipeline has stabilized on `00-spec.md` and `06-impl-{N}.md` as canonical filenames; no further renames are planned.
- Cycle 1 interview mode is a permanent third Spec mode, not a temporary experiment.
- Readers of these agent files are developers modifying or extending the task skill; correctness of documented inputs matters more than stylistic polish.
- Fallback references to `01-analysis.md` in reviewer/tester/resume/SKILL are load-bearing for v1 workspaces and are NOT in scope for this change.
