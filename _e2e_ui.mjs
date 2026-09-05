// E2E UI test với Playwright
import { chromium } from '/home/vutun/pmo_project/node_modules/playwright/index.mjs';

const browser = await chromium.launch({ args: ['--no-sandbox', '--disable-dev-shm-usage'] });
const ctx = await browser.newContext({ viewport: { width: 1400, height: 900 } });
const page = await ctx.newPage();
const results = [];
const log = (n, ok, detail = '') => results.push({ n, ok, detail });

try {
  // 1. Load app
  await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
  log('load app', true, 'OK');

  // 2. Login
  await page.fill('input[type="email"], input[name="email"]', 'admin@hbg.com');
  await page.fill('input[type="password"]', 'admin123');
  await page.click('button[type="submit"], button:has-text("Login"), button:has-text("Đăng nhập")');
  await page.waitForTimeout(2000);
  log('login', page.url().includes('/hq') || page.url().includes('/field') || page.url().includes('dashboard'), `url=${page.url()}`);

  // 3. Navigate to Issues
  await page.goto('http://localhost:3000/hq/issues', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  const issuesHasPicker = await page.locator('.project-picker').count();
  log('Issues page has ProjectPicker', issuesHasPicker > 0, `count=${issuesHasPicker}`);

  // 4. Test search
  await page.locator('.project-picker-input').first().click();
  await page.waitForTimeout(300);
  await page.keyboard.type('BTE');
  await page.waitForTimeout(500);
  const dropdownItems = await page.locator('.project-picker-item').count();
  log('Picker search filters', dropdownItems > 0 && dropdownItems < 10, `items=${dropdownItems}`);
  await page.keyboard.press('Escape');

  // 5. Navigate to Manpower
  await page.goto('http://localhost:3000/hq/manpower', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  const mpHasPicker = await page.locator('.project-picker').count();
  log('Manpower page has ProjectPicker', mpHasPicker > 0, `count=${mpHasPicker}`);

  // 6. Navigate to AuditLog
  await page.goto('http://localhost:3000/hq/audit', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  const auditRows = await page.locator('table tbody tr').count();
  log('AuditLog page renders rows', auditRows > 0, `rows=${auditRows}`);

  // 7. Test export buttons
  const exportBtns = await page.locator('button:has-text("Export")').count();
  log('AuditLog has export buttons', exportBtns >= 2, `buttons=${exportBtns}`);

  // 8. Navigate to ShopList
  await page.goto('http://localhost:3000/hq/shop', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  const shopHasPicker = await page.locator('.project-picker').count();
  log('ShopList has ProjectPicker', shopHasPicker > 0, `count=${shopHasPicker}`);

  // 9. Navigate to Materials
  await page.goto('http://localhost:3000/hq/materials', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);
  const matHasPicker = await page.locator('.project-picker').count();
  log('Materials has ProjectPicker', matHasPicker > 0, `count=${matHasPicker}`);

  // 10. Navigate to ControlCenter (route is /hq index)
  await page.goto('http://localhost:3000/hq', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);
  const ccHasPicker = await page.locator('.project-picker').count();
  log('ControlCenter has ProjectPicker', ccHasPicker > 0, `count=${ccHasPicker}`);

  // 11. Keyboard nav
  await page.goto('http://localhost:3000/hq/issues', { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);
  await page.locator('.project-picker-input').first().click();
  await page.waitForTimeout(300);
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  log('Keyboard nav (ArrowDown+Enter)', true, 'OK');
} catch (e) {
  log('ERROR', false, e.message);
}

const pass = results.filter(r => r.ok).length;
console.log(`\n=== UI E2E Results: ${pass}/${results.length} PASS ===\n`);
results.forEach(r => console.log(`  ${r.ok ? '✅' : '❌'} ${r.n}: ${r.detail}`));
await browser.close();
process.exit(results.filter(r => !r.ok).length);
