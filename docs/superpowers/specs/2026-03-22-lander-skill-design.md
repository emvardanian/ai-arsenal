---
name: lander
description: Multi-agent brainstorming orchestrator for landing pages. Deep research of reference sites, design system creation, copywriting — producing spec files ready for the task skill. Triggers on "landing page", "лендінг", "lander", "build a landing", "design a page", "зроби лендінг".
---

# Lander — Landing Page Brainstorm Orchestrator

## Overview

A multi-agent brainstorming skill for landing pages. Takes a user from idea (or reference URLs) through deep research, design decisions, and copywriting — producing a comprehensive set of spec files ready for implementation via the `task` skill.

**Core principle:** This skill does NOT write code. It orchestrates the best available agents and tools to produce a detailed, implementation-ready spec through an interactive brainstorming process with many clarifying questions at every stage.

## Architecture: Phased Pipeline + Interactive Loops

Four sequential phases, each containing an interactive loop with user questions. Parallelism where possible (multi-site research).

```
Phase 1 — Discovery (interactive loop)                          [approval]
  Interviewer → Scout

Phase 2 — Research (parallel + interactive)                     [approval]
  Researcher ×N → Synthesizer

Phase 3 — Design (interactive loop)                             [approval per agent]
  Strategist → Designer → Copywriter

Phase 4 — Compile (auto)                                        [auto]
  Compiler
```

### Progress Tracker

Every response starts with:

```
[✅ Discovery] → [▶ Research 2/3] → [ Design] → [ Compile]
```

Icons: `✅` done · `▶` active · ` ` pending · `⭕` skipped · `🔄` re-run · `❌` failed
Research: `[▶ Research 2/3]` = 2 of 3 sites done
Design sub-stages: `[▶ Design: Strategy]` → `[▶ Design: Visual]` → `[▶ Design: Copy]`

## Agent Reference

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Interviewer | `agents/interviewer.md` | **opus** | user request | `01-brief.md` |
| 2 | Scout | `agents/scout.md` | sonnet | `01-brief.md` | `02-references.md` |
| 3 | Researcher | `agents/researcher.md` | sonnet | `02-references.md` (one URL) | `03-research-{site}.md` |
| 4 | Synthesizer | `agents/synthesizer.md` | **opus** | `01-brief.md`, `03-research-*.md` | `04-synthesis.md` |
| 5 | Strategist | `agents/strategist.md` | **opus** | `01-brief.md`, `04-synthesis.md` | `05-strategy.md` |
| 6 | Designer | `agents/designer.md` | sonnet | `01-brief.md`, `04-synthesis.md`, `05-strategy.md` | `06-design.md` |
| 7 | Copywriter | `agents/copywriter.md` | sonnet | `01-brief.md`, `04-synthesis.md`, `05-strategy.md`, `06-design.md` | `07-copy.md` |
| 8 | Compiler | `agents/compiler.md` | sonnet | `00-summary.md`, `0{1-7}*.md` | `08-final-spec.md` |

**Model strategy:** Opus — complex reasoning, synthesis, strategic decisions (Interviewer, Synthesizer, Strategist). Sonnet — execution, analysis, generation, consistency checking (Scout, Researcher, Designer, Copywriter, Compiler).

**Rule**: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Workspace

```
.lander/
├── 00-summary.md              ← pipeline status (updated after each stage)
├── 01-brief.md                ← business goal, audience, constraints
├── 02-references.md           ← URL list + why chosen
├── 03-research-stripe.md      ← per-site deep analysis
├── 03-research-linear.md
├── 03-research-vercel.md
├── 04-synthesis.md            ← cross-reference patterns & recommendations
├── 05-strategy.md             ← sections, order, conversion flow, scroll narrative
├── 06-design.md               ← design system: colors, fonts, spacing, components
├── 07-copy.md                 ← headlines, body copy, CTAs, tone guide
├── 08-final-spec.md           ← index + executive summary of all specs
└── screenshots/               ← reference site screenshots
    ├── stripe-full.png
    ├── stripe-hero.png
    ├── linear-full.png
    └── ...
```

**First step**: `mkdir -p .lander/screenshots`

