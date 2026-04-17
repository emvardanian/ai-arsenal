# Feature Specification: Task Skill Cycle 2 — Integration

**Feature Branch**: `task-cycle2-integration`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Task skill Cycle 2 — Integration. Three coordinated changes: (1) SKILL.md split into thin shell + refs. (2) Per-module Review-lite haiku agent. (3) Superpowers delegation: Planner/Debugger/Implementer-Tester as thin wrappers with fallback. Out of scope: slash commands, state persistence, batch approvals, README autosync (Cycle 3)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Per-Module Review-Lite (Priority: P1)

A developer runs a medium-to-large task through the pipeline. Today, all review happens at the end (final Reviewer stage). If the Reviewer finds a critical bug in module 1's code, the pipeline has already built modules 2-3 on top, and the fix forces Debugger/Implementer/Tester/Reviewer loops that could have been avoided. With Review-Lite, a lightweight haiku-tier reviewer runs after each module's Tester, catching critical issues (hardcoded secrets, N+1 queries, obvious anti-patterns) immediately before the next module starts. The final Reviewer still runs cross-cutting after all modules — Review-Lite is complementary, not a replacement.

**Why this priority**: This is the most user-visible improvement in Cycle 2. It directly cuts Debug cycles (SC-001), reduces rework (SC-002), and improves signal-to-noise at the final Reviewer stage (fewer trivial findings, more cross-cutting ones). Shipping this alone already delivers value; Cycle 2 without Review-Lite is just plumbing.

**Independent Test**: Run a scope-M feature with an intentional hardcoded secret in module 1 implementation. Verify Review-Lite catches it after Tester (before module 2 starts). Without Review-Lite, the same task runs to final Reviewer and fix requires re-running module 2+ stages. Count Debug cycles, wall-clock time, and approval prompts; compare.

**Acceptance Scenarios**:

1. **Given** scope M or above, **When** Tester completes for module N, **Then** Review-Lite runs automatically for module N before module N+1 begins.
2. **Given** scope XS or S, **When** the pipeline runs, **Then** Review-Lite is skipped (scope-pipelines.md explicitly marks it unavailable at XS/S).
3. **Given** Review-Lite detects a Critical issue, **When** the pipeline continues, **Then** it routes to Debugger→Implementer→Tester→Review-Lite re-run, same cycle semantics as Test/Debug (max 2 cycles).
4. **Given** Review-Lite detects only Minor issues, **When** the pipeline continues, **Then** findings are logged to `09.5-review-lite-{N}.md` and passed to the final Reviewer for aggregation.
5. **Given** a module passes Review-Lite, **When** the final Reviewer runs after all modules, **Then** the final Reviewer reads `09.5-review-lite-*.md` files alongside implementation logs and produces a deduplicated cross-cutting review without re-raising already-fixed issues.
6. **Given** strict tier, **When** Review-Lite completes, **Then** output is gated by approval (per-module approval in strict tier only); in standard/express tiers Review-Lite runs without approval gate.

---

### User Story 2 - Lean SKILL.md with On-Demand Refs (Priority: P2)

A developer's Claude Code session activates the Task skill. Today, SKILL.md is 537 lines and every activation pays that token cost, regardless of whether the orchestrator needs to consult tier rules, pipeline matrices, or resume logic in that particular task. After the split, SKILL.md drops to ~100 lines (description, triggers, entry steps, Agent Reference table) and four new refs (`orchestration.md`, `pipelines.md`, `approvals.md`, `resume.md`) load only when the orchestrator needs them. Skill activation becomes significantly cheaper in tokens; per-invocation context budget grows proportionally.

**Why this priority**: Pure efficiency win with low risk. Doesn't change behavior — only where the prose lives. P2 because it's foundational cleanup for Cycle 3 (where lean SKILL.md is prerequisite for slash commands that each reference a subset of refs). If skipped, Cycle 3 inherits bloat; if done, every future cycle pays the reduced skill-activation cost.

**Independent Test**: Count SKILL.md line count before (537) and after (target ≤120). Confirm all content is preserved (no prose loss) by topic coverage mapping of pre-split headings to post-split locations. Run a scope-M feature end-to-end; verify behavior unchanged.

**Acceptance Scenarios**:

