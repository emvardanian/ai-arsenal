# Criticality Signals

Authoritative list of signals that trigger a strict-tier recommendation regardless of scope. The orchestrator scans for these at invocation time and presents a one-reply gate prompt.

## Detection sources

Three sources, checked in priority order (first match wins for source attribution):

### 1. User flag (preamble)

The user explicitly declares criticality in the invocation preamble:

```
critical: true
<task description>
```

Source recorded as `user_flag`. Matched term recorded as `true`.

### 2. Keyword match (task description)

The orchestrator scans the user's task description (preamble excluded) for any of the keywords below. Case-insensitive whole-word match.

Source recorded as `keyword`. Matched term recorded as the literal matched word.

### 3. Spec metadata (Quality Gates)

After the Spec stage completes, the orchestrator scans `## Quality Gates` section in `.task/00-spec.md` for any of the keywords below. This detection runs post-Spec and may trigger a late criticality prompt if not already detected earlier.

Source recorded as `spec_metadata`. Matched term recorded as the matched keyword plus the QG identifier.

## Keyword list

| Keyword | Category | Notes |
|---|---|---|
| security | security posture | matches "security audit", "security review", etc. |
| production | production impact | "production bug", "production database" |
| hotfix | urgency | explicit hotfix intent |
| critical | urgency | generic criticality marker |
| breaking | contract change | breaking API change, breaking migration |
| data loss | data integrity | exact two-word match; also matches "lose data" informally if repeated |
| auth | authentication | "auth middleware", "authentication" |
| payment | financial | "payment processing", "payment flow" |
| pii | privacy | PII = personally identifiable information |

**Single-keyword matches are sufficient to trigger.** Multiple matches amplify nothing — the first hit determines source attribution.

Keywords are maintained here. To add or remove keywords, edit this file; orchestrator picks up changes at the next pipeline run.

## Gate prompt

When criticality is detected, the orchestrator shows:

```
**Criticality detected** via <source>: "<matched_term>".

Recommended tier: strict (scope default would be <scope_default>).

[strict]  (proceed with strict tier)
[override] (proceed with scope_default tier)
```

One-reply gate. User replies `strict` or `override`. Response recorded:

- `strict` → `tier: strict`, `tier_source: criticality`, `criticality_flag: true`.
- `override` → `tier: <scope_default>`, `tier_source: user`, `criticality_flag: true`, `tier_override: <scope_default>`.

In both cases, `criticality_flag` is `true` for audit. The flag does not block — it only recommends.

## When the gate is NOT shown

- User explicitly declared `tier: strict` in preamble (already at strict; no need to recommend).
- User explicitly declared `tier: express` or `tier: standard` in preamble AND criticality would recommend strict — the gate is still shown because the user's explicit tier predates the criticality detection signal. However, if the user's preamble includes both `critical: false` AND a non-strict tier, the orchestrator respects both and skips the gate.

## Invariants

- Criticality never forces strict without user confirmation (FR-014 + Edge Case: "User's explicit declarations take precedence over skill recommendations").
- Criticality flag is recorded regardless of gate outcome.
- Keyword matching is case-insensitive.
- Keyword list is authoritative; the orchestrator does NOT use LLM judgment for criticality (per research.md §4 rationale: deterministic, auditable).

## Back-compat

Future cycles may:
- Add new keywords.
- Add new detection sources (e.g., git repo metadata, prior-task patterns).
- Add per-project keyword overrides.

Readers MUST tolerate unknown detection sources and unknown keyword categories.
