# Spec Library

Reference for the `specs/archive/` library: structure, naming convention, INDEX format, frontmatter schema, and staleness scoring. Loaded by Archivist on every run and by Scout when a library scan is triggered.

## Why `specs/archive/`

The `specs/` root is used for TRC (Task Request Context) specs named after git branches (e.g., `specs/fix-stale-refs/spec.md`). Spec agent Mode Detection rule 5 looks for `specs/<current-branch>/spec.md` and triggers validate mode when found. Archivist writes to `specs/archive/` to keep the two conventions from colliding — the branch name can never equal `archive/<slug>`, so rule 5 never fires on archived specs.

## Structure

```
specs/
├── INDEX.md                                    <- Catalog of all archived specs (root level)
├── archive/                                    <- Archivist output only — do not create dirs here manually
│   ├── 2026-05-20-jwt-authentication/
│   │   ├── spec.md                             <- Full spec with merged frontmatter
│   │   └── research-1.md                       <- Research archive (optional)
│   ├── 2026-04-17-fix-stale-refs/
│   │   ├── spec.md
│   │   └── research-1.md
│   └── ...
├── fix-stale-refs/                             <- TRC specs (branch-named, manually created)
│   └── spec.md
└── ...
```

## Naming Convention

Archive directory: `specs/archive/<YYYY-MM-DD>-<feature-slug>/`

- **Date**: `detected_at` from spec frontmatter — the day the spec was written, not when implementation ran.
- **Slug**: feature name lowercased, spaces and `/` replaced with `-`, non-alphanumeric characters stripped.
- **Version suffix**: if a slug already exists, Archivist appends `-v2`, `-v3`, etc.

Examples:
- `specs/archive/2026-05-20-jwt-authentication-with-refresh-tokens/`
- `specs/archive/2026-04-17-fix-stale-doc-references/`
- `specs/archive/2026-03-22-lander-skill-design-v2/`

## INDEX.md Format

Lives at `specs/INDEX.md` (root of specs, not inside archive/).

```markdown
# Spec Library Index

<!-- Maintained automatically by the Archivist agent. Do not edit rows manually. -->
<!-- See skills/task/agents/refs/spec-library.md for conventions. -->

| # | Slug | Feature | Date | Scope | Type | Staleness | Affected Paths |
|---|------|---------|------|-------|------|-----------|----------------|
| 3 | 2026-05-20-jwt-auth | JWT Authentication | 2026-05-20 | M | feature | fresh | src/auth/, src/middleware/auth.ts |
| 2 | 2026-04-17-fix-stale-refs | Fix Stale Doc References | 2026-04-17 | S | bugfix | stale | skills/task/agents/ |
| 1 | 2026-03-22-lander-skill | Lander Skill | 2026-03-22 | L | feature | fresh | skills/lander/ |
```

Rows are ordered most-recent-first. The `#` column is a display counter — Archivist increments on each new entry.

**Multi-worktree note**: concurrent pipeline runs can cause a write race on INDEX.md. For single-user environments this is safe. If you run multiple worktrees in parallel, consider replacing the `#` integer with `archived_at` (ISO timestamp) as a unique identifier to avoid counter collisions.

## Archived Spec Frontmatter

Archived specs carry additional frontmatter prepended by the Archivist. All fields live in a single flat YAML block — no inline YAML comments, which can break downstream parsers.

| Field | Type | Description |
|-------|------|-------------|
| `archived_at` | ISO-8601 | Timestamp when Archivist ran |
| `archived_sha` | string | Git HEAD SHA at time of implementation (`"no-git"` if unavailable) |
| `archived_pipeline_scope` | XS/S/M/L/XL | Scope the pipeline ran at |
| `archived_task_type` | string | feature / bugfix / refactor / hotfix |
| `archived_tier` | string | strict / standard / express |
| `staleness` | string | `fresh` / `stale` / `critical` / `superseded` — updated by Scout or on refresh |
| `affected_paths` | list | Files written by Implementer; the diff surface for staleness checks |

The original spec frontmatter (`mode`, `classified_scope`, `detected_at`, etc.) follows the Archivist fields in the same YAML block.

## Staleness Scoring