1. **Given** the redesigned skill, **When** SKILL.md is opened, **Then** the file contains only: frontmatter, top-level description, triggers, progress tracker format, Agent Reference table, and numbered entry steps (references to refs for details).
2. **Given** SKILL.md references `refs/pipelines.md`, **When** the orchestrator needs to resolve a (scope, task_type) pipeline, **Then** it loads `refs/pipelines.md` on demand (not at skill activation).
3. **Given** the split, **When** pre-split SKILL.md topics are mapped to post-split artifacts, **Then** every H2/H3 heading from pre-split SKILL.md has a target location (zero topic loss).
4. **Given** SKILL.md ≤120 lines after split, **When** skill is activated, **Then** only the shell is loaded; refs load on first use.
5. **Given** a scope-L task run through the redesigned skill, **When** it completes, **Then** output is equivalent to pre-split behavior (same approvals, same stages, same artifact shape).

---

### User Story 3 - Superpowers Plugin Delegation with Fallback (Priority: P3)

A developer has the `superpowers` plugin installed. When Planner, Debugger, and Implementer+Tester stages run, they delegate the heavy work to mature superpowers skills (`writing-plans`, `systematic-debugging`, `executing-plans`, `test-driven-development`) via thin wrapper agents. Task skill provides glue: pass inputs, adapt outputs back into `.task/` contract files. When the plugin is missing, the wrapper detects it at startup and uses the existing inline agent behavior. The user sees the same artifacts in both paths.

**Why this priority**: Strategic. Reduces duplicate prose between Task skill and superpowers, leverages community-maintained skills, cuts drift risk. But P3 because: (a) it is pure plumbing — no new capability to the end user; (b) fallback logic is a source of bugs; (c) superpowers skills may drift in format across versions. Risk outweighs value unless paired with a concrete maintenance win, which this cycle delivers by reducing the per-agent line count of Planner/Debugger/Implementer/Tester.

**Independent Test**: Run a scope-M feature with superpowers plugin enabled; verify wrappers invoke the superpowers skills and produce valid `.task/` artifacts. Disable the plugin; re-run the same task; verify fallback to inline behavior produces equivalent artifacts. Diff the final commits — they should be functionally equivalent (same files modified, same tests passing).

**Acceptance Scenarios**:

1. **Given** superpowers plugin is installed and detected at pipeline start, **When** Planner stage runs, **Then** Planner wrapper invokes `superpowers:writing-plans` with the module's scope and research context, and adapts the superpowers output into the `.task/05-plan-{N}.md` contract format.
2. **Given** superpowers plugin is installed, **When** Debugger stage runs after a failed Tester, **Then** Debugger wrapper invokes `superpowers:systematic-debugging` with the test failure report and produces `.task/08-debug-{N}-{C}.md` with the same structure (hypotheses, evidence, fix instructions, complexity classification).
3. **Given** superpowers plugin is NOT installed (detected at pipeline start), **When** Planner/Debugger stages run, **Then** wrappers fall back to the pre-redesign inline agent behavior; pipeline-summary.md logs `delegation_mode: fallback`.
4. **Given** superpowers plugin is installed but a specific skill invocation fails (plugin error, malformed output), **When** the wrapper catches the error, **Then** it automatically falls back to inline behavior for that single invocation and logs the transient failure; does not block the pipeline.
5. **Given** the user explicitly declares `delegation: disable` in the preamble, **When** the pipeline runs, **Then** all wrappers use inline behavior regardless of plugin availability (user override).
6. **Given** a task runs once with delegation and once with fallback on the same git commit, **When** results are compared, **Then** `.task/` artifacts have the same structure and the committer produces functionally equivalent commits (tolerating minor wording differences).

---

### User Story 4 - Backward Compatibility Across Cycle 2 Changes (Priority: P2)

All three Cycle 2 changes must preserve existing user behavior in strict tier. Users who run the Task skill at strict tier after Cycle 2 must experience: same approval prompts (plus exactly one additive Review-Lite approval per module at scope M+), same stage order, same artifact file names (plus new `09.5-*` when Review-Lite ran), and the same final commit structure. Cycle 1 backward-compat guarantees extend to Cycle 2 unchanged.

**Why this priority**: P2 constraint, not P1 capability. Breaking existing user workflows in Cycle 2 would destroy trust built up through Cycle 1. However, it's not P1 because testing exposes violations immediately (run identical task on both skill versions, diff approvals + artifacts).