**Site name convention:** Derived from domain minus TLD (e.g., `stripe.com` → `stripe`, `linear.app` → `linear`, `my-saas.io` → `my-saas`).

## Pipeline Summary File

After each phase completes, update `.lander/00-summary.md`:

```markdown
# Pipeline Summary
- **Project**: [name from brief]
- **Goal**: [1-sentence goal]
- **Audience**: [target audience]
- **References**: [N sites]
- **Phase 1 — Discovery**: ✅ brief collected, 4 references selected
- **Phase 2 — Research**: ✅ 4 sites analyzed, dark minimal style, animated hero pattern
- **Phase 3 — Design**: ✅ 8 sections, Inter+Mono fonts, dark palette, 12 copy blocks
- **Phase 4 — Compile**: ✅ 7 spec files, no contradictions
```

The Compiler reads this file first for quick context before processing individual specs.

## Before Starting

1. Check if `.lander/` exists from a previous run — if so, ask user: resume or start fresh?
2. Detect available tools:
   - Firecrawl MCP → enables branding extraction (check for `firecrawl_scrape` tool)
   - Playwright MCP or gstack → enables automated screenshots
   - ui-ux-pro-max skill → enables design catalog
   - agent-teams plugin → enables parallel research
3. If Firecrawl is unavailable, warn user: "Research will rely on screenshots + AI vision (less precise)"
4. If user provided URLs in their initial message, pass them directly to Scout (skip that Interviewer question)

## Starting the Pipeline

1. `mkdir -p .lander/screenshots`
2. Read `agents/interviewer.md`
3. Execute Interviewer → present → wait for approval
4. Update `00-summary.md`
5. Continue to Scout, then Phase 2

## Phase 1 — Discovery

### Interviewer Agent (opus)

**Goal:** Collect complete business context in 5-8 adaptive questions.

Questions (asked one at a time, skips obvious ones):

1. What product/service? Who is it for?
2. Main goal of the landing page? (sign up, waitlist, buy, download)
3. Target audience? (developers, designers, business, mass market)
4. Tone/mood? (serious, playful, minimalist, bold)
5. Existing brand guidelines? (logo, colors, fonts — or from scratch)
6. Reference sites that you like? (URLs or style description)
7. Technical constraints? (framework, hosting, existing codebase)
8. What do you definitely NOT want? (anti-patterns, styles to avoid)

**Rules:**
- One question at a time
- Multiple choice where possible
- If user gave lots of context upfront — skip obvious questions
- Max 8 questions total
- If user provides URLs in their initial message, note them for Scout

**Output:** `.lander/01-brief.md`

### Scout Agent (sonnet)

**Goal:** Assemble 3-5 relevant references for deep analysis. Default 3, maximum 5 (more = slower + more expensive).

**Mode A — User provided URLs:**
1. Validate URLs via Firecrawl `firecrawl_scrape` (markdown format, just title + meta — quick check that URL is reachable and relevant)
2. Optionally search for 1-2 similar sites via web search
3. Present list to user for approval

**Mode B — User described an idea:**
1. Web search by niche (e.g., "best AI startup landing pages 2026")
2. Quick validate candidates via Firecrawl `firecrawl_scrape` (markdown format, title + meta only)
3. Present 5-7 options to user with one-line descriptions
4. User selects 3-5 for deep analysis

**Output:** `.lander/02-references.md` (URLs + preview + why chosen)

## Phase 2 — Research

### Researcher Agent ×N (sonnet, parallel)

**Goal:** Extract everything valuable from one reference site. One agent per site.

**Step 1 — Data collection (per site):**

| Tool | MCP Call | What it gets |
|------|----------|-------------|
| Firecrawl branding | `firecrawl_scrape` with `formats: ["branding"]` | Colors, fonts, spacing, logo, UI components as structured BrandingProfile |
| Firecrawl content | `firecrawl_scrape` with `formats: ["markdown"]` | Page content, section structure, headings, CTAs as clean markdown |
| Playwright screenshots | `browser_take_screenshot` or gstack equivalent | Full-page + hero + key sections at desktop & mobile |

**Failure handling:** If Firecrawl fails for a specific site (timeout, blocked), fall back to Playwright screenshots + AI vision analysis. If Playwright also fails, ask user to provide a screenshot manually. Never skip a reference — always get data through some path.

