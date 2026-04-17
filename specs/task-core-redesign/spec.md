# Feature Specification: Task Skill Core Redesign for Daily Usability

**Feature Branch**: `task-core-redesign`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Task skill core redesign for daily usability. Four coordinated changes to skills/task/: (1) scope-driven adaptive pipeline; (2) three-tier approval model; (3) merge Brainstormer and Validator into a single Spec agent; (4) rebalance agent models. Pipeline must remain backward-compatible in strict mode. Out of scope for this cycle: superpowers delegation, SKILL.md split, state persistence, slash commands, review-lite, batch approvals, README autosync, parallelism."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scope-Driven Pipeline Adaptation (Priority: P1)

A developer invokes the Task skill for a small, well-understood change (e.g., rename a function, add a field to an existing DTO). Instead of being forced through all 15 pipeline stages with multiple approval gates, the skill automatically classifies the task as small scope and executes a minimal pipeline with a single final approval. Conversely, when the developer invokes the skill for a large, cross-cutting feature, the skill runs the full pipeline with all gates intact.

**Why this priority**: This is the single largest daily-usability win. Today the Task skill is impractical for the majority of tasks that are small, forcing 6-10+ approval clicks to rename something or add a simple endpoint. Without this change the skill remains a heavyweight tool reserved for occasional large features, not a daily companion. All other changes in this cycle amplify this one.

**Independent Test**: Invoke the skill on a small task (single file, single function change) and on a large task (multi-module refactor). Verify that the small task pipeline contains 3-5 stages and the large task pipeline contains the full 15 stages. No behavior changes beyond pipeline selection should occur; both tasks should complete successfully.

**Acceptance Scenarios**:

1. **Given** a task that touches 1 file and involves no architectural decisions, **When** the skill runs classification, **Then** the scope is classified as XS and the pipeline contains Implementer plus Tester plus Committer only.
2. **Given** a task that touches 2-5 files within a single module, **When** the skill runs classification, **Then** the scope is classified as S and the pipeline adds Planner before Implementer.
3. **Given** a task that touches 5-15 files across 2-3 modules, **When** the skill runs classification, **Then** the scope is classified as M and the pipeline includes Scout, Decomposer, per-module Research/Plan/Impl/Test, and Committer.
4. **Given** a task that touches 15-40 files across 3-5 modules, **When** the skill runs classification, **Then** the scope is L and the pipeline adds Reviewer, Refactorer, Documenter stages.
5. **Given** a task that touches 40+ files or declares design work, **When** the skill runs classification, **Then** the scope is XL and the full pipeline runs including Designer and Design-QA stages for UI modules.
6. **Given** a task where the user explicitly declares scope (e.g., `scope: L`), **When** the skill runs classification, **Then** the user-declared scope overrides automatic classification.

---

### User Story 2 - Three-Tier Approval Control (Priority: P1)