**Independent Test**: For each scope (XS, S, M, L, XL) and each task_type (feature, bugfix, refactor, hotfix), run an identical representative task at strict tier through the Cycle 1 skill and the Cycle 2 skill. Expected diff: Cycle 2 adds Review-Lite approvals at M+ (new stage, strict-tier gated, documented); everything else is identical. Resume a pre-Cycle-2 `.task/` workspace with the Cycle 2 skill and verify no errors.

**Acceptance Scenarios**:

1. **Given** a scope-L feature task at strict tier, **When** the Cycle 2 pipeline runs, **Then** the approval prompts match Cycle 1's approval prompts plus exactly one new Review-Lite approval per module at strict tier.
2. **Given** scope XS or S at any tier, **When** the Cycle 2 pipeline runs, **Then** Review-Lite is NOT present (no new approvals vs Cycle 1).
3. **Given** a pre-Cycle-2 `.task/` workspace (`summary_schema: v2`, no delegation fields in front-matter), **When** the Cycle 2 skill resumes it, **Then** it reads the existing front-matter successfully and treats `delegation_mode` as `fallback` (safe default).
4. **Given** any scope at any tier on Cycle 2, **When** the pipeline completes, **Then** `.task/` artifact file names match the Cycle 1 set exactly, plus optional `09.5-review-lite-{N}.md` files when Review-Lite ran.
5. **Given** SKILL.md was split, **When** any agent or the orchestrator looks up prior content by header (e.g., "Mode Detection"), **Then** the content is findable either in SKILL.md (summary) or in a refs file (full text) — no broken references.

---

### Edge Cases

- **Review-Lite catches issue already caught by Tester**: Deduplicate. Review-Lite reads `07-tests-{N}-{C}.md` Brief section and skips findings already reported as test failures.
- **Review-Lite produces zero findings across all modules**: Final Reviewer still runs (unchanged behavior). Review-Lite is additive, not conditional on findings.
- **Review-Lite critical finding routes back to Debugger, but Debugger already reported max cycles for this module**: Escalate to user (same as Test/Debug escalation rule — max 2 cycles). Do not loop.
- **SKILL.md split drops some content**: Content verification is mandatory (topic-coverage mapping check). If any topic is absent from split artifacts, the split is rejected and prose is restored before merge.
- **SKILL.md references refs file that doesn't exist**: Orchestrator logs broken-reference warning and continues (fail-soft). Ref file absence is treated as "content unavailable" — downstream stages may degrade but pipeline does not crash.
- **Superpowers plugin installed but skill returns malformed output**: Wrapper detects invalid format, logs failure, falls back to inline behavior for that single invocation. Repeat failures within the same pipeline trigger fallback for remainder of pipeline.
- **Superpowers plugin version changed mid-pipeline**: Out of scope. Version-pinning is a Cycle 3+ concern. If a plugin update breaks behavior mid-pipeline, user escalation is acceptable.
- **User declares `delegation: force` but plugin is missing**: Skill logs error and asks user: abort, or fall back? Default: fall back with warning.
- **Review-Lite disagrees with final Reviewer on severity** (e.g., Review-Lite says Critical, final Reviewer says Minor): Final Reviewer's judgment wins (it sees cross-cutting context). Review-Lite's original severity recorded for audit.
- **User on scope M has declared `tier: strict` and wants to skip Review-Lite approvals**: Tier override is honored. Review-Lite in strict tier gates by default; user declares `review_lite: skip` to run without gate. Explicit opt-out is allowed.

## Requirements *(mandatory)*

### Functional Requirements

**Review-Lite (US1)**

