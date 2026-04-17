# Contract: SKILL.md Shell (Post-Split)

**File**: `skills/task/SKILL.md`
**Size target**: ≤120 lines (SC-003)

## Structure (in order)

1. **Frontmatter** (`name`, `description`) — unchanged from Cycle 1.
2. **Top-level title and description** — 2-3 paragraphs explaining what the skill does and when it triggers.
3. **Progress Tracker** — compact status line format spec.
4. **Agent Reference** — full 15-row table (Spec, Scout, Decomposer, Researcher, Planner, Designer, Implementer, Tester, Debugger, Design-QA, **Reviewer-Lite (new)**, Reviewer, Refactorer, Documenter, Committer). Model column references `refs/model-tiers.md`.
5. **Workspace** — `.task/` file listing (includes new `09.5-review-lite-{N}.md`).
6. **Refs map** — one-line pointer to each ref with load trigger (ties to `refs-layout.md`).
7. **Starting the Pipeline** — numbered entry steps (1-10), each terse, with "see `refs/<file>.md`" for details.
8. **Resuming** — 3-line reference to `refs/resume.md`.
9. **Cleaning Up** — 1 line.

## Explicit exclusions (moved to refs)

- Execution Strategy (Tier 1 Agent Teams / Tier 2 Subagents / Tier 3 Sequential) → `refs/orchestration.md`
- Model Tier Resolution algorithm → `refs/orchestration.md`
- Context Management → `refs/orchestration.md`
- Pipeline Overview ASCII diagram → `refs/pipelines.md`
- Adaptive Pipeline summary table → `refs/pipelines.md`
- Classification & Pipeline Selection (all subsections) → `refs/pipelines.md`
- Adaptive Entry / Spec Mode Detection → `refs/pipelines.md`
- Flow Control / Approval Gates algorithm → `refs/approvals.md`
- Approval Tier Selection + Override + Mid-Flight + Criticality → `refs/approvals.md`
- Resume Detection + Scope Inference + Schema Upgrade → `refs/resume.md`

## Reference linking convention

Every reference to a ref file in SKILL.md MUST use the form:

```
For <topic> details, see `agents/refs/<file>.md`.
```

This keeps references greppable and unambiguous.

## Verification

After the split, topic coverage MUST be verified:
1. For every H2/H3 heading in pre-split SKILL.md, identify target location in post-split artifacts (either SKILL.md or one of the refs).
2. Result recorded in `refs-layout.md`.
3. If any topic has no target → split rejected, prose restored.
