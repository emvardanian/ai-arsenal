# Research: Fix Task Skill Agent Definitions

**Branch**: `fix-task-agents` | **Date**: 2026-04-09

## Summary

No research needed. All three fixes are fully specified by the user with exact scope, trigger conditions, and expected behavior. No technology choices, no external dependencies, no unknowns.

## Decisions

### D1: Documenter source-read exception scope

- **Decision**: Allow reading only files explicitly mentioned in `04-impl-{N}.md` as containing new public APIs, limited to signatures/exports
- **Rationale**: Minimal scope expansion -- preserves the "don't read source code" principle for everything except new public API documentation
- **Alternatives considered**: Allow reading all modified files (too broad), require Implementer to include API signatures in the log (adds burden to wrong agent)

### D2: Refactorer escalation threshold

- **Decision**: Escalate when changes touch >3 files OR require cross-module restructuring
- **Rationale**: >3 files is a clear, countable threshold. Cross-module restructuring requires architectural understanding beyond haiku's capability
- **Alternatives considered**: Escalate on line count (harder to assess pre-edit), escalate on all DRY extraction (too aggressive -- simple single-file DRY is fine for haiku)

### D3: Reviewer security scanning invocation

- **Decision**: Use `/security-scanning:security-sast` as the exact command, with structured fallback to `refs/security-checklist.md`
- **Rationale**: Matches the installed plugin's skill name. Unified finding format ensures downstream agents (Refactorer, Implementer) can process findings consistently
- **Alternatives considered**: Generic `/security-scanning` (ambiguous -- plugin has multiple sub-commands), inline checklist in reviewer.md (duplicates refs/)
