# Research: Designer Agent Rewrite + Design QA Agent

**Date**: 2026-04-09

## Summary

No unknowns to research. The design specification provides complete details for all deliverables. All decisions are pre-made in the spec.

## Findings

### Pipeline Numbering

- **Decision**: Use current main numbering (Designer 3.5, Design QA 6.5) with TODO comments for post-restructuring renumbering (5.5, 8.5)
- **Rationale**: Pipeline restructuring branch exists but is not merged to main
- **Evidence**: `git worktree list` shows `ai-arsenal-pipeline-restructuring` worktree on separate branch

### Existing Agent Format

- **Decision**: Follow established agent definition pattern (frontmatter-free markdown with Model, Activation, Inputs, Process, Output, Guidelines sections)
- **Rationale**: Consistency with 10 existing agents in `skills/task/agents/`
- **Evidence**: Read `skills/task/agents/designer.md`, `skills/task/agents/implementer.md` for pattern

### Design Tokens Reference Format

- **Decision**: Extend existing file with new sections rather than splitting into multiple files
- **Rationale**: Single reference file is simpler; file is well under 800-line limit even after expansion
- **Evidence**: Current `design-tokens-example.md` is 62 lines
