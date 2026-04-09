# Feature Specification: Fix Task Skill Agent Definitions

**Feature Branch**: `fix-task-agents`
**Created**: 2026-04-09
**Status**: Draft
**Input**: Fix 3 issues in Task SDLC pipeline agent definitions (documenter, refactorer, reviewer)

## User Scenarios & Testing

### User Story 1 - Documenter can document new public APIs (Priority: P1)

When implementation adds new public APIs/endpoints, the Documenter agent needs access to source file signatures to write accurate API documentation. Currently the rule "Don't read source code" blocks this entirely.

**Why this priority**: Without this fix, new APIs ship undocumented -- the most user-visible gap.

**Independent Test**: Run Documenter on an implementation log that mentions a new public endpoint. Verify it reads the file for signatures and produces API documentation.

**Acceptance Scenarios**:

1. **Given** an implementation log (`04-impl-{N}.md`) that mentions new public API files, **When** Documenter runs, **Then** it reads those specific files for signatures/exports only (not full implementation) and documents the API
2. **Given** the project has no existing API docs section, **When** Documenter finds new public APIs, **Then** it creates a new API documentation section
3. **Given** an implementation log with no new public APIs, **When** Documenter runs, **Then** it does NOT read any source files (existing behavior preserved)

---

### User Story 2 - Refactorer escalates complex refactoring (Priority: P1)

The Refactorer (haiku model) lacks guidance on when a refactoring task exceeds its capability. Complex cross-file restructuring should be escalated to the orchestrator for routing to Implementer (sonnet).

**Why this priority**: Wrong-model execution risks broken refactoring with no safety net.

**Independent Test**: Give Refactorer a review report with a cross-file DRY extraction spanning 4+ files. Verify it stops and returns an escalation recommendation.

**Acceptance Scenarios**:

1. **Given** a review item requiring changes to >3 files, **When** Refactorer evaluates it, **Then** it stops and returns the item to orchestrator with recommendation to route to Implementer (sonnet)
2. **Given** a review item requiring cross-module restructuring, **When** Refactorer evaluates it, **Then** it escalates with explanation of why haiku model is insufficient
3. **Given** simple refactoring items (rename, extract constant, reorder), **When** Refactorer evaluates them, **Then** it applies them normally (existing behavior preserved)

---

### User Story 3 - Reviewer invokes security scanning correctly (Priority: P1)

The Reviewer mentions the security-scanning plugin but provides no invocation syntax. The fallback checklist output format doesn't match the plugin output format, making downstream processing inconsistent.

**Why this priority**: Ambiguous plugin invocation means security scanning may be skipped entirely.

**Independent Test**: Run Reviewer with and without the security-scanning plugin available. Verify both paths produce findings in the same format.

**Acceptance Scenarios**:

1. **Given** the security-scanning plugin is available, **When** Reviewer runs security review, **Then** it invokes `/security-scanning:security-sast` with correct syntax
2. **Given** the security-scanning plugin is unavailable, **When** Reviewer runs security review, **Then** it falls back to `agents/refs/security-checklist.md`
3. **Given** either security path is taken, **When** findings are reported, **Then** each finding uses the format: severity (CRITICAL/HIGH/MEDIUM/LOW), location (file:line), description, recommendation

---

### Edge Cases

- Documenter: implementation log mentions API files that were deleted or moved after implementation
- Refactorer: a review item touches exactly 3 files (boundary -- should NOT escalate)
- Refactorer: a single-file change requires 200+ lines of DRY extraction (complex but single-file -- should NOT escalate)
- Reviewer: security-scanning plugin is installed but returns an error

## Requirements

### Functional Requirements

- **FR-001**: Documenter MUST be allowed to read source files for signatures/exports when `04-impl-{N}.md` mentions new public APIs or endpoints
- **FR-002**: Documenter MUST limit source file reads to public signatures, exports, and type definitions -- not full implementation
- **FR-003**: Documenter MUST be allowed to create new API documentation sections when none exist
- **FR-004**: Refactorer MUST include an "Escalation" section defining when to stop and return work to orchestrator
- **FR-005**: Refactorer MUST escalate when changes touch >3 files or require cross-module restructuring
- **FR-006**: Refactorer MUST recommend routing escalated items to Implementer (sonnet model)
- **FR-007**: Refactorer MUST continue to handle simple refactoring (rename, extract constant, reorder) on haiku
- **FR-008**: Reviewer MUST specify exact invocation syntax for security scanning: `/security-scanning:security-sast`
- **FR-009**: Reviewer MUST fall back to `agents/refs/security-checklist.md` when the plugin is unavailable
- **FR-010**: Reviewer MUST use a unified finding format across both security paths: severity, location (file:line), description, recommendation

## Success Criteria

### Measurable Outcomes

- **SC-001**: All three agent files contain the specified additions without altering existing behavior
- **SC-002**: Documenter's source-read exception is scoped only to files mentioned in implementation logs with new public APIs
- **SC-003**: Refactorer's escalation criteria are unambiguous (>3 files OR cross-module restructuring)
- **SC-004**: Reviewer's security scanning invocation uses exact plugin command syntax
- **SC-005**: Security finding format is identical regardless of plugin vs fallback path

## Assumptions

- The `04-impl-{N}.md` implementation log format reliably indicates which files contain new public APIs
- The `/security-scanning:security-sast` command is the correct invocation for the security-scanning plugin's SAST capability
- `agents/refs/security-checklist.md` exists as part of the existing agent references
- The Implementer agent runs on sonnet model and can handle complex refactoring
