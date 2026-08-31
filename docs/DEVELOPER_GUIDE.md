# PMO MVP - Developer Guide

> Hướng dẫn cho developer mới join project: setup, workflow, code conventions, common tasks.

**Phiên bản:** 2026-08-31

---

## 🚀 Setup môi trường dev

### Yêu cầu
- Node.js 20+ (LTS)
- npm 10+ (hoặc pnpm/yarn)
- Git
- Editor: VSCode (khuyến nghị) với extensions: ESLint, Prettier, GitLens
- SQLite browser (DB Browser for SQLite)

### Bước 1: Clone + install
```bash
git clone https://github.com/your-org/pmo-project.git
cd pmo-project

# Install backend deps
cd backend
npm install

# Install frontend deps
cd ../frontend
npm install

cd ..
```

### Bước 2: Seed database
```bash
cd backend
node scripts/seed-test-master-business.mjs    # Initial demo data
node scripts/seed-demo-data-enrich.mjs         # Enrich vòng 7+
```

### Bước 3: Start dev servers
```bash
# Terminal 1: Backend (port 3000)
cd backend
npm start
# hoặc: node src/index.js

# Terminal 2: Frontend (port 5173) - Vite dev với HMR
cd frontend
npm run dev
```

Mở http://localhost:5173 → login `admin@hbg.com` / `admin123`

### Bước 4: Verify
```bash
curl http://localhost:3000/api/health
# {"status":"ok","timestamp":"...","authenticated":false}
```

---

## 🏗 Project structure

```
pmo-project/
├── backend/           # Express API
│   ├── src/
│   │   ├── index.js   # All routes (60+)
│   │   ├── db/        # SQLite + PG
│   │   ├── lib/       # auth, permissions, excel, zone_matcher
│   │   └── services/  # ingest/ (Excel → DB), export/
│   ├── scripts/       # seed, test, generate
│   └── data/          # pmo.db, uploads/
├── frontend/          # React 19 + Vite
│   ├── src/
│   │   ├── App.jsx    # Router + Providers
│   │   ├── api/       # API client (one object per domain)
│   │   ├── components/  # Shared UI
│   │   ├── hq/        # 20 HQ screens
│   │   ├── field/     # 9 Field screens
│   │   ├── governance/  # 4 Governance screens
│   │   ├── styles/    # CSS
│   │   └── icons.jsx  # ~30 SVG icons
│   └── dist/          # Production build
├── docs/              # All documentation
│   ├── CODEBASE.md       # File/function reference
│   ├── ARCHITECTURE.md   # System design
│   ├── OPERATIONS.md     # Runbook
│   ├── SETUP_FOR_CLIENT.md  # Deploy guide
│   ├── USER_GUIDE.md     # End-user docs
│   └── DEVELOPER_GUIDE.md   # This file
├── scripts/           # Playwright E2E tests
├── reference_sheets/  # Sample Excel files
└── CHECKLIST.md       # Per-vòng progress log
```

---

## 📝 Code conventions

### Backend (Node.js / Express)

**Style:**
- ESM modules (`import`/`export`)
- 2-space indent
- Single quotes
- Semicolons
- Use prepared statements: `db.prepare(...).get/all/run`

**Naming:**
- Files: `kebab-case.js`
- Functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- DB columns: `snake_case`
- API routes: `/api/kebab-case/`

**Route pattern:**
```js
app.get('/api/projects/:id/construction-schedule',
  requireAuth,
  requirePerm('construction', 'read'),
  async (req, res) => {
    try {
      const db = getDb();
      const items = db.prepare(`
        SELECT * FROM construction_schedule_items
        WHERE project_id = ?
      `).all(req.params.id);
      res.json(items);
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: e.message });
    }
  }
);
```

**Audit:**
```js
// Every write should call audit()
audit(req.user.id, 'UPDATE', 'kpi_target', { id, before, after });
```

### Frontend (React / Vite)

**Style:**
- JSX (no TypeScript)
- Functional components only (no class)
- Hooks: `useState`, `useEffect`, custom hooks in `components/`
- 2-space indent, single quotes, semicolons

**Naming:**
- Files: `PascalCase.jsx` for components, `camelCase.js` for utilities
- Components: `PascalCase`
- Functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

**Component pattern:**
```jsx
import { useState, useEffect } from 'react';
import { shop } from '../api';

export default function ShopList() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState({ status: '', zone: '' });

  useEffect(() => {
    setLoading(true);
    shop.list(filter).then(setData).finally(() => setLoading(false));
  }, [filter]);

  return (
    <div>
      {/* UI */}
    </div>
  );
}
```

**API usage:**
```js
// ALWAYS use the API client, not raw fetch
import { shop, materials, toast } from '../api';

async function approveShop(id) {
  const ok = await confirm({ title: 'Duyệt shop drawing?' });
  if (!ok) return;

  try {
    await shop.transition(id, { action: 'APPROVE' });
    toast.success('Đã duyệt');
    // refetch
  } catch (e) {
    toast.error('Lỗi: ' + e.message);
  }
}
```

