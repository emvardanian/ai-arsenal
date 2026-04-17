# Spec Dialogue Patterns

Reference patterns for the Spec agent's interactive mode. Loaded on demand when Spec runs in `interactive` mode. Section ordering and question flow are preserved from the pre-redesign Brainstormer to satisfy FR-025.

## One Question Rule

Ask exactly one question per message, then wait for the user's answer before continuing.

- Never batch multiple questions in a single message
- If follow-up is needed, ask it in the next message after the user responds
- Exception: multiple-choice options within a single question are fine (that's one question with options, not multiple questions)

## Multiple Choice Preferred

When a question has a finite, enumerable set of answers, present it as multiple choice:

```
Which approach do you prefer?

A) Server-side rendering with session-based auth
B) SPA with token-based auth
C) Hybrid (SSR for public pages, SPA for app)
D) Something else (describe)
```

Use open-ended questions only when:
- The answer is truly free-form (e.g., "Describe the feature in your own words")
- Options would be misleading or artificially constraining
- You need a narrative explanation, not a selection

## Red Flags Table

These thoughts mean STOP -- you're rationalizing skipping the process:

| Thought | Reality |
|---------|---------|
| "This is simple, I don't need to brainstorm" | Simple tasks become complex. Follow the process. |
| "I already understand what they want" | Understanding =/= validated understanding. Confirm it. |
| "Let me just start writing the spec" | Spec without dialogue produces assumptions, not requirements. |
| "The user seems impatient" | A 5-minute brainstorm saves hours of rework. |
| "I can infer the rest from context" | Inferred requirements are guessed requirements. Ask. |
| "This is just a technical change" | Technical changes still have user-facing implications. Explore them. |

If you catch yourself thinking any of these, pause and continue the structured dialogue.

## Incremental Validation

After completing each section of the spec, present it to the user and wait for explicit approval:

1. Show the completed section in full
2. Ask: "Does this look right? Approve to continue, or tell me what to revise."
3. If the user says "approve", "ok", "yes", "looks good", or similar -- proceed to the next section
4. If the user says "revise", "change", "no", or provides feedback -- update the section and re-present it
5. Never skip ahead to the next section without approval
6. Never combine multiple sections into one approval step

Section order: Context -> User Stories -> Acceptance Criteria -> Quality Gates -> Edge Cases -> Scope

## Propose Approaches

Before finalizing a key design decision (architecture approach, priority ordering, scope boundary), propose 2-3 alternatives:

```
I see three approaches for this:

**Option A: [Name]**
- Pros: [benefits]
- Cons: [drawbacks]
- Best when: [conditions]

**Option B: [Name]**
- Pros: [benefits]
- Cons: [drawbacks]
- Best when: [conditions]

**Option C: [Name]**
- Pros: [benefits]
- Cons: [drawbacks]
- Best when: [conditions]

**My recommendation**: Option [X] because [reasoning].

Which do you prefer?
```

Apply this for:
- Choosing between fundamentally different feature scopes
- Prioritizing competing user stories
- Deciding on scope boundaries (include vs. exclude a capability)

Don't apply this for:
- Trivial formatting choices
- Standard patterns with one obvious answer
- Details that don't affect the spec's direction

## Scope Decomposition

If the user's request spans multiple independent domains or would produce a spec too large to be actionable:

1. **Detect**: Request touches 3+ unrelated systems, or would produce 5+ independent user stories, or mixes infrastructure changes with feature work
2. **Propose split**: Present sub-projects with clear boundaries
   ```
   This is large enough to split into sub-projects:

   1. [Sub-project A]: [scope] -- [why it's independent]
   2. [Sub-project B]: [scope] -- [why it's independent]
   3. [Sub-project C]: [scope] -- [why it's independent]

   I recommend starting with [A] because [reasoning].
   Shall we brainstorm [A] first?
   ```
3. **Proceed with first**: After user approval, brainstorm only the first sub-project
4. **Record deferred**: Note other sub-projects in the spec's Scope OUT section with a brief description of each

# Interview Mode Patterns

Loaded when Spec agent runs in `interview` mode. Interview is adaptive, not templated — the patterns here define HOW to pick and frame questions, not a rigid sequence of sections.

## Gap Attack Categories

Every round, scan the working spec for attackable gaps across five categories. You don't have to hit all five per round — pick the 3-5 most productive gaps overall. Use this as a sampling frame, not a checklist.

### 1. Hidden assumptions

Things the author took for granted without writing them down.

Signals:
- User stories imply infrastructure that isn't in Scope IN ("users can undo" implies action log).
- ACs refer to concepts without defining them ("standard rate limit" — whose standard?).
- No mention of offline, concurrency, time zones, locales, when the feature could obviously hit them.

Example attack: "US1 says 'users can undo an action'. There's no mention of how far back undo goes. Is it in-session only, 24h, unbounded? A/B/C"

### 2. Unnamed tradeoffs

Choices in the spec with unacknowledged downsides.

Signals:
- A decision is stated without tradeoff analysis ("We'll use JWT" — why not session? what breaks?).
- Two stories imply different architectures (one says 'stateless', another says 'user presence').
- An AC has a threshold without explaining the cost of that threshold (p95 < 200ms implies no synchronous external I/O).

Example attack: "AC-3: p95 < 200ms. This rules out synchronous calls to the billing API (which averages 400ms). Either billing is async/cached, or the threshold is aspirational. A/B/C/D"

### 3. Scale & failure modes

What breaks at N users / during outage / on concurrent writes / on retry / on partial failure.

Signals:
- No target user count, req/s, data volume stated anywhere.
- External dependencies mentioned without failure handling (database, SMTP, payment gateway, third-party API).
- Write paths without idempotency discussion.
- Retries without bounded backoff or dead-letter.

Example attack: "Scope IN: 'email notifications'. Scope OUT: 'retry on failure'. What happens when SMTP is down 2h — silent drop, user-visible error, queue with bounded backoff, dead-letter + admin alert? A/B/C/D"

### 4. UX blindspots

Every spec specifies the happy path. Interview attacks the rest.

Signals:
- No mention of empty, loading, error, offline, permissions-denied states.
- No accessibility (contrast, keyboard-only, screen reader, reduced motion).
- No localization / RTL / long-text handling.
- No confirmation / destructive-action guard.

Example attack: "US2: 'users view their transaction history'. What does an empty history show? A/B/C. What does a failed load show? Refresh prompt, cached state, error dialog? D/E/F"

### 5. Technical concerns

Implementation-adjacent gaps that affect spec completeness.

Signals:
- Data model not sketched (what entities, what fields, what relationships).
- Integration surfaces not named (internal services, external APIs, webhooks).
- Migration strategy missing for features that change existing data.
- Observability silent (logging, metrics, tracing, alerts).
- Secret/PII handling implicit.
- Rollback plan absent.

Example attack: "Spec adds 'password reset flow' but no mention of existing session invalidation. When the user resets, do active sessions die, survive, or prompt re-auth? A/B/C"

## Question Format (AskUserQuestionTool)

Every question has this shape:

```
Q{N}: <one-line gap summary>

Context: "<exact quote from spec location>"

A) <option 1 — concrete, named> — <tradeoff or implication>
B) <option 2 — concrete, named> — <tradeoff or implication>
C) <option 3 — concrete, named> — <tradeoff or implication>
D) Custom: <brief hint for the custom path>
```

Rules:
- **Named options**, not abstractions. "Queue with 1h bounded backoff + DLQ" beats "robust retry".
- **Tradeoffs named**. Options should expose the cost of choosing each.
- **Custom always present**. User may see an option you didn't think of.
- **One gap per question**. If two gaps are tangled, split them into Q{N} and Q{N+1}.

## Banned Question Patterns

These patterns waste a round and violate the non-obvious rule:

- "Who are the users?" — already in the spec, or should have been caught by interactive mode.
- "Should it be secure / fast / reliable?" — yes. Ask for thresholds instead.
- "Any other considerations?" — shotgun question; user has to do the gap-scan for you.
- "What if there's an error?" — too vague. Ask about a specific failure mode.
- "Is this important?" — false choice. Everything in the spec is nominally important; interview sharpens priority through tradeoffs.

## Round Structure

Each round:
1. Pick 3-5 concrete gaps.
2. Frame each as a question per the format above.
3. Issue all questions in one AskUserQuestionTool call (batch).
4. On return, update the working spec.
5. Log the (question, answer, edit) triple for Interview Delta.

## Termination Signals

- **3 consecutive empty rounds** — gap-scan yields nothing new. Spec is stable.
- **User says "done"** (or "enough", "that's all", "ship it") in any answer — respect it. Close remaining open gaps as `[OPEN QUESTION]` markers.
- **5 rounds reached** — hard cap. List open gaps as `[OPEN QUESTION]` and move to assembly.
