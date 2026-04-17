# Implementation Plan: Task Skill Cycle 3 — Daily UX

**Branch**: `task-cycle3-daily-ux` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)

## Summary

Four daily-UX changes:
1. **Slash commands** `/task-quick`, `/task-fix`, `/task-feature`, `/task-full` as `.claude/commands/*.md` files — zero-preamble entry points.
2. **Preferences persistence** via `~/.claude/task-prefs.json` (global) + `.claude/task-prefs.json` (project). Orchestrator reads at startup.
3. **Batch approval** for independent modules at strict tier — one prompt for all Planners/Implementers/Reviewer-Lites when `depends_on: []`.
4. **README autosync** via `scripts/sync-readme.sh` + optional pre-commit hook. `<!-- AUTOSYNC -->` markers fence regenerable regions.

Backward-compat: everything is opt-in; users without new files / hooks / slash commands see Cycle 2 behavior unchanged.

## Technical Context

**Language/Version**: Markdown + YAML frontmatter; bash (sync script + install hook); JSON (prefs files).
**Primary Dependencies**: Claude Code CLI; optional `jq` for JSON parsing in bash (graceful fallback).
**Storage**: filesystem only. `~/.claude/task-prefs.json` (global prefs), `<project>/.claude/task-prefs.json` (project prefs), `.claude/commands/task-*.md` (slash commands), `scripts/sync-readme.sh` + `scripts/install-hooks.sh` + `.git/hooks/pre-commit` (optional).
**Testing**: Manual per constitution; verification in `quickstart.md`.
**Performance Goals**: sync-readme idempotent (SC-008); slash command entry <500ms overhead vs bare invocation.
**Constraints**: fully backward-compat with Cycle 2; no new files required for existing users.
**Scale/Scope**: 4 slash commands, 1 prefs schema, 1 approval mode enum extension, 1 bash sync script, 1 hook installer, SKILL.md additions (Slash Commands section + Preferences section).

## Constitution Check

| Mandate | Status | Notes |
|---|---|---|
| Markdown-only, no runtime/build/tests | PASS_WITH_NOTE | Introduces 2 bash scripts (sync-readme.sh, install-hooks.sh) — justified as tooling, not runtime. Kept minimal, no dependencies beyond POSIX + optional jq. |
| File-based communication | PASS | prefs files + slash command files; orchestrator reads at startup |
| Progressive disclosure | PASS | New content in refs/prefs.md + refs/batch-approval.md + refs/slash-commands.md loaded on demand |
| Adaptive pipeline | EXTENDED | batch approval mode per stage type |
| Plugin delegation with fallback | PASS | no plugin change; prefs affect existing delegation preamble |
| Brief sections | PASS | no new agent outputs |
| Agent declarations | PASS | no new agents |
| Refs on-demand | STRENGTHENED | 3 new refs |
| Git workflow | PASS | branch + worktree isolation; autosync hook is opt-in |

**Gate outcome**: PASS with one note (bash scripts). Scripts are small (< 200 lines each), POSIX-compatible, optional.

## Project Structure

```text
specs/task-cycle3-daily-ux/
├── spec.md, plan.md, research.md, data-model.md, quickstart.md
├── contracts/
│   ├── slash-commands.md            # 4 command schemas
│   ├── prefs-schema.md              # JSON schema + precedence rules
│   ├── batch-approval-flow.md       # approval mode state machine
│   └── autosync-markers.md          # AUTOSYNC marker contract
├── checklists/requirements.md
└── tasks.md
```

### Source changes scoped to repo root + skills/task/:

```text
.claude/commands/
├── task-quick.md                    # NEW
├── task-fix.md                      # NEW
├── task-feature.md                  # NEW
└── task-full.md                     # NEW

scripts/
├── sync-readme.sh                   # NEW (README regenerator)
└── install-hooks.sh                 # NEW (opt-in pre-commit installer)

skills/task/
├── SKILL.md                         # MODIFY: add ## Slash Commands + ## User Preferences + note approval_mode
└── agents/refs/
    ├── prefs.md                     # NEW (precedence rules, schema)
    ├── batch-approval.md            # NEW (eligibility + prompt flow)
    ├── slash-commands.md            # NEW (command registry)
    └── approvals.md                 # MODIFY: approval_mode field, batch prompt semantics

README.md                            # MODIFY: add AUTOSYNC markers around existing sections
```

**Structure Decision**: Four concerns, four orthogonal file areas. Slash commands in `.claude/commands/`. Scripts in `scripts/`. Skill changes in `skills/task/`. README markers in place.

## Complexity Tracking

| Decision | Why Needed | Rejected alternative |
|---|---|---|
| 4 separate slash command files (not one) | Each command has its own default (scope/tier/task_type) and its own trigger. One file with conditional logic would be opaque. | Single `/task` command with subcommand arg — harder to discover, same file count after help text. |
| Prefs as JSON (not YAML) | Claude Code conventionally uses JSON for settings.json etc.; JSON parses natively in bash via jq (optional). | YAML requires yq (non-standard); TOML needs another parser. |
| Two scopes of prefs (global + project) | Matches Claude Code settings.json pattern; global for "my tier preference", project for "this team prefers strict". | Single global: loses team-level settings. Single project: always need to re-apply per new project. |
| Batch approval per stage type (not per run) | Some stages (Planners) benefit from batch; others (Implementers) user may want to scrutinize. Per-stage-type lets user choose per type. | Once-for-all loses granularity. Per-module defeats batch's purpose. |
| AUTOSYNC HTML comments as markers | Markdown ignores HTML comments in renderers; git diff visibility; idempotent. | Dedicated frontmatter: doesn't fit README. Separate generated file: defeats drift prevention. |

