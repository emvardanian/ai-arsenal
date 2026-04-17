# Quickstart: Verify fix-stale-refs

**Feature**: fix-stale-refs
**Date**: 2026-04-17

Run these commands from the worktree root (`/Users/emmanuil/work/AI/ai-arsenal-fix-stale-refs`) after the implement phase. All must output the expected result.

## 1. Scout, Decomposer, Committer, Documenter cleaned

```bash
grep -n "01-analysis.md" skills/task/agents/scout.md skills/task/agents/decomposer.md skills/task/agents/committer.md skills/task/agents/documenter.md
```
**Expected**: no output (zero matches).

```bash
grep -n "00-spec.md" skills/task/agents/scout.md skills/task/agents/decomposer.md skills/task/agents/committer.md
```
**Expected**: at least one line per file (each Inputs section references `00-spec.md`).

## 2. Documenter filename fix

```bash
grep -n "04-impl-" skills/task/agents/documenter.md
```
**Expected**: no output.

```bash
grep -n "06-impl-" skills/task/agents/documenter.md
```
**Expected**: at least one match.

## 3. model-tiers three-mode Spec

```bash
grep -n "| haiku |" skills/task/agents/refs/model-tiers.md
```
**Expected**: one line showing `| haiku | 7 |`.

```bash
grep -n "exactly three rows" skills/task/agents/refs/model-tiers.md
grep -n "interactive, validate, or interview" skills/task/agents/refs/model-tiers.md
grep -n "three modes" skills/task/agents/refs/model-tiers.md
```
**Expected**: each returns at least one match.

```bash
grep -n "exactly two rows\|(two modes)" skills/task/agents/refs/model-tiers.md
```
**Expected**: no output.

## 4. Fallback references preserved

```bash
grep -n "01-analysis.md" skills/task/agents/reviewer.md skills/task/agents/tester.md skills/task/agents/refs/resume.md skills/task/SKILL.md
```
**Expected**: the same set of matches as before the change (legitimate fallback mentions untouched).

## 5. Diff scope

```bash
git diff --name-only main..HEAD
```
**Expected**: exactly these 5 files:
- `skills/task/agents/scout.md`
- `skills/task/agents/decomposer.md`
- `skills/task/agents/committer.md`
- `skills/task/agents/documenter.md`
- `skills/task/agents/refs/model-tiers.md`

(plus `specs/fix-stale-refs/*` artefacts from the trc workflow, which are separate).

## 6. No new files (excluding specs/)

```bash
git diff --diff-filter=A --name-only main..HEAD -- ':!specs/'
```
**Expected**: no output.

## If any check fails

- Re-run the failing check. If stale content persists, re-apply the corresponding edit from `tasks.md`.
- If SC-008 fails (fallback files modified), `git restore <file>` to revert.
- Do not re-run the trc chain. Edits are idempotent.
