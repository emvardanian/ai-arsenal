# Lander Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a multi-agent brainstorming skill for landing pages that produces implementation-ready spec files (+ visual preview) through interactive research and design phases.

**Architecture:** Phased pipeline with 9 agents across 4 phases (Discovery → Research → Design → Compile+Preview). Each agent reads/writes markdown files in a `.lander/` workspace directory. The orchestrator SKILL.md coordinates agent execution, approval gates, and progress tracking. Accepted CEO review expansions: Prototyper agent, visual moodboard, WCAG checks, A/B copy variants, Style Dictionary tokens.

**Tech Stack:** Markdown skill definitions following the existing `task` and `redesign` skill patterns. Agent tool for subagent dispatch. Optional integrations: Firecrawl MCP, Playwright/gstack, ui-ux-pro-max, agent-teams.

---

## File Structure

```
skills/lander/
├── SKILL.md              ← Main orchestrator (Phase 1-4 flow, approval gates, progress tracker)
└── agents/
    ├── interviewer.md     ← Phase 1: collect business context via 5-8 questions (opus)
    ├── scout.md           ← Phase 1: find 3-5 reference sites (sonnet)
    ├── researcher.md      ← Phase 2: deep-analyze ONE reference site (sonnet, parallel ×N)
    ├── synthesizer.md     ← Phase 2: merge all research into recommendations (opus)
    ├── strategist.md      ← Phase 3: define sections, order, conversion flow (opus)
    ├── designer.md        ← Phase 3: create design system + moodboard + WCAG checks (sonnet)
    ├── copywriter.md      ← Phase 3: write all page copy with A/B variants (sonnet)
    ├── compiler.md        ← Phase 4: assemble + validate final spec (sonnet)
    └── prototyper.md      ← Phase 4: generate static HTML preview (sonnet)
```

Each file has one clear responsibility. Agents communicate exclusively through files in `.lander/`. The orchestrator reads one agent `.md` at a time, just before executing it.

---

### Task 1: Create SKILL.md — Orchestrator

**Files:**
- Create: `skills/lander/SKILL.md`

This is the main orchestrator file. It follows the same structure as `skills/task/SKILL.md` and `skills/redesign/SKILL.md`: frontmatter, overview, pipeline diagram, agent reference table, progress tracker, workspace layout, execution strategy, flow control, and context management.

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/lander/agents
```

- [ ] **Step 2: Write SKILL.md**

Create `skills/lander/SKILL.md` with the full orchestrator content. The file must include:

1. **Frontmatter** — name: `lander`, description matching the spec trigger phrases ("landing page", "лендінг", "lander", "build a landing", "design a page", "зроби лендінг")

2. **Title & Role** — "You are the orchestrator of a multi-agent brainstorming pipeline for landing pages. You don't do the work yourself — you delegate to specialized agents and manage pipeline state."

3. **Pipeline Overview** — ASCII diagram showing the 4 phases:
```
Phase 1 — Discovery (interactive loop)                          [approval]
  Interviewer → Scout

Phase 2 — Research (parallel + interactive)                     [approval]
  Researcher ×N → Synthesizer

Phase 3 — Design (interactive loop)                             [approval per agent]
  Strategist → Designer → Copywriter

Phase 4 — Compile + Preview (auto)                              [auto]
  Compiler → Prototyper
```

4. **Progress Tracker** — format: `[✅ Discovery] → [▶ Research 2/3] → [ Design] → [ Compile]`
Icons: `✅` done · `▶` active · ` ` pending · `⭕` skipped · `🔄` re-run · `❌` failed
Research shows `[▶ Research 2/3]` = 2 of 3 sites done.
Design sub-stages: `[▶ Design: Strategy]` → `[▶ Design: Visual]` → `[▶ Design: Copy]`

5. **Agent Reference Table** — 9 agents:

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Interviewer | `agents/interviewer.md` | **opus** | user request | `01-brief.md` |
| 2 | Scout | `agents/scout.md` | sonnet | `01-brief.md` | `02-references.md` |
| 3 | Researcher | `agents/researcher.md` | sonnet | `02-references.md` (one URL) | `03-research-{site}.md` |
| 4 | Synthesizer | `agents/synthesizer.md` | **opus** | `01-brief.md`, `03-research-*.md` | `04-synthesis.md` |
| 5 | Strategist | `agents/strategist.md` | **opus** | `01-brief.md`, `04-synthesis.md` | `05-strategy.md` |
| 6 | Designer | `agents/designer.md` | sonnet | `01-brief.md`, `04-synthesis.md`, `05-strategy.md` | `06-design.md`, `moodboard.html` |
| 7 | Copywriter | `agents/copywriter.md` | sonnet | `01-brief.md`, `04-synthesis.md`, `05-strategy.md`, `06-design.md` | `07-copy.md` |
| 8 | Compiler | `agents/compiler.md` | sonnet | `00-summary.md`, `0{1-7}*.md` | `08-final-spec.md` |
| 9 | Prototyper | `agents/prototyper.md` | sonnet | `05-strategy.md`, `06-design.md`, `07-copy.md` | `prototype.html` |

Model strategy note: Opus for complex reasoning/synthesis/strategic decisions (Interviewer, Synthesizer, Strategist). Sonnet for execution/analysis/generation/consistency (Scout, Researcher, Designer, Copywriter, Compiler, Prototyper).

Rule: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

6. **Workspace** — `.lander/` directory layout:
```
.lander/
├── 00-summary.md
├── 01-brief.md
├── 02-references.md
├── 03-research-stripe.md
├── 03-research-linear.md
├── 03-research-vercel.md
├── 04-synthesis.md
├── 05-strategy.md
├── 06-design.md
├── 07-copy.md
├── 08-final-spec.md
├── moodboard.html            ← visual design system preview
├── prototype.html            ← static HTML page preview
└── screenshots/
```

First step: `mkdir -p .lander/screenshots`

Site name convention: domain minus TLD (e.g., `stripe.com` → `stripe`, `linear.app` → `linear`).

7. **Pipeline Summary File** — after each phase, update `.lander/00-summary.md`. Include timestamps, tool availability, and user decision log:
```markdown
# Pipeline Summary
- **Project**: [name from brief]
- **Goal**: [1-sentence goal]
- **Audience**: [target audience]
- **References**: [N sites]
- **Tools detected**: Firecrawl: ✅/❌, Playwright: ✅/❌, ui-ux-pro-max: ✅/❌, agent-teams: ✅/❌
- **Phase 1 — Discovery**: ✅ brief collected, 4 references selected (3m 42s)
- **Phase 2 — Research**: ✅ 4 sites analyzed, dark minimal style, animated hero pattern (8m 15s)
- **Phase 3 — Design**: ✅ 8 sections, Inter+Mono fonts, dark palette, 12 copy blocks (6m 30s)
  - Design direction chosen: "Dark Minimal" (over "Bold Gradient")
  - Copy variant chosen: "Variant A — Direct/Confident" (per-section mix)
