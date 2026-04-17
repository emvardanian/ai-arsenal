# Contract: Skill Invocation

**Scope**: How the user expresses scope, tier, criticality, and spec mode when invoking the Task skill.

## Grammar

### Preamble (preferred)

First line of the user's message MAY be a preamble matching this regex:

```
^[a-z_]+:\s*[a-z0-9_]+(,\s*[a-z_]+:\s*[a-z0-9_]+)*$
```

Keys and allowed values:

| Key | Type | Allowed values | Default |
|---|---|---|---|
| `scope` | enum | `xs`, `s`, `m`, `l`, `xl` | auto-classified |
| `tier` | enum | `strict`, `standard`, `express` | derived from scope |
| `critical` | bool | `true`, `false` | auto-detected |
| `mode` | enum | `interactive`, `validate` | auto-detected per Adaptive Entry |

**Example preambles**:

```
scope: l, tier: strict
Rewrite the authentication stack to use OAuth2 with refresh tokens.

scope: s
Add a `retry` field to the CronJob DTO.

tier: express, critical: false
Rename `getUserById` to `fetchUserById` across the repo.

mode: validate
docs/specs/2026-04-15-payments.md — implement this spec.
```

### Natural-language fallback

If no preamble is present, the orchestrator scans the task request for inference keywords:

**Scope keywords**:
- XS/S: "quick", "small", "trivial", "one-liner", "just", "tiny"
- M: "medium", "normal", "moderate"
- L: "large", "big", "across the codebase"
- XL: "huge", "massive", "rewrite", "new module"

**Tier keywords**:
- express: "fast", "quickly", "just do it", "don't ask", "autopilot"
- strict: "carefully", "step by step", "review every step"

**Criticality keywords** (trigger strict recommendation):
- "security", "production", "hotfix", "critical", "breaking", "data loss", "auth", "payment", "pii"

Inference is **advisory**: the orchestrator shows detected values to the user in the opening pipeline summary and proceeds. If user wants different values, they can restart with a preamble or answer tier-change at the first approval prompt.

### Precedence rules

1. Preamble field wins over inference.
2. User flag wins over keyword detection.
3. Criticality = true → recommend strict; user confirmation required (FR-014).
4. Scope override (preamble) wins over classification.
5. Tier override (preamble) wins over scope-derived default.

### Mid-flight override

At any approval prompt, the user may respond with:

```
approve and switch to <tier>
```

Where `<tier>` ∈ {strict, standard, express}. Orchestrator updates `pipeline-summary.md` front-matter and dispatches subsequent stages with the new tier. Completed stages are not re-run (FR-013).

## Examples end-to-end

### Example 1: Express path

**User invocation**:
```
scope: xs
Rename getUserById to fetchUserById in user-service module.
```

**Orchestrator parses**:
```yaml
scope: xs
tier: express      # derived from scope
critical: false
mode: interactive  # default (no spec detected)
```

**Pipeline** (from `scope-pipelines.md` matrix, cell [XS, refactor]):
```
Implementer → Tester → Committer
```

**Approval prompts**: 1 (Committer).

### Example 2: Standard path with criticality detected

**User invocation**:
```
Add rate limiting to the payment endpoint.
```

**Orchestrator parses**:
- No preamble.
- Keyword match: "payment" → criticality recommendation.

**Orchestrator prompts**:
> Criticality detected via keyword: "payment". Recommended tier: strict.
> Proceed with strict, or override?

**User replies**: `strict`.

**Final parsed state**:
```yaml
scope: m           # inferred from task ("add rate limiting to endpoint" → M)
tier: strict       # criticality confirmed
critical: true
criticality_source: keyword
criticality_matched_term: "payment"
```

**Pipeline** (from matrix [M, feature]):
```
Spec → Scout → Decomposer → (Research → Plan → Impl → Test)×N → Committer
```

**Approval prompts**: all strict-tier gates (~6-8 depending on module count).

### Example 3: Ready-made spec (validate mode)

**User invocation**:
```
mode: validate
docs/specs/2026-04-15-payments.md — implement this.
```

**Orchestrator parses**:
- `mode: validate` → Spec enters validate mode.
- Detected file `docs/specs/2026-04-15-payments.md` → source of truth.

**Spec stage**:
- Reads file.
- Transforms to canonical `.task/00-spec.md` format.
- Runs validation, writes `## Validation` section.
- Presents for approval (one prompt, not two).

**Remainder of pipeline**: per scope (auto-classified from spec content after Spec stage).

### Example 4: Mid-flight tier upgrade

**User invocation**: (default inferred to M / standard).

**At Decomposition approval prompt**:
> Decomposer produced 5 modules including auth refactor.
> [approve] / [revise] / [reject]

**User replies**:
```
approve and switch to strict
```

**Orchestrator**:
- Updates front-matter: `tier: strict`, `tier_source: mid_flight`.
- Subsequent per-module Planner, Implementer, etc. prompt for approval per strict tier.

## Back-compat

Pre-redesign invocations (no preamble, no criticality keywords) result in:
- Scope auto-classified.
- Tier = scope-default.

If the auto-classified tier happens to be express or standard and the user expected strict behavior, they must either:
1. Declare `tier: strict` in preamble going forward.
2. Reply to the first approval prompt with "approve and switch to strict".

This is not a regression for users who explicitly used the pre-redesign skill for small tasks (they previously got every approval; now they get one) — SC-008 and FR-024 only promise strict-tier equivalence, not auto-selection equivalence.
