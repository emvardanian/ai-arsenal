# Quickstart: Task Skill Core Redesign

**Purpose**: Walkthrough three representative paths through the redesigned Task skill. Each path documents expected approval prompts and expected `pipeline-summary.md` contents so reviewers can diff actual runs against them.

---

## Path 1 — Express (scope XS, no overrides)

**Goal**: Quick rename across one file. Zero interruptions until commit.

**Invocation**:

```
Rename getUserById to fetchUserById in user-service.
```

**Expected orchestrator parse**:

```yaml
preamble: null
scope: (inferred XS from signal: 1 function, likely 1-2 file touches)
tier: express (derived from scope XS)
critical: false (no keywords)
mode: interactive (default; no spec detected)
```

**Pipeline** (from matrix cell [XS, refactor]):

```
Implementer → Tester → Committer
```

Note: XS cells skip Spec entirely. The user's one-line request is the spec.

**Expected approval prompts**: **1** (final Committer).

**Expected `pipeline-summary.md` after completion**:

```yaml
---
scope: XS
scope_source: classified
tier: express
tier_source: default
criticality_flag: false
skipped_stages:
  - { name: Spec, reason: "scope=XS" }
  - { name: Scout, reason: "scope=XS" }
  - { name: Decomposer, reason: "scope=XS" }
  - { name: Researcher, reason: "scope=XS" }
  - { name: Planner, reason: "scope=XS" }
  - { name: Designer, reason: "scope=XS" }
  - { name: Design-QA, reason: "scope=XS" }
  - { name: Debugger, reason: "only on test failure" }
  - { name: Reviewer, reason: "scope=XS" }
  - { name: Refactorer, reason: "scope=XS" }
  - { name: Documenter, reason: "scope=XS" }
stage_count_expected: 3
stage_count_approval_gated: 1
summary_schema: v2
---

# Pipeline Summary
- **Task**: Rename getUserById to fetchUserById in user-service
- **Type**: refactor | **Scope**: XS | **Tier**: express | **Pipeline**: scope-xs-any
- **Stage 6 -- Implementer**: ok 1 file modified
- **Stage 7 -- Tester**: ok 8/8 tests passed, no regressions
- **Stage 12 -- Committer**: ok 1 commit prepared
```

**Verification targets**:
- SC-001 (express scope-S approval prompt count ≤ 1): exceeded target (XS, also 1).
- SC-005 (wall-clock reduction ≥ 50% on scope-S): measure vs pre-redesign baseline.
- SC-007 (scope + tier recorded): present in front-matter.

---

## Path 2 — Standard (scope M, default tier, feature)

**Goal**: Medium feature with 3 modules; approve only at the architectural decision points.

**Invocation**:

```
Add email notification support for password reset: generate a reset token, send an email with a time-limited link, handle click-through to reset form.
```

**Expected orchestrator parse**:

```yaml
preamble: null
scope: (inferred M from signals: ~10 file touches across 3 modules — auth, mailer, frontend)
tier: standard (derived from scope M)
critical: false (no keywords — "password" alone not in list)
mode: interactive
```

**Pipeline** (from matrix cell [M, feature]):

```
Spec → Scout → Decomposer → (Research → Plan → Impl → Test)×3 → Committer
```

**Expected approval prompts**: **3** (Spec completion, Decomposition completion, Committer).

**Approval moment breakdown**:

1. **After Spec**: "Spec complete — verdict PASS. 3 user stories, 9 AC. Approve?"
2. **After Decomposer**: "3 modules identified. Execution order: mailer → auth → frontend. Approve?"
3. **At Committer**: "3 commits prepared. Approve to stage?"

Per-module Plan, Impl stages execute WITHOUT prompting.

**Expected `pipeline-summary.md` after completion**:

```yaml
---
scope: M
scope_source: classified
scope_signals:
  file_count_est: 10
  module_count_est: 3
  ui_present: false
  task_type: feature
tier: standard
tier_source: default
criticality_flag: false
skipped_stages:
  - { name: Designer, reason: "scope=M, no UI modules" }
  - { name: Design-QA, reason: "scope=M, no UI modules" }
  - { name: Reviewer, reason: "scope=M" }
  - { name: Refactorer, reason: "scope=M" }
  - { name: Documenter, reason: "scope=M" }
stage_count_expected: 15   # 1 Spec + 1 Scout + 1 Decomposer + 3×4 per-module + 1 Committer
stage_count_approval_gated: 3
summary_schema: v2
---

# Pipeline Summary
- **Task**: Add email notifications for password reset
- **Type**: feature | **Scope**: M | **Tier**: standard | **Pipeline**: scope-m-feature
- **Stage 1 -- Spec**: ok interactive, 3 US, 9 AC, Validation PASS
- **Stage 2 -- Scout**: ok MERN stack, 3 modules, kebab-case
- **Stage 3 -- Decomposer**: ok 3 modules (mailer → auth → frontend)
- **Stage 4.1 -- Researcher**: ok mailer, 4 affected files
- **Stage 5.1 -- Planner**: ok mailer, 3 create, 1 modify
- **Stage 6.1 -- Implementer**: ok mailer done
- **Stage 7.1 -- Tester**: ok 9/9 tests, no regressions
- **Stage 4.2 -- Researcher**: ok auth, 5 affected files
- **Stage 5.2 -- Planner**: ok auth, 2 modify
- **Stage 6.2 -- Implementer**: ok auth done
- **Stage 7.2 -- Tester**: ok 12/12 tests
- **Stage 4.3 -- Researcher**: ok frontend, 3 affected files
- **Stage 5.3 -- Planner**: ok frontend, 1 create, 2 modify
- **Stage 6.3 -- Implementer**: ok frontend done
- **Stage 7.3 -- Tester**: ok 6/6 tests
- **Stage 12 -- Committer**: ok 3 commits prepared
```