## Phase 0: Outline & Research

See [research.md](./research.md). Key decisions:
1. Slash command defaults map: `/task-quick` → `scope:s, tier:express` (S upper cap via auto-classification); `/task-fix` → `task_type:bugfix`; `/task-feature` → `scope:m, tier:standard, task_type:feature`; `/task-full` → `tier:strict, task_type:feature, scope:l`.
2. Prefs schema v1 with strict allowlist of keys; extra keys ignored with warning (forward compat).
3. Precedence stack: preamble > slash > project > global > Cycle-2 defaults. Recorded in `prefs_source` front-matter.
4. Batch approval eligibility: strict tier + module count ≥ 2 + all independent per `depends_on: []`.
5. Batch prompt UX: `[approve all] [approve except N,M] [individual]`; per-stage-type memory.
6. Autosync markers: `<!-- AUTOSYNC:BEGIN:<region> -->` ... `<!-- AUTOSYNC:END -->`, 4 regions (agent-count, agent-table, scope-summary, pipeline-diagram).
7. Sync script strategy: regex extract from SKILL.md/refs, regenerate each AUTOSYNC region, write back README atomically.

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](./data-model.md). Entities: SlashCommand, UserPreferences, PrefsSource, ApprovalMode, BatchApprovalContext, AutosyncRegion, Extended PipelineSummary (additive v2 fields).

### Contracts

- **slash-commands.md** — 4 command schemas, YAML frontmatter format, body template, preamble override rules.
- **prefs-schema.md** — full JSON schema, allowed values per key, example files, precedence rules.
- **batch-approval-flow.md** — eligibility rules, prompt UI, user response parsing, state machine per stage type.
- **autosync-markers.md** — 4 AUTOSYNC regions, marker syntax, extraction rules, idempotency guarantee.

### Quickstart

See [quickstart.md](./quickstart.md). Paths:
1. `/task-quick foo` → XS/S express, 1 approval.
2. `/task-full migrate auth` → L/XL strict.
3. Global prefs `{default_tier: strict}` → all tasks strict unless overridden.
4. Batch approval on 4 independent modules → 3 gates (75% reduction).
5. `scripts/sync-readme.sh` on stale README → regenerated; idempotent on second run.
6. Cycle 2 workspace resume → no Cycle 3 fields; safe defaults.

## Post-Design Constitution Re-Check

**Final re-check after implementation** (2026-04-17, all Phase 1-8 tasks complete):

| Mandate | Status | Notes |
|---|---|---|
| Markdown-only, no runtime/build/tests | PASS_WITH_NOTE | 2 bash scripts added (sync-readme.sh 140 lines, install-hooks.sh 45 lines). POSIX-compatible, optional jq, no dependencies beyond coreutils. Acceptable for tooling; not user-facing runtime. |
| File-based communication | PASS | `.task/` unchanged. New: `.claude/commands/`, `~/.claude/task-prefs.json`, `<project>/.claude/task-prefs.json`. All file-based. |
| Progressive disclosure | PASS | 3 new refs loaded on demand (prefs, slash-commands, batch-approval). |
| Adaptive pipeline | EXTENDED | `approval_mode` field adds per-stage-type batch vs per-module decision. |
| Plugin delegation | PASS | No plugin touched; prefs integrate with existing `delegation` preamble. |
| Brief sections | PASS | No new agent outputs. |
| Agent declarations | PASS | No new agents. |
| Refs on-demand | STRENGTHENED | 3 new refs. |
| Git workflow | PASS | Feature branch, worktree isolation, opt-in autosync hook. |

**Gate outcome**: PASS with one note about bash scripts. Scripts are small, POSIX, optional jq. No violations.

## Lessons learned

1. **Opt-in as default for UX features**: every Cycle 3 feature ships with an opt-in trigger (slash command file, prefs file, hook install). Users who don't know about Cycle 3 see zero change. This is the right model for daily-UX accretion.
2. **JSON prefs chosen over YAML**: consistent with Claude Code settings.json; parseable without external tools if jq absent (bash grep/sed fallback possible).
3. **Sticky `individual` in batch approval prevents prompt fatigue**: users who dislike batch can say no once per stage type and it stays. Contrast with non-sticky batch (may be offered again for fresh module set).
4. **AUTOSYNC HTML comments work cleanly**: invisible in rendered markdown, visible in git diff, idempotent extraction. No need for dedicated frontmatter or separate generated files.

## Follow-ups (deferred)

- Interactive prefs editor (`/task-prefs show/set/reset`) — Cycle 4 candidate.
- Scout caching via project-hash — carried from Cycle 1 deferred list.
- Version-pinning of superpowers plugin — carried from Cycle 2 deferred list.
- Cross-project task history archive — Cycle 4+ if demand.