- **FR-001**: The skill MUST introduce a new agent `agents/reviewer-lite.md` that runs per-module after Tester.
- **FR-002**: Review-Lite MUST be haiku-tier per `refs/model-tiers.md` (new row).
- **FR-003**: Review-Lite's checklist MUST focus on critical/obvious issues only: hardcoded secrets, N+1 queries, SQL injection patterns, missing error handling on external calls, unbounded loops. Full architectural analysis remains the final Reviewer's job.
- **FR-004**: Review-Lite MUST be present in `refs/scope-pipelines.md` for scope M, L, XL; absent for XS, S.
- **FR-005**: Review-Lite MUST gate on approval only in strict tier per `refs/approval-tiers.md`.
- **FR-006**: Review-Lite output MUST be written to `.task/09.5-review-lite-{N}.md` per module.
- **FR-007**: When Review-Lite finds a Critical issue, the orchestrator MUST route to Debugger→Implementer→Tester→Review-Lite retry, respecting the existing 2-cycle max.
- **FR-008**: The final Reviewer MUST read all `09.5-review-lite-*.md` files and deduplicate findings against its own cross-cutting review before writing `09-review.md`.
- **FR-009**: Users MUST be able to disable Review-Lite per-task via `review_lite: skip` preamble key.

**SKILL.md split (US2)**

- **FR-010**: After the split, `skills/task/SKILL.md` MUST be ≤120 lines.
- **FR-011**: The split MUST produce four new reference files: `refs/orchestration.md` (Execution Strategy + Model Tier Resolution), `refs/pipelines.md` (Pipeline Overview + Classification & Pipeline Selection), `refs/approvals.md` (Flow Control + Approval Gate Resolution), `refs/resume.md` (Resume Detection + Scope Inference + Schema Upgrade).
- **FR-012**: SKILL.md MUST retain: frontmatter, top-level description, triggers, Progress Tracker format, Agent Reference table (full), Workspace file listing, Starting the Pipeline numbered entry steps, Resuming cross-reference.
- **FR-013**: Every topic present in pre-split SKILL.md MUST appear in SKILL.md OR in one of the four refs (no content loss; verified by topic-coverage checklist).
- **FR-014**: SKILL.md MUST include explicit references to each ref file at the point where the orchestrator would need to load it (e.g., "For tier resolution details, see `refs/approvals.md`").
- **FR-015**: The split MUST NOT change any stage behavior; behavior-equivalence is verified by running the Cycle 1 quickstart paths (XS/M/L) through Cycle 2 skill and comparing artifacts.

**Superpowers delegation (US3)**

- **FR-016**: The skill MUST detect `superpowers` plugin availability at pipeline start and record `delegation_mode: delegate | fallback` in `.task/pipeline-summary.md` front-matter.
- **FR-017**: Planner, Debugger, Implementer, Tester agents MUST become thin wrappers when `delegation_mode: delegate`, invoking the corresponding superpowers skills (`writing-plans`, `systematic-debugging`, `executing-plans`, `test-driven-development`).
- **FR-018**: Wrappers MUST provide glue code (prompt-level instructions) that adapts the superpowers skill's output to the `.task/` contract files (`05-plan-{N}.md`, `08-debug-{N}-{C}.md`, `06-impl-{N}.md`, `07-tests-{N}-{C}.md`).
- **FR-019**: When `delegation_mode: fallback`, wrappers MUST execute the pre-Cycle-2 inline agent behavior without invoking any superpowers skill.
- **FR-020**: Users MUST be able to force fallback via `delegation: disable` preamble key.
- **FR-021**: On superpowers invocation failure (plugin error, malformed output), the wrapper MUST catch the error, log it, and fall back to inline behavior for that specific invocation.
- **FR-022**: `delegation_mode` MUST be immutable for the duration of a pipeline run (no mid-flight switching); changes require restart.

**Backward compatibility (US4)**

- **FR-023**: Strict tier approval set MUST equal Cycle 1's strict tier set plus exactly N per-module Review-Lite gates (where N = module count from Decomposer).
- **FR-024**: Pre-Cycle-2 `.task/` workspaces MUST resume without errors; absence of `delegation_mode` in front-matter is treated as `fallback`.
- **FR-025**: Cycle 2 artifact file names MUST be a strict superset of Cycle 1's set (existing names unchanged; Review-Lite adds `09.5-*`).
- **FR-026**: SKILL.md references to refs MUST use relative paths that resolve in any Claude Code environment that can read the skill directory.

**Observability**

- **FR-027**: The pipeline summary MUST record per-stage delegation-mode decisions (one line per Planner/Debugger/Implementer/Tester invocation: `delegated` or `fallback`).
- **FR-028**: Every Review-Lite invocation MUST produce a Brief with counts (modules checked, findings by severity, time).
- **FR-029**: Skill activation cost (tokens to load SKILL.md metadata) MAY be logged in pipeline summary (optional, best-effort).