**Action feedback rule (CRITICAL):**
- Mọi button (Submit, Approve, Reject, Delete, Export, Upload) PHẢI show toast
- Destructive actions (Delete, Reject) PHẢI có confirm modal trước

---

## 🧪 Testing

### Backend tests
```bash
cd backend

# Permission matrix test (130 tests)
node scripts/test-role-permissions.mjs

# Admin full access
node scripts/test-admin-full-access.mjs

# Upload pipeline E2E
node scripts/upload-test-pipeline.mjs
```

### Frontend E2E (Playwright)
```bash
# Install Playwright (one-time)
npx playwright install chromium

# Run tests
node scripts/ui-verify-v7-mobile.mjs          # Mobile responsive
node scripts/ui-verify-v7-dashboard-approval.mjs  # Dashboard + Approval
node scripts/ui-verify-tooltip.mjs            # Tooltip
```

### Manual test checklist (per feature)
- [ ] Login với 6 roles khác nhau → menu items khác nhau
- [ ] Mobile (375×812) - sidebar ẩn, hamburger mở drawer
- [ ] Dark mode - text đủ tương phản
- [ ] Upload file - progress feedback, success toast
- [ ] Approval - confirm modal, inline expand
- [ ] Filter - clear button hoạt động

---

## 🛠 Common dev tasks

### Add a new API endpoint

1. Open `backend/src/index.js`
2. Find similar endpoint to copy pattern
3. Add new route:
```js
app.get('/api/projects/:id/my-new-thing',
  requireAuth,
  requirePerm('mymodule', 'read'),
  (req, res) => {
    const db = getDb();
    const items = db.prepare('SELECT * FROM my_table WHERE project_id = ?').all(req.params.id);
    res.json(items);
  }
);
```
4. If new module, add to `permissions.js` matrix
5. Test: `curl http://localhost:3000/api/projects/1/my-new-thing -H "Authorization: Bearer ..."`

### Add a new screen

1. Create `frontend/src/hq/MyNewScreen.jsx`
2. Add route in `App.jsx`:
```jsx
<Route path="my-new" element={<MyNewScreen />} />
```
3. Add menu item in `HqShell.jsx` (with permission check)
4. Use API client from `frontend/src/api/index.js`
5. If new domain, add to `api/index.js`:
```js
export const myDomain = {
  list: (params) => req('GET', '/api/my-domain', null, params),
  create: (data) => req('POST', '/api/my-domain', data),
};
```

### Add a new ingestor

1. Create `backend/src/services/ingest/my_type.js`:
```js
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt } from '../../lib/excel.js';

export async function ingestMyType(filePath, projectId, zoneCode) {
  const db = getDb();
  const report = { ok: 0, errors: 0, items: [] };
  // ... read sheets, insert rows
  return report;
}
```
2. Register in `services/ingest/index.js`:
```js
case 'my_type': return await ingestMyType(filePath, opts.projectId, opts.zoneCode);
```
3. Add to `detectDocType` in `lib/excel.js`

### Add a new permission

1. Edit `backend/src/lib/permissions.js`:
```js
const PERMISSION_MATRIX = {
  admin: { my_module: { read: true, write: true, approve: true } },
  pm:    { my_module: { read: true, write: true, approve: false } },
  // ... for each role
};
```
2. Use in route: `requirePerm('my_module', 'read')`

### Add a new icon

1. Edit `frontend/src/icons.jsx`:
```jsx
export const ICON = {
  // ... existing
  myIcon: <svg viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2" fill="none">
    <path d="..." />
  </svg>,
};
```
2. Use: `<span className="icon">{ICON.myIcon}</span>`

### Add a new CSS var / dark mode

1. Edit `frontend/src/styles/global.css`:
```css
:root {
  --c-my-thing: #abc123;
  --c-my-thing-2: #def456;
}
body.theme-dark {
  --c-my-thing: #789012;  /* dark variant */
}
```
2. Use in component: `style={{ color: 'var(--c-my-thing)' }}`

---

## 🐛 Debugging tips

### Backend
```js
// Add console.log
console.log('DEBUG: variable =', variable);

// Better: use pino logger
import pino from 'pino';
const log = pino();
log.info({ projectId, count }, 'Fetching items');

// Inspect DB
sqlite3 ~/pmo-data/pmo.db
> .schema my_table
> SELECT * FROM my_table LIMIT 5;
> .quit
```

### Frontend
```jsx
// Add console.log in component
useEffect(() => {
  console.log('Data:', data);
}, [data]);

// Use React DevTools (browser extension)
// Or vite HMR will show errors in terminal

// Network tab: inspect fetch requests
//   - Headers: check Authorization
//   - Response: check JSON
//   - Status: 200 OK, 401 unauth, 403 forbidden
```

### Common errors

