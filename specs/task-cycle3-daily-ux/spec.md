# Feature Specification: Task Skill Cycle 3 — Daily UX

**Feature Branch**: `task-cycle3-daily-ux`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Cycle 3 — Daily UX. Slash commands, user preferences persistence, batch approval for independent modules, README autosync. Backward-compatible with Cycle 2. Out of scope: version-pinning, scout caching, any change to scope thresholds / tier defaults / gate semantics."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Slash Commands as Direct Entry Points (Priority: P1)

A developer wants a zero-friction entry into the Task pipeline without writing a preamble. They type `/task-quick rename getUserById to fetchUserById` and the pipeline auto-selects scope XS/S and tier express. They type `/task-full migrate auth to OAuth2` and get strict-tier L/XL with every approval gate. Four commands cover 90% of daily intents.

**Why this priority**: Slash commands are the most visible daily UX improvement. They collapse "remember the preamble syntax" into muscle memory: `/task-quick` → 1 approval pipeline, `/task-full` → full ceremony. Without them, the preamble grammar introduced in Cycle 1 remains a discoverability problem.

**Independent Test**: Each command invoked on a representative task produces the expected (scope, tier) combo. `/task-quick foo` → XS/S express. `/task-fix X` → auto-classified scope with task_type=bugfix. `/task-feature X` → M standard. `/task-full X` → L/XL strict. Custom preamble inside the command overrides the command default.

**Acceptance Scenarios**:

1. **Given** user types `/task-quick <task>`, **When** pipeline starts, **Then** scope defaults to XS or S (auto-classified, capped at S) and tier defaults to express.
2. **Given** user types `/task-fix <task>`, **When** pipeline starts, **Then** task_type forces to `bugfix`; scope auto-classified; tier follows scope default.
3. **Given** user types `/task-feature <task>`, **When** pipeline starts, **Then** task_type forces to `feature`, scope defaults to M (user override allowed), tier defaults to standard.
4. **Given** user types `/task-full <task>`, **When** pipeline starts, **Then** tier forces to strict; scope defaults to L (user override allowed up to XL).
5. **Given** user types `/task-quick scope: m add retry logic`, **When** preamble is parsed, **Then** `scope: m` in preamble overrides the command's default scope=XS/S.
6. **Given** user types bare `task: ...` or skill trigger without slash command, **When** pipeline starts, **Then** behavior is identical to Cycle 2 (full auto-classification, no command-specific defaults).

---

### User Story 2 - User Preferences Persistence (Priority: P2)

A developer always wants their Task skill to default to `delegation: disable` (prefers inline behavior), skip Refactorer (they never like it), and use `tier: strict` for safety. Writing the preamble every time is friction. A JSON preferences file at `~/.claude/task-prefs.json` stores these defaults; the orchestrator reads it at pipeline start and applies them unless a preamble explicitly overrides. A per-project `.claude/task-prefs.json` at project root overrides the global file for just that project.

**Why this priority**: P2 because it benefits power users who repeat preferences across tasks; casual users won't notice. Not P1 because it's pure convenience — everything achievable via preamble, just requires typing each time.

**Independent Test**: Place a `~/.claude/task-prefs.json` with `{default_tier: "strict", skip_stages: ["refactorer"]}`. Invoke skill with no preamble; verify orchestrator applies these. Override one with preamble; verify preamble wins. Add per-project `.claude/task-prefs.json` with `{default_tier: "express"}`; verify it wins over global for this project.

**Acceptance Scenarios**:

