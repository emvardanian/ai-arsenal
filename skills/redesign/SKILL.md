---
name: redesign
description: Pixel-perfect UI redesign with automated visual comparison loop. Use when the user wants to match an existing implementation to a design mockup/screenshot/Figma. Triggers on "redesign", "match design", "pixel-perfect", "make it look like the design", or when the user provides a design and wants the UI to match it exactly. This skill does NOT build new features — it makes existing UI match a target design.
---

# Redesign — Visual Comparison Loop

You orchestrate an iterative redesign pipeline that keeps refining UI code until it matches the target design. You don't do the work — you delegate to specialized agents and manage the comparison loop.

## Plugin & Tool Dependencies

This skill leverages existing plugins and MCP servers. Check availability at start:

| Dependency | Type | Purpose | Required? |
|------------|------|---------|-----------|
| **Figma MCP** (`figma`) | MCP Server | Extract exact design data from Figma | No (fallback: screenshot analysis) |
| **`frontend-design`** plugin | Plugin/Skill | High-quality UI implementation guidelines | No (enhances quality) |
| **`agent-teams`** plugin | Plugin | Parallel agent execution | No (fallback: sequential) |
| **Playwright** | npm package | Automated screenshots | No (fallback: manual screenshots) |

## Pipeline Overview

```
 1. Extractor     -> design analysis (Figma MCP or screenshot)          [approval]
 2. Scout         -> scan codebase, find files to change                [auto]
 3. Implementer   -> apply design (uses frontend-design guidelines)     [approval]
 ┌──────────────────────────────────────────────────────────────────┐
 │ 4. Screenshotter -> take automated screenshot via Playwright       │
 │ 5. Comparator    -> compare screenshot vs design, list diffs       │
 │ 6. Fixer         -> fix specific diffs                             │
 │    └─> back to Screenshotter (max 5 iterations)                    │
 └──────────────────────────────────────────────────────────────────┘
 7. Final         -> present side-by-side result for approval          [approval]
```

## Agent Reference

| # | Agent | File | Model | Reads | Writes |
|---|-------|------|-------|-------|--------|
| 1 | Extractor | `agents/extractor.md` | **opus** | Figma data OR design screenshot | `01-design-spec.md` |
| 2 | Scout | `agents/scout.md` | sonnet | `01-design-spec.md` | `02-scout.md` |
| 3 | Implementer | `agents/implementer.md` | sonnet | `01-design-spec.md`, `02-scout.md` | `03-impl.md` + code |
| 4 | Screenshotter | (inline) | — | running app | screenshot file |
| 5 | Comparator | `agents/comparator.md` | **opus** | design screenshot, current screenshot, `01-design-spec.md` | `04-diff-{N}.md` |
| 6 | Fixer | `agents/fixer.md` | sonnet | `04-diff-{N}.md`, `01-design-spec.md` | `05-fix-{N}.md` + code |

**Model strategy:** Opus for visual analysis (extraction, comparison — needs best vision). Sonnet for code execution.

**Rule**: Never pre-read all agent files. Read an agent `.md` only when you're about to execute it.

## Progress Tracker

Every response starts with:

```
[✅ Extract] -> [✅ Scout] -> [✅ Implement] -> [▶ Compare 2/5] -> [ Final]
```

Icons: `✅` done · `▶` active · ` ` pending · `🔄` re-run

## Workspace

```
.redesign/
├── 00-summary.md              <- updated after each stage
├── 01-design-spec.md          <- design spec (from Figma or screenshot)
├── 02-scout.md                <- codebase scan results
├── 03-impl.md                 <- initial implementation log
├── 04-diff-{N}.md             <- comparison diff (per iteration)
├── 05-fix-{N}.md              <- fix log (per iteration)
├── screenshots/
│   ├── design.png             <- target design image (from Figma export or user)
│   └── current-{N}.png        <- screenshot per iteration
└── playwright-screenshot.js   <- auto-screenshot script
```

**First step**: `mkdir -p .redesign/screenshots`

## Design Source: Figma MCP (Preferred)

When the user provides a Figma URL:

1. **Parse the URL** to extract file key and node IDs
2. Use Figma MCP tools to fetch design data:
   - `get_file` — get the full file structure
   - `get_node` — get specific component/frame data with layout, styles, colors
   - `download_figma_images` — export the design as PNG for visual comparison
3. Figma MCP provides **exact values** — no guessing colors or spacing:
   - Exact hex colors with opacity
   - Exact font family, size, weight, line-height
   - Exact padding, margins, gaps
   - Layout mode (auto-layout = flexbox, constraints = absolute positioning)
   - Border radius, shadows, effects

**Figma URL formats:**
- `https://www.figma.com/design/{fileKey}/{fileName}?node-id={nodeId}`
- `https://www.figma.com/file/{fileKey}/{fileName}?node-id={nodeId}`

**Always export the design as PNG** via `download_figma_images` and save to `.redesign/screenshots/design.png` — the Comparator needs it for visual comparison.

### Fallback: Screenshot Analysis

When Figma URL is not available (user provides a screenshot):
- Extractor analyzes the screenshot using vision (opus model)
- Less precise but still functional
- Values will be approximations — note this in the design spec

## Implementation: frontend-design Integration

The Implementer agent **must** apply `frontend-design` plugin guidelines when writing UI code:

1. **Read the `frontend-design` SKILL.md** before implementing — it contains critical quality guidelines
2. Apply its principles for:
   - Typography choices (distinctive, not generic)
   - Color application (CSS variables for consistency)
   - Spatial composition
   - Visual effects and micro-interactions
3. **But**: design spec values override frontend-design defaults. The plugin provides *how* to implement well; the design spec provides *what* to implement.

In other words: use frontend-design for **quality of execution**, design spec for **accuracy to target**.

## Screenshot Automation

### Setup (runs once at start)

Check if the project has Playwright installed. If not, install it temporarily:

```bash
# Check for existing Playwright
ls node_modules/playwright 2>/dev/null || ls node_modules/@playwright 2>/dev/null

# If missing, install
npm install --save-dev playwright 2>/dev/null || npx playwright install chromium
```

### Screenshot Script

Generate `.redesign/playwright-screenshot.js` tailored to the project. See `agents/refs/screenshot-script.md` for template.

The script must:
1. Launch chromium headless
2. Navigate to the correct URL (detect from project)
3. Wait for network idle + fonts loaded
4. Set viewport to match design dimensions
5. Take full-page or element-level screenshot
6. Save to `.redesign/screenshots/current-{N}.png`

**Important**: Before taking screenshots, verify the dev server is running. If not, start it in background and wait for it.

### Fallback

If Playwright setup fails:
1. Tell the user: "Auto-screenshot failed. Please provide a screenshot of the current state."
2. Continue the loop with manual screenshots
3. Never block the pipeline on automation failure

## Comparison Loop

The core mechanism. After initial implementation:

```
Iteration 1: Screenshot -> Compare -> list diffs -> Fix diffs
Iteration 2: Screenshot -> Compare -> fewer diffs -> Fix remaining
...
Iteration N: Screenshot -> Compare -> zero diffs -> DONE
```

### Exit Conditions

1. **Zero visual diffs** — Comparator reports no meaningful differences -> proceed to Final
2. **Max 5 iterations** — Stop, present current state, ask user for direction
3. **Diminishing returns** — Same diffs persist after 2 fix attempts -> escalate to user
4. **User approval** — User says "good enough" at any point

### Diff Tracking

Maintain a running diff count in `00-summary.md`:

```
Iteration 1: 12 diffs (spacing: 4, colors: 3, typography: 2, layout: 2, sizing: 1)
Iteration 2: 5 diffs (spacing: 2, colors: 1, typography: 1, sizing: 1)
Iteration 3: 1 diff (spacing: 1)
Iteration 4: 0 diffs -> DONE
```

If diff count stops decreasing for 2 consecutive iterations -> escalate.

## Execution Strategy

### With agent-teams (preferred — parallel where possible)

**Scout + Screenshot setup** can run in parallel (independent tasks):

```
[Extractor completes]
  ├── Scout (scan codebase)           ← parallel
  └── Screenshot setup (Playwright)   ← parallel
[Both complete] -> Implementer
```

**Multiple component areas** can be fixed in parallel if they don't share files:

```
/team-spawn custom --name redesign-fixers --members 2
  ├── fixer-1: fix layout + spacing diffs (owns layout files)
  └── fixer-2: fix color + typography diffs (owns style/token files)
```

Use this only when there are >6 diffs spanning clearly separate files. Otherwise sequential is simpler.

### Without agent-teams (sequential fallback)

Run each agent inline, one by one. Use `.redesign/` as shared memory.

## Flow Control

### Before Starting

Ask the user:
1. **Design source** — Figma URL (preferred) or screenshot path (required)
2. **Target scope** — full page, specific component, or specific section?
3. **Dev server** — how to start it? (auto-detect from `package.json` scripts)
4. **URL to screenshot** — which page/route? (default: `/`)
5. **Viewport** — desktop only, or also mobile? (default: match design dimensions)

If answers are obvious from context, skip asking.

### Dev Server Management

1. Detect start command from `package.json` (`dev`, `start`, `serve`)
2. Start in background before first screenshot
3. Wait for server to be ready (poll with curl)
4. Keep running throughout the loop
5. Don't kill it at the end — user may want to inspect

## Context Management

1. **File system as memory** — agents write to `.redesign/`, downstream reads from files
2. **Design spec is king** — `01-design-spec.md` is the source of truth, referenced by all agents
3. **Figma data = exact values** — when from Figma MCP, values are authoritative, not approximations
4. **Diffs are specific** — every diff has a category, component, expected value, actual value
5. **Budget** — Fixer reads only the diffs and relevant source files, not the entire codebase
6. **Screenshots persist** — each iteration's screenshot is kept for comparison

## Starting the Pipeline

1. `mkdir -p .redesign/screenshots`
2. Detect design source:
   - **Figma URL?** -> Use Figma MCP to fetch data + export PNG to `.redesign/screenshots/design.png`
   - **Screenshot?** -> Copy to `.redesign/screenshots/design.png`
3. Read `agents/extractor.md`
4. Execute Extractor -> present -> wait for approval
5. Update `00-summary.md`
6. Continue to Scout, then Implementer, then enter comparison loop

## Resuming

1. Check `.redesign/` for existing artifacts
2. Read `00-summary.md` for context
3. Resume from next incomplete stage or next comparison iteration

## Cleaning Up

After user approves final result: `rm -rf .redesign/` — don't clean up automatically.