| Error | Cause | Fix |
|---|---|---|
| 401 Unauthorized | Token missing/expired | Re-login |
| 403 Forbidden | Missing permission | Add to matrix in `permissions.js` |
| 404 Not Found | Wrong route | Check `index.js` |
| 429 Too Many Requests | Rate limit | Wait 1 min |
| 500 Internal Server Error | Code bug | Check `docker logs pmo-app` |
| `Cannot find module 'xlsx'` | Missing dep | `npm install` in backend |
| Pie chart not rendering | No data | Check data, check filter |
| Sidebar overlaps content | CSS issue | Check `grid-template-columns` in `hq.css` |
| Mobile hamburger missing | Old code | Check `HqShell.jsx` for `<=` 768px logic |

---

## 🚀 Git workflow

### Branch strategy
- `main` - production-ready
- `feature/*` - new features
- `fix/*` - bug fixes
- `docs/*` - documentation

### Commit message convention
```
Vòng N: <short description>

- <bullet 1>
- <bullet 2>
- <bullet 3>

Test results:
- <X>/<Y> PASS
```

Example:
```
Vòng 7: mobile nav + permission matrix + tooltip + dark mode

- Add hamburger button + drawer overlay <768px
- Add 6 role × 14 module × 3 action permission matrix
- Fix tooltip offset (18px instead of 12px)
- Add dark mode for 30+ selectors

Test: 130/130 permission tests PASS
```

### Pull request checklist
- [ ] Code follows conventions
- [ ] Tests pass (`npm test` in both frontend and backend)
- [ ] No new console errors
- [ ] Manual test in Chrome + mobile viewport
- [ ] Updated docs (if API changed)
- [ ] Updated CHECKLIST.md (add vòng N section)
- [ ] Demoed to PM/stakeholder (if user-facing)

---

## 📊 Performance tips

### Frontend
- Use `React.memo` for components that re-render often
- Lazy load: `const Heavy = lazy(() => import('./Heavy'))`
- Avoid inline functions in render (use `useCallback`)
- Use `useMemo` for expensive calculations
- Image: `<img loading="lazy" />` for off-screen

### Backend
- Always use `db.prepare(...).get/all/run` (prepared statements)
- Add indexes: `CREATE INDEX IF NOT EXISTS idx_X ON table(col)`
- For SQLite: `PRAGMA cache_size = -20000` (20MB)
- For PG: connection pooling, prepared statement cache
- Avoid N+1: use JOIN or subquery
- For exports: stream XLSX instead of loading all in memory

### Bundle size
- Current: 372KB JS / 103KB gzip
- Tree-shaking: ensure no `import * as`
- Check: `cd frontend && npx vite-bundle-visualizer`

---

## 📚 Reference docs (in this repo)

- [CODEBASE.md](CODEBASE.md) - all files/functions
- [ARCHITECTURE.md](ARCHITECTURE.md) - system design
- [SETUP_FOR_CLIENT.md](SETUP_FOR_CLIENT.md) - deploy guide
- [OPERATIONS.md](OPERATIONS.md) - runbook
- [USER_GUIDE.md](USER_GUIDE.md) - end-user docs
- [CHECKLIST.md](../CHECKLIST.md) - progress log per vòng
- [demo_script.md](../demo_script.md) - stakeholder demo

## 🔗 External references

- [React 19 docs](https://react.dev)
- [Vite 8 docs](https://vite.dev)
- [Express docs](https://expressjs.com)
- [better-sqlite3](https://github.com/WiseLibs/better-sqlite3)
- [Drizzle ORM](https://orm.drizzle.team)
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Playwright](https://playwright.dev)

---

## ❓ FAQ for new devs

### Tại sao dùng SQLite thay vì PG?
- MVP, single-tenant, single-server → SQLite đủ
- PG switch dễ (đã có schema-pg.js + migration script)

### Tại sao không dùng Tailwind / MUI?
- Bundle size: 103KB gzipped vs 200-500KB của MUI
- Custom CSS dễ control, không có opinionated styles
- Dark mode chỉ cần override CSS vars

### Tại sao không dùng TypeScript?
- MVP, tốc độ quan trọng hơn type safety
- Nếu cần, có thể migrate dần

### Tại sao không dùng Redux / Zustand?
- State đơn giản, useState + context đủ
- Tránh over-engineering

### Tại sao có 2 file seed?
- `seed-test-master-business.mjs`: data gốc (projects, zones, master)
- `seed-demo-data-enrich.mjs`: enrich thêm states cho demo (5 status, severity, etc.)
- Tách ra để chạy lại từng phần

### Tại sao có 2 ingest folder structures?
- `services/ingest/` - per-doc-type handlers
- `services/ingest/project_level.js` - multi-zone rollup (special)

### Tại sao không có WebSocket?
- MVP, polling/manual refresh đủ
- Sẽ thêm SSE hoặc WS trong vòng sau nếu cần real-time
</content>
