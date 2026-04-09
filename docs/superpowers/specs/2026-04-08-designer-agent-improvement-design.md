# Design Spec: Designer Agent Improvement + Design QA Agent

**Date**: 2026-04-08
**Status**: Draft
**Scope**: Rewrite `skills/task/agents/designer.md`, create new `skills/task/agents/design-qa.md`, update `skills/task/SKILL.md`

## Problem

The current Designer agent is a minimal extractor (~94 lines). When designs exist (Figma exports, screenshots), the Implementer receives approximate values and has to guess colors, spacing, component states, responsive behavior, and typography. The result diverges from the original design.

## Goal

When designs are provided, the Designer must be their slave -- zero creative liberty, pixel-perfect extraction, every value copy-pasteable into code. A new Design QA agent verifies that the implementation matches the design.

## Decision: Approach B -- Deep Extractor + Design QA Step

Two artifacts:
1. **Designer** (rewritten) -- precise extraction at Level 3 depth, model upgraded to Opus
2. **Design QA** (new agent) -- post-implementation verification at step 8.5

---

## Designer Agent

### Identity

- **Model**: opus (upgraded from sonnet -- Level 3 extraction requires deep reasoning)
- **Stage**: 5.5 (inside per-module loop, between Planner and Implementer)
- **Role**: Precise translator of visual design into implementation-ready specification. Every value is copy-paste into code. Zero interpretation, zero invention. When the project has existing components/libraries -- map design to them instead of creating from scratch.

### Activation

Runs only when:
- Decomposer flagged module as `ui: true`
- User provided design input (Figma export or screenshot)

Without design input -- skip. Write a `NO_DESIGN` warning to output file.

### Inputs

- Figma export / screenshot from user
- `.task/05-plan-{N}.md` -- Brief section (module context)
- `.task/02-scout.md` -- Brief section (project structure, conventions)
- `.task/04-research-{N}.md` -- Brief section (found patterns, existing components)
- Existing project design assets (auto-detect):
  - Component libraries (UI kit with versions, e.g., `@paypath/ui v2`)
  - Tailwind config / CSS variables / design tokens
  - Style guides, theme files

### Process

#### Step 1: Inventory Design Input

Catalog everything the user provided:
- Which screens/pages exist
- Which states are shown (default, hover, error, empty, loading)
- Which breakpoints are shown (desktop, tablet, mobile)
- Which states are NOT shown -- explicitly record as `MISSING_STATE`

Output format:

```
| Screen      | States shown          | States missing              | Breakpoints    |
|-------------|-----------------------|-----------------------------|----------------|
| Dashboard   | default, empty        | loading, error              | desktop only   |
| User card   | default, hover        | focus, disabled, active     | desktop, mobile|
```

#### Step 2: Scan Project Design Assets

Read briefs from Scout and Researcher. Auto-detect:
- Component library: path, version, list of available components
- Existing tokens: location, format (CSS vars / Tailwind / theme object)
- Naming conventions: `--color-primary` vs `--brand-500`, `btn-lg` vs `button-large`

Output format:

```
Project assets detected:
  Library: @paypath/ui v2 (src/lib/ui/)
    Available: Button (primary|secondary|ghost), Card, Input, Badge, Modal
    Missing from lib: PricingCard, FeatureGrid, AnimatedCounter
  Tokens: tailwind.config.ts -> theme.extend.colors, theme.extend.spacing
  Naming: kebab-case CSS vars, PascalCase components
```

#### Step 3: Extract Global Design Tokens

From the design -- exact values. Level 3 format for each:

```
Colors:
  --color-primary: #3B82F6        (Figma: "Brand/Primary")
  --color-primary-hover: #2563EB  (Figma: "Brand/Primary Dark")

Typography:
  --font-heading: 'Inter', sans-serif  (Figma: "Inter")
  --text-h1: 48px / 1.1 / 700         (Figma: frame "Hero Title")

Spacing:
  Base unit: 8px (derived from: padding patterns 8, 16, 24, 32)
  --space-1: 4px
  --space-2: 8px
```

Each token references its source in the design (which frame, which element in Figma). Uncertain values marked `~APPROXIMATE` with explanation.

When project already has tokens -- compare with extracted:
- Match: use existing token name and value
- Mismatch: flag as `CONFLICT` with both values, mark as `DECISION`

```
CONFLICT: design shows #3B82F6 for primary, project has --color-primary: #2563EB
DECISION: [user must resolve]
```

#### Step 4: Component Specification (Level 3)

Every unique component from the design -- full specification. Two paths:

**A) Component exists in project library** -- mapping:

