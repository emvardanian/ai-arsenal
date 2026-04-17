# Verification Results: Task Skill Core Redesign

**Feature**: task-core-redesign
**Date**: 2026-04-17 (skeleton — manual runs pending)
**Purpose**: Record actual approval counts, token tier usage, and wall-clock time from representative pipeline runs. Compare against Success Criteria (SC-001..SC-010).

## Status

**Phase**: SKELETON / PENDING RUNS

The implementation is complete (68/68 tasks checked off in `tasks.md`). What remains is running three representative tasks through both the pre-redesign and redesigned skill versions to produce measured evidence. Because this project has no test harness (constitution: `No package manager, no build, no lint, no tests`), verification is manual — the procedure is documented below and results slots are reserved for population after the runs.

## Verification procedure

For each path, run the task twice:

1. **Baseline (pre-redesign)**: check out `main` at commit `0786dee`; run the task; record metrics.
2. **Redesigned**: check out this branch (`task-core-redesign`); run the same task; record metrics.

Metrics to collect per run:

- Approval prompt count (from pipeline start to Committer presentation).
- Wall-clock time (invocation → Committer output shown).
- Token consumption per model tier (opus / sonnet / haiku), if available from Claude Code usage reports.
- Final `.task/pipeline-summary.md` contents.

## Path 1 — Express (scope XS, `rename-function` task)

**Task**: "Rename getUserById to fetchUserById in user-service."

**Expected redesign outcome** (per quickstart.md):
- Scope auto-classified: XS
- Tier auto-selected: express
- Pipeline: Implementer → Tester → Committer
- Approvals: exactly 1 (Committer)

### Results (baseline)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Wall-clock time | _pending_ |
| Opus tokens | _pending_ |
| Sonnet tokens | _pending_ |
| Haiku tokens | _pending_ |

### Results (redesigned)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Wall-clock time | _pending_ |
| Opus tokens | _pending_ |
| Sonnet tokens | _pending_ |
| Haiku tokens | _pending_ |

### SC checks

- [ ] **SC-001** (express scope-S ≤ 1 approval): _pending_
- [ ] **SC-005** (-50% wall-clock on scope-S): _pending_
- [ ] **SC-007** (scope + tier in front-matter): _pending_
- [ ] **SC-009** (classification < 2s): _pending_

## Path 2 — Standard (scope M, `password-reset-email` task)

**Task**: "Add email notifications for password reset: generate reset token, send time-limited link, handle click-through to reset form."

**Expected redesign outcome**:
- Scope auto-classified: M
- Tier auto-selected: standard
- Pipeline: Spec → Scout → Decomposer → (Research → Plan → Impl → Test)×3 → Committer
- Approvals: exactly 3 (Spec, Decomposer, Committer)

### Results (baseline)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Wall-clock time | _pending_ |
| Opus tokens | _pending_ |
| Sonnet tokens | _pending_ |
| Haiku tokens | _pending_ |

### Results (redesigned)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Wall-clock time | _pending_ |
| Opus tokens | _pending_ |
| Sonnet tokens | _pending_ |
| Haiku tokens | _pending_ |

### SC checks

- [ ] **SC-002** (standard scope-M = 3 approvals): _pending_
- [ ] **SC-004** (-40% opus tokens on scope-M): _pending_
- [ ] **SC-006** (Validation section present in 00-spec.md): _pending_
- [ ] **SC-007** (scope + tier in front-matter): _pending_

## Path 3 — Strict (scope L, `oauth2-migration` task)

**Task**: "Migrate the authentication stack from session cookies to OAuth2 with refresh tokens. Update middleware, token issuance, refresh flow, and all downstream service clients."

**Expected redesign outcome**:
- Scope auto-classified: L
- Criticality detected (keyword "auth") → user confirms strict.
- Pipeline: Spec → Scout → Decomposer → (Research → Plan → Impl → Test)×4 → Reviewer → Refactorer → Documenter → Committer
- Approvals: ~11-13 — MUST match pre-redesign baseline exactly.

### Results (baseline)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Approval count per gated stage | _pending_ |
| Wall-clock time | _pending_ |
| Stage order | _pending_ |

### Results (redesigned)

| Metric | Value |
|---|---|
| Approval prompts | _pending_ |
| Approval count per gated stage | _pending_ |
| Wall-clock time | _pending_ |
| Stage order | _pending_ |

### SC checks

- [ ] **SC-003** (strict scope-L approval count identical to pre-redesign): _pending_
- [ ] **SC-008** (zero increase in strict-tier approvals): _pending_
- [ ] Strict-Tier Invariant (FR-024): gated stages match pre-redesign list from `refs/approval-tiers.md` — _pending_

## Path 4 — Backward-compat resume

**Task**: Take a pre-redesign `.task/` workspace (from a real prior pipeline run), invoke the redesigned skill with no arguments.

**Expected redesign behavior**:
1. Orchestrator reads `.task/pipeline-summary.md`.
2. Detects absence of `---` front-matter → v1 schema.
3. Defaults `tier: strict`, infers scope from body content.
4. Upgrades front-matter in place (`summary_schema: v1 → v2 upgraded at <timestamp>`).
5. Resumes from next incomplete stage under strict tier.

### Results

- [ ] **SC-010** (pre-redesign workspace resumes without errors): _pending_
- [ ] Front-matter written correctly: _pending_
- [ ] Scope inferred correctly from body: _pending_
- [ ] Subsequent stages gate per strict tier: _pending_

## Overall verification status

| SC | Target | Status |
|---|---|---|
| SC-001 | express scope-S ≤ 1 approval | _pending_ |
| SC-002 | standard scope-M = 3 approvals | _pending_ |
| SC-003 | strict scope-L unchanged | _pending_ |
| SC-004 | -40% opus tokens on M | _pending_ |
| SC-005 | -50% wall-clock on S | _pending_ |
| SC-006 | Validation section always present | _pending_ |
| SC-007 | scope + tier in front-matter | _pending_ |
| SC-008 | zero approvals increase in strict | _pending_ |
| SC-009 | classification < 2s | _pending_ |
| SC-010 | pre-redesign resume 100% | _pending_ |

## How to populate this document

After running the representative tasks:

1. Replace each `_pending_` cell with the measured value.
2. Tick the corresponding SC checkbox.
3. If any SC fails, update `tasks.md` with a follow-up task and escalate before merging the PR.
4. Commit with message: `docs(task-core-redesign): record verification results`.
