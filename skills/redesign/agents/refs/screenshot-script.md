# Screenshot Script Template

Generate this script adapted to the specific project. Replace placeholders with detected values.

## Basic Template

```javascript
// .redesign/playwright-screenshot.js
const { chromium } = require('playwright');

const CONFIG = {
  url: '{{URL}}',              // e.g., 'http://localhost:3000'
  viewport: {
    width: {{WIDTH}},          // from design spec
    height: {{HEIGHT}},        // from design spec
  },
  outputPath: '{{OUTPUT}}',   // e.g., '.redesign/screenshots/current-1.png'
  waitFor: '{{SELECTOR}}',    // optional: wait for specific element
  fullPage: {{FULL_PAGE}},    // true for full page, false for viewport only
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: CONFIG.viewport,
    deviceScaleFactor: 2, // retina for better comparison
  });
  const page = await context.newPage();

  await page.goto(CONFIG.url, { waitUntil: 'networkidle' });

  // Wait for content to render
  if (CONFIG.waitFor) {
    await page.waitForSelector(CONFIG.waitFor, { timeout: 10000 });
  }

  // Additional wait for fonts and images
  await page.waitForTimeout(1000);

  // Hide scrollbars for clean screenshot
  await page.addStyleTag({
    content: `
      *::-webkit-scrollbar { display: none !important; }
      * { scrollbar-width: none !important; }
    `
  });

  await page.screenshot({
    path: CONFIG.outputPath,
    fullPage: CONFIG.fullPage,
  });

  await browser.close();
  console.log(`Screenshot saved to ${CONFIG.outputPath}`);
})();
```

## Element-Level Screenshot

When redesigning a specific component, screenshot only that element:

```javascript
const element = await page.locator('{{SELECTOR}}');
await element.screenshot({
  path: CONFIG.outputPath,
});
```

## Running

```bash
node .redesign/playwright-screenshot.js
```

## Common URL Detection

Check `package.json` scripts for:
- `"dev"` with Vite -> `http://localhost:5173`
- `"dev"` with Next.js -> `http://localhost:3000`
- `"start"` with CRA -> `http://localhost:3000`
- Custom port -> check for `--port` or `PORT` env
