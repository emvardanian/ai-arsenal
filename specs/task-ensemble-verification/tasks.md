# Tasks: Ensemble Verification for the `task` Skill

**Input**: research/design at `docs/superpowers/specs/2026-05-13-task-ensemble-verification-design.md`, `spec.md`, `plan.md`.
**Branch**: `feature/task-ensemble-verification`
**Worktree**: `/Users/emmanuil/work/AI/ai-arsenal-task-ensemble/`

## Format

`[ID] [P?] [US?] Description — verification: <how to verify completion>`

- `[P]` = can run in parallel (different file, no dependency).
- `[US]` = which User Story from spec.md this task belongs to.

## Phase 1: Foundational refs (BLOCKING — every other task reads these)

- [ ] **T001** Create `skills/task/agents/refs/ensemble.md` — defines: activation matrix per scope (XS/S/M/L/XL × eligible stages), file-naming convention (`<stage>-<N>-{a,b,c}.md` raw + `<stage>-<N>.md` canonical), `divergence_threshold` defaults per stage, failure handling (timeout / divergence-error / identical short-circuit / synthesizer failure), pipeline-summary front-matter schema for the `ensemble` block. — verification: file exists; activation matrix matches spec.md FR-015; schema example present.

- [ ] **T002 [P]** Update `skills/task/agents/refs/model-tiers.md` — add 5 synthesizer entries:
  - `synthesizer-verify-reviewer: sonnet`
  - `synthesizer-verify-reviewer-lite: haiku`
  - `synthesizer-verify-spec: sonnet`
  - `synthesizer-produce-research: sonnet`
  - `synthesizer-produce-decomposer: opus`
  — verification: each new key resolvable from the file; existing keys unchanged.

## Phase 2: Generic synthesizer agent

- [ ] **T003 [US1, US2, US3]** Create `skills/task/agents/synthesizer.md` — generic synthesizer.
  - Frontmatter: model resolved via lookup in `refs/model-tiers.md` based on `--target-stage`.
  - Inputs: `--mode` (verify | produce), `--target-stage` (reviewer | reviewer-lite | spec | research | decomposer), `--raw-paths` (list of 3 raw artefact paths), `--canonical-path` (where to write merged output).
  - Process:
    - Hash-compare raw inputs; if all 3 identical → return raw-a verbatim with note "triple agreement, no merge needed".
    - In `verify` mode: extract findings from each raw, dedup by paraphrase similarity, tag with reviewer count `[N/3]`, sort by severity then count, write canonical with merged list + divergence summary.
    - In `produce` mode: read all 3 raws, attempt semantic synthesis; if divergence > threshold (per `refs/ensemble.md`) → return `divergence-error` instead of writing canonical.
    - Failure mode handling per `refs/ensemble.md`.
  - Outputs: canonical at `<canonical-path>` + divergence summary block at the top of canonical.
  — verification: file exists; references `refs/ensemble.md` and `refs/model-tiers.md`; both modes documented with explicit step lists; failure paths enumerated.

## Phase 3: Orchestrator routing

- [ ] **T004 [US1, US2]** Update `skills/task/SKILL.md` Step 9 (Dispatch stages) — insert ensemble routing logic.
  - At each stage dispatch: call `should_ensemble(stage, scope, tier)` per `refs/ensemble.md` activation matrix.
  - If ensemble active: spawn 3 parallel instances of stage agent in one `Agent` tool call → write raw `-a/-b/-c.md` → dispatch synthesizer agent (`agents/synthesizer.md`) with mode + target-stage + raw paths → write canonical → gate on canonical with divergence summary.
  - If ensemble inactive: existing single-pass dispatch (no change).
  - Honor preamble overrides `ensemble: off` / `ensemble: full`.
  — verification: SKILL.md Step 9 explicitly references `refs/ensemble.md`; both branches (ensemble + single-pass) preserved; gate target = canonical only per FR-008.

- [ ] **T005 [US3]** Update `skills/task/SKILL.md` pipeline-summary front-matter schema — add `ensemble` block per `refs/ensemble.md` schema.
  - Schema reference rather than full inline definition.
  - Set `ensemble.override_source` to one of: `scope-pipelines` (default), `preamble`, `prefs`.
  — verification: schema description in SKILL.md references the ensemble block; ai-arsenal regenerated front-matter on next dogfood run includes the block.

