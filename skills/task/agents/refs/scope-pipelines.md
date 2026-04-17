# Scope Pipelines

Authoritative mapping from `(scope, task_type)` to ordered pipeline stages. The orchestrator reads this table at Spec completion to select which stages run.

## Legend

- `stage1 -> stage2 -> stage3` — sequential execution in order.
- `(stage1 -> stage2)×N` — per-module repetition. `N` equals the number of modules produced by Decomposer.
- `stage ⇄ stage` — loop (max 2 cycles); exit on pass.
- `stage?` — conditional; included only when its trigger condition holds (see Notes).

Scope tiers: `XS`, `S`, `M`, `L`, `XL` (see `data-model.md` for classification rules).

Task types: `feature`, `bugfix`, `refactor`, `hotfix`.

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
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> implementer -> tester ⇄ debugger)×N -> committer` |
| bugfix | `spec -> scout -> (implementer -> tester ⇄ debugger) -> committer` |
| refactor | `spec -> scout -> (planner -> implementer -> tester)×N -> committer` |
| hotfix | `spec -> (implementer -> tester ⇄ debugger) -> committer` |

Notes: Decomposer included only for feature and refactor; bugfix/hotfix at M still skip it when the failure locus is known from the spec.

### L (15-40 files, 3-5 modules)

M plus cross-cutting review and documentation.

| task_type | stages |
|---|---|
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> implementer -> tester ⇄ debugger)×N -> reviewer -> refactorer -> documenter -> committer` |
| bugfix | `spec -> scout -> decomposer? -> (implementer -> tester ⇄ debugger)×N -> reviewer -> committer` |
| refactor | `spec -> scout -> decomposer -> (planner -> implementer -> tester)×N -> reviewer -> refactorer -> committer` |
| hotfix | `spec -> (implementer -> tester ⇄ debugger) -> reviewer -> committer` |

Notes: `decomposer?` in L-bugfix triggers when affected-file count exceeds 15 and modules can be meaningfully split; otherwise flat.

### XL (40+ files OR any UI work, 5+ modules)

L plus Designer and Design-QA for UI modules.

| task_type | stages |
|---|---|
| feature | `spec -> scout -> decomposer -> (researcher -> planner -> designer? -> implementer -> tester ⇄ debugger -> design-qa?)×N -> reviewer -> refactorer -> documenter -> committer` |
| bugfix | same as L-bugfix, plus designer?/design-qa? for any UI module touched |
| refactor | same as L-refactor, plus designer?/design-qa? when UI modules involved |
| hotfix | L-hotfix (rare at XL scope) |

Notes: `designer?` and `design-qa?` trigger only for modules flagged `ui: true` by Decomposer. Non-UI modules in the same XL pipeline skip both.

## Invariants

- Every pipeline ends in `committer`.
- XS pipelines never include `spec`.
- `designer` and `design-qa` appear only at XL scope.
- `reviewer`, `refactorer`, `documenter` appear only at L and XL.
- Task-type differentiation is preserved at every scope (FR-006).
- Changing this table changes pipeline selection. Do not edit without also updating `data-model.md` and running verification per `quickstart.md`.

## Scope upgrade mid-pipeline

If Scout (present at M and above) reports an affected-file count exceeding the current scope threshold by 2x or more:

1. Orchestrator pauses.
2. Prompts user: "Scout found N files, exceeding scope=<X> threshold. Upgrade to <Y>?"
3. On approval: swap the pipeline to the target scope's cell and continue from the next unexecuted stage in the new pipeline.
4. On rejection: continue with current scope; note mismatch in `pipeline-summary.md`.

## Back-compat

Future cycles may add columns (e.g., `security-audit` stage) or rows (new scope tiers). Readers MUST tolerate unknown fields and fall back to the closest match by scope row. Readers MUST NOT hardcode the stage list — always parse the cell at dispatch time.
