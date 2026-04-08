# Feature Specification: Task Skill -- Brainstorm Phase (Stage 0)

**Feature Branch**: `task-brainstorm-phase`
**Created**: 2026-04-08
**Status**: Draft
**Input**: Design document: `docs/superpowers/specs/2026-04-08-task-brainstorm-phase-design.md`

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive Brainstorm Session (Priority: P1)

A developer invokes the task skill with a vague or incomplete feature request. Instead of the pipeline analyzing a raw request from scratch, a Brainstormer agent engages the user in a structured dialogue -- asking about context, user stories, acceptance criteria, quality gates, edge cases, and scope boundaries. After each section the agent presents its output and waits for approval before moving on. The session concludes with a complete TRC-format spec written to `.task/00-spec.md`.

**Why this priority**: This is the core new capability. Without it, the pipeline still relies on the Analyst to infer intent from a raw request, which produces lower-quality specs and more rework downstream.

**Independent Test**: Invoke `/task` with a brief feature description (e.g., "add dark mode"). Verify the Brainstormer agent starts a dialogue, asks structured questions one at a time, presents each section for approval, and produces a valid `00-spec.md` with all required sections (Summary, User Stories with ACs, Quality Gates, Edge Cases, Scope IN/OUT).

**Acceptance Scenarios**:

1. **Given** a user invokes the task skill with a brief description, **When** the Brainstormer activates, **Then** it asks context questions (what and why) before proceeding to user stories.
2. **Given** the Brainstormer has assembled a section (e.g., User Stories), **When** it presents the section to the user, **Then** it waits for explicit approval ("approve" or "revise") before moving to the next section.
3. **Given** the user says "revise" on a section, **When** the Brainstormer receives revision feedback, **Then** it updates the section and re-presents it for approval.
4. **Given** all sections are approved, **When** the Brainstormer assembles the final spec, **Then** the output file `.task/00-spec.md` contains all required TRC sections (Summary, User Stories with priorities and ACs, Quality Gates, Edge Cases, Scope IN/OUT).

---

### User Story 2 - Adaptive Entry: Skip Brainstormer with Ready-Made Spec (Priority: P1)

A developer invokes the task skill and provides (or has recently created) a structured spec document -- a TRC spec, a superpowers design doc, or any document with clear sections. The pipeline detects this and skips the Brainstormer entirely, passing the spec directly to the Analyst for transformation and validation.

**Why this priority**: Equal priority to US1 because users who already have a spec should not be forced through an interactive session. Both entry paths must work for the pipeline to be usable.

**Independent Test**: Invoke `/task` while a fresh spec exists at `docs/superpowers/specs/`. Verify the Brainstormer is skipped, the Analyst transforms the input into TRC-format `00-spec.md`, and validation proceeds normally.

**Acceptance Scenarios**:

1. **Given** a user invokes the task skill and explicitly passes a file path to a spec, **When** the orchestrator evaluates entry, **Then** the Brainstormer is skipped and the Analyst receives the file.
2. **Given** a fresh spec exists at `docs/superpowers/specs/` (written within the last hour), **When** the user invokes the task skill without referencing a file, **Then** the orchestrator auto-detects the fresh spec and skips the Brainstormer.
3. **Given** no ready-made spec is detected, **When** the user invokes the task skill, **Then** the Brainstormer runs as normal (US1 flow).

---

### User Story 3 - Analyst Validates Brainstormer Output (Priority: P1)

After the Brainstormer produces `00-spec.md` (or the Analyst transforms a ready-made spec), the Analyst reads the spec and validates it for completeness, consistency, edge case coverage, and testability. It classifies the task (type, scope, pipeline stages) and produces a gap report. If gaps are found, the user can fix, ignore, or return to the Brainstormer.

**Why this priority**: Validation is the quality gate between specification and planning. Without it, poor specs flow unchecked into downstream stages.

**Independent Test**: Provide a `00-spec.md` with a known gap (e.g., a user story missing acceptance criteria). Verify the Analyst identifies the gap, reports it with severity, and offers the user options to resolve.

