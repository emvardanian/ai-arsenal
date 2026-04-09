# Brainstorm Dialogue Patterns

Reference patterns for conducting structured brainstorm sessions. Loaded on demand by the Brainstormer agent.

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
