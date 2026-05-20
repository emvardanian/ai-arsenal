# Scope Pipelines

Authoritative mapping from `(scope, task_type)` to ordered pipeline stages. The orchestrator reads this table at Spec completion to select which stages run.

## Legend

- `stage1 -> stage2 -> stage3` — sequential execution in order.
- `(stage1 -> stage2)×N` — per-module repetition. `N` equals the number of modules produced by Decomposer.
- `stage ⇄ stage` — loop (max 2 cycles); exit on pass.
- `stage?` — conditional; included only when its trigger condition holds (see Notes).

Scope tiers: `XS`, `S`, `M`, `L`, `XL` (see `data-model.md` for classification rules).

Task types: `feature`, `bugfix`, `refactor`, `hotfix`.

## Implicit tail stage

Every pipeline that includes `spec` appends `archivist` automatically after `committer` (no approval gate). XS pipelines (no `spec`) end at `committer` only. The cells below omit `archivist` for brevity — it is always appended at S+.

## Matrix

### XS (1 file, 1 module)

All task types collapse to the minimum viable path.

| task_type | stages |
|---|---|
| feature | `implementer -> tester -> committer` |
| bugfix | `implementer -> tester ⇄ debugger -> committer` |
| refactor | `implementer -> tester -> committer` |
| hotfix | `implementer -> tester ⇄ debugger -> committer` |

Notes: No Spec stage — the user's one-line request is the spec.

### S (2-5 files, 1 module)

| task_type | stages |
|---|---|
| feature | `spec -> planner -> implementer -> tester ⇄ debugger -> committer` |
| bugfix | `spec -> implementer -> tester ⇄ debugger -> committer` |
| refactor | `spec -> planner -> implementer -> tester -> committer` |
| hotfix | `spec -> implementer -> tester ⇄ debugger -> committer` |

Notes: Spec included for traceability (requirements documented). Scout/Decomposer skipped (single module).

### M (5-15 files, 2-3 modules)

| task_type | stages |
|---|---|
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> implementer -> tester ⇄ debugger -> reviewer-lite)×N -> committer` |
| bugfix | `spec -> scout -> (implementer -> tester ⇄ debugger -> reviewer-lite) -> committer` |
| refactor | `spec -> scout -> (planner -> implementer -> tester -> reviewer-lite)×N -> committer` |
| hotfix | `spec -> (implementer -> tester ⇄ debugger) -> committer` |

Notes: Decomposer included only for feature and refactor; bugfix/hotfix at M still skip it when the failure locus is known from the spec. **Reviewer-Lite** (Cycle 2) runs per-module after Tester at M+ for feature/bugfix/refactor; hotfix skips Review-Lite for speed.

### L (15-40 files, 3-5 modules)

M plus cross-cutting review and documentation.

| task_type | stages |
|---|---|
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> implementer -> tester ⇄ debugger -> reviewer-lite)×N -> reviewer -> refactorer -> documenter -> committer` |
| bugfix | `spec -> scout -> decomposer? -> (implementer -> tester ⇄ debugger -> reviewer-lite)×N -> reviewer -> committer` |
| refactor | `spec -> scout -> decomposer -> (planner -> implementer -> tester -> reviewer-lite)×N -> reviewer -> refactorer -> committer` |
| hotfix | `spec -> (implementer -> tester ⇄ debugger) -> reviewer -> committer` |

Notes: `decomposer?` in L-bugfix triggers when affected-file count exceeds 15 and modules can be meaningfully split; otherwise flat. **Reviewer-Lite** runs per-module at L+ for feature/bugfix/refactor; hotfix always skips it.

### XL (40+ files OR any UI work, 5+ modules)

L plus Designer and Design-QA for UI modules.

| task_type | stages |
|---|---|
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> designer? -> implementer -> tester ⇄ debugger -> design-qa? -> reviewer-lite)×N -> reviewer -> refactorer -> documenter -> committer` |
| bugfix | same as L-bugfix, plus designer?/design-qa? for any UI module touched |
| refactor | same as L-refactor, plus designer?/design-qa? when UI modules involved |
| hotfix | L-hotfix (rare at XL scope) |

Notes: `designer?` and `design-qa?` trigger only for modules flagged `ui: true` by Decomposer. Non-UI modules in the same XL pipeline skip both.

## Invariants

- Every pipeline ends in `committer`. Every pipeline that includes `spec` additionally runs `archivist` as an automatic (no-gate) final stage.
- XS pipelines never include `spec` and never run `archivist`.
- `designer` and `design-qa` appear only at XL scope.
- `reviewer`, `refactorer`, `documenter` appear only at L and XL.
- Task-type differentiation is preserved at every scope (FR-006).
- Changing this table changes pipeline selection. Do not edit without also updating `data-model.md` and running verification per `quickstart.md`.

## Ensemble activation per scope

Independent of which stages run, this matrix declares which stages run as **ensemble** (3 parallel + synthesizer) versus single-pass at each scope. See `refs/ensemble.md` for ensemble mechanics.

| Scope | Reviewer | Reviewer-Lite | Researcher | Spec validation | Decomposer |
|-------|----------|---------------|------------|-----------------|------------|
| XS    | ensemble | —             | —          | single          | —          |
| S     | ensemble | —             | —          | single          | —          |
| M     | ensemble | single        | ensemble   | single          | single     |
| L     | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |
| XL    | ensemble | ensemble      | ensemble   | ensemble        | ensemble   |

Legend: `ensemble` — 3 parallel + synthesizer; `single` — single-pass; `—` — stage does not run at this scope per the pipeline table above (so the ensemble question doesn't apply).

Preamble overrides (precedence: preamble > slash-command > project-prefs > global-prefs > this matrix):
- `ensemble: off` → no stage ensembled.
- `ensemble: full` → every stage in the row marked `ensemble` runs ensembled (effectively no-op vs default for L/XL; expands eligibility for M).
- `ensemble: reviewer-only` → only Reviewer ensembled regardless of scope.

The orchestrator consults this matrix at each stage dispatch. See `refs/ensemble.md` for the `should_ensemble(stage, scope, tier)` algorithm and `agents/synthesizer.md` for the merge logic.

## Scope upgrade mid-pipeline

If Scout (present at M and above) reports an affected-file count exceeding the current scope threshold by 2x or more:

1. Orchestrator pauses.
2. Prompts user: "Scout found N files, exceeding scope=<X> threshold. Upgrade to <Y>?"
3. On approval: swap the pipeline to the target scope's cell and continue from the next unexecuted stage in the new pipeline.
4. On rejection: continue with current scope; note mismatch in `pipeline-summary.md`.

## Back-compat

Future cycles may add columns (e.g., `security-audit` stage) or rows (new scope tiers). Readers MUST tolerate unknown fields and fall back to the closest match by scope row. Readers MUST NOT hardcode the stage list — always parse the cell at dispatch time.
