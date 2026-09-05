// Browser test: load page qua tunnel, check console errors
import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage();
const errors = [];
const consoleMsgs = [];
page.on('console', msg => consoleMsgs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', e => errors.push('PAGE ERROR: ' + e.message));
page.on('requestfailed', r => errors.push('REQ FAIL: ' + r.url() + ' - ' + r.failure()?.errorText));

try {
  await page.goto('https://firm-writings-ids-basename.trycloudflare.com/', { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(5000);
  const html = await page.content();
  console.log('=== URL:', page.url());
  console.log('=== Title:', await page.title());
  console.log('=== Body length:', html.length);
  console.log('=== Has #root?', html.includes('id="root"'));
  console.log('=== Has React content?', html.includes('ControlCenter') || html.includes('Dashboard'));

  // Try login
  await page.fill('input[type="email"], input[name="email"]', 'admin@hbg.com');
  await page.fill('input[type="password"]', 'admin123');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(3000);
  console.log('=== After login URL:', page.url());
  const html2 = await page.content();
  console.log('=== After login body length:', html2.length);
  console.log('=== Has #root content?', html2.length > 1000);

  await page.screenshot({ path: '/tmp/pmo_screen.png' });
  console.log('=== Screenshot saved /tmp/pmo_screen.png');
} catch (e) {
  console.log('TEST FAILED:', e.message);
}

console.log('\n=== CONSOLE ===');
consoleMsgs.forEach(m => console.log(m));
console.log('\n=== ERRORS ===');
errors.forEach(m => console.log(m));

await browser.close();