### Key Entities

- **ReviewerLiteFinding**: `{module_N, severity (Critical/Minor), location (file:line), description, category (secrets/performance/pattern)}`. Source of truth for per-module critical reviews.
- **DelegationMode**: enum `{delegate, fallback}`. Pipeline-level decision recorded in front-matter; immutable per run.
- **WrapperInvocationResult**: `{agent, mode (delegated/fallback), duration_ms, success, fallback_reason?}`. Logged per Planner/Debugger/Implementer/Tester invocation.
- **SkillMetadata**: the frontmatter + description + Agent Reference table in SKILL.md, distinct from the deep-logic refs.
- **RefsMap**: `{orchestration.md, pipelines.md, approvals.md, resume.md, model-tiers.md, scope-pipelines.md, approval-tiers.md, criticality-signals.md, spec-dialogue-patterns.md, plus existing checklists}`. Authoritative list of loadable refs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In scope-M tasks where module 1 contains an intentional Critical bug, Review-Lite catches it before module 2 begins in 100% of test runs.
- **SC-002**: For a representative scope-L feature with 4 modules and an intentional Critical bug in module 2, Cycle 2 reduces total pipeline wall-clock time by at least 25% vs Cycle 1 by catching the bug earlier.
- **SC-003**: SKILL.md line count drops from 537 to ≤120 after the split (≥75% reduction).
- **SC-004**: Topic coverage verification confirms zero prose loss from pre-split SKILL.md (every H2/H3 heading present in the pre-split version maps to exactly one location in post-split artifacts).
- **SC-005**: With superpowers plugin installed, a scope-M task completes successfully in delegated mode; `.task/05-plan-{N}.md` and `.task/08-debug-{N}-{C}.md` structures are valid per their contracts.
- **SC-006**: Without superpowers plugin, the same scope-M task completes in fallback mode; `.task/` artifacts are functionally equivalent to Cycle 1 behavior.
- **SC-007**: For a representative scope-L feature at strict tier, Cycle 2 approval count equals Cycle 1 approval count plus exactly N Review-Lite approvals (where N = module count).
- **SC-008**: Pre-Cycle-2 `.task/` workspaces resume under Cycle 2 skill without errors in 100% of test cases.
- **SC-009**: Final Reviewer produces zero findings that duplicate Review-Lite findings that were already resolved (deduplication works).
- **SC-010**: User-declared `delegation: disable` forces fallback in 100% of test cases; pipeline summary reflects the override source as `user`.

## Assumptions

- Users have the `superpowers` plugin installed (it's the recommended path); fallback is for emergency resilience and testing, not the expected primary mode.
- Superpowers skills `writing-plans`, `systematic-debugging`, `executing-plans`, `test-driven-development` remain available and roughly stable in output format during the Cycle 2 lifespan. Breaking plugin changes trigger a Cycle 2.1 release.
- Review-Lite's slim checklist is adequate for catching the majority of critical issues that hurt the Cycle-1 Reviewer cycle (hardcoded secrets, N+1, missing error handling). Less-obvious issues still require cross-cutting analysis at the final Reviewer. SC-001 measures intentionally-injected bugs; broader coverage is best-effort.
- SKILL.md consumers (agents, orchestrator, future cycles) can tolerate a one-hop indirection to refs files. No consumer today requires all content inline.
- Users will not frequently override `delegation: disable` — the option exists for debugging and regression tests, not daily workflow.
- Cycle 1 guarantees (scope classification, tier selection, unified Spec, model rebalance, strict-tier backward-compat) remain valid and are extended, not replaced, by Cycle 2.

## Out of Scope (This Cycle)

Explicitly deferred to Cycle 3:

- Dedicated slash command entry points (`/task-quick`, `/task-fix`, `/task-feature`, `/task-full`).
- Persistence of user preferences across invocations (`~/.claude/task-prefs.json`).
- Persistence of task history (`.task-history/` archive).
- Batch approval for independent modules and real parallelism at approval gates.
- README auto-synchronization with SKILL.md (now further complicated by the split — auto-sync must aggregate across shell + refs).
- Version-pinning of superpowers plugin.
- Scout caching based on project state hash.
- Any change to Cycle 1 scope classification thresholds, tier defaults, or approval gate matrix semantics.
