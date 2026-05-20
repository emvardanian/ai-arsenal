# Spec Library

Reference for the `specs/` library: structure, naming convention, INDEX format, frontmatter schema, and staleness scoring. Loaded by Archivist on every run and by Scout when a library scan is triggered.

## Structure

```
specs/
├── INDEX.md                                    <- Catalog of all archived specs
├── 2026-05-20-jwt-authentication/
│   ├── spec.md                                 <- Full spec with merged frontmatter
│   └── research-1.md                           <- Research archive (optional)
├── 2026-04-17-fix-stale-refs/
│   ├── spec.md
│   └── research-1.md
└── ...
```

## Naming Convention

Directory: `<YYYY-MM-DD>-<feature-slug>/`

- **Date**: `detected_at` from spec frontmatter — the day the spec was written, not when implementation ran.
- **Slug**: feature name lowercased, spaces and `/` replaced with `-`, non-alphanumeric characters stripped.
- **Version suffix**: if a slug already exists, Archivist appends `-v2`, `-v3`, etc.

Examples:
- `2026-05-20-jwt-authentication-with-refresh-tokens/`
- `2026-04-17-fix-stale-doc-references/`
- `2026-03-22-lander-skill-design-v2/`

## INDEX.md Format

```markdown
# Spec Library Index

<!-- Maintained automatically by the Archivist agent. Do not edit rows manually. -->

| # | Slug | Feature | Date | Scope | Type | Staleness | Affected Paths |
|---|------|---------|------|-------|------|-----------|----------------|
| 3 | 2026-05-20-jwt-auth | JWT Authentication | 2026-05-20 | M | feature | fresh | src/auth/, src/middleware/auth.ts |
| 2 | 2026-04-17-fix-stale-refs | Fix Stale Doc References | 2026-04-17 | S | bugfix | stale | skills/task/agents/ |
| 1 | 2026-03-22-lander-skill | Lander Skill | 2026-03-22 | L | feature | fresh | skills/lander/ |
```

Rows are ordered most-recent-first. The `#` column is a display counter only — Archivist increments it on each new entry.

## Archived Spec Frontmatter

Archived specs carry additional frontmatter prepended by the Archivist:

| Field | Type | Description |
|-------|------|-------------|
| `archived_at` | ISO-8601 | Timestamp when Archivist ran |
| `archived_sha` | string | Git HEAD SHA at time of implementation (`"no-git"` if unavailable) |
| `archived_pipeline_scope` | XS/S/M/L/XL | Scope the pipeline ran at |
| `archived_task_type` | string | feature / bugfix / refactor / hotfix |
| `archived_tier` | string | strict / standard / express |
| `staleness` | string | `fresh` / `stale` / `critical` — updated by Scout on future runs |
| `affected_paths` | list | Files written by Implementer; the diff surface for staleness checks |

The original spec frontmatter (`mode`, `classified_scope`, `detected_at`, etc.) is preserved unchanged after the Archivist fields.

## Staleness Scoring

Scout runs a staleness check (Step 0) at the start of every S+ pipeline run. For each spec in `specs/INDEX.md` whose name or affected paths overlap with the current task's affected zone:

### Check algorithm

```bash
# 1. Read archived_sha from specs/<slug>/spec.md frontmatter
archived_sha=$(grep 'archived_sha:' specs/<slug>/spec.md | awk '{print $2}')

# 2. Get files changed since that SHA
changed=$(git diff "${archived_sha}..HEAD" --name-only 2>/dev/null)

# 3. Cross-reference with affected_paths in the spec
```

If `archived_sha` is `"no-git"`, skip the diff and mark as `unknown`.

### Staleness tiers

| Tier | Condition | Action |
|------|-----------|--------|
| `fresh` | 0 `affected_paths` changed since `archived_sha` | No action |
| `stale` | ≥1 `affected_paths` changed, but the changes are minor (tests, docs, comments) | Warn in Scout output |
| `critical` | Core `affected_paths` changed (source files, not just tests/docs) | Warn prominently; suggest re-interview |
| `unknown` | `archived_sha` is `"no-git"` or git is unavailable | Skip |

Scout updates the `staleness` field in both `specs/<slug>/spec.md` and `specs/INDEX.md` when it detects a change from `fresh`.

### Reporting format

Scout outputs a staleness summary block in `02-scout.md`:

```
## Spec Library Scan

| Slug | Staleness | Changed Files |
|------|-----------|---------------|
| 2026-04-17-fix-stale-refs | stale | skills/task/agents/scout.md, skills/task/SKILL.md |
| 2026-03-22-lander-skill | fresh | — |

Recommendation: specs/2026-04-17-fix-stale-refs/spec.md is stale. Pass @specs/2026-04-17-fix-stale-refs/spec.md to the Spec agent in interview mode to refresh it.
```

## Refreshing a Stale Spec

When Scout reports a spec as `stale` or `critical`:

1. Pass the spec path to the next pipeline invocation: `@specs/<slug>/spec.md`
2. Spec agent auto-detects the `@<path>` reference and runs in **interview** mode (Mode Detection rule 2), attacking the gaps revealed by the changed files.
3. On pipeline completion, Archivist creates a new versioned entry (`-v2`) for the refreshed spec.
4. The original entry's `staleness` field is updated to `superseded` in INDEX.md.

## Prefs Integration

Add `"archive_spec": false` to `~/.claude/task-prefs.json` or `<project>/.claude/task-prefs.json` to disable archiving globally or per-project. Default: `true` at S+ scope.