- **Phase 4 — Compile**: ✅ 7 spec files, no contradictions, prototype generated (2m 10s)
```

8. **Before Starting** — check for existing `.lander/` (resume or fresh), detect available tools (Firecrawl MCP → `firecrawl_scrape`, Playwright/gstack, ui-ux-pro-max, agent-teams), warn if Firecrawl unavailable, pass user-provided URLs to Scout. **Resume project check**: if `.lander/` exists, read `00-summary.md` and compare project name against current request. If mismatch, ask user: "Found existing specs for [old project]. Start fresh or resume?"

9. **Starting the Pipeline** — `mkdir -p .lander/screenshots`, read `agents/interviewer.md`, execute, present, wait for approval, update `00-summary.md`, continue.

10. **Phase 1 — Discovery** section — Interviewer collects business context via interactive questioning loop (one question at a time, approval gate after brief is compiled). Scout assembles reference sites (retry loop if user rejects all, up to 2 retries then ask for manual URLs). Both agents have approval gates — user must approve before Phase 2 begins. Read agent `.md` just before executing.

11. **Phase 2 — Research** section — describes parallel execution of Researcher agents (one per site). Each researcher runs its interactive loop independently. After all complete, Synthesizer merges findings with interactive review (user feedback on what resonates). References agent-teams for parallel, subagents for fallback, sequential as last resort.

12. **Phase 3 — Design** section — sequential: Strategist → Designer → Copywriter. Each has its own approval gate and interactive loop (Strategist asks about sections, Designer proposes 2 directions for user to choose + generates moodboard for visual approval, Copywriter presents A/B variants for user selection). User approves each before the next agent runs.

13. **Phase 4 — Compile + Preview** section — Compiler runs automatically, validates consistency, flags contradictions for user decision. After Compiler passes, Prototyper generates a static HTML preview. Both are automatic (no approval gate), but contradictions from Compiler are escalated.

14. **Dependencies & Integrations** — table from spec:

| Dependency | Type | Purpose | Required? | Fallback |
|------------|------|---------|-----------|----------|
| **Firecrawl MCP** | MCP Server | Branding extraction + page scraping | Recommended | Playwright screenshots + AI vision |
| **Playwright MCP or gstack** | MCP/Plugin | Screenshots + scrolling | Recommended | User provides screenshots manually |
| **ui-ux-pro-max** | Skill | Design catalog | Enhanced | Designer generates from scratch |
| **agent-teams** | Plugin | Parallel research | Enhanced | Sequential research |
| **frontend-design** | Plugin | Enhanced design spec quality | Optional | Designer uses own judgment |

15. **Execution Strategy** — three tiers from spec (Agent Teams → Subagents → Sequential).

16. **Context Management** — 7 rules from spec (file system as memory, brief sections, pipeline summary, dependency map, web content budget, one site per Researcher, max 5-7 files in agent context).

17. **Flow Control** — interactive loops (run agent → present → ask → re-run or approve), approval gates (all agents except Compiler and Prototyper), resuming from `.lander/`.

18. **Cleaning Up** — after user proceeds to implementation: `.lander/` stays, user decides when to clean.

- [ ] **Step 3: Verify SKILL.md structure**

Run: `head -5 skills/lander/SKILL.md && grep -c "^##" skills/lander/SKILL.md`
Expected: frontmatter visible, 10+ level-2 headings

- [ ] **Step 4: Commit**

```bash
git add skills/lander/SKILL.md
git commit -m "feat(lander): add orchestrator SKILL.md for landing page brainstorm pipeline"
```

---

### Task 2: Create Interviewer Agent

**Files:**
- Create: `skills/lander/agents/interviewer.md`

The Interviewer is the first agent in the pipeline. It collects business context through 5-8 adaptive questions, one at a time. Model: opus.

- [ ] **Step 1: Write agents/interviewer.md**

Follow the agent file pattern from existing skills (`# Agent Name`, `> **Model**: X`, Role, Inputs, Process with Steps, Output structure, Guidelines).

Content requirements from spec:
- **Role**: Collect complete business context in 5-8 adaptive questions. First agent — output becomes foundation.
- **Inputs**: User request, conversation history
- **Process**:
  - **Step 1: Parse Initial Context** — extract what the user already provided (product, audience, goal, URLs, constraints). Note any URLs for Scout.
  - **Step 2: Ask Adaptive Questions** — from the 8-question bank (product/service, page goal, audience, tone, brand guidelines, reference sites, tech constraints, anti-patterns). Rules: one question at a time, multiple choice where possible, skip obvious ones, max 8 total.
  - **Step 3: Synthesize Brief** — compile all answers into structured brief.
  - **Step 4: Present for Approval** — present brief, wait for approval or adjustments.