**Verification targets**:
- SC-002 (standard scope-M approval count = 3): confirmed.
- SC-004 (-40% opus tokens vs baseline): measure (Spec on haiku for validate, Scout on haiku, Designer skipped save ~2 opus calls vs pre-redesign).
- SC-007 (scope + tier recorded): present.

---

## Path 3 — Strict (scope L, default tier, feature) — backward-compat

**Goal**: Large cross-cutting feature. Preserve pre-redesign approval cadence exactly (FR-024, US5).

**Invocation**:

```
Migrate the authentication stack from session cookies to OAuth2 with refresh tokens. Update middleware, token issuance, refresh flow, and all downstream service clients.
```

**Expected orchestrator parse**:

```yaml
preamble: null
scope: (inferred L from signals: ~25 file touches across 4 modules)
tier: strict (derived from scope L)
critical: true (keyword "auth" detected; user confirms strict → no change)
criticality_source: keyword
criticality_matched_term: "auth"
mode: interactive
```

**Pipeline** (from matrix cell [L, feature]):

```
Spec → Scout → Decomposer → (Research → Plan → Impl → Test)×4 → Reviewer → Refactorer → Documenter → Committer
```

**Expected approval prompts** (strict tier, ~10-11 for 4 modules):

1. After Spec completion.
2. After Decomposition.
3-6. After Planner (one per module, 4 modules).
7-10. After Implementer (one per module, 4 modules).
11. After Refactorer.
12. After Documenter.
13. At Committer.

Matches pre-redesign strict behavior stage-for-stage (FR-024, SC-008).

**Expected `pipeline-summary.md`** (highlights):

```yaml
---
scope: L
scope_source: classified
tier: strict
tier_source: criticality      # initial classification produced strict via scope; keyword confirmed
criticality_flag: true
criticality_source: keyword
criticality_matched_term: "auth"
skipped_stages:
  - { name: Designer, reason: "no UI modules" }
  - { name: Design-QA, reason: "no UI modules" }
stage_count_expected: ~22
stage_count_approval_gated: 13
summary_schema: v2
---

# Pipeline Summary
- **Task**: Migrate authentication stack to OAuth2
- **Type**: feature | **Scope**: L | **Tier**: strict | **Pipeline**: scope-l-feature
- **Stage 1 -- Spec**: ok interactive, 5 US, 15 AC, Validation PASS WITH WARNINGS (2 weak ACs)
- **Stage 2 -- Scout**: ok Node/Express, 4 modules
- **Stage 3 -- Decomposer**: ok 4 modules, 2 independent, DAG valid
- ... (all strict-gated stages follow pre-redesign order)
- **Stage 9 -- Reviewer**: ok PASS WITH MINOR ISSUES (0R 1Y 3G 2S)
- **Stage 10 -- Refactorer**: ok 4 minor changes applied
- **Stage 11 -- Documenter**: ok README + CHANGELOG + inline comments
- **Stage 12 -- Committer**: ok 4 commits prepared
```

**Verification targets**:
- SC-003 (approval count equal to pre-redesign for scope L): exact match required.
- SC-008 (zero increase in strict-tier approvals): verified by approval prompt diff.
- FR-024 (strict reproduces pre-redesign behavior): end-to-end test.

---

## Verification script outline

For each path, produce an artifact comparison:

1. Run the same representative task through the pre-redesign skill (baseline).
2. Run through the redesigned skill on the same git commit.
3. Diff `.task/pipeline-summary.md` contents.
4. Count approval prompts in the conversation transcript.
5. Measure wall-clock time and token usage by tier.
6. Record results in `specs/task-core-redesign/verification-results.md` (created by /trc.implement or manual test run).

Expected diffs:
- **Path 1 (XS express)**: Major reduction in approval count (baseline ~5+, redesign 1); significant wall-clock reduction.
- **Path 2 (M standard)**: Approval count reduction (baseline 7+, redesign 3); opus token reduction ~40% via Spec haiku validate + Scout haiku + Designer skipped.
- **Path 3 (L strict)**: No approval count change; model tier differences (Scout haiku, Design-QA haiku) produce small token savings; strict gate behavior identical.

---

## Backward-compat verification

**Test**: take an existing `.task/` workspace from a pre-redesign pipeline run (a real in-flight task), invoke the redesigned skill with no arguments to "resume".

**Expected behavior**:

1. Orchestrator reads `.task/pipeline-summary.md`.
2. Detects absence of `---` front-matter → v1 schema (pre-redesign).
3. Defaults `tier: strict`, `scope: inferred`.
4. Scans body: presence of `Stage 3 -- Decomposer` line → infers scope ≥ M.
5. Writes front-matter back to the file with `scope_source: inferred`, `tier_source: default (resume)`, `summary_schema: v1 → v2 upgraded at <timestamp>`.
6. Continues from next incomplete stage with strict-tier gates.

**Target**: SC-010 (100% resume without errors).

---

## Running the verification suite (manual)

Because the project has no test runner (constitution: no tests), verification is manual:

1. Check out the pre-redesign skill at commit `0786dee` (current main).
2. Run representative task A (XS), B (M feature), C (L feature with auth keyword) — record approval count, token cost, wall-clock.
3. Check out the redesigned skill (this branch after implementation).
4. Run the same tasks — record the same metrics.
5. Diff and confirm:
   - Paths 1, 2: approval count reduced to spec targets.
   - Path 3: approval count unchanged.
   - All paths: `pipeline-summary.md` front-matter present and correct.
6. Log results in `specs/task-core-redesign/verification-results.md`.

If any target fails, loop back to plan/tasks revision before PR.