**Acceptance Scenarios**:

1. **Given** a complete and consistent `00-spec.md`, **When** the Analyst validates, **Then** it produces `01-analysis.md` with classification (type, scope, pipeline stages) and an "OK" gap report.
2. **Given** a `00-spec.md` where a user story lacks acceptance criteria, **When** the Analyst validates, **Then** the gap report includes a "Gap" severity finding for that story.
3. **Given** contradicting user stories in the spec, **When** the Analyst validates, **Then** the gap report includes a "Conflict" severity finding.
4. **Given** the Analyst reports gaps, **When** the user chooses "fix in spec," **Then** the user can edit the spec and re-trigger validation.
5. **Given** the Analyst reports gaps, **When** the user chooses "return to Brainstormer," **Then** the Brainstormer re-opens the relevant section for revision.

---

### User Story 4 - Dialogue Patterns: Structured Conversation (Priority: P2)

The Brainstormer follows specific dialogue patterns loaded from a reference file: one question per message, multiple-choice options where possible, a "red flags" table to prevent skipping the process, incremental section-by-section validation, and proposing 2-3 approaches with trade-offs before finalizing decisions.

**Why this priority**: Dialogue quality directly impacts spec quality, but the patterns are an enhancement to the core brainstorm flow (US1) rather than a separate capability.

**Independent Test**: During a brainstorm session, verify the agent asks one question at a time (never batches), offers A/B/C/D options when feasible, and proposes multiple approaches for key decisions before finalizing.

**Acceptance Scenarios**:

1. **Given** the Brainstormer is in dialogue, **When** it asks a question, **Then** only one question is presented per message.
2. **Given** a question has enumerable answers, **When** the Brainstormer asks it, **Then** it presents multiple-choice options (A/B/C/D).
3. **Given** a key design decision, **When** the Brainstormer reaches that point, **Then** it proposes 2-3 approaches with trade-offs and a recommendation before asking the user to choose.

---

### User Story 5 - Scope Decomposition for Large Tasks (Priority: P3)

When the Brainstormer determines that the user's request is too large for a single spec, it proposes splitting into sub-projects and brainstorms the first one, deferring the rest.

**Why this priority**: Important for large features but not required for the core flow. Most tasks will fit a single spec.

**Independent Test**: Invoke `/task` with a request spanning multiple independent systems (e.g., "rebuild the entire auth system plus add analytics"). Verify the Brainstormer proposes a decomposition and proceeds with only the first sub-project.

**Acceptance Scenarios**:

1. **Given** a user request that spans multiple independent domains, **When** the Brainstormer evaluates scope, **Then** it proposes splitting into sub-projects with clear boundaries.
2. **Given** the user approves the decomposition, **When** the Brainstormer proceeds, **Then** it brainstorms only the first sub-project and notes the deferred items.

---

### Edge Cases