- **Failure handling**:
  - THIN_BRIEF: If user gives minimal answers, ask targeted follow-up questions to fill gaps. Flag if brief has <3 substantive sections filled.
  - CONFLICTING_REQS: If user says contradictory things (e.g., "minimalist AND bold"), flag the conflict and ask for clarification.
- **Output**: Write to `.lander/01-brief.md`
- **Output structure**:
```
## Brief
Product, goal, audience, tone, brand status, references provided,
constraints, anti-patterns

## Product & Service
[What it is, who it's for]

## Page Goal
[Primary conversion action]

## Target Audience
[Who, what they care about, their sophistication level]

## Tone & Style
[Mood, adjectives, reference styles]

## Brand Assets
[Existing logo/colors/fonts or "from scratch"]

## Reference Sites
[URLs provided by user, or "none — Scout will find"]

## Technical Constraints
[Framework, hosting, existing code, or "none"]

## Anti-Patterns
[What to avoid, or "none specified"]
```
- **Guidelines**: Be conversational, one question at a time, respect user's time, skip what's obvious, max 8 questions total, never suggest solutions.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/interviewer.md && grep -c "^###" skills/lander/agents/interviewer.md`
Expected: `# Interviewer Agent` header, 4+ Step headings

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/interviewer.md
git commit -m "feat(lander): add Interviewer agent — adaptive question-based brief collection"
```

---

### Task 3: Create Scout Agent

**Files:**
- Create: `skills/lander/agents/scout.md`

The Scout assembles 3-5 reference sites for deep analysis. Model: sonnet. Two modes: user provided URLs vs. user described an idea.

- [ ] **Step 1: Write agents/scout.md**

Content requirements from spec:
- **Role**: Assemble 3-5 relevant references for deep analysis. Default 3, max 5 (more = slower + more expensive).
- **Inputs**: `.lander/01-brief.md` — Brief section only
- **Process**:
  - **Step 1: Determine Mode** — Mode A (user provided URLs) or Mode B (user described an idea).
  - **Step 2A: Validate User URLs** — Use Firecrawl `firecrawl_scrape` (markdown format, title + meta) to validate each URL. Optionally web search for 1-2 similar sites. Present list to user for approval.
  - **Step 2B: Search for References** — Web search by niche (e.g., "best AI startup landing pages 2026"). Quick validate candidates via Firecrawl. Present 5-7 options to user with one-line descriptions. User selects 3-5 for deep analysis.
  - **Step 3: Compile Reference List** — for each approved reference: URL, site name (domain minus TLD), one-line description of why it's relevant.
  - **Step 4: Present for Approval** — present final list, user approves or adjusts.
- **Failure handling**:
  - SCRAPE_TIMEOUT: Retry once. If still fails, mark URL as "unvalidated" and include with warning.
  - EMPTY_SEARCH: Broaden search terms twice (e.g., remove industry qualifier, then search by style). If still empty, ask user for URLs manually.
  - NO_VALID_REFS: If ALL candidate URLs fail validation, ask user to provide reference URLs manually. Never stall — always give the user a path forward.
  - USER_REJECTS_ALL: If user rejects all suggestions, retry with modified search terms (shift niche, style, or region). Max 2 retries. After 2 retries, ask user to provide URLs manually or describe what they're looking for more specifically.
- **Output**: Write to `.lander/02-references.md`
- **Output structure**:
```
## Brief
Mode (URLs provided / searched), reference count, categories covered

## References

### 1. [Site Name] — [one-line description]
- URL: [url]
- Why chosen: [relevance to brief]
- Category: [e.g., "SaaS hero", "dev tools pricing", "minimalist design"]

### 2. [Site Name] — [one-line description]
...
```
- **Guidelines**: Default to 3 references, max 5. Validate URLs before including. Diverse selection (don't pick 5 sites that all look the same). Brief relevance to the user's product/audience. Site name = domain minus TLD.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/scout.md && grep "Mode" skills/lander/agents/scout.md | head -3`
Expected: `# Scout Agent` header, Mode A / Mode B references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/scout.md
git commit -m "feat(lander): add Scout agent — reference site discovery with retry loops"
```

---

### Task 4: Create Researcher Agent

**Files:**
- Create: `skills/lander/agents/researcher.md`

The Researcher deep-analyzes ONE reference site. Multiple instances run in parallel (one per site). Model: sonnet.

- [ ] **Step 1: Write agents/researcher.md**

Content requirements from spec:
- **Role**: Extract everything valuable from one reference site. One agent per site — never analyze multiple sites.
- **Inputs**: `.lander/02-references.md` — only the entry for THIS site (one URL + context)
- **Process**:
  - **Step 1: Data Collection** — three tools:
    1. Firecrawl branding: `firecrawl_scrape` with `formats: ["branding"]` → colors, fonts, spacing, logo, UI components
    2. Firecrawl content: `firecrawl_scrape` with `formats: ["markdown"]` → page content, section structure, headings, CTAs
    3. Screenshots: `browser_take_screenshot` or gstack equivalent → full-page + hero + key sections at desktop & mobile
    Failure handling: If Firecrawl fails → fall back to screenshots + AI vision. If screenshots also fail → ask user for manual screenshot. Never skip a reference.
  - **Step 2: Analysis (6 axes)**:
    1. **Page structure** — sections, order, scroll depth, attention retention
    2. **Visual design** — style, color palette, typography, whitespace
    3. **Messaging & copy** — tone, value prop, CTAs, social proof
    4. **UX patterns** — animations, scroll effects, interactive elements, navigation
    5. **Conversion tactics** — CTA placement/frequency, pricing display, trust signals, urgency
    6. **Takeaways** — specific patterns that work for our case
- **Output**: Write to `.lander/03-research-{site-name}.md`
- **Output structure**:
```
## Brief
Site: [name] ([url]), style: [1-2 words], sections: [count],
key takeaway: [one sentence], data sources: [firecrawl/screenshots/both]