Scout runs a staleness check (Step 0) at the start of every S+ pipeline run. For each spec in `specs/INDEX.md` whose name or affected paths overlap with the current task's affected zone:

### Check algorithm

```bash
# 1. Read archived_sha from specs/archive/<slug>/spec.md frontmatter
archived_sha=$(grep '^archived_sha:' specs/archive/<slug>/spec.md | awk '{print $2}')

# 2. If "no-git", skip — mark as unknown
[ "$archived_sha" = "no-git" ] && echo "unknown" && exit 0

# 3. Get files changed since that SHA
changed=$(git diff "${archived_sha}..HEAD" --name-only 2>/dev/null)

# 4. Intersect with affected_paths from the spec frontmatter
```

If git is unavailable, mark as `unknown` and skip.

### Staleness classification heuristic

After computing `changed_affected = affected_paths ∩ git_diff_files`:

| Step | Rule | Result |
|------|------|--------|
| 1 | `changed_affected` is empty | `fresh` — stop |
| 2 | All `changed_affected` match **minor patterns** below | `stale` |
| 3 | Any `changed_affected` matches a **core pattern** | `critical` |

**Minor patterns** (tests, docs, config — implementation semantics unlikely changed):
- Path contains: `test/`, `tests/`, `__tests__/`, `spec/`, `specs/` (subdirectory, not root), `docs/`, `.storybook/`
- Extension: `.md`, `.mdx`, `.txt`, `.json`, `.yml`, `.yaml`, `.toml`, `.lock`, `.env.example`
- Filename: `*.test.ts`, `*.test.js`, `*.spec.ts`, `*.spec.js`, `*.test.py`

**Core patterns** (source code — implementation semantics likely changed):
- Any path not matching a minor pattern above
- Typical examples: `*.ts`, `*.js`, `*.py`, `*.go`, `*.rs`, `*.java`, `*.kt`, `*.swift` outside test directories

This is a heuristic. Scout may override the classification if context makes it obvious (e.g., a `.json` change that modifies an API contract).

### Staleness tiers

| Tier | Condition | Action |
|------|-----------|--------|
| `fresh` | 0 `affected_paths` changed since `archived_sha` | No action |
| `stale` | ≥1 changed, all minor patterns | Warn in Scout output |
| `critical` | ≥1 changed, at least one core file | Warn prominently; recommend refresh |
| `unknown` | `archived_sha` is `"no-git"` or git unavailable | Skip silently |
| `superseded` | A newer `-v2`/`-v3` entry exists for this slug | Skip — defer to newer version |

Scout updates the `staleness` field in both `specs/archive/<slug>/spec.md` and `specs/INDEX.md` when the tier changes from `fresh`.

### Reporting format

Scout outputs a staleness summary block in `02-scout.md`:

```
## Spec Library Scan

| Slug | Staleness | Changed Files |
|------|-----------|---------------|
| 2026-04-17-fix-stale-refs | stale | skills/task/agents/scout.md |
| 2026-03-22-lander-skill | fresh | — |

Recommendation: specs/archive/2026-04-17-fix-stale-refs/spec.md is stale (minor changes only).
To refresh: use `interview @specs/archive/2026-04-17-fix-stale-refs/spec.md` in the next invocation.
The `interview` keyword is required — @<path> alone triggers validate mode (rule 3), not interview mode (rule 2).
```

## Refreshing a Stale Spec

When Scout reports a spec as `stale` or `critical`:

1. Include both the `interview` keyword and the spec path in the next pipeline invocation:
   ```
   interview @specs/archive/<slug>/spec.md
   ```
   The `interview` keyword satisfies Mode Detection rule 2 (`@<path>` + interview keyword → interview mode). Without it, rule 3 fires instead (`@<path>` alone → validate mode), which only checks completeness rather than attacking hidden assumptions.
2. Spec agent runs in **interview** mode, closing gaps revealed by the changed files.
3. On pipeline completion, Archivist creates a new versioned entry (`specs/archive/<slug>-v2/`).
4. The original entry's `staleness` field is updated to `superseded` in INDEX.md.

## Prefs Integration

Add `"archive_spec": false` to `~/.claude/task-prefs.json` or `<project>/.claude/task-prefs.json` to disable archiving globally or per-project. Default: `true` at S+ scope.
