# Resume

**Load trigger**: only on resume path (when `.task/pipeline-summary.md` exists at pipeline start).

Covers schema detection, scope inference, front-matter upgrade, and pre-Cycle-1 artifact fallback.

## Resume Detection

The orchestrator detects pre-redesign (`v1`) vs redesigned (`v2`) workspaces by inspecting the first line of `.task/pipeline-summary.md`:

- First line is `---\n` → **v2 schema**. Parse YAML front-matter; read `scope`, `tier`, `scope_source`, `tier_source`, etc. Resume using stored state.
- First line is NOT `---\n` (typically `# Pipeline Summary` or empty file) → **v1 schema** (pre-redesign). Apply v1 defaults and infer where needed.

### v1 defaults on resume

| Field | Default |
|---|---|
| `tier` | `strict` (safe default — preserves pre-redesign approval density) |
| `tier_source` | `default (resume from v1)` |
| `scope` | inferred per `### Scope Inference on Resume` below |
| `scope_source` | `inferred` |
| `criticality_flag` | `false` |
| `summary_schema` | `v1` (to be upgraded per `### Schema Upgrade on Resume`) |
| `delegation_mode` (Cycle 2) | `fallback` (safe default; no retroactive delegation) |
| `review_lite_enabled` (Cycle 2) | `false` (no retroactive Review-Lite insertion) |

### v2.1 vs pre-Cycle-2 detection (Cycle 2)

Orchestrator encountering v2 front-matter without Cycle 2 fields:

```yaml
---
scope: M
tier: standard
summary_schema: v2
# ... (no delegation_mode, no review_lite_*)
---
```

Defaults:
- Missing `delegation_mode` → treat as `fallback` (safe).
- Missing `review_lite_enabled` → treat as `false` (no retroactive Review-Lite on resumed pipelines).

On resume, orchestrator does NOT insert Review-Lite into an already-running pipeline. Only new runs get Review-Lite.

### Scope Inference on Resume

If `scope` is unknown (resume from v1, or front-matter field missing), orchestrator infers from the existing body of `pipeline-summary.md`:

| Body contains line for stage | Implied scope |
|---|---|
| `Designer` or `Design-QA` | **XL** |
| `Reviewer` | **L** |
| `Decomposer` | **M** |
| `Planner` (but not Decomposer) | **S** |
| None of the above | **XS** |

Inferred scope is recorded with `scope_source: inferred`. It never overrides a user-declared scope — if the user provides a preamble on resume, their declaration wins.

### Schema Upgrade on Resume

When a v1 workspace is resumed, orchestrator prepends the YAML front-matter block to `pipeline-summary.md`:

1. Compute `tier` (default strict), `scope` (inferred), `tier_source` (`default (resume from v1)`), `scope_source` (`inferred`).
2. Compute `stage_count_expected` and `stage_count_approval_gated` based on resolved pipeline.
3. Set Cycle-2 fields to safe defaults (`delegation_mode: fallback`, `review_lite_enabled: false`).
4. Write front-matter with `summary_schema: v1 → v2 upgraded at <ISO-8601 timestamp>`.
5. Preserve the existing body verbatim (no line changed, no stage re-ordered).

The upgrade is irreversible in-place — subsequent stages read and write v2 format. The v1 body still satisfies body-only readers (Documenter, Committer).

### Pre-redesign artifact fallback

Some pre-redesign artifacts (e.g., `.task/01-analysis.md`) are no longer produced by the redesigned skill. When resuming a v1 workspace:

- Downstream stages that previously read `01-analysis.md` (Scout, Decomposer, Tester, Committer) MAY read it as fallback when `00-spec.md` lacks the expected content (e.g., no `## Validation` section, no `classified_scope` front-matter).
- The Spec stage is NOT re-run on resume unless `00-spec.md` is missing or malformed. The pre-redesign spec body is acceptable input to Scout.

## Safe Default Invariant

If `.task/pipeline-summary.md` lacks front-matter, default `tier: strict`. This guarantees that a resumed pre-redesign workspace never escalates approval density above what the user had before (FR-027, SC-008).

Likewise, `delegation_mode: fallback` default on resume guarantees no silent behavior change — the resumed pipeline runs exactly as it would have on the user's pre-Cycle-2 skill version.
