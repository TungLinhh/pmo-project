// Render Mermaid → PNG using Playwright (Chrome đã cài qua playwright)
// Usage: node render_mermaid.mjs <input.mmd> <output.png>
import { chromium } from '/home/vutun/pmo_project/node_modules/playwright/index.mjs';
import fs from 'node:fs';

const [, , input, output] = process.argv;
if (!input || !output) {
  console.error('Usage: node render_mermaid.mjs <input.mmd> <output.png>');
  process.exit(1);
}

const code = fs.readFileSync(input, 'utf8');

const browser = await chromium.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
const ctx = await browser.newContext({ viewport: { width: 2400, height: 1800 }, deviceScaleFactor: 1 });
const page = await ctx.newPage();

const html = `<!DOCTYPE html>
<html><head><meta charset="utf-8">
<style>
  * { box-sizing: border-box; }
  body { margin: 0; padding: 32px; background: white; font-family: system-ui, -apple-system, sans-serif; }
  #container { display: inline-block; }
  #container svg { max-width: none !important; }
</style>
</head><body>
<pre id="code" style="display:none">${code.replace(/</g, '&lt;')}</pre>
<div id="container"></div>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  mermaid.initialize({
    startOnLoad: false,
    theme: 'default',
    securityLevel: 'loose',
    fontFamily: 'system-ui',
    flowchart: { htmlLabels: true, useMaxWidth: false },
    er: { useMaxWidth: false },
    sequence: { useMaxWidth: false },
    class: { useMaxWidth: false },
    state: { useMaxWidth: false }
  });
  try {
    const { svg } = await mermaid.render('m1', document.getElementById('code').textContent);
    document.getElementById('container').innerHTML = svg;
    document.title = 'ok';
  } catch (e) {
    document.title = 'err: ' + e.message;
  }
</script>
</body></html>`;

await page.setContent(html, { waitUntil: 'domcontentloaded' });
await page.waitForFunction(() => document.title === 'ok' || document.title.startsWith('err:'), { timeout: 30000 });
if (await page.title() === 'err:') {
  console.error('Mermaid error:', await page.title());
  process.exit(2);
}
await page.waitForTimeout(500);

const box = await page.$eval('#container svg', el => {
  const r = el.getBoundingClientRect();
  return { x: r.x, y: r.y, width: r.width, height: r.height };
});
console.log(`SVG bbox: ${box.width}x${box.height}`);

await page.screenshot({
  path: output,
  clip: { x: box.x, y: box.y, width: box.width, height: box.height },
  omitBackground: false,
});
console.log(`Rendered ${input} → ${output}`);

await browser.close();