1. **Given** `~/.claude/task-prefs.json` with `{default_tier: "strict"}`, **When** skill invoked with no tier preamble, **Then** pipeline runs at strict tier; `tier_source: user_prefs (global)`.
2. **Given** global prefs with `default_tier: "strict"` AND project prefs with `default_tier: "express"`, **When** skill runs in that project, **Then** tier is express; `tier_source: user_prefs (project)`.
3. **Given** any prefs, **When** preamble explicitly declares `tier: standard`, **Then** tier is standard; `tier_source: user`.
4. **Given** prefs file has `skip_stages: ["refactorer", "documenter"]`, **When** pipeline resolves, **Then** Refactorer and Documenter added to `skipped_stages` in pipeline-summary with `reason: "user_prefs (global|project)"`.
5. **Given** no prefs file exists, **When** skill runs, **Then** behavior identical to Cycle 2 (no errors, no prompts).
6. **Given** prefs file is malformed JSON, **When** skill starts, **Then** skill logs warning, ignores the file, and continues with Cycle 2 defaults (fail-safe).
7. **Given** prefs file contains an unknown key, **When** skill starts, **Then** unknown key is ignored (forward compatibility).

---

### User Story 3 - Batch Approval for Independent Modules (Priority: P2)

A scope-L feature at strict tier produces 4 independent modules (Decomposer reports `depends_on: []` for each). Today each Planner output gates individually: 4 Planner approvals + 4 Implementer approvals + 4 Reviewer-Lite approvals = 12 gates just for per-module work. Batch approval collapses them: the orchestrator runs all 4 Planners, presents them in one prompt "Approve all 4 plans? (or pick individual)", and continues. Only when the user picks "individual" does it fall back to per-module gating.

**Why this priority**: P2 because it's a real daily-UX win for strict-tier power users on large tasks, but affects a minority of invocations (strict + scope L + fully independent modules). Adds complexity to the approval flow (new approval mode), so P2, not P1.

**Independent Test**: scope-L feature at strict tier with 4 independent modules. Today: 12 approvals per-module stages. With batch: 3 approvals (batched Planners, batched Implementers, batched Review-Lites) + per-stage-type choice to drill down. Approval count drops from 12 to 3 when user accepts batches.

**Acceptance Scenarios**:

