# Research: Task Skill -- Brainstorm Phase

**Branch**: `task-brainstorm-phase` | **Date**: 2026-04-08

## Findings

### 1. Current Pipeline Structure

**Decision**: Insert Brainstormer as Stage 0, shift Analyst to validation role.

**Rationale**: The existing pipeline starts at Stage 1 (Analyst) which analyzes raw user requests from scratch. Research confirms the SKILL.md pipeline overview, agent reference table, and progress tracker all use this numbering. Adding Stage 0 before Stage 1 requires updating these sections but does not affect Stages 2-10.

**Alternatives considered**:
- Merge brainstorm into Analyst (rejected: Analyst already has a clear role; combining doubles its prompt size and mixes interactive dialogue with analytical validation)
- Replace Analyst entirely (rejected: validation is still needed even with a good spec)

### 2. File Numbering Conflict

**Decision**: Rename `00-summary.md` to `pipeline-summary.md`.

**Rationale**: The current `00-summary.md` conflicts with the new `00-spec.md` (Brainstormer output). Research confirms `00-summary.md` is referenced in SKILL.md workspace section and by terminal agents (Documenter, Committer) who read it instead of individual briefs.

**Impact**: Must update references in `skills/task/SKILL.md` (workspace section, pipeline summary section), `skills/task/agents/documenter.md`, and `skills/task/agents/committer.md`.

**Alternatives considered**:
- Name brainstormer output `00a-spec.md` (rejected: breaks clean numbering convention)
- Use `spec.md` without prefix (rejected: all other workspace files use numbered prefixes)

### 3. Dialogue Patterns Source

**Decision**: Create `agents/refs/brainstorm-patterns.md` by extracting patterns from the superpowers:brainstorming skill design.

**Rationale**: The design document specifies six dialogue patterns (one question rule, multiple choice, red flags table, incremental validation, propose approaches, scope decomposition). These are documented in `docs/superpowers/specs/2026-04-08-task-brainstorm-phase-design.md` lines 59-66. The `.superpowers/brainstorm/` directory contains session artifacts, not the skill definition itself.

**Alternatives considered**:
- Inline patterns in brainstormer.md agent definition (rejected: violates progressive disclosure -- ref docs are Level 3, loaded on demand)
- Reference superpowers:brainstorming skill directly (rejected: creates external dependency; task skill should be self-contained)

### 4. Agent Definition Format

**Decision**: Follow the existing agent definition pattern used by all 11 current agents.

**Rationale**: Research confirms all agents follow a consistent structure: metadata header (model, reads, writes), instructions body, output format specification, and brief section template. The Brainstormer must follow this same format for consistency.

**Pattern**:
```
# Agent Name
Model: [tier]
Reads: [inputs]
Writes: [outputs]
Refs: [on-demand references]

## Instructions
[agent-specific logic]

## Output Format
[template for .task/ output file]

## Brief
[5-10 line summary template for downstream agents]
```

### 5. Adaptive Entry Detection

**Decision**: Implement cascading detection in the orchestrator (SKILL.md), not in the Brainstormer agent.

**Rationale**: The orchestrator already determines which stages run (adaptive pipeline pattern from constitution). Detection order: (1) explicit file path in user request, (2) fresh spec at `docs/superpowers/specs/` within 1 hour, (3) TRC spec at `.trc/` or `docs/`. First match wins.

**Alternatives considered**:
- Detection inside Brainstormer (rejected: Brainstormer should not run at all when spec exists -- orchestrator decides)

### 6. Approval Gate for Brainstormer

**Decision**: Add approval gate after Brainstormer output, consistent with existing gates.

**Rationale**: Research confirms the SKILL.md pipeline overview marks approval gates with `[approval]` tags. Analyst, Researcher, Planner, Designer, Implementer, Documenter, and Committer all have gates. The Brainstormer's section-by-section approval during dialogue serves as inline approval; the final assembled spec gets a pipeline-level approval gate before Analyst validation begins.

### 7. Model Tier

**Decision**: Opus for Brainstormer.

**Rationale**: Consistent with the Analyst (also opus). The Brainstormer requires complex reasoning to conduct structured dialogue, extract user intent, propose approaches with trade-offs, and assemble a coherent spec. Sonnet would be insufficient for the interactive reasoning depth needed.
