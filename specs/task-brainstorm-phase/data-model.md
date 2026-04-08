# Data Model: Task Skill -- Brainstorm Phase

**Branch**: `task-brainstorm-phase` | **Date**: 2026-04-08

## Entities

### Spec (00-spec.md)

The structured specification produced by the Brainstormer or transformed by the Analyst from a ready-made document.

**Attributes**:
- Name (string): feature name extracted from brainstorm dialogue
- Summary (text): 1-2 sentence description
- User Stories (list): ordered by priority (P1, P2, P3)
  - ID (string): US1, US2, ...
  - Priority (enum): P1, P2, P3
  - Description (text): "As a ... I want ... so that ..."
  - Acceptance Criteria (list):
    - ID (string): AC-1, AC-2, ...
    - Description (text): testable criterion
- Quality Gates (list):
  - ID (string): QG-1, QG-2, ...
  - Description (text): what blocks release
- Edge Cases (list):
  - ID (string): EC-1, EC-2, ...
  - Description (text): boundary condition or failure scenario
- Scope IN (list): explicitly included items
- Scope OUT (list): explicitly excluded items

**State transitions**:
```
[empty] -> [in-progress] -> [section-pending-approval] -> [complete]
                ^                     |
                |                     v
                +--- [revision-requested]
```

- `empty`: file does not exist yet
- `in-progress`: Brainstormer is actively building sections
- `section-pending-approval`: a section is presented to the user, awaiting "approve" or "revise"
- `revision-requested`: user requested changes to the current section
- `complete`: all sections approved, spec assembled

**Relationships**:
- Read by: Analyst (01-analysis.md)
- Produced by: Brainstormer agent OR Analyst (when transforming ready-made spec)

---

### Analysis (01-analysis.md)

The Analyst's validation output. Updated role: validates spec instead of analyzing from scratch.

**Attributes**:
- Brief (text): 5-10 line validation summary for downstream consumption
- Classification:
  - Type (enum): feature, bugfix, refactor, hotfix
  - Scope (enum): small, medium, large, critical
  - Pipeline stages (list): which stages to run
- Gap Report (list):
  - Finding (text): specific issue description
  - Severity (enum): Gap, Conflict, Weak, OK
  - Location (string): which spec section
- Assumptions (list): carried from spec + analyst additions
- Open Questions (list): unresolved items (if any)

**State transitions**:
```
[pending] -> [validating] -> [gaps-found] -> [user-action] -> [re-validating]
                                                                      |
                           [clean] <----------------------------------+
```

- `gaps-found`: at least one Gap/Conflict/Weak finding
- `user-action`: user chooses fix/ignore/return-to-brainstormer
- `clean`: all findings resolved or explicitly ignored

**Relationships**:
- Reads: 00-spec.md
- Read by: Researcher (02-research.md), Planner (03-plan.md) via brief section

---

### Brainstorm Patterns (refs/brainstorm-patterns.md)

Reference document loaded on demand (Level 3 progressive disclosure) by the Brainstormer.

**Attributes**:
- One Question Rule (pattern): one question per message, wait for answer
- Multiple Choice (pattern): A/B/C/D options where answer set is enumerable
- Red Flags Table (table): list of rationalizing thoughts that mean STOP
- Incremental Validation (pattern): show section, wait for approval
- Propose Approaches (pattern): 2-3 variants with trade-offs and recommendation
- Scope Decomposition (pattern): split large tasks into sub-projects

**Relationships**:
- Loaded by: Brainstormer agent (on demand via `Refs:` declaration)
- Source: Extracted from superpowers:brainstorming skill patterns

---

### Pipeline Summary (pipeline-summary.md)

Renamed from `00-summary.md` to avoid numbering conflict.

**Attributes**: Unchanged from current format -- one-liner per completed stage, updated after each stage completion.

**Relationships**:
- Updated by: Orchestrator (SKILL.md) after each stage
- Read by: Documenter, Committer (terminal agents)

## Validation Rules

| Rule | Entity | Constraint |
|------|--------|-----------|
| Every User Story must have at least one AC | Spec | Enforced by Analyst validation |
| Quality Gates must be defined | Spec | Enforced by Analyst validation |
| Scope IN and OUT must both be present | Spec | Enforced by Analyst validation |
| No contradictions between User Stories | Spec | Checked by Analyst consistency review |
| All ACs must be testable | Spec | Checked by Analyst testability review |
| Gap severity must be one of: Gap, Conflict, Weak, OK | Analysis | Enforced by Analyst output format |
| Classification type must be one of: feature, bugfix, refactor, hotfix | Analysis | Enforced by Analyst output format |