```
Button "Get Started":
  MAPS TO: @paypath/ui v2 -> Button
  variant: "primary"
  size: "lg"
  OVERRIDES: none -- exact match

Button "Learn More":
  MAPS TO: @paypath/ui v2 -> Button
  variant: "ghost"
  size: "md"
  OVERRIDES:
    color: var(--color-text-muted) (#6B7280) -- lib default is --color-primary
    DECISION: [extend variant or one-off override -- user must resolve]
```

**B) New component** -- full Level 3 specification:

```
PricingCard (NEW -- not in @paypath/ui):
  container:
    background: var(--color-bg-surface) (#F9FAFB)
    border: 1px solid var(--color-border) (#E5E7EB)
    border-radius: var(--radius-lg) (16px)
    padding: var(--space-8) var(--space-6) (32px 24px)
    box-shadow: var(--shadow-md) (0 4px 6px rgba(0,0,0,0.07))
    transition: transform 200ms ease, box-shadow 200ms ease

  :hover:
    transform: translateY(-4px)
    box-shadow: var(--shadow-lg) (0 10px 15px rgba(0,0,0,0.1))

  :focus-visible:
    outline: 2px solid var(--color-ring) (#93C5FD)
    outline-offset: 2px

  header:
    font: var(--font-heading) var(--text-h4) (Inter 24px/1.3/600)
    color: var(--color-text-heading) (#111827)
    margin-bottom: var(--space-2) (8px)

  price:
    font: var(--font-heading) var(--text-h2) (Inter 36px/1.1/700)
    color: var(--color-text-heading) (#111827)

  price-period:
    font: var(--font-body) var(--text-sm) (Inter 14px/1.5/400)
    color: var(--color-text-muted) (#6B7280)

  feature-list-item:
    font: var(--font-body) var(--text-base) (Inter 16px/1.5/400)
    color: var(--color-text-body) (#374151)
    padding-left: var(--space-6) (24px)
    icon: checkmark, color var(--color-success) (#10B981)
    margin-bottom: var(--space-2) (8px)

  cta-button:
    MAPS TO: @paypath/ui v2 -> Button variant="primary" size="lg"
    width: 100%

  WCAG:
    #111827 on #F9FAFB = 15.4:1 (AA pass)
    #374151 on #F9FAFB = 10.3:1 (AA pass)
    #6B7280 on #F9FAFB = 5.7:1 (AA pass)

  MISSING STATES from design:
    - disabled: NOT SHOWN -- [recommended] opacity 0.5, pointer-events none
    - loading: NOT SHOWN -- [recommended] skeleton shimmer
```

Every `MISSING STATE` clearly marked. Recommendations prefixed with `[recommended]` to distinguish from extracted facts.

#### Step 5: Layout & Responsive Specification

Per screen:

```
Dashboard Layout (desktop -- 1440px):
  container: max-width 1200px, margin 0 auto, padding 0 var(--space-6)
  grid: 12 columns, gap var(--space-6) (24px)
  sidebar: col-span-3 (300px)
  main: col-span-9

Dashboard Layout (mobile -- MISSING from design):
  INFERRED from desktop:
    sidebar: collapse to top nav or hamburger [DECISION: user must resolve]
    grid: single column
    card gap: var(--space-4) (16px)
  CONFIDENCE: low -- no mobile mockup provided
```

Everything inferred is marked `INFERRED` with confidence level. Everything from design is stated as fact without markers.

#### Step 6: WCAG Accessibility Audit

Check every text/background pair from all components. Not a sample -- ALL pairs.

```
WCAG 2.1 AA Accessibility Report:

| # | Text Color | Background | Element              | Ratio  | Req   | Status |
|---|------------|------------|----------------------|--------|-------|--------|
| 1 | #374151    | #FFFFFF    | body on page         | 12.6:1 | 4.5:1 | PASS   |
| 2 | #9CA3AF    | #FFFFFF    | muted on page        | 3.0:1  | 4.5:1 | FAIL   |
| 3 | #FFFFFF    | #3B82F6    | btn label on primary | 4.56:1 | 4.5:1 | PASS   |

FAILURES:
  #2: muted text #9CA3AF on #FFFFFF -- 3.0:1, needs 4.5:1
       ORIGINAL: #9CA3AF
       ADJUSTED: #6B7280 (5.7:1 -- PASS)
       DECISION: [use adjusted or accept non-compliance -- user must resolve]
```

Never silently replace. Show both values, let user choose.

#### Step 7: Generate Verification Checklist

Checklist for Design QA agent (step 8.5). Every item is concrete, verifiable, with expected value:

```
Verification Checklist (module {N}):

TOKENS:
  [ ] Primary color renders as #3B82F6
  [ ] Font heading is Inter
  [ ] Base spacing unit is 8px
  [ ] Border radius on cards is 16px

COMPONENTS:
  [ ] Button "Get Started" uses @paypath/ui Button variant="primary" size="lg"
  [ ] PricingCard header font is 24px/600 Inter
  [ ] PricingCard hover lifts 4px with shadow-lg
  [ ] Feature list checkmark icon is #10B981

LAYOUT:
  [ ] Dashboard grid is 12 columns with 24px gap
  [ ] Sidebar is 300px (col-span-3)
  [ ] Container max-width is 1200px

STATES:
  [ ] Button hover background is #2563EB
  [ ] Button focus has 2px #93C5FD ring with 2px offset
  [ ] PricingCard hover translateY is -4px

ACCESSIBILITY:
  [ ] All text/background pairs pass WCAG AA (see audit table)
  [ ] Focus indicators visible on all interactive elements
  [ ] No color-only information indicators

RESPONSIVE:
  [ ] [items from design]
  [ ] INFERRED items marked for manual review

Total: {N} checks
Design-extracted: {N} (must match exactly)
Inferred/recommended: {N} (review with user)
```

#### Step 8: Present for Approval

Show user:
1. Count of token conflicts (`CONFLICT`)
2. Count of missing states (`MISSING_STATE`)
3. Count of WCAG failures with proposals
4. Count of inferred values (`INFERRED`)
5. Decisions needed (`DECISION`)

All `DECISION` items block. Designer does not proceed without resolution.

### Output

Write to `.task/05.5-design-{N}.md`.

Structure:

```
## Brief
Source: Figma export (3 screens: dashboard, pricing, settings)
Screens: 3 shown, 0 mobile breakpoints
Project lib: @paypath/ui v2 -- 5 components mapped, 3 new needed
Tokens: 18 colors, 12 typography, 8 spacing, 5 radius, 4 shadows
WCAG: 14/16 pairs pass, 2 failures with adjusted alternatives
Decisions pending: 3 (see DECISION tags below)
Confidence: high for desktop, low for mobile (no mobile mockups)

## Design Source Inventory
[Step 1 output -- screen/state/breakpoint table]

## Project Assets Map
[Step 2 output -- existing lib, tokens, conventions]

## Design Tokens
### Colors
[Level 3 format, each with Figma source reference]
[CONFLICT markers where project differs]

### Typography
[Level 3 format with font, size, weight, line-height, spacing]

### Spacing
[Base unit, full scale, section padding]

### Effects
[Shadows, radius, gradients, glassmorphism -- exact CSS values]

## Component Specifications
### Mapped Components (existing in project)
[Step 4A -- each component with lib reference and overrides]

### New Components
[Step 4B -- full Level 3 spec per component]

## Layout & Responsive
[Step 5 output -- per screen, per breakpoint]
[INFERRED markers with confidence]

## WCAG Report
[Step 6 output -- full table + failure handling]

## Decisions Required
[Aggregated list of all CONFLICT, MISSING_STATE, INFERRED items needing user input]

## Verification Checklist
[Step 7 output -- complete point-by-point checklist for Design QA]

## CSS Custom Properties
:root { /* all extracted tokens */ }

## Tailwind Config Extension
theme: { extend: { /* mapped tokens */ } }
```

### Guidelines

- **Extract, don't invent** -- if the design has #3B82F6 for a button, the spec says #3B82F6, not "a suitable blue"
- **Source every value** -- each value references the frame/element in the design it was extracted from
- **Map before create** -- check if a component already exists in the project library before specifying a new one
- **Flag, don't guess** -- unclear values get `~APPROXIMATE` or `MISSING_STATE`, never invented values
- **Decisions block** -- everything tagged `DECISION` requires user resolution before proceeding
- **WCAG is mandatory** -- every text/background pair is checked, failures are never ignored
- **Existing conventions win** -- if the project uses `--brand-500` not `--color-primary`, follow the project convention
- **Tokens reference, raw value in parentheses** -- always `var(--color-primary) (#3B82F6)`, never only one of the two

### Failure Handling

```
NO_DESIGN:
  Module flagged ui: true but no design input provided.
  Action: skip Designer, write warning to 05.5-design-{N}.md:
    "> NO_DESIGN: No Figma export or screenshot provided.
    > Implementer will work without design specification.
    > Consider providing design input for pixel-perfect results."

PARTIAL_DESIGN:
  Some screens/states provided, others missing.
  Action: extract what exists, mark rest as MISSING_STATE/INFERRED.
  Continue -- don't block.

UNREADABLE_DESIGN:
  Screenshot too low resolution or Figma export corrupted.
  Action: stop, ask user for better input. Don't approximate from blurry source.

LIB_VERSION_CONFLICT:
  Design uses patterns from v1 but project is on v2 (or vice versa).
  Action: flag as DECISION, show both options with implications.

TOKEN_CONFLICT:
  Design values differ from existing project tokens.
  Action: flag each as CONFLICT with both values. User resolves.
```