## Data Sources
[Which tools succeeded, which fell back, screenshot paths]

## Page Structure
[Sections in order, scroll depth, attention patterns]

## Visual Design
[Style category, color palette with hex values, typography, whitespace strategy]

## Messaging & Copy
[Tone, value prop formulation, CTA texts, social proof approach]

## UX Patterns
[Animations, scroll effects, interactive elements, navigation]

## Conversion Tactics
[CTA placement, pricing display, trust signals, urgency cues]

## Takeaways for Our Project
[3-5 specific patterns worth borrowing, with reasoning]
```
- **Guidelines**: One site per agent instance. Extract structured data, not raw HTML. Screenshots go to `screenshots/`, not inline. Be specific with hex values and pixel measurements. Attribution matters — downstream agents need to know which pattern came from which site.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/researcher.md && grep -c "^###" skills/lander/agents/researcher.md`
Expected: `# Researcher Agent` header, 6+ Step/section headings

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/researcher.md
git commit -m "feat(lander): add Researcher agent — single-site deep analysis with 6-axis framework"
```

---

### Task 5: Create Synthesizer Agent

**Files:**
- Create: `skills/lander/agents/synthesizer.md`

The Synthesizer merges findings from all Researcher outputs into unified recommendations. Model: opus.

- [ ] **Step 1: Write agents/synthesizer.md**

Content requirements from spec:
- **Role**: Merge findings from all reference site analyses into unified, actionable recommendations filtered through the project brief.
- **Inputs**: All `.lander/03-research-*.md` files + `.lander/01-brief.md`
- **Process**:
  - **Step 1: Read All Research** — load all `03-research-*.md` files and the brief.
  - **Step 2: Find Common Patterns** — identify patterns that appear across 2+ references (e.g., "3 of 4 sites use dark hero with gradient CTA").
  - **Step 3: Highlight Unique Ideas** — note standout patterns that appear on only one site but are highly relevant.
  - **Step 4: Filter Through Brief** — apply the brief's audience, goal, and tone as filters. Discard patterns that don't fit. Prioritize what matches.
  - **Step 5: Produce Recommendations with Attribution** — "Hero layout like Linear, pricing section like Graphite, CTA style like Vercel." Every recommendation traces back to a reference.
  - **Step 6: Interactive Review** — present synthesis to user and ask:
    - What resonates? What doesn't?
    - Any patterns from references that should NOT be used?
    - Any specific elements to prioritize?
  - **Step 7: Revise Based on Feedback** — incorporate user feedback and finalize.
- **Failure handling**:
  - INSUFFICIENT_DATA: If fewer than 2 research files exist, proceed but add a prominent caveat at the top of the synthesis: "⚠️ Limited data: synthesis based on [N] reference(s). Recommendations may be less reliable. Consider adding more references." Note in the Brief section.
  - CONFLICTING_REFS: If references show contradictory patterns (e.g., one site is dark minimal, another is bright maximalist), document both directions and let the brief's tone preference be the tiebreaker. Present the conflict to the user explicitly.
- **Output**: Write to `.lander/04-synthesis.md`
- **Output structure**:
```
## Brief
References analyzed: [N], common patterns: [count],
unique highlights: [count], recommended style: [1-2 words],
key recommendation: [one sentence]

## Common Patterns
[Patterns found across 2+ references, with attribution]

## Unique Highlights
[Standout ideas from individual references]

## Recommendations

### Page Structure
[Recommended section order and approach, with attribution]

### Visual Direction
[Style, colors, typography recommendations, with attribution]

### Messaging Approach
[Tone, value prop strategy, CTA approach, with attribution]

### UX & Interaction
[Animation, scroll effects, interactive elements, with attribution]

### Conversion Strategy
[CTA placement, pricing, trust signals, with attribution]