- What happens when the user abandons the brainstorm mid-session? Partial progress should be preserved in `.task/00-spec.md` so it can be resumed.
- What happens when the user provides a file path that doesn't exist or is empty? The orchestrator should fall back to running the Brainstormer.
- What happens when a "fresh spec" at `docs/superpowers/specs/` is older than one hour? It should not be auto-detected; the Brainstormer runs instead.
- What happens when the user provides a spec in a non-TRC format (e.g., plain bullet points)? The Analyst should still attempt transformation to TRC-format.
- What happens when the Analyst finds only "Weak" findings (vague but not missing criteria)? The user should be informed but allowed to proceed without fixing.
- What happens when the user says "ignore" to all gap findings? The pipeline proceeds with the spec as-is, with a warning logged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an interactive Brainstormer agent (Stage 0) that runs before the Analyst in the task pipeline.
- **FR-002**: Brainstormer MUST follow a structured dialogue sequence: context -> user stories -> acceptance criteria -> quality gates -> edge cases -> scope.
- **FR-003**: Brainstormer MUST present each completed section to the user and wait for explicit approval before proceeding to the next section.
- **FR-004**: Brainstormer MUST write output to `.task/00-spec.md` in TRC format (Summary, User Stories with priorities and ACs, Quality Gates, Edge Cases, Scope IN/OUT).
- **FR-005**: System MUST detect ready-made specs (explicit file path, fresh spec at `docs/superpowers/specs/`, or TRC spec at `.trc/`/`docs/`) and skip the Brainstormer when found.
- **FR-006**: Detection of "fresh" specs MUST use a one-hour recency window based on file modification time.
- **FR-007**: Analyst MUST validate `00-spec.md` for completeness (all stories have ACs, quality gates defined, scope explicit), consistency (no contradictions), and testability (criteria are unambiguous).
- **FR-008**: Analyst MUST classify the task by type (feature/bugfix/refactor/hotfix), scope (small/medium/large/critical), and applicable pipeline stages.
- **FR-009**: Analyst MUST produce a gap report with severity levels: Gap (missing), Conflict (contradiction), Weak (vague), OK (clean).
- **FR-010**: When gaps are found, the system MUST offer the user three options: fix in spec, ignore, or return to Brainstormer.
- **FR-011**: When Brainstormer is skipped, the Analyst MUST transform the input document into TRC-format `00-spec.md` before validation.
- **FR-012**: Brainstormer MUST load dialogue patterns from `agents/refs/brainstorm-patterns.md` reference file.
- **FR-013**: Brainstormer MUST offer multiple-choice options (A/B/C/D) where the answer set is enumerable.
- **FR-014**: Brainstormer MUST propose 2-3 approaches with trade-offs and a recommendation for key design decisions.
- **FR-015**: When a task is too large for a single spec, Brainstormer MUST propose decomposition into sub-projects and proceed with only the first one.
- **FR-016**: Pipeline summary file MUST be renamed from `00-summary.md` to `pipeline-summary.md` to avoid numbering conflict with the new `00-spec.md`.
- **FR-017**: Progress tracker MUST display Stage 0 (Brainstorm) and update Stage 1 label to "Validate."

### Key Entities

- **Spec (00-spec.md)**: The structured specification produced by the Brainstormer or transformed by the Analyst. Contains Summary, User Stories (with priorities, ACs), Quality Gates, Edge Cases, and Scope (IN/OUT).
- **Analysis (01-analysis.md)**: The Analyst's validation output. Contains a brief with validation summary, task classification, and gap report.
- **Brainstorm Patterns (refs/brainstorm-patterns.md)**: Reference document loaded by the Brainstormer. Contains dialogue rules (one question at a time, multiple choice, red flags, incremental validation, approach proposals, scope decomposition).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users starting with a vague one-line request produce a spec with all required sections (Summary, User Stories, ACs, Quality Gates, Edge Cases, Scope) in a single brainstorm session.
- **SC-002**: The brainstorm dialogue asks no more than one question per message and provides multiple-choice options for at least 50% of questions.
- **SC-003**: Users with a ready-made spec bypass the brainstorm phase entirely and reach the validation step without manual intervention.
- **SC-004**: The Analyst detects at least 90% of specs missing acceptance criteria, contradicting stories, or undefined scope boundaries.
- **SC-005**: The full brainstorm-to-validation flow (Stage 0 + Stage 1) completes without requiring the user to manually edit files or restart the pipeline.
- **SC-006**: Partial brainstorm progress is recoverable if the session is interrupted, allowing the user to resume rather than restart.

## Assumptions

- The existing task skill SKILL.md orchestrator can be extended with a new Stage 0 without breaking stages 2-10.
- The `.task/` workspace directory convention is stable and all agents already respect it.
- The `00-` prefix for the spec file does not conflict with any other pipeline artifact (the existing `00-summary.md` will be renamed to `pipeline-summary.md`).
- Opus model is available for the Brainstormer agent, matching the existing Analyst model tier.
- The one-hour freshness window for auto-detecting specs is a reasonable default; it may need user-configurable override in the future but is not required for the initial implementation.
- Planner and subsequent stages (3+) are out of scope and will be addressed in a separate design iteration.