## Phase 4: Scope-pipelines ensemble matrix

- [ ] **T006 [US2]** Update `skills/task/agents/refs/scope-pipelines.md` — add ensemble activation matrix per scope:
  - XS, S: `ensemble_stages: [reviewer]`
  - M: `ensemble_stages: [reviewer, researcher]`
  - L, XL: `ensemble_stages: [reviewer, reviewer-lite, researcher, spec-validation, decomposer]`
  - Preamble `ensemble: off` → empty list; `ensemble: full` → max list per scope's eligible stages.
  — verification: matrix in `refs/scope-pipelines.md` matches spec.md FR-015 exactly.

## Phase 5: Dogfood tests (manual)

Run after Phase 1-4 complete and committed. Each test is a real `/task-*` invocation against a contrived target.

- [ ] **T007 [US1]** Test E1 — Reviewer ensemble at XS scope. — verification: `.task/09-review-{a,b,c,canonical}.md` produced; canonical has `[N/3]` tags.

- [ ] **T008 [US2]** Test E2 — Scope gating at S scope. — verification: no `04-research-*.md` raw files; no `03-decomposition-*.md` raw files; only Reviewer ensembled.

- [ ] **T009 [US2]** Test E3 — Full ensemble at L scope. — verification: per-module research raw + canonical; decomposer raw + canonical; review-lite raw + canonical; final review raw + canonical.

- [ ] **T010** Test E4 — Identical-output short-circuit. — verification: synthesizer output contains "triple agreement, no merge needed" when forced.

- [ ] **T011** Test E5 — Divergence-error escalation. — verification: synthesizer returns divergence-error; orchestrator pauses; raw side-by-side shown.

- [ ] **T012 [US2]** Test E6 — `ensemble: off` override. — verification: no raw files anywhere; existing single-pass behavior fully preserved.

- [ ] **T013 [US3]** Test E7 — Front-matter recording. — verification: `pipeline-summary.md` contains `ensemble:` block per schema.

## Phase 6: Polish

- [ ] **T014** Update `skills/task/SKILL.md` Refs Map — add `refs/ensemble.md` row with "Loaded at startup, after Agent Reference" trigger. — verification: row present.

- [ ] **T015** Update `skills/task/README.md` (or create CHANGELOG entry) — document the ensemble concept, new `.task/` files, scope-gated activation. — verification: README has Ensemble section.

## Dependencies

```
T001 (ensemble.md) blocks T002–T015
T002 (model-tiers) blocks T003 (synthesizer model lookup)
T003 (synthesizer) blocks T004 (orchestrator references it)
T004 (orchestrator) blocks T005, T006 (front-matter + matrix references)
T005 + T006 block T007–T013 (tests need everything wired)
T014 + T015 — polish, blocked by T004
```

## Execution Order

1. T001 (foundational)
2. T002 (parallel-safe with T001 if separate files; sequential here for safety)
3. T003 (depends on T002)
4. T004 (depends on T003)
5. T005, T006 (can run in parallel after T004)
6. T007–T013 (dogfood, sequential)
7. T014, T015 (polish, parallel)

## Parallel Opportunities

- T002 is `[P]` w.r.t. T001 if file boundaries allow (different files).
- T005 and T006 are `[P]` once T004 lands.
- T014 and T015 are `[P]`.
- Dogfood tests T007–T013 are sequential because they share the same `.task/` workspace.

## Implementation Strategy

**MVP-first**: Land T001 → T003 → T004 → T006 in that order. At this point, Reviewer ensemble works at any scope. Validate via T007. Then T002 + T005 enrich the system. Then T006 expands to producing stages. Tests T008–T013 cover the full surface. T014 + T015 polish docs.

Stop at T007 (Reviewer-only ensemble) if cost analysis shows the producing-stage ensembles are too expensive in practice; the Reviewer ensemble alone delivers the highest-value recall improvement.

## Notes

- No automated tests. Dogfooding via `/task-*` invocations is the verification mechanism, since `task` is itself a skill (orchestrator, not executable code).
- All changes are confined to `skills/task/`. No constitution or cross-skill changes.
- The 3-instance count is hard-coded throughout; not parameterized in this iteration.
- Synthesizer model is resolved per-stage via `refs/model-tiers.md`, not via the synthesizer agent's own frontmatter (which can be a single `model: dynamic` or similar marker).