---

## Design QA Agent (New)

### Identity

- **Model**: sonnet
- **Stage**: 8.5 (after Tester, before Reviewer)
- **Role**: Point-by-point verification that implementation matches the design specification. Uses the Designer's verification checklist plus visual comparison via browse/screenshot.

### Activation

Runs only when `05.5-design-{N}.md` exists for the current module (Designer ran for this module).

### Inputs

- `.task/05.5-design-{N}.md` -- Verification Checklist section
- Original design (Figma export / screenshot from user)
- Browse screenshot of implementation (agent captures this itself)

### Process

#### Step 1: Screenshot Implementation

Launch or find the running dev server. Screenshot every screen that exists in the design. Same viewport sizes.

```
Screenshots taken:
  dashboard-desktop-1440.png -- viewport 1440x900
  pricing-desktop-1440.png -- viewport 1440x900
```

#### Step 2: Checklist Verification

Walk through the Verification Checklist point by point. For each:

```
[PASS] Primary color renders as #3B82F6
  Evidence: inspected .btn-primary background-color via DOM

[FAIL] PricingCard hover lifts 4px
  Expected: translateY(-4px)
  Actual: translateY(-2px)
  Severity: MEDIUM
  Fix: src/components/PricingCard.tsx:42 -- change -2px to -4px

[SKIP] Mobile sidebar collapses to hamburger
  Reason: INFERRED item, no mobile design provided
```

#### Step 3: Visual Comparison

Place implementation screenshot next to original design. Identify visual discrepancies not covered by the checklist:
- Overall spacing feels different
- Element mispositioned
- Element order differs
- Something present in design but missing in implementation (or vice versa)

```
Visual deviations (not in checklist):
  [HIGH] Feature grid has 3 columns in design, 2 in implementation
    Location: pricing page, below hero
    File: src/pages/pricing.tsx:88

  [LOW] Card shadow slightly deeper than design
    Acceptable -- within token range
```

#### Step 4: Generate Report

```
## Brief
Module: {N} -- {name}
Checklist: 42 checks -- 38 PASS, 3 FAIL, 1 SKIP
Visual: 2 deviations found (1 HIGH, 1 LOW)
Verdict: FAIL -- 3 checklist failures + 1 high visual deviation

## Checklist Results
[full pass/fail/skip for every item]

## Visual Deviations
[with screenshot references and file:line locations]

## Required Fixes
[aggregated list with severity, sorted HIGH first]

## Verdict
PASS -- ship it
PASS WITH NOTES -- minor deviations, acceptable
FAIL -- requires fixes, route back to Implementer
```

### Output

Write to `.task/08.5-design-qa-{N}.md`.

### Routing

- **PASS**: proceed to Reviewer
- **PASS WITH NOTES**: proceed to Reviewer, notes included
- **FAIL**: route back to Implementer with specific fix list. Full cycle: Design QA FAIL -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs. Max 2 full cycles. After 2 cycles: escalate to user. Implementer receives `08.5-design-qa-{N}.md` as additional input (Required Fixes section).

---

## SKILL.md Updates Required

### Pipeline Overview

Add step 8.5 inside the per-module loop:

```
    | 7. Tester       -> test module N                                 |
    | 8. Debugger     -> hypothesis-driven failure analysis            |
    |    back to Implementer -> Tester (max 2 cycles)                  |
    | 8.5 Design QA   -> verify impl matches design (if UI module)    |
    |    back to Implementer -> Design QA (max 2 cycles)              |
```

### Agent Reference Table

Add row:

```
| 8.5 | Design QA | agents/design-qa.md | sonnet | 05.5-design-{N}.md (checklist), design input, browse screenshot | 08.5-design-qa-{N}.md |
```

Update Designer row model from sonnet to opus.

### Workspace

Add file:

```
  08.5-design-qa-{N}.md  (per UI module)
```

### Adaptive Pipeline

Update `feature + design`:

```
| feature + design | All stages + Designer for UI modules + Design QA for UI modules |
```

### Flow Control

Add Design QA cycle:

```
Design QA Cycle (runs after Test/Debug cycle completes):
  Cycle 1: Design QA fails -> Implementer fixes -> Tester -> (Debug if needed) -> Design QA re-runs
  Cycle 2: Still failing -> Implementer -> Tester -> (Debug) -> Design QA
  Cycle 3: STOP -> Escalate to user with full context
```

Note: code changes from Design QA fixes must pass through Tester before re-verification. Implementer receives `08.5-design-qa-{N}.md` (Required Fixes section) as additional input during Design QA fix cycles.

### Out of Scope

The "no design" case (UI module without design input) is explicitly out of scope. To be handled separately, possibly through `ui-ux-pro-max` integration.