1. **Given** scope L+, strict tier, multiple modules with `depends_on: []` (all independent), **When** Planner completes for all modules, **Then** orchestrator presents one prompt listing all plans; user may approve all, approve-all-except-N, or request individual per-module gates.
2. **Given** modules have inter-module dependencies, **When** Planner completes, **Then** batch approval is NOT offered; fall back to per-module gating (respects dependency ordering).
3. **Given** user accepts a batch approval, **When** next stage type runs (Implementer), **Then** orchestrator offers batch again for that stage type if still all independent.
4. **Given** user declines batch at Planner stage type, **When** subsequent stage types run, **Then** orchestrator remembers "per-module" preference for remainder of run for that stage type; does not re-prompt.
5. **Given** strict tier with batch accepted for Planner, **When** Implementer runs, **Then** batch prompt at Implementer still appears; user chose per-stage-type, not once-for-all.
6. **Given** standard or express tier, **When** Planner runs, **Then** batch approval is N/A (standard tier doesn't gate per-module anyway; express skips completely).
7. **Given** approval mode recorded in pipeline-summary front-matter (`approval_mode: per_module | batch`), **When** pipeline resumes, **Then** prior mode is respected.

---

### User Story 4 - README Autosync (Priority: P3)

A developer adds a new agent to `skills/task/agents/`. Today, they must manually update `README.md` (agent count, agent table, pipeline diagram) or drift accumulates — as happened between Cycle 0 and Cycle 1 where README said "10 agents" while skill had 15. With autosync, a pre-commit hook (or manual script) regenerates README sections from the skill's authoritative sources (`SKILL.md` Agent Reference table, `refs/model-tiers.md`, `refs/scope-pipelines.md`). Drift becomes impossible if the hook runs.

**Why this priority**: P3 because it's maintenance automation, not user-visible. It prevents future drift but doesn't change today's behavior. Can be deferred if time-constrained. The hook is opt-in per repository (not installed globally); the manual script is always available.

**Independent Test**: Add a test agent `agents/widget-maker.md`, update `refs/model-tiers.md` with a new row. Run `.claude/scripts/sync-readme.sh` (or trigger pre-commit). Verify README.md agent count incremented, new agent row appears, pipeline diagram mentions it if in a scope pipeline. Revert the agent; re-run sync; verify README reverted.

**Acceptance Scenarios**:

1. **Given** `skills/task/SKILL.md` Agent Reference table and README agent table differ in row count, **When** sync script runs, **Then** README agent table matches SKILL.md, agent count updated, diff visible in git status.
2. **Given** `refs/scope-pipelines.md` changes (new stage or new cell), **When** sync runs, **Then** README scope-family summary table updated.
3. **Given** sync script is installed as pre-commit hook, **When** user commits with stale README, **Then** hook auto-updates README, re-stages it, and completes commit.
4. **Given** sync script fails (malformed SKILL.md, missing refs file), **When** invoked, **Then** exit code non-zero, clear error message, README untouched.
5. **Given** user explicitly wants custom README text (e.g., marketing copy), **When** sync runs, **Then** sections between `<!-- AUTOSYNC:BEGIN -->` and `<!-- AUTOSYNC:END -->` are regenerated; everything outside those markers is preserved.
6. **Given** sync has never run, **When** invoked for the first time, **Then** it adds `AUTOSYNC` markers around the agent table, pipeline summary, and agent-count paragraph if they match expected format; otherwise exits with instructions.

---

### User Story 5 - Backward Compatibility Across Cycle 3 (Priority: P2)

All Cycle 3 changes must preserve Cycle 2 behavior for users who don't opt in. A user with no prefs file, no slash commands (uses raw `task: ...` invocation), no batch approval acceptance (clicks "per-module"), and no autosync hook must experience a pipeline indistinguishable from Cycle 2.

**Why this priority**: P2 constraint, same rationale as Cycle 1 / Cycle 2 US5: trust preservation. Easy to verify.

**Independent Test**: Fresh user on a fresh system, no `~/.claude/task-prefs.json`, invokes bare `task: add retry logic`. Pipeline runs identically to Cycle 2.

**Acceptance Scenarios**:

1. **Given** no `~/.claude/task-prefs.json` and no project `.claude/task-prefs.json`, **When** skill invoked, **Then** behavior matches Cycle 2 exactly (no new prompts, no new delays).
2. **Given** user never uses slash commands, **When** skill invoked via `task: ...`, **Then** Cycle 2 Adaptive Entry logic runs unchanged.
3. **Given** user on strict-tier scope-L run with 4 independent modules, **When** orchestrator offers batch approval, **Then** user may decline and get Cycle 2's per-module gating. Resulting approval count matches Cycle 2 strict count.
4. **Given** user does not install autosync pre-commit hook, **When** they commit, **Then** no new commit blockers.
5. **Given** Cycle 2 `.task/` workspace being resumed, **When** Cycle 3 skill resumes it, **Then** missing Cycle 3 front-matter fields (`approval_mode`, `prefs_source`) default to safe values (per_module, none).

---

### Edge Cases

- **Slash command name collides with existing command**: `/task-*` namespace is reserved; future commands use same prefix.
- **Slash command with empty argument**: `/task-quick` alone → prompt user for task description; do not start pipeline.
- **Global prefs file exists but is unreadable**: skill logs warning, treats as no-prefs (fail-safe).
- **Project prefs file references stages that don't exist** (e.g., `skip_stages: ["reviewer-xyz"]`): skill logs warning for unknown stage, skips valid ones.
- **Batch approval presented but user accidentally approves one module and wants to redo**: supported via "approve all except N" syntax. If user realizes a mistake later → switch tier mid-flight to strict + individual mode; per-module gating resumes.
- **Decomposer marks modules as independent but Researcher discovers cross-module dependency mid-run**: batch approval was already granted for Planner. Implementer runs per batch; cross-module issues fall through to Debug cycle normally. Batch mode is optimistic; it does not prevent per-module debug.
- **Autosync hook runs but README is open in editor**: hook writes the file; editor prompts user to reload. No data lost (git stages the new version).
- **Autosync runs on a commit that also edits README manually**: if user's manual edits touched AUTOSYNC-marked sections, they are overwritten. Non-AUTOSYNC sections preserved.
- **User installs Cycle 3 slash command files on a project without Task skill**: slash command references `task` skill; if not present, fails gracefully.

## Requirements *(mandatory)*

### Functional Requirements

**Slash commands (US1)**

- **FR-001**: Four markdown command files MUST exist in `.claude/commands/`: `task-quick.md`, `task-fix.md`, `task-feature.md`, `task-full.md`.
- **FR-002**: Each command file MUST invoke the Task skill with a preamble that sets the command's defaults (scope, tier, task_type where applicable).
- **FR-003**: User preamble inside the command body MUST override the command's defaults.
- **FR-004**: Slash commands MUST be documented in `SKILL.md` under a new `## Slash Commands` section.
- **FR-005**: Empty invocation of any slash command MUST prompt the user for a task description rather than starting an empty pipeline.

**User preferences (US2)**

- **FR-006**: The skill MUST check `~/.claude/task-prefs.json` (global) and `<project_root>/.claude/task-prefs.json` (project) at pipeline startup.
- **FR-007**: Precedence: preamble > slash command > project prefs > global prefs > Cycle 2 defaults.
- **FR-008**: Preferences file schema MUST support at minimum: `default_tier`, `default_scope`, `default_delegation`, `skip_stages`, `review_lite` (`skip` or `default`), `approval_mode` (`per_module` or `batch`).
- **FR-009**: Orchestrator MUST record `prefs_source` in pipeline-summary front-matter (`none | global | project | both`) when a preference influenced the run.
- **FR-010**: Missing prefs file MUST NOT produce warnings, prompts, or errors.
- **FR-011**: Malformed prefs file MUST produce a single warning and be ignored; pipeline continues with Cycle 2 defaults.
- **FR-012**: Unknown keys in prefs file MUST be ignored without warning.

**Batch approval (US3)**

- **FR-013**: The orchestrator MUST offer batch approval ONLY when: current tier is `strict`, current stage is Planner/Implementer/Reviewer-Lite, AND all modules reaching this stage are mutually independent per Decomposer's `depends_on: []`.
- **FR-014**: Batch prompt MUST present: count of modules, summary brief of each, options `[approve all] [approve except N] [individual]`.
- **FR-015**: User choice MUST be recorded in pipeline-summary front-matter `approval_mode: per_module | batch` per stage type.
- **FR-016**: Once user chooses `individual` at a stage type, subsequent stages of same type MUST continue in `individual` mode without re-prompting.
- **FR-017**: Batch mode is per-stage-type, not per-run: a user can batch Planner approvals and individually approve Implementers.
- **FR-018**: Standard and express tiers MUST NOT offer batch approval (they don't gate per-module in those tiers).

**README autosync (US4)**

- **FR-019**: A sync script MUST exist at `.claude/scripts/sync-readme.sh` that regenerates README sections from SKILL.md + `refs/model-tiers.md` + `refs/scope-pipelines.md`.
- **FR-020**: README MUST mark regenerable regions with `<!-- AUTOSYNC:BEGIN section-name -->` and `<!-- AUTOSYNC:END -->` HTML comments.
- **FR-021**: Sections subject to autosync: agent count paragraph, agent table, scope-family summary table, pipeline overview diagram.
- **FR-022**: Running sync on an already-synchronized README MUST produce zero diff.
- **FR-023**: A pre-commit hook MUST be optionally installable via `./install-hooks.sh` in the repo.
- **FR-024**: Sync script exit code MUST be 0 on success, 1 on parse error (with error to stderr), 2 on missing files.

**Backward compatibility (US5)**

- **FR-025**: A user with no prefs file and using bare `task: <req>` invocations MUST see Cycle 2 behavior unchanged (no new prompts, no new delays, same approval count).
- **FR-026**: Cycle 2 `.task/` workspaces MUST resume cleanly; missing `approval_mode` defaults to `per_module`; missing `prefs_source` defaults to `none`.
- **FR-027**: README autosync markers MUST be added idempotently: if already present, script skips adding; if absent, script adds on first successful run.
- **FR-028**: Users without pre-commit hooks installed MUST experience no commit delays.

**Observability**

- **FR-029**: Pipeline summary body MUST log preference application per resolved field (e.g., `tier: strict [source: global prefs]`).
- **FR-030**: Slash command entry MUST record which command was used (`entry_point: /task-full` in front-matter).

### Key Entities

- **SlashCommand**: `{name, default_scope?, default_tier?, default_task_type?, body_template}`. Four instances: `/task-quick`, `/task-fix`, `/task-feature`, `/task-full`.
- **UserPreferences**: `{default_tier?, default_scope?, default_delegation?, skip_stages?, review_lite?, approval_mode?}`. JSON document at `~/.claude/task-prefs.json` and/or `<project>/.claude/task-prefs.json`.
- **PrefsSource**: enum `{none, global, project, both}`. Recorded in pipeline-summary front-matter.
- **ApprovalMode**: enum `{per_module, batch}`. Per-stage-type decision, recorded in pipeline-summary front-matter.
- **BatchApprovalContext**: `{stage_type, modules_independent, batch_offered, user_choice}`. One per eligible stage-type invocation.
- **AutosyncRegion**: `{section_name, begin_marker, end_marker, generator_source}`. Maps each AUTOSYNC block in README to its SKILL.md/refs source.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: User can invoke `/task-quick foo` and see a 1-approval pipeline complete successfully (no need to learn preamble).
- **SC-002**: User can invoke `/task-full migrate auth` and see strict-tier L/XL behavior without any preamble.
- **SC-003**: Preferences file with `{default_tier: "strict"}` causes default-tier selection to choose strict in 100% of test runs with no preamble.
- **SC-004**: Preference precedence verified in 100% of test combinations: preamble > slash > project > global > Cycle 2.
- **SC-005**: Malformed prefs file produces at most one warning log entry; pipeline completes successfully.
- **SC-006**: On a scope-L strict-tier feature with 4 independent modules, accepting batch approval for Planner/Implementer/Reviewer-Lite reduces approval count from Cycle 2's 12 per-module gates to 3 batch gates (75% reduction).
- **SC-007**: Batch approval is never offered in standard/express tier or when modules have dependencies.
- **SC-008**: README autosync script produces identical output on second run (idempotent); diff against first output is zero bytes.
- **SC-009**: Adding a new agent to SKILL.md Agent Reference + `refs/model-tiers.md` and running sync updates README agent count AND adds the new row within 5 seconds.
- **SC-010**: User running bare `task: ...` with no prefs file and no Cycle 3 features experiences approval count, stage order, and artifact shape identical to Cycle 2 in 100% of test runs.

## Assumptions

- Users are familiar with Claude Code slash command conventions (command files in `.claude/commands/` with YAML frontmatter + body template).
- Most users will not hand-edit `task-prefs.json`; if adoption takes off, a future cycle can add a `/task-prefs` command for interactive editing.
- "Independent modules" per Decomposer is accurate; if Decomposer misclassifies dependencies, batch approval may surface bugs that per-module gating would catch earlier. This is an accepted risk at P2.
- README autosync is opt-in per repo via manual install (`install-hooks.sh`). Global enforcement is out of scope.
- Preference precedence is stable: users will not chain multiple override layers unless they understand them. Documentation in README + refs covers the rules.
- Cycle 1 and Cycle 2 guarantees (scope/tier, Spec merge, model rebalance, Review-Lite, SKILL.md split, delegation fallback, strict-tier backward-compat) remain intact.

## Out of Scope (This Cycle)

- Version-pinning of superpowers plugin (deferred; no cycle planned).
- Scout caching based on project state hash (deferred).
- Any change to Cycle 1 scope thresholds, tier defaults, or approval gate semantics beyond introducing `approval_mode`.
- Interactive prefs editor (e.g., `/task-prefs show/set/reset` commands).
- README autosync global enforcement via CI — opt-in per repo.
- Slash commands beyond the 4 declared (future cycles can add with same pattern).
- Cross-project sharing of `.task-history/` or spec archives.