## Rejected Patterns
[Patterns from references that don't fit the brief, with reasoning]

## User Feedback
[Incorporated after interactive review]
```
- **Guidelines**: Every recommendation has attribution ("like [site]"). Filter through the brief — what works for a dev tools landing page won't work for a kids' app. Be opinionated — rank recommendations, don't just list. Flag conflicts between references.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/synthesizer.md && grep "attribution" skills/lander/agents/synthesizer.md | head -2`
Expected: `# Synthesizer Agent` header, attribution references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/synthesizer.md
git commit -m "feat(lander): add Synthesizer agent — cross-reference pattern merging with attribution"
```

---

### Task 6: Create Strategist Agent

**Files:**
- Create: `skills/lander/agents/strategist.md`

The Strategist defines the landing page structure — which sections, in what order, with what purpose. Model: opus.

- [ ] **Step 1: Write agents/strategist.md**

Content requirements from spec:
- **Role**: Define the landing page architecture — sections, order, content purpose, conversion flow, and scroll narrative.
- **Inputs**: `.lander/01-brief.md` + `.lander/04-synthesis.md`
- **Process**:
  - **Step 1: Define Section Plan** — determine which sections the page needs (Hero, Social Proof, Features, How It Works, Pricing, FAQ, CTA, Footer, etc.). Each section gets: name, purpose, primary content, CTA (if any).
  - **Step 2: Establish Section Order** — arrange sections to tell a coherent story from hero to footer. The scroll narrative should build: hook → credibility → value → proof → action.
  - **Step 3: Define Conversion Flow** — primary CTA (what action), secondary CTA (alternative), CTA repetition strategy (where CTAs appear), pricing strategy (if applicable).
  - **Step 4: Design Scroll Narrative** — the emotional/logical journey: what the user thinks/feels at each scroll checkpoint. Map: section → user state → what convinces them to keep scrolling.
  - **Step 5: Interactive Review** — ask user about section choices:
    - Pricing section: yes/no? How to display?
    - FAQ: yes/no?
    - Number of features to showcase
    - Testimonials/social proof approach
    - Any sections to add/remove?
  - **Step 6: Finalize** — incorporate feedback, produce final strategy.
- **Output**: Write to `.lander/05-strategy.md`
- **Output structure**:
```
## Brief
Section count: [N], primary CTA: [action],
conversion points: [N], scroll narrative: [1-sentence summary]

## Sections

### 1. Hero
- Purpose: [first impression, hook]
- Content: [headline, subheadline, CTA, visual element]
- CTA: [primary action]

### 2. Social Proof
- Purpose: [build trust]
- Content: [logos, testimonials, metrics]
...

### N. Footer
- Purpose: [navigation, legal, final CTA]
- Content: [links, copyright, social links]

## Conversion Flow
- Primary CTA: [action, text, placement]
- Secondary CTA: [action, text, placement]
- Repetition: [which sections repeat CTAs]
- Pricing: [strategy or "no pricing section"]

## Scroll Narrative
[Section-by-section emotional/logical journey]
| Section | User State | What Convinces |
|---------|-----------|----------------|
| Hero | Curious | Strong hook + clear value prop |
| Social Proof | Skeptical | Logos/numbers build credibility |
...
```
- **Guidelines**: Be opinionated about section order — the sequence matters for conversion. Every section must justify its existence. Keep section count reasonable (6-10 is typical). The scroll narrative is the backbone — if it doesn't flow, restructure.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/strategist.md && grep "Scroll Narrative" skills/lander/agents/strategist.md`
Expected: `# Strategist Agent` header, Scroll Narrative section reference

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/strategist.md
git commit -m "feat(lander): add Strategist agent — section planning and conversion flow design"
```

---

### Task 7: Create Designer Agent

**Files:**
- Create: `skills/lander/agents/designer.md`

The Designer creates the complete design system for the landing page, generates a visual moodboard, validates WCAG accessibility, and exports tokens in multiple formats. Model: sonnet.

- [ ] **Step 1: Write agents/designer.md**

Content requirements from spec + CEO review expansions:
- **Role**: Create a complete, implementation-ready design system for the landing page. Select from existing catalogs (ui-ux-pro-max) rather than inventing from scratch. Generate a visual moodboard for approval. Validate accessibility.
- **Inputs**: `.lander/01-brief.md` + `.lander/04-synthesis.md` + `.lander/05-strategy.md`
- **Process**:
  - **Step 1: Analyze Design Direction** — from brief (tone, brand) and synthesis (visual recommendations), determine the overall design direction.
  - **Step 2: ui-ux-pro-max Integration** — if the ui-ux-pro-max skill is available, use its catalog of 50+ styles, 161 color palettes, 57 font pairings, 161 product types. Select from catalog based on brief + reference analysis rather than inventing from scratch. If unavailable, derive from reference site analysis.
  - **Step 3: Define Color Palette** — primary, secondary, accent, backgrounds, text colors, borders, status colors. Must include exact hex values and CSS custom properties.
  - **Step 4: Define Typography** — font pair selection, type scale (H1-H6, body, small), weights, line-heights. Include both CSS and Tailwind equivalents.
  - **Step 5: Define Spacing & Layout** — base unit, section padding, gaps, max-width, grid system, responsive breakpoints.
  - **Step 6: Define Components** — buttons (primary, secondary, ghost), cards, inputs, badges, nav — with all states (hover, focus, active, disabled).
  - **Step 7: Define Effects** — shadows, gradients, border-radius scale, glassmorphism, blur.
  - **Step 8: Define Motion** — scroll animations, hover effects, transitions, micro-interactions.
  - **Step 9: WCAG Accessibility Checks** — for every text-on-background color combination, calculate the contrast ratio. Flag any that fail WCAG 2.1 AA (< 4.5:1 for body text, < 3:1 for large text). If failures exist, propose adjusted colors that pass while staying close to the original palette. Include a contrast ratio table in the output.
  - **Step 10: Generate Visual Moodboard** — generate a self-contained HTML file (`.lander/moodboard.html`) that visually renders: color swatches with hex values and names, font pairing samples (heading + body text rendered at actual sizes), spacing scale visualization (boxes showing base unit multiples), button and card component samples in all states, shadow and border-radius examples. This lets the user see the design system before approving.
  - **Step 11: Propose 2 Directions** — present 2 design directions based on references. Each with a name, mood board description, and key differentiators. User picks one. The moodboard HTML reflects the chosen direction.
  - **Step 12: Refine and Finalize** — refine chosen direction with user feedback. Regenerate moodboard if direction changes significantly.
- **Failure handling**:
  - NO_CATALOG: If ui-ux-pro-max is unavailable, generate design system from scratch based on reference site analysis and brief. Note in output that recommendations are derived from references, not catalog.
  - A11Y_FAIL: If any color combinations fail WCAG, propose adjusted alternatives and present both original and adjusted to user for approval.
- **Output**: Write to `.lander/06-design.md` + `.lander/moodboard.html`
- **Output structure** (06-design.md):
```
## Brief
Style: [style name], palette: [primary + accent colors],
fonts: [pair], base unit: [N]px, component count: [N],
WCAG status: [all pass / N failures adjusted]

## Color Palette
| Role | Hex | CSS Variable | Tailwind |
|------|-----|-------------|----------|
| Primary | #xxx | --color-primary | primary |
| Secondary | #xxx | --color-secondary | secondary |
...

## Accessibility Report
| Text Color | Background | Ratio | WCAG AA | Status |
|------------|-----------|-------|---------|--------|
| --text-body (#xxx) | --bg-page (#xxx) | 12.5:1 | ≥4.5:1 | ✅ Pass |
| --text-muted (#xxx) | --bg-card (#xxx) | 3.8:1 | ≥4.5:1 | ❌ Fail → adjusted to #xxx (4.6:1) |
...

## Typography
| Element | Font | Size | Weight | Line Height | CSS Variable |
|---------|------|------|--------|-------------|-------------|
| H1 | [font] | [size] | [weight] | [lh] | --text-h1 |
...
Font pair: [primary] + [secondary/mono]
Type scale ratio: [ratio]

## Spacing & Layout
- Base unit: [N]px
- Section padding: [values]
- Element gaps: [scale]
- Max width: [value]
- Grid: [columns, gap]
- Breakpoints: sm [px], md [px], lg [px], xl [px]

## Components

### Buttons
[Primary, secondary, ghost — all states with exact values]

### Cards
[Variants with exact values]

### Inputs
[Text, select, textarea — all states]

### Badges
[Variants]

### Navigation
[Desktop, mobile patterns]

## Effects
- Shadows: [scale from sm to xl with exact values]
- Gradients: [defined gradients]
- Border radius: [scale]
- Glassmorphism: [if applicable]

## Motion
- Scroll animations: [types, duration, easing]
- Hover effects: [transforms, transitions]
- Transitions: [default duration, easing]
- Micro-interactions: [specific interactive elements]

## CSS Custom Properties
[Complete :root block with all design tokens]

## Tailwind Config Extension
[tailwind.config.js extend block if applicable]

## Style Dictionary Tokens
[JSON format for cross-platform token export]
```json
{
  "color": {
    "primary": { "value": "#xxx", "type": "color" },
    "secondary": { "value": "#xxx", "type": "color" }
  },
  "font": {
    "heading": { "value": "Inter", "type": "fontFamily" },
    "body": { "value": "Inter", "type": "fontFamily" }
  },
  "spacing": {
    "base": { "value": "8", "type": "spacing" }
  }
}
```
```
- **Guidelines**: Be specific — "Inter 48px bold" not "large heading". Every value is implementation-ready. CSS custom properties are required. Tailwind config is optional but recommended. Propose 2 directions, not 1. Reference which patterns came from which reference site. Use ui-ux-pro-max catalog when available. The moodboard HTML must be self-contained (inline CSS, no external dependencies). All color pairings must pass WCAG AA.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/designer.md && grep "WCAG\|moodboard\|Style Dictionary" skills/lander/agents/designer.md | head -5`
Expected: `# Designer Agent` header, WCAG, moodboard, and Style Dictionary references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/designer.md
git commit -m "feat(lander): add Designer agent — design system, moodboard, WCAG checks, multi-format tokens"
```

---

### Task 8: Create Copywriter Agent

**Files:**
- Create: `skills/lander/agents/copywriter.md`

The Copywriter writes all text content for every section, with A/B tonal variants for the full page. Model: sonnet.

- [ ] **Step 1: Write agents/copywriter.md**

Content requirements from spec + CEO review expansions:
- **Role**: Write all text content for every landing page section. Produce 2 full-page copy variants with different tonal approaches. Align copy tone with the visual direction.
- **Inputs**: `.lander/01-brief.md` + `.lander/04-synthesis.md` + `.lander/05-strategy.md` + `.lander/06-design.md`
- **Process**:
  - **Step 1: Establish Tone** — from brief (tone) + design (visual mood), define two tonal directions for A/B variants (e.g., A=direct/confident, B=conversational/warm). Write a tone guide for each variant with do's and don'ts.
  - **Step 2: Write Headlines** — for each section from strategy: heading + subheading in BOTH variants. For the hero section: 2-3 headline options per variant.
  - **Step 3: Write Body Copy** — feature descriptions, how-it-works steps, testimonial placeholders, FAQ items (if strategy includes FAQ). Both variants.
  - **Step 4: Write CTAs** — button texts, form labels, conversion element copy. Primary CTA and secondary CTA per variant.
  - **Step 5: Write Meta Content** — page title, meta description, OG tags text. One version (tone-neutral).
  - **Step 6: Validate Section Coverage** — cross-check every section in `05-strategy.md` against the copy produced. If any section is missing copy, add it before proceeding. Flag in output if sections were added to fill gaps.
  - **Step 7: Interactive Review** — present both variants side-by-side for hero and key sections. User picks one variant per section or mixes. Adjust based on feedback.
  - **Step 8: Finalize** — incorporate feedback, mark chosen variant per section.
- **Failure handling**:
  - INCOMPLETE_COPY: Before presenting to user, validate that every section from strategy has matching copy in both variants. If sections are missing (e.g., strategy added a section the Copywriter didn't cover), write the missing copy before proceeding. Log in output which sections were gap-filled.
- **Output**: Write to `.lander/07-copy.md`
- **Output structure**:
```
## Brief
Tone: [variant A tone] / [variant B tone], sections covered: [N],
headline variants: [N], CTA count: [N], gaps filled: [N or "none"]

## Tone Guide

### Variant A — [Name] (e.g., "Direct & Confident")
#### Voice
[Personality, register, energy level]
#### Do's
[3-5 tone rules]
#### Don'ts
[3-5 anti-patterns]

### Variant B — [Name] (e.g., "Conversational & Warm")
#### Voice
[Personality, register, energy level]
#### Do's
[3-5 tone rules]
#### Don'ts
[3-5 anti-patterns]

### Tone Examples
| Context | ✅ Variant A | ✅ Variant B | ❌ Incorrect |
|---------|-------------|-------------|-------------|
| Hero headline | [example] | [example] | [example] |
| CTA button | [example] | [example] | [example] |

## Section Copy

### 1. Hero

#### Variant A
##### Headline Option 1
[headline]
##### Headline Option 2
[headline]
##### Subheadline
[subheadline]
##### CTA
[primary CTA text] | [secondary CTA text]

#### Variant B
##### Headline Option 1
[headline]
##### Headline Option 2
[headline]
##### Subheadline
[subheadline]
##### CTA
[primary CTA text] | [secondary CTA text]

### 2. Social Proof
#### Variant A
...
#### Variant B
...

### N. Footer
...

## CTAs Summary
| Location | Variant A Primary | Variant A Secondary | Variant B Primary | Variant B Secondary |
|----------|------------------|--------------------|--------------------|---------------------|
| Hero | [text] | [text] | [text] | [text] |
...

## User Selections
[After interactive review: which variant was chosen per section, or "full Variant A/B"]

## Meta Content
- Page title: [title]
- Meta description: [description]
- OG title: [title]
- OG description: [description]
```
- **Guidelines**: Every section from strategy must have matching copy in BOTH variants. Hero gets 2+ headline options per variant. CTAs are action-oriented ("Start building" not "Submit"). Tone must match the design mood. Placeholder content should be realistic, not "Lorem ipsum". Meta content is required. Cross-check section count against strategy before presenting.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/copywriter.md && grep "Variant A\|Variant B\|A/B" skills/lander/agents/copywriter.md | head -3`
Expected: `# Copywriter Agent` header, A/B variant references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/copywriter.md
git commit -m "feat(lander): add Copywriter agent — A/B copy variants, tone guide, section validation"
```

---

### Task 9: Create Compiler Agent

**Files:**
- Create: `skills/lander/agents/compiler.md`

The Compiler assembles all specs into a consistent package and validates cross-references. Model: sonnet.

- [ ] **Step 1: Write agents/compiler.md**

Content requirements from spec:
- **Role**: Assemble all spec files into a consistent, validated package ready for the `task` skill. Quality gate — catch contradictions and gaps.
- **Inputs**: `.lander/00-summary.md` + all `.lander/0{1-7}*.md` files
- **Process**:
  - **Step 1: Read Pipeline Summary** — `00-summary.md` for quick context.
  - **Step 2: Validate Input Completeness** — check that all expected files exist: `01-brief.md`, `02-references.md`, at least one `03-research-*.md`, `04-synthesis.md`, `05-strategy.md`, `06-design.md`, `07-copy.md`. If any are missing, report which files are absent and escalate to user with options: re-run the missing agent, or proceed without it.
  - **Step 3: Read All Spec Files** — load all existing files, Brief sections first for orientation, then full content.
  - **Step 4: Consistency Checks**:
    1. Every section in `05-strategy.md` has matching copy in `07-copy.md`
    2. Design tokens in `06-design.md` match the tone described in `01-brief.md`
    3. Color choices in `06-design.md` align with visual direction in `04-synthesis.md`
    4. CTA texts in `07-copy.md` match conversion strategy in `05-strategy.md`
    5. No orphaned references (sections mentioned but never defined)
    6. Section count matches across strategy, design, and copy files
    7. WCAG accessibility report in `06-design.md` has no unresolved failures
  - **Step 5: Flag Contradictions** — if contradictions found, flag them for the user with specifics (e.g., "Strategy defines 8 sections but Copy only covers 6"). User decides: re-run an agent or accept as-is.
  - **Step 6: Generate Final Spec** — `08-final-spec.md` with executive summary, file index, implementation notes.
- **Failure handling**:
  - MISSING_SPECS: If expected spec files are missing, report a clear list of what's absent and offer options: (1) re-run the missing agent, (2) proceed without it (with reduced spec quality noted). Never silently proceed with incomplete specs.
  - CONTRADICTION: Flag with specifics. Present to user with three options: (1) re-run the problematic agent, (2) accept as-is with the contradiction noted, (3) manually resolve.
- **Output**: Write to `.lander/08-final-spec.md`
- **Output structure**:
```
## Brief
Files validated: [N], contradictions: [N or "none"],
status: [ready / needs attention], tech recommendation: [stack]

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
| 06-design.md | Design system, tokens, WCAG | ✅ |
| 07-copy.md | All copy (A/B variants), tone guide | ✅ |

## Consistency Report
### ✅ Passed
[List of checks that passed]
### ❌ Issues
[List of contradictions/gaps with specifics, or "None"]

## Implementation Notes
- **Recommended stack**: [tech stack based on brief constraints]
- **Key challenges**: [2-3 implementation challenges]
- **Estimated complexity**: [low/medium/high]
- **Section count**: [N sections]
- **Responsive approach**: [strategy]
- **Design token formats**: CSS custom properties, Tailwind config, Style Dictionary JSON

## Next Step
Run `/task` with `.lander/08-final-spec.md` as input to begin implementation.
```
- **Guidelines**: Read `00-summary.md` first for quick context. Be thorough with consistency checks — missing copy for a section is a real problem. Contradictions are flagged, not silently resolved. The final spec is the handoff document — it must be complete and self-contained. Recommend a tech stack based on brief constraints.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/compiler.md && grep "Consistency\|MISSING_SPECS\|contradiction" skills/lander/agents/compiler.md | head -3`
Expected: `# Compiler Agent` header, consistency/missing/contradiction references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/compiler.md
git commit -m "feat(lander): add Compiler agent — spec validation with input completeness checks"
```

---

### Task 10: Create Prototyper Agent

**Files:**
- Create: `skills/lander/agents/prototyper.md`

The Prototyper generates a self-contained static HTML+CSS preview of the landing page using real design tokens and copy. Runs after the Compiler validates consistency. Model: sonnet.

- [ ] **Step 1: Write agents/prototyper.md**

Content requirements (CEO review expansion):
- **Role**: Generate a single self-contained HTML file that renders the landing page layout with real design tokens (colors, fonts, spacing), real copy from the chosen variant, and placeholder images. No JS framework — static HTML+CSS only. The preview lets stakeholders see the page before implementation begins.
- **Inputs**: `.lander/05-strategy.md` + `.lander/06-design.md` + `.lander/07-copy.md`
- **Process**:
  - **Step 1: Validate Inputs** — check that all three input files exist and have content. Check that `06-design.md` has CSS custom properties defined, `07-copy.md` has the user's chosen variant marked, and `05-strategy.md` has a section list. If any are incomplete, report the specific gap and escalate to user.
  - **Step 2: Extract Design Tokens** — parse CSS custom properties from `06-design.md` and build the `<style>` block. Include colors, typography, spacing, shadows, border-radius.
  - **Step 3: Build Section Structure** — for each section in `05-strategy.md`, create an HTML section with appropriate semantic tags (`<header>`, `<section>`, `<footer>`). Apply layout from the strategy (section order, content type).
  - **Step 4: Fill Copy** — insert the chosen copy variant from `07-copy.md` into each section. Use the user's selection (from `## User Selections` in the copy file). If no selection was made, default to Variant A.
  - **Step 5: Add Placeholder Visuals** — for hero images, feature icons, testimonial photos: use simple CSS shapes, gradients, or SVG placeholders. Do NOT use external image URLs or CDNs. Everything must be self-contained.
  - **Step 6: Add Responsive Basics** — include media queries for the breakpoints defined in the design system. At minimum: desktop and mobile layouts.
  - **Step 7: Validate Output** — check that the generated HTML is well-formed (matching tags, valid CSS). If validation fails, fix and retry once. If still broken, output what you have and flag the issues.
- **Failure handling**:
  - TOKEN_GAP: If design tokens are incomplete (e.g., no font defined, no colors), use sensible defaults and note in the output which tokens were substituted. The prototype should always render something.
  - BAD_HTML: If generated HTML has issues, attempt one self-correction pass. If still broken, output the best version with a note about known issues.
- **Output**: Write to `.lander/prototype.html`
- **Output notes**: Write a brief log to `.lander/09-prototype.md`:
```
## Brief
Sections rendered: [N], tokens applied: [N], copy variant: [A/B/mixed],
responsive: [yes/no], placeholder visuals: [N], known issues: [list or "none"]

## Prototype File
Path: .lander/prototype.html
Open in browser: `open .lander/prototype.html` (macOS) or `xdg-open .lander/prototype.html` (Linux)

## Sections Rendered
[List of sections with status]

## Token Application
[Which design tokens were used, which fell back to defaults]

## Known Issues
[Any rendering concerns, or "None"]
```
- **Guidelines**: The HTML file must be completely self-contained — inline CSS, inline SVG, no external dependencies, no CDN links, no JavaScript. It should render correctly when opened directly in a browser (`file://` protocol). Prioritize accurate layout and typography over pixel-perfect components. The prototype is a preview, not the implementation. Use the chosen copy variant, not both. Keep the file under 500 lines if possible.

- [ ] **Step 2: Verify file structure**

Run: `head -3 skills/lander/agents/prototyper.md && grep "self-contained\|prototype.html\|TOKEN_GAP" skills/lander/agents/prototyper.md | head -3`
Expected: `# Prototyper Agent` header, self-contained/prototype/token references

- [ ] **Step 3: Commit**

```bash
git add skills/lander/agents/prototyper.md
git commit -m "feat(lander): add Prototyper agent — static HTML preview from design tokens and copy"
```

---

### Task 11: Final Verification

**Files:**
- Verify: all `skills/lander/**/*.md`

- [ ] **Step 1: Verify all files exist**

Run: `find skills/lander -name "*.md" | sort`
Expected:
```
skills/lander/SKILL.md
skills/lander/agents/compiler.md
skills/lander/agents/copywriter.md
skills/lander/agents/designer.md
skills/lander/agents/interviewer.md
skills/lander/agents/prototyper.md
skills/lander/agents/researcher.md
skills/lander/agents/scout.md
skills/lander/agents/strategist.md
skills/lander/agents/synthesizer.md
```
Total: 10 files (1 SKILL.md + 9 agents)

- [ ] **Step 2: Verify agent reference consistency**

Run: `grep -h "^> \*\*Model" skills/lander/agents/*.md`
Expected output matching agent reference table:
```
> **Model**: sonnet     (compiler)
> **Model**: sonnet     (copywriter)
> **Model**: sonnet     (designer)
> **Model**: opus       (interviewer)
> **Model**: sonnet     (prototyper)
> **Model**: sonnet     (researcher)
> **Model**: sonnet     (scout)
> **Model**: opus       (strategist)
> **Model**: opus       (synthesizer)
```

- [ ] **Step 3: Verify SKILL.md references all agent files**

Run: `grep "agents/" skills/lander/SKILL.md | grep -o "agents/[a-z]*.md" | sort`
Expected: all 9 agent files referenced

- [ ] **Step 4: Verify output file naming**

Run: `grep -h "Write to\|Output.*:" skills/lander/agents/*.md | grep ".lander/"`
Expected: each agent writes to its designated `.lander/` file

- [ ] **Step 5: Verify CEO review expansions are present**

Run: `grep -l "WCAG\|moodboard\|Variant A\|Variant B\|Style Dictionary\|prototype.html\|TOKEN_GAP" skills/lander/agents/*.md | sort`
Expected:
```
skills/lander/agents/copywriter.md     (Variant A/B)
skills/lander/agents/designer.md       (WCAG, moodboard, Style Dictionary)
skills/lander/agents/prototyper.md     (prototype.html, TOKEN_GAP)
```

- [ ] **Step 6: Verify failure handling is present in all agents**

Run: `grep -l "Failure handling\|THIN_BRIEF\|NO_VALID_REFS\|INSUFFICIENT_DATA\|INCOMPLETE_COPY\|MISSING_SPECS\|TOKEN_GAP" skills/lander/agents/*.md | sort`
Expected: interviewer, scout, synthesizer, copywriter, compiler, prototyper all have failure handling

- [ ] **Step 7: Final commit (if any fixes were needed)**

```bash
git add skills/lander/
git commit -m "fix(lander): consistency fixes from final verification"
```
