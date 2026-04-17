# Implementation Plan: Task Skill Core Redesign for Daily Usability

**Branch**: `task-core-redesign` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/task-core-redesign/spec.md`

## Summary

Reshape the Task skill orchestrator (`skills/task/SKILL.md` plus 15 agent files) around two new orthogonal axes — **scope** (XS/S/M/L/XL classification of task size) and **approval tier** (strict/standard/express density of user approval prompts) — while merging the Brainstormer and Validator agents into one two-mode Spec agent and rebalancing model tiers across all agents. Strict tier preserves exact pre-redesign approval behavior for safety. All state lives in markdown files; no runtime, no package manager, no tests beyond manual pipeline dry-runs on representative tasks.

**Technical approach**: Introduce three new reference documents (`refs/scope-pipelines.md`, `refs/approval-tiers.md`, `refs/model-tiers.md`) as authoritative data tables. Extend SKILL.md with scope-classification and tier-selection logic that reads those tables. Replace `agents/brainstormer.md` + `agents/analyst.md` with a single `agents/spec.md` supporting `interactive` and `validate` modes. Update each agent's frontmatter-declared model tier to match the authoritative mapping. Extend the `pipeline-summary.md` format to record scope, tier, overrides, and skipped stages without breaking downstream readers.

## Technical Context

**Language/Version**: Markdown (CommonMark); YAML frontmatter for skill/agent metadata; bash for TRC lifecycle scripts (unchanged)
**Primary Dependencies**: Claude Code CLI (runtime); optional plugins `security-scanning`, `git-pr-workflows`, `agent-teams`, `frontend-design`; optional MCP `context7`
**Storage**: File system only — `skills/task/` for skill source; `.task/` workspace for per-run artifacts; `.task/pipeline-summary.md` as extended record
**Testing**: Manual validation only per constitution (`No package manager, no build, no lint, no tests`); acceptance verified by dry-run pipelines on representative tasks at each scope/tier combination
**Target Platform**: Claude Code (CLI), Claude Desktop, Claude Code web, IDE extensions — any host that loads Claude Code skills
**Project Type**: Toolkit / skill collection (markdown-only prompt engineering artifacts)
**Performance Goals**: Classification overhead under 2s wall-clock (SC-009); at least 40% opus-token reduction on scope-M pipelines (SC-004); at least 50% wall-clock reduction on scope-S pipelines (SC-005)
**Constraints**: Strict-tier approval behavior must remain bit-compatible with pre-redesign (FR-024, US5); pre-redesign `.task/` workspaces must remain resumable (FR-026); no changes to SKILL.md split, slash commands, state persistence, or plugin delegation (Out of Scope)
**Scale/Scope**: 1 skill (Task), 15 agents today (14 after Spec merge) plus 4-5 new/modified reference documents, ~30 functional requirements, 10 success criteria

## Constitution Check

Constitution from `.trc/memory/constitution.md` — verified against each mandate:

| Mandate | Status | Notes |
|---|---|---|
| Markdown-only, no runtime/build/tests | PASS | All artifacts are markdown; no code, no compiled assets, no test runner introduced |
| File-based agent communication (`.task/` workspace) | PASS | Preserved and extended; `pipeline-summary.md` gains new fields only (append-only additions, FR-028/029/030) |
| Progressive disclosure (3 levels: metadata / instructions / refs on demand) | PASS WITH NOTE | Scope/tier logic pushed to new `refs/*.md` files per Level 3 convention; SKILL.md grows by ~50-80 lines of orchestration logic (stage dispatcher). Growth is tracked in Complexity Tracking below; split of SKILL.md itself is explicitly deferred to Cycle 2 by spec. |
| Adaptive pipeline (task type determines stages) | EXTENDED | Scope becomes a second axis orthogonal to task type; task-type differentiation (FR-006) is preserved |
| Plugin delegation with fallback | PASS | No change to plugin integration in this cycle (Out of Scope) |
| Brief sections on every agent output | PASS | Unchanged; Spec agent preserves Brief convention and adds `## Validation` section |
| Agent declarations: inputs, outputs, model tier | STRENGTHENED | Model tier moves from per-agent frontmatter string to single authoritative `refs/model-tiers.md` table (FR-023); per-agent frontmatter references the table |
| Reference docs on-demand | PASS | 3-4 new refs added under existing `agents/refs/` pattern; loaded only when SKILL.md / Spec agent needs them |
| Git workflow: feature-name branching, conventional commits, squash merge | PASS | Already on branch `task-core-redesign`; plan documents no deviation |

**Gate outcome**: PASS. One note (SKILL.md growth) tracked in Complexity section below with rationale and mitigation. No violations block Phase 0.

**Post-design re-check** (after Phase 1 artifacts produced): to be updated at end of planning; currently expected PASS subject to no unforeseen data-model expansion.

## Project Structure

### Documentation (this feature)

```text
specs/task-core-redesign/
├── spec.md                  # Feature specification (complete)
├── plan.md                  # This file
├── research.md              # Phase 0 output
├── data-model.md            # Phase 1 output
├── quickstart.md            # Phase 1 output
├── contracts/               # Phase 1 output
│   ├── skill-invocation.md         # How user passes scope/tier at invocation
│   ├── pipeline-summary.md         # Extended pipeline-summary.md schema
│   ├── spec-document.md            # .task/00-spec.md schema with Validation section
│   └── agent-frontmatter.md        # Agent model tier declaration contract
├── checklists/
│   └── requirements.md      # Spec quality checklist (complete)
└── tasks.md                 # Phase 2 output (NOT created here — /trc.tasks)
```

### Source Code (repository root)

Single-project toolkit layout. Files changed or added are scoped entirely to `skills/task/`:

```text
skills/task/
├── SKILL.md                                # MODIFIED: scope classifier, tier selector, pipeline dispatcher
├── agents/
│   ├── spec.md                             # NEW: merged Brainstormer + Validator, two modes
│   ├── brainstormer.md                     # REMOVED (merged into spec.md)
│   ├── analyst.md                          # REMOVED (merged into spec.md)
│   ├── scout.md                            # MODIFIED: model tier → haiku
│   ├── decomposer.md                       # UNCHANGED (opus confirmed)
│   ├── researcher.md                       # UNCHANGED (sonnet confirmed)
│   ├── planner.md                          # UNCHANGED (opus confirmed)
│   ├── designer.md                         # MODIFIED: model tier → sonnet (was opus)
│   ├── implementer.md                      # UNCHANGED (sonnet confirmed)
│   ├── tester.md                           # UNCHANGED (sonnet confirmed)
│   ├── debugger.md                         # UNCHANGED (sonnet confirmed)
│   ├── design-qa.md                        # MODIFIED: model tier → haiku (was sonnet)
│   ├── reviewer.md                         # UNCHANGED (sonnet confirmed)
│   ├── refactorer.md                       # UNCHANGED (haiku confirmed)
│   ├── documenter.md                       # UNCHANGED (haiku confirmed)
│   ├── committer.md                        # UNCHANGED (haiku confirmed)
│   └── refs/
│       ├── scope-pipelines.md              # NEW: scope → stages mapping table
│       ├── approval-tiers.md               # NEW: strict/standard/express rules
│       ├── model-tiers.md                  # NEW: authoritative model-tier assignments
│       ├── criticality-signals.md          # NEW: keywords & flags that trigger strict recommendation
│       ├── spec-dialogue-patterns.md       # NEW: moved from brainstorm-patterns.md (renamed to reflect merge)
│       ├── brainstorm-patterns.md          # REMOVED (renamed to spec-dialogue-patterns.md)
│       ├── architecture-checklist.md       # UNCHANGED
│       ├── commit-conventions.md           # UNCHANGED
│       ├── commit-template.md              # UNCHANGED
│       ├── debug-examples.md               # UNCHANGED
│       ├── design-tokens-example.md        # UNCHANGED
│       ├── doc-formats.md                  # UNCHANGED
│       ├── performance-checklist.md        # UNCHANGED
│       └── security-checklist.md           # UNCHANGED
```

**Structure Decision**: Single-project toolkit. All changes live under `skills/task/`. No new top-level directories. Reference documents for scope, tier, and model tables live inside `skills/task/agents/refs/` following the existing Level 3 progressive disclosure pattern. The Spec agent replaces two files with one; dialogue patterns are renamed but content structure is preserved for diff-ability.

## Complexity Tracking

| Decision / Deviation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| SKILL.md grows by ~60-80 lines for scope classifier and tier selector | Scope classification and tier dispatch are orchestration concerns, not stage concerns; they must live where the orchestrator reads them before any agent is dispatched | Pushing dispatch logic into a dedicated ref still requires SKILL.md to contain the invocation glue; hiding everything in refs makes the orchestrator behavior opaque |
| Four new reference documents in `agents/refs/` (scope-pipelines, approval-tiers, model-tiers, criticality-signals) | Each is a distinct authoritative data table consulted at different times in the pipeline by different readers (orchestrator, Spec agent, every agent) | Merging all tables into one ref would bind unrelated decisions together and force every reader to load data it doesn't need |
| Single authoritative model-tier table (FR-023) | Without central declaration, changing any tier requires editing every agent file and the risk of drift is high; audit impossible | Keeping model tier in each agent's frontmatter was the pre-redesign approach and produced the exact misallocation this cycle corrects |
| Two modes (interactive/validate) in one Spec agent file | Merging eliminates a duplicate approval gate and collapses two opus-tier agents into one file with mode-appropriate models; modes share output format | Keeping two files means maintaining both and re-justifying their separation each time Spec behavior evolves |
| Spec agent interactive mode runs on sonnet, validate mode on haiku | Per-invocation mode is known before agent dispatch; orchestrator can select model based on detected mode | Using a single model for both modes either overpays for validation (sonnet) or underpowers dialogue (haiku) |

No constitution violations. The two entries above are design notes, not waivers.

## Phase 0: Outline & Research

See [research.md](./research.md) for full findings. Summary of decisions below.

### Key research questions resolved

1. **Scope classification signals & thresholds** — Decision: use four weighted signals (estimated file count, estimated module count, UI-presence flag, task-type hint). Thresholds as defined in spec FR-001..006 and acceptance scenarios US1.1-5. Tie-break rule: round up (prefer larger scope) when signals are mixed. Early classification by the Spec agent based on the spec's Key Entities + user stories count + scope IN/OUT size; refined post-Scout.
2. **How user overrides scope/tier at invocation** — Decision: accept YAML-style preamble in user prompt (e.g., `scope: L, tier: strict`) or explicit keywords in natural language ("please run strict"). The orchestrator parses these before classification. No new CLI flags (out of scope — cycle 3).
3. **Model tier mapping location** — Decision: single file `agents/refs/model-tiers.md` with a table `(agent, mode) -> model`. Agent frontmatter still declares `model: see model-tiers.md` for discoverability; orchestrator reads the table at dispatch time.
4. **Criticality detection** — Decision: keyword-based detection over user request and spec content (keywords: "security", "production", "hotfix", "critical", "breaking", "data loss", "auth", "payment", "pii"). Plus explicit user flag `critical: true` in preamble. Recommendation presented as a gate prompt; user confirms or declines with one reply.
5. **Pipeline-summary.md extension** — Decision: add a front-matter YAML block at the top of `pipeline-summary.md` with fields `scope`, `tier`, `scope_override`, `tier_override`, `criticality_flag`, `skipped_stages[]`. Existing markdown body unchanged — downstream agents (Documenter, Committer) that read the body continue to work; only the Orchestrator reads the front-matter.
6. **(scope, task_type) -> stages mapping** — Decision: matrix defined in `scope-pipelines.md` as a 5x4 table (5 scopes × 4 task types). Feature/refactor cells fully populated; bugfix/hotfix cells prune Scout/Decomposer/Designer/Design-QA/Documenter where redundant. Exact table in data-model.md.
7. **Mid-pipeline tier change** — Decision: tier stored in-memory on the orchestrator's state and mirrored to `pipeline-summary.md` front-matter. User can declare new tier at any approval prompt ("approve and switch to strict"). Subsequent stages read current tier; completed stages never re-run.
8. **Pre-redesign workspace detection** — Decision: if `pipeline-summary.md` lacks the new front-matter block, orchestrator treats as pre-redesign and defaults tier=strict, scope=unclassified (classification optional on resume; presence of decomposer output implies at least M).

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](./data-model.md). Entities:

- **ScopeTier** — enum {XS, S, M, L, XL} with classification thresholds.
- **ApprovalTier** — enum {strict, standard, express} with gate rules per stage.
- **PipelineDefinition** — `(scope, task_type)` → ordered list of `Stage` with `approval_required` flag resolved from ApprovalTier.
- **Stage** — name, agent reference, approval flag, mode (for Spec), depends_on, inputs, outputs.
- **ModelTierAssignment** — `(agent_name, mode?) -> model` table.
- **CriticalitySignal** — source {user_flag, keyword, spec_metadata}, matched_term, recommendation.
- **PipelineSummary** — extended structure: YAML front-matter (scope, tier, overrides, skipped) + existing markdown body (stage lines).
- **SpecValidationResult** — enum {PASS, PASS_WITH_WARNINGS, NEEDS_ATTENTION} + findings list with severity {Gap, Conflict, Weak, OK}.

### Contracts

This project exposes no runtime APIs. "Contracts" here means the textual interfaces the skill presents to its readers (the user, downstream agents, future maintainers). See `/contracts/`:

1. **skill-invocation.md** — How users express scope/tier/criticality at invocation (preamble grammar, natural-language keywords, override semantics).
2. **pipeline-summary.md** — The full extended schema of `.task/pipeline-summary.md` including YAML front-matter fields, stage line format, and back-compat rules for readers that only parse the body.
3. **spec-document.md** — The `.task/00-spec.md` schema showing the original Brainstormer format plus the new `## Validation` section and its three valid states.
4. **agent-frontmatter.md** — How agents declare their model tier now (reference to `refs/model-tiers.md` in frontmatter) and how the orchestrator resolves it at dispatch.

### Quickstart

See [quickstart.md](./quickstart.md). Three walkthroughs:

1. **Express path** (scope XS task, no overrides): invocation → Spec validate → Implementer → Tester → Committer (1 approval on commit).
2. **Standard path** (scope M task, default tier): invocation → Spec interactive → Decomposer → per-module Research/Plan/Impl/Test → Committer (3 approvals: Spec, Decomposition, Commit).
3. **Strict path** (scope L task, default tier): identical to pre-redesign behavior; documented for backward-compat verification.

Each walkthrough lists expected approval prompts and expected `pipeline-summary.md` contents so reviewers can diff actual runs against them.

## Post-Design Constitution Re-Check

**Final re-check after implementation** (2026-04-17, all Phase 1-8 tasks complete):

| Mandate | Status | Evidence |
|---|---|---|
| Markdown-only, no runtime/build/tests | PASS | All deliverables are `.md`; no code, no test runner introduced |
| File-based agent communication | PASS | `.task/pipeline-summary.md` extended with front-matter (append-only); body unchanged |
| Progressive disclosure (3 levels) | PASS WITH NOTE | SKILL.md grew from 283 → 529 lines (~+246); Complexity Tracking predicted 60-80; overshoot due to verbose documentation of tier/criticality/resume blocks. Acceptable for this cycle; SKILL.md split deferred to Cycle 2 per spec. |
| Adaptive pipeline | EXTENDED | Scope (5 tiers) is a new orthogonal axis to task type; `scope-pipelines.md` matrix codifies the mapping |
| Plugin delegation with fallback | PASS | No plugin touched |
| Brief sections | PASS | Spec agent preserves Brief; adds `## Validation` section |
| Agent declarations: inputs, outputs, model tier | STRENGTHENED | All 14 agent files reference authoritative `refs/model-tiers.md`; single-edit tier changes |
| Reference docs on-demand | PASS | 4 new refs under existing pattern: scope-pipelines, approval-tiers, model-tiers, criticality-signals; plus renamed spec-dialogue-patterns |
| Git workflow | PASS | Feature branch `task-core-redesign`; worktree isolation; ready for conventional-commit PR |

**Overshoot justification**: SKILL.md grew more than predicted because tier documentation was more prose-heavy than expected (mid-flight change semantics, criticality detection gate, resume detection). Tracked as known debt for Cycle 2 (SKILL.md split into thin shell + refs).

**No violations introduced**. No constitution waiver required.

## Follow-ups (deferred to later cycles)

Per spec's Out of Scope section — these are NOT addressed in this cycle but are flagged as prerequisite work:

- **Cycle 2**: SKILL.md split into thin shell + `refs/orchestration.md` + `refs/flow-control.md`. Review-lite per-module. Delegate Brainstormer/Planner/Debugger to superpowers skills.
- **Cycle 3**: Slash commands (`/task-quick`, `/task-fix`). User preferences persistence (`~/.claude/task-prefs.json`). Batch approvals for parallel modules. README auto-sync with SKILL.md.

## Lessons learned

1. **Strict-tier backward-compat was cheap**: defining it as "reproduce existing gate set" + dynamic lookup took one table row; the invariant is self-auditing because `refs/approval-tiers.md` enumerates it.
2. **Front-matter vs separate file for pipeline metadata**: front-matter won on zero-breakage grounds; body-only readers don't notice. Alternative (separate `.task/pipeline-meta.yaml`) would have scattered state.
3. **Model tier centralization**: immediate win. Retier now = edit one row. Legacy notes (`*(previously: X; new: Y)*`) make PR review trivial; can be removed in a follow-up commit once verified.
4. **Spec merge simplification**: Brainstormer + Validator combined to Spec saved one approval gate and eliminated an entire stage output file (`01-analysis.md`). Downstream agent reads re-pointed from `01-analysis.md` to `00-spec.md` — single file now carries both the spec and its validation report.
5. **Scope classification deferred to Spec stage** (not orchestrator preamble): better because Spec has the content (user stories, ACs, Scope IN) to classify from; orchestrator at preamble time only has raw user text.