A developer wants control over how often the skill pauses for approval. For fast, low-risk tasks, they want to approve only at the end (express tier). For medium tasks, they want to approve at meaningful decision points (standard tier). For large or critical tasks, they want to approve every stage (strict tier, matching today's behavior). The skill auto-selects a default tier based on scope, but the developer can override it at invocation or mid-flight.

**Why this priority**: Approval overhead is the second-order cost of the current skill. Even with a scope-driven pipeline, if a medium task still has 7 approval gates, it remains impractical for daily use. Pairing scope with tier gives the developer two orthogonal knobs: how many stages run, and how often the skill interrupts for input. P1 because it compounds with US1; without approval tiering, US1 alone only cuts stages, not interruptions.

**Independent Test**: Run the same task at each of the three approval tiers and count approval prompts. Express tier must produce exactly 1 approval (commit), standard tier must produce exactly 3 approvals (Spec + Decomposition + Commit), strict tier must preserve current behavior (one approval per approval-gated stage).

**Acceptance Scenarios**:

1. **Given** scope XS or S, **When** pipeline starts with no tier override, **Then** the default tier is express and only the final commit stage requires approval.
2. **Given** scope M, **When** pipeline starts with no tier override, **Then** the default tier is standard and approvals are required only at Spec completion, Decomposition completion, and final commit.
3. **Given** scope L or XL, **When** pipeline starts with no tier override, **Then** the default tier is strict and approval behavior is identical to the pre-redesign skill.
4. **Given** any scope, **When** the user explicitly declares tier (e.g., `tier: strict` or `tier: express`), **Then** the user-declared tier overrides the scope-based default.
5. **Given** an active pipeline in express tier, **When** the user requests to switch to strict mid-flight, **Then** subsequent approval-gated stages begin prompting for approval and stages already completed are not re-run.
6. **Given** a critical security-related task (task metadata or user flag indicates criticality), **When** the pipeline starts with no tier override, **Then** the skill recommends strict tier regardless of scope and asks for confirmation before proceeding with a lower tier.

---

### User Story 3 - Unified Spec Stage (Priority: P2)

A developer today sees two separate stages at the start of the pipeline: Brainstormer (interactive dialogue to produce a spec) and Validator (checks the spec is complete). Both run on opus, both ask for approval, both read the same sections. In the redesigned skill, a single Spec agent handles both responsibilities in two modes: interactive (when no spec is provided, runs the dialogue) or validate (when a spec document is provided, transforms it into project format and validates it). The developer sees one stage, produces one output document, grants one approval.

**Why this priority**: P2 because it is strictly an efficiency improvement — it does not change what the user can accomplish, only how much friction is between them and the outcome. It is also a prerequisite simplification for future cycles (e.g., delegating to superpowers brainstorming). Doing this now prevents later cycles from having to split the work across two agents.

**Independent Test**: Invoke the skill with no prior spec and verify Spec agent enters interactive mode, produces `.task/00-spec.md` with full spec content and a `## Validation` section marked PASS. Then invoke the skill with a ready-made spec file path and verify Spec agent enters validate mode, transforms the input into the project format, and produces `.task/00-spec.md` with the `## Validation` section reflecting any gaps or weaknesses.

**Acceptance Scenarios**:

1. **Given** no existing spec artifact and no user-provided document, **When** the pipeline starts, **Then** the Spec agent runs in interactive mode conducting the structured dialogue previously handled by Brainstormer.
2. **Given** a user-provided spec document (file path or pasted content) or a detected fresh spec in the project's conventional spec location, **When** the pipeline starts, **Then** the Spec agent runs in validate mode, transforms the input into the project's canonical spec format, and runs validation checks.
3. **Given** the Spec agent completes in either mode, **When** the output is written to `.task/00-spec.md`, **Then** the file contains both the spec body and a `## Validation` section with one of: PASS, PASS WITH WARNINGS, NEEDS ATTENTION.
4. **Given** a spec produced by the Spec agent in interactive mode, **When** validation runs as part of the same agent execution, **Then** validation does not prompt for a second user approval (one approval per Spec stage, not two).
5. **Given** validation finds Gap or Conflict findings, **When** the Spec agent presents results, **Then** the user sees the same three options as today (fix in spec, ignore, return to interactive mode).

---

### User Story 4 - Cost-Efficient Model Allocation (Priority: P3)

The skill consumes LLM tokens on every agent invocation. Today, every agent that involves any reasoning defaults to opus or sonnet regardless of actual cognitive demand. A developer running 10 medium tasks a day generates significant cost primarily driven by opus calls on agents performing mechanical work (field presence checks, file system scanning, checklist comparison). In the redesign, each agent is assigned a model tier matching its actual cognitive load: opus is reserved for genuine architectural reasoning (Decomposer, Planner); sonnet for code-generating or multi-file-reasoning work (Implementer, Tester, Debugger, Reviewer, Designer, Spec interactive mode, Researcher); haiku for mechanical or checklist-driven work (Spec validate mode, Scout, Design-QA, Refactorer, Documenter, Committer).

**Why this priority**: P3 because it is pure cost/speed optimization with no user-visible functional change. It would be valuable on its own, but less valuable than US1/US2 (which change what developers can actually do with the skill) and depends on US3 (which introduces the Spec agent whose modes have different tiers). Can be safely deferred or simplified without breaking the core redesign.

**Independent Test**: For each agent, verify the assigned model tier matches the target allocation. Run a representative medium task and measure total token cost by tier. Cost reduction must be measurable compared to the pre-redesign baseline on the same task.

**Acceptance Scenarios**:

1. **Given** the pipeline starts, **When** the Scout stage runs, **Then** the Scout agent executes on haiku.
2. **Given** the Spec stage runs in validate mode, **When** the agent executes, **Then** it runs on haiku.
3. **Given** the Spec stage runs in interactive mode, **When** the agent executes, **Then** it runs on sonnet.
4. **Given** the Designer stage runs, **When** the agent executes, **Then** it runs on sonnet.
5. **Given** the Design-QA stage runs, **When** the agent executes, **Then** it runs on haiku.
6. **Given** the Decomposer or Planner stages run, **When** the agents execute, **Then** they run on opus.
7. **Given** a representative medium-scope task, **When** the full pipeline runs to completion, **Then** opus-tier token consumption is reduced by at least 40% compared to the baseline (pre-redesign) pipeline on the same task.

---

### User Story 5 - Backward Compatibility in Strict Mode (Priority: P2)

An existing user of the Task skill has habits, expectations, and in-flight tasks built around current behavior. After the redesign ships, they must be able to continue using the skill without surprises. Invoking the skill with `tier: strict` (or scope L/XL which defaults to strict) must reproduce the pre-redesign approval behavior exactly. The Spec agent in interactive mode must run the same structured dialogue as the prior Brainstormer. All existing `.task/` workspace artifacts must remain readable.

**Why this priority**: P2 because breaking existing workflows destroys trust in the skill. However, it is not P1 because it is a non-functional constraint rather than a new capability, and failure to satisfy it is visible immediately during testing (not a hidden regression).

**Independent Test**: Run an identical task through the pre-redesign skill and through the redesigned skill in strict mode. Compare: number of approval prompts, order of stages, filename and content format of artifacts written to `.task/`. Differences should be zero for approval count and stage order, and limited to the Validation section (new) and model assignments (transparent to flow) for artifacts.

**Acceptance Scenarios**:

1. **Given** a scope-L or scope-XL task, **When** the pipeline runs with no tier override, **Then** the default tier is strict and approval behavior matches the pre-redesign pipeline stage-for-stage.
2. **Given** any scope, **When** the user declares `tier: strict`, **Then** approval behavior matches the pre-redesign pipeline.
3. **Given** an existing `.task/` workspace from a prior skill version, **When** the redesigned skill is invoked to resume, **Then** it reads existing artifacts successfully and continues from the next incomplete stage.
4. **Given** a Spec stage running in interactive mode under strict tier, **When** the dialogue progresses, **Then** the question flow, section order, and approval prompts match the pre-redesign Brainstormer behavior.
5. **Given** a user who never customizes tier or scope, **When** they invoke the skill on the kinds of tasks they normally ran pre-redesign, **Then** they experience equal or fewer approval prompts, never more.

---

### Edge Cases

- **Scope ambiguity at invocation**: When the skill cannot confidently classify scope from the task description alone (e.g., description is too abstract, task touches a codebase area not yet scouted), the skill must default to the next-larger scope tier and surface its classification reasoning so the user can override early.
- **Scope upgrade mid-pipeline**: When implementation reveals the task is larger than originally classified (e.g., Researcher discovers 30 affected files on what was classified as scope M), the skill must detect the mismatch, pause, and ask the user whether to upgrade the pipeline to L/XL or continue with the current scope.
- **Scope downgrade mid-pipeline**: When Decomposer produces fewer modules than the scope implied, the skill does not automatically downgrade — changing tiers mid-flight creates confusion about which approvals already happened. Report the mismatch in the pipeline summary only.
- **Critical task with low scope**: A scope-S task flagged as security-critical or production-impacting must not run in express tier by default. The skill detects criticality from task metadata or user signals and recommends strict tier with confirmation.
- **User provides both scope and tier override conflicting with criticality**: The user's explicit declarations take precedence over skill recommendations. The skill logs its concern in the pipeline summary but does not block.
- **Spec validate mode with malformed input**: When the Spec agent in validate mode receives input it cannot map to project spec format (unreadable, corrupted, or wildly non-conforming document), it must report the failure and offer to fall back to interactive mode rather than producing a malformed `00-spec.md`.
- **Spec validate mode with partial input**: When some required sections are missing from the input document, Spec agent generates stubs marked as generated content (consistent with current Validator behavior), includes them in the Validation section as Gap findings, and presents the Gap report for user resolution.
- **Existing pipeline resume across redesign boundary**: A user with an in-flight `.task/` from the pre-redesign skill must be able to resume. The redesigned skill detects the absence of scope/tier metadata in the pipeline summary and defaults to strict tier for safety.
- **Model tier unavailable at runtime**: If a requested model tier is unavailable (API outage, missing plan), the skill must surface the specific stage that cannot execute and offer to fall back to an available tier with a clearly logged degradation note.
- **Interactive Spec dialogue interrupted**: If the user abandons the Spec interactive dialogue partway (as happens with the current Brainstormer), the skill must preserve partial output in `.task/00-spec.md` and allow resuming from the last approved section.

## Requirements *(mandatory)*

### Functional Requirements

**Scope classification and pipeline selection**

- **FR-001**: The skill MUST classify every task into one of five scope tiers: XS, S, M, L, XL.
- **FR-002**: Scope classification MUST consider at minimum: estimated number of affected files, estimated number of modules, presence of explicit design work, and task-type signals (feature/bugfix/refactor/hotfix).
- **FR-003**: Scope classification MUST produce a rationale visible to the user (at least: which signals drove the classification).
- **FR-004**: The skill MUST support user-declared scope override at invocation time and MUST prefer the user declaration over automatic classification.
- **FR-005**: The skill MUST maintain a documented mapping from scope tier to pipeline stages such that the same scope always produces the same stage list.
- **FR-006**: Pipeline stage selection by scope MUST preserve the existing task-type differentiation (a bugfix at scope M produces a different pipeline from a feature at scope M where appropriate).

**Approval tiering**

- **FR-007**: The skill MUST support three approval tiers: strict, standard, express.
- **FR-008**: In express tier, only the final commit stage MUST require explicit user approval.
- **FR-009**: In standard tier, exactly three stages MUST require approval: Spec completion, Decomposition completion, final commit.
- **FR-010**: In strict tier, all stages currently marked `[approval]` in the pipeline MUST continue to require approval.
- **FR-011**: The skill MUST auto-select a default tier from scope: XS/S default to express, M defaults to standard, L/XL default to strict.
- **FR-012**: The skill MUST support user-declared tier override at invocation time and MUST prefer the user declaration over scope-based default.
- **FR-013**: The skill MUST support tier change mid-pipeline; subsequent stages MUST honor the new tier without re-running completed stages.
- **FR-014**: When a task is flagged as critical (security-sensitive, production-impacting, or explicitly marked), the skill MUST recommend strict tier regardless of scope and MUST require explicit confirmation before proceeding with a lower tier.

**Spec agent unification**

- **FR-015**: The skill MUST expose a single Spec stage (replacing separate Brainstormer and Validator stages) that operates in one of two modes per invocation.
- **FR-016**: When no spec artifact exists and no user-provided document is detected, the Spec agent MUST run in interactive mode conducting a structured dialogue equivalent to the current Brainstormer behavior.
- **FR-017**: When a spec artifact or user-provided document is detected, the Spec agent MUST run in validate mode, transforming the input into the project's canonical spec format and running completeness, consistency, and testability checks.
- **FR-018**: The Spec agent MUST write a single output document `.task/00-spec.md` containing both the spec body and a `## Validation` section reporting PASS, PASS WITH WARNINGS, or NEEDS ATTENTION.
- **FR-019**: The Spec agent MUST complete both modes with exactly one user approval prompt at the end of the stage (not one per mode, not one per section beyond the interactive dialogue's existing per-section approvals).
- **FR-020**: The mode detection logic MUST match the current Adaptive Entry behavior (user-passed path wins, then fresh spec in conventional location, then TRC spec location, else interactive).

**Model allocation**

- **FR-021**: The skill MUST assign each agent a specific model tier (opus/sonnet/haiku).
- **FR-022**: Model tier assignments MUST be: Spec validate mode on haiku; Spec interactive mode on sonnet; Scout on haiku; Design-QA on haiku; Designer on sonnet; Decomposer on opus; Planner on opus; Researcher on sonnet; Implementer on sonnet; Tester on sonnet; Debugger on sonnet; Reviewer on sonnet; Refactorer on haiku; Documenter on haiku; Committer on haiku.
- **FR-023**: Model tier assignments MUST be declared in a single authoritative location such that changes do not require editing every agent file individually to stay consistent.

**Backward compatibility**

- **FR-024**: Strict tier MUST reproduce pre-redesign approval behavior for every pipeline stage.
- **FR-025**: Spec agent in interactive mode under strict tier MUST reproduce the pre-redesign Brainstormer question flow and section ordering.
- **FR-026**: The skill MUST read existing `.task/` artifacts from the pre-redesign skill without errors and MUST resume a pre-redesign in-flight pipeline from the next incomplete stage.
- **FR-027**: When resuming a pipeline that predates scope/tier metadata, the skill MUST default to strict tier.

**Observability**

- **FR-028**: The pipeline summary file MUST record the classified scope and active tier for every completed task.
- **FR-029**: Every stage skipped due to scope selection MUST be visible in the pipeline summary with the reason (e.g., "Skipped by scope S").
- **FR-030**: Every deviation from default tier (user override, criticality recommendation, mid-flight change) MUST be logged in the pipeline summary.

### Key Entities

- **Scope tier**: A five-level classification of task size (XS, S, M, L, XL). Each tier has documented signals (file count, module count, UI presence) and a pipeline mapping.
- **Approval tier**: A three-level classification of approval density (strict, standard, express). Each tier has a documented set of stages at which approval is required.
- **Pipeline definition**: An ordered list of stages for a given (scope, task-type) combination. Pipeline definitions are the single source of truth for which stages run when.
- **Spec agent mode**: One of interactive or validate. Selected per invocation based on input detection; each mode has distinct inputs, processes, and model assignments but shares output format.
- **Model tier assignment**: A declarative mapping from (agent, mode) to model (opus/sonnet/haiku). Agents consult this mapping rather than hardcoding model in individual agent prompts.
- **Pipeline summary**: The existing `.task/pipeline-summary.md` artifact, extended to record scope, tier, overrides, and skipped stages.
- **Task criticality signal**: A boolean indicator on the task (from user flag, task keywords like "security" or "production", or spec metadata) that influences tier recommendation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a representative scope-S task, approval prompts are reduced from the current 5+ to exactly 1, measured by counting approval interactions from pipeline start to commit presentation.
- **SC-002**: For a representative scope-M task, approval prompts are reduced from the current 7+ to exactly 3, measured the same way.
- **SC-003**: For a representative scope-L/XL task, approval prompts remain identical to pre-redesign behavior (backward compatibility).
- **SC-004**: For a representative scope-M task run through the full pipeline, opus-tier token consumption is reduced by at least 40% compared to the pre-redesign baseline on the same task.
- **SC-005**: Total wall-clock time from invocation to commit presentation for a representative scope-S task is reduced by at least 50% compared to the pre-redesign baseline.
- **SC-006**: 100% of tasks produce a `## Validation` section in `.task/00-spec.md` regardless of whether they entered interactive or validate mode.
- **SC-007**: 100% of completed pipelines record scope and tier in the pipeline summary.
- **SC-008**: Zero of the pre-redesign test tasks produce more approval prompts under strict tier in the redesigned skill than they did in the pre-redesign skill.
- **SC-009**: For a user invoking the skill without declaring scope or tier, the skill completes classification and tier selection in under 2 seconds of wall-clock time (classification overhead does not become a new friction point).
- **SC-010**: When a pre-redesign `.task/` workspace is present, the redesigned skill resumes it without errors in 100% of test cases.

## Assumptions

- The existing pipeline structure (stage order, dependencies between stages, approval semantics) is broadly correct; this cycle reshapes which stages run and when approvals happen, not what each stage does internally (other than the Spec merge).
- Task-type classification (feature/bugfix/refactor/hotfix) already exists and continues to function; scope classification is a new, orthogonal axis layered on top.
- Users will accept the skill's default scope and tier selections most of the time. Override mechanisms exist but are not expected to be the common path.
- The `.task/pipeline-summary.md` format can be extended with new fields without breaking agents that read it (append-only additions).
- A single authoritative location for model tier assignments is preferable to scattered declarations; the exact file location is an implementation detail.
- Superpowers delegation, state persistence across tasks, slash command entry points, per-module review, and other items explicitly listed as out of scope will be addressed in follow-up cycles and are not prerequisites for this cycle.
- Existing users of the skill are willing to test the redesign and report regressions; the backward-compatibility guarantees in US5 are enforced by test, not by policy alone.
- The skill's downstream plugins (security-scanning, git-pr-workflows, agent-teams, context7, frontend-design) continue to function as today; this cycle does not touch plugin integration.

## Out of Scope (This Cycle)

The following items are explicitly deferred to later cycles and are not to be addressed by the plan or implementation of this cycle:

- Delegation of Brainstormer/Planner/Debugger to superpowers skills.
- Splitting SKILL.md into a thin shell plus referenced sub-documents.
- Persistence of user preferences or task history across invocations.
- Dedicated slash command entry points (e.g., `/task-quick`, `/task-fix`).
- Per-module review-lite stage.
- Batch approval for independent modules and real parallelism at approval gates.
- README auto-synchronization with SKILL.md.
- Any change to the downstream plugin integrations.