**Step 2 — Analysis (6 axes):**

1. **Page structure** — sections, order, scroll depth, attention retention
2. **Visual design** — style (minimalism, bold, playful), color palette, typography, whitespace
3. **Messaging & copy** — tone of voice, value prop formulation, CTA texts, social proof
4. **UX patterns** — animations, scroll effects, interactive elements, navigation
5. **Conversion tactics** — CTA placement and frequency, pricing display, trust signals, urgency
6. **Takeaways** — specific patterns that work for our case

**Output per site:** `.lander/03-research-{site-name}.md`

### Parallel Execution

When `agent-teams` plugin is available:
```
├── Researcher-1 → site-1 (parallel)
├── Researcher-2 → site-2 (parallel)
└── Researcher-3 → site-3 (parallel)
```
Fallback: sequential execution, one site at a time.

### Synthesizer Agent (opus)

**Goal:** Merge findings from all references into unified recommendations.

**Process:**
1. Read all `03-research-*.md` + `01-brief.md`
2. Find common patterns across references
3. Highlight unique ideas from each
4. Filter through brief lens (audience, goal, tone)
5. Produce recommendations with attribution: "Hero like Linear, pricing like Graphite"

**Interactive:** After synthesis, ask user:
- What resonates? What doesn't?
- Any patterns from references that should NOT be used?
- Any specific elements to prioritize?

**Output:** `.lander/04-synthesis.md`

## Phase 3 — Design

### Strategist Agent (opus)

**Goal:** Define landing page structure — which sections, in what order, with what content.

**Reads:** `01-brief.md` + `04-synthesis.md`

**Defines:**
- **Sections and order** — Hero → Social proof → Features → How it works → Pricing → CTA → Footer
- **Section content** — what each section shows, its purpose, its CTA
- **Conversion flow** — primary CTA, secondary CTA, repetition strategy, pricing strategy
- **Scroll narrative** — the story told from hero to footer

**Interactive:** Ask user about section choices (pricing yes/no, FAQ, number of features, testimonials).

**Output:** `.lander/05-strategy.md`

### Designer Agent (sonnet)

**Goal:** Create complete design system for the landing page.

**Reads:** `01-brief.md` + `04-synthesis.md` + `05-strategy.md`

**ui-ux-pro-max integration:** Uses the skill's catalog of 50+ styles, 161 color palettes, 57 font pairings, 161 product types. Agent selects from catalog based on brief + reference analysis rather than inventing from scratch.

**Defines:**

| Area | Details |
|------|---------|
| Color palette | Primary, secondary, accent, backgrounds, text, borders, status colors |
| Typography | Font pair, scale (H1-H6, body, small), weights, line-heights |
| Spacing & Layout | Base unit, section padding, gaps, max-width, grid system |
| Components | Buttons, cards, inputs, badges, nav — with all states (hover, focus, active, disabled) |
| Effects | Shadows, gradients, border-radius, glassmorphism, blur |
| Motion | Scroll animations, hover effects, transitions, micro-interactions |

**Interactive:** Propose 2 design directions based on references, user picks one, then refine details.

**Output:** `.lander/06-design.md` (full design system with CSS custom properties / Tailwind config)

### Copywriter Agent (sonnet)

**Goal:** Write all text content for every section.

**Reads:** `01-brief.md` + `04-synthesis.md` + `05-strategy.md` + `06-design.md` (to align copy tone with visual direction)

**Writes per section:**
- **Headlines** — heading + subheading for each section. 2-3 variants for hero.
- **Body copy** — feature descriptions, how-it-works steps, testimonial placeholders
- **CTAs** — button texts, form labels, conversion element copy
- **Tone guide** — do's & don'ts, examples of correct/incorrect tone

**Interactive:** Present 2-3 headline variants for hero and key sections, let user pick or adjust.

**Output:** `.lander/07-copy.md`

## Phase 4 — Compile

### Compiler Agent (sonnet)

**Goal:** Assemble all specs into a consistent package ready for `task` skill.

**Process:**
1. Read `00-summary.md` + all `.lander/0{1-7}*.md`
2. Check consistency: every section in `05-strategy.md` has matching copy in `07-copy.md`, design tokens in `06-design.md` match the tone described in brief, no orphaned references
3. Generate `08-final-spec.md` — index + executive summary + implementation notes
4. If contradictions found — flag them for the user with specifics (e.g., "Strategy defines 8 sections but Copy only covers 6"). User decides whether to re-run an agent or accept as-is

**Output format of `08-final-spec.md`:**

```markdown
# Lander Spec: [Project Name]

## Executive Summary
[2-3 sentences: what, for whom, what style]

## Spec Files
| File | Contents | Status |
|------|----------|--------|
| 01-brief.md | Business goal, audience, constraints | ✅ |
| 02-references.md | N analyzed references | ✅ |
| 03-research-*.md | Per-site deep analysis | ✅ |
| 04-synthesis.md | Cross-reference patterns | ✅ |
| 05-strategy.md | N sections, conversion flow | ✅ |
| 06-design.md | Design system, tokens | ✅ |
| 07-copy.md | All copy, tone guide | ✅ |

## Implementation Notes
[Tech stack recommendation, key challenges, estimated complexity]
```

## Dependencies & Integrations

| Dependency | Type | Purpose | Required? | Fallback |
|------------|------|---------|-----------|----------|
| **Firecrawl MCP** | MCP Server | Branding extraction + page scraping | Recommended | Playwright screenshots + AI vision analysis (see Researcher failure handling) |
| **Playwright MCP or gstack** | MCP/Plugin | Screenshots + scrolling + JS execution | Recommended | User provides screenshots manually |
| **ui-ux-pro-max** | Skill | Design catalog (styles, palettes, fonts) — used by Designer agent | Enhanced | Designer generates from scratch based on references |
| **agent-teams** | Plugin | Parallel research of multiple references | Enhanced | Sequential research (slower) |
| **frontend-design** | Plugin | Enhanced design spec quality — used by Designer agent | Optional | Designer uses own judgment |

## Execution Strategy

### Tier 1: Agent Teams (preferred — parallel research)

When `agent-teams` plugin is available, use it for Phase 2:

```
/team-spawn custom --name lander-research --members N
  ├── researcher-1: analyze site-1
  ├── researcher-2: analyze site-2
  └── researcher-3: analyze site-3
```

Each researcher has file ownership: `03-research-{their-site}.md`.

### Tier 2: Subagents (fallback — isolated context)

Spawn each agent as an independent subagent:
```
Spawn subagent:
  - Instructions: Read and follow agents/{agent}.md
  - Input: {only the files listed in Reads column}
  - Output: .lander/{output file}
```

### Tier 3: Sequential (last resort)

Execute agents inline, one by one. Use `.lander/` as shared memory.

## Context Management

1. **File system as memory** — agents write to `.lander/`, downstream agents read from files
2. **Brief sections** — every agent output starts with `## Brief` (5-10 lines). Downstream agents read only briefs when full context isn't needed
3. **Pipeline summary** — `00-summary.md` accumulates one line per completed phase. The Compiler reads this file for quick context
4. **Dependency map** — each agent reads only what's in the Reads column of the Agent Reference table
5. **Web content budget** — Researcher agents should extract structured data (Firecrawl branding/markdown), not dump raw HTML. Screenshots go to `screenshots/`, not inline in markdown
6. **One site per Researcher** — each Researcher agent handles exactly one reference site to keep context focused
7. **Max 5-7 files in agent context simultaneously**

## Flow Control

### Interactive Loops

Every phase except Compile has interactive loops. The orchestrator:
1. Runs the agent
2. Presents output to user
3. Asks targeted questions
4. If user wants changes → re-runs agent with feedback
5. If user approves → moves to next agent/phase

### Approval Gates

All agents except Compiler require user approval before the pipeline advances.

### Resuming

1. Check `.lander/` for existing artifacts
2. Read `00-summary.md` for context
3. Resume from next incomplete stage

## Trigger

**Name:** `lander`

**Triggers on:** "landing page", "лендінг", "lander", "build a landing", "design a page", "зроби лендінг"

**Does NOT:** Write code. Implement. The final output is a set of spec files ready for the `task` skill.

## Cleaning Up

After user proceeds to implementation: `rm -rf .lander/` — don't clean up automatically.
