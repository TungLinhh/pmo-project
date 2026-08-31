# PMO MVP - Codebase Reference

> Complete file-by-file reference. Every file, every function, every route, every export.

**Generated:** 2026-08-31
**Stack:** Node 20 + Express + SQLite/PostgreSQL + React 19 + Vite 8
**Total LOC:** ~3500 lines backend + ~5500 lines frontend

---

## 📋 Table of Contents

1. [Root Files](#root-files)
2. [Backend](#backend)
   - [src/index.js (Express app)](#backendindexjs)
   - [src/db/ (database layer)](#databaselayer)
   - [src/lib/ (libraries)](#backendlibraries)
   - [src/services/ (business logic)](#backendservices)
   - [src/services/ingest/ (Excel ingestors)](#backendingestors)
3. [Frontend](#frontend)
   - [src/main.jsx, App.jsx](#frontendroot)
   - [src/api/ (API client)](#frontendapi)
   - [src/components/ (shared UI)](#frontendcomponents)
   - [src/hq/ (HQ screens, 20 files)](#frontendhq)
   - [src/field/ (Field screens)](#frontendfield)
   - [src/governance/ (Governance screens)](#frontendgovernance)
   - [src/styles/ (CSS)](#frontendcss)
4. [Scripts](#scripts)
5. [Deploy files](#deploy)

---

## Root Files

### `package.json` (workspace root)
- **Purpose:** npm workspaces config (or stub)
- **Contents:** Name only, real deps are in `backend/` and `frontend/`

### `Dockerfile` (multi-stage)
- **Stage 1** (`node:20-alpine AS frontend-build`): builds Vite frontend → `dist/`
- **Stage 2** (`node:20-alpine`): installs backend deps, copies source + built frontend
- **Final:** runs `docker-entrypoint.sh` which migrates DB then starts `node src/index.js`
- **Env vars:** `NODE_ENV=production`, `PORT=3000`, `DB_DRIVER=sqlite`, `SQLITE_PATH=/app/backend/data/pmo.db`
- **Expose:** 3000

### `docker-entrypoint.sh`
- Bash script: runs migration if needed, then `exec node src/index.js`
- 466 bytes

### `CHECKLIST.md` (18 KB)
- Per-vòng progress log. Tracks every change across sessions.

### `demo_script.md` (8 KB)
- Stakeholder demo flow (14 steps, 30 min). Test accounts, expected outputs.

### `README.md` (7 KB)
- Project intro, quick start, features, screenshots.

### `reference_sheets/`
- Sample Excel files from HBG-HBC-BCTT project (558 MB).
- 8 subfolders: `2019.04.28 HBG-HBC-BCTT/` with categories:
  - `TIẾN ĐỘ SHOP/`, `TIẾN ĐỘ THI CÔNG/`, `TIẾN ĐỘ CUNG ỨNG VẬT TƯ/`
  - `TIẾN ĐỘ THANH TOÁN A_B/`, `TÀI NGUYÊN/`, `QUY TRÌNH/`
  - `SƠ ĐỒ CÂY/`, `FILE START.xlsx`
- Used as demo/test data sources.

---

## Backend

### Backend index.js

**`backend/src/index.js`** (47 KB, 962 lines, **60 API routes**)

The Express app. Wires every route, middleware, and the static frontend.

**Imports (lines 1-12):**
- `express`, `cors`, `multer`, `rateLimit` (express-rate-limit)
- `saveFile`, `getFilePath`, `fileExists` from `./lib/storage.js`
- `detectDocType`, `listSheets` from `./lib/excel.js`
- `findZoneByName` from `./lib/zone_matcher.js`
- `getDb`, `closeDb` from `./db/index.js`
- `ingest`, `findOrCreateProject`, `ingestProjectLevelFile` from `./services/ingest/index.js`
- `getPermissions` from `./lib/permissions.js`
- `authMiddleware` from `./lib/auth.js`
- `permissionMiddleware` from `./lib/permission-middleware.js`

**Constants (line 14):**
- `PORT = process.env.PORT || 3000`
- `TENANT_ID = 1` (hardcoded for MVP)

**Middleware chain (lines 17-22):**
- `app.use(cors())` - allow all origins
- `app.use(express.json())` - JSON body parser
- `app.use(authMiddleware)` - parses Bearer token
- `app.use(permissionMiddleware)` - attach permissions to req

**Rate Limiting (lines 25-48):**
- `authLimiter`: 5 req / min / IP for `/api/auth/login` (anti-brute-force)
- `uploadLimiter`: 20 uploads / hour / IP
- `apiLimiter`: 100 req / min / IP for everything else

**Helper functions:**
- `audit(userId, action, resource, payload)` (line ~50): write to `audit_log` table
- `requireAuth(req, res, next)` (line ~65): 401 if not logged in
- `requirePerm(module, action)` (line ~70): middleware factory, returns 403 if no perm
- `decidePermission(user, module, action)` (line ~75): check matrix

**API Endpoints (60 total):**

#### Auth (3)
| Method | Path | Handler | Permission |
|---|---|---|---|
| POST | `/api/auth/login` | login(email, password) → token | none |
| POST | `/api/auth/logout` | invalidate token | auth |
| GET  | `/api/auth/me` | current user info | auth |

#### Projects / Master Data (4)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects` | list projects (filter by user role) | `project.read` |
| GET | `/api/projects/:id/zones` | list zones of project | `project.read` |
| GET | `/api/master-data/:resource` | list generic master data (subcontractors, suppliers, etc.) | `master.read` |
| GET | `/api/dashboard/portfolio-kpi` | portfolio-level KPI rollup | `dashboard.read` |

#### Daily Reports (2)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/daily-reports` | list daily reports (filter by date, zone) | `daily_report.read` |
| GET | `/api/daily-reports/:id/full` | full report with all related rows (work_items, manpower, materials, acceptance) | `daily_report.read` |

#### Construction / Shop / Material (6)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/construction-schedule` | schedule items (filter by zone, date, status) | `construction.read` |
| GET | `/api/projects/:id/shop-drawings` | shop drawings (filter by status, zone) | `shop.read` |
| GET | `/api/projects/:id/zones/:code/items` | items in 1 zone | `construction.read` |
| GET | `/api/projects/:id/materials` | materials (filter by zone) | `material.read` |
| GET | `/api/projects/:id/material-breakdown` | materials grouped by category | `material.read` |
| GET | `/api/projects/:id/material-submittals` | material submittals (5-state workflow) | `material.read` |
| GET | `/api/projects/:id/material-submittals/overdue` | overdue submittals (sla_deadline < today) | `material.read` |

#### Business Process (1)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/business-process/:code` | get business process steps by code | `master.read` |

#### Upload / Files (2)
| Method | Path | Handler | Permission |
|---|---|---|---|
| POST | `/api/upload` | multer + detectDocType + ingest | `upload.create` |
| GET  | `/api/uploads` | list past uploads (file_uploads table) | `upload.read` |
| GET  | `/api/health` | `{status: 'ok', timestamp}` | none |

#### Export (3) - returns XLSX files
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/export/daily-report/:id.xlsx` | export 1 daily report | `daily_report.read` |
| GET | `/api/export/construction-schedule/:projectId.xlsx` | export all schedule items | `construction.read` |
| GET | `/api/export/shop-drawings/:projectId.xlsx` | export shop drawings | `shop.read` |

#### Issues & Directives (5)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/issues` | list issues (filter by severity, status) | `issue.read` |
| GET | `/api/issues/:id` | 1 issue detail | `issue.read` |
| POST | `/api/projects/:id/issues` | create issue | `issue.create` |
| POST | `/api/issues` | create issue (alt) | `issue.create` |
| POST | `/api/directives` | create CEO directive | `directive.create` |
| GET | `/api/directives` | list directives | `directive.read` |

#### Notifications (4)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/notifications` | list current user's notifications | auth |
| POST | `/api/notifications/:id/read` | mark as read | auth |
| POST | `/api/notifications/mark-all-read` | mark all as read | auth |
| POST | `/api/notifications` | create notification (admin/system) | `notification.create` |

#### Audit (1)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/audit` | list audit log entries | `audit.read` |

#### Workflows / Approvals (3)
| Method | Path | Handler | Permission |
|---|---|---|---|
| POST | `/api/shop-drawings/:id/transition` | state machine transition (DRAFT→SUBMITTED→...) | depends on state |
| POST | `/api/material-submittals` | create submittal | `material.create` |
| POST | `/api/material-submittals/:id/submit` | submit for review | `material.create` |
| POST | `/api/material-submittals/:id/approve` | approve submittal | `material.approve` |
| POST | `/api/material-submittals/:id/reject` | reject submittal | `material.approve` |

#### Schedule Baselines (2)
| Method | Path | Handler | Permission |
|---|---|---|---|
| POST | `/api/projects/:id/schedule-baselines` | create baseline | `construction.create` |
| GET  | `/api/projects/:id/schedule-baselines` | list baselines | `construction.read` |

#### Contracts / Payments (5)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/contracts` | list contracts | `contract.read` |
| GET | `/api/contracts/:id/invoices` | invoices of contract | `contract.read` |
| POST | `/api/invoices/:id/payment-requests` | create payment request | `payment.create` |
| GET | `/api/invoices/:id/payment-requests` | list payment requests | `payment.read` |
| GET | `/api/projects/:id/payments` | payment milestones (aggregate) | `payment.read` |
| GET | `/api/projects/:id/payment-requests` | list payment requests | `payment.read` |
| GET | `/api/payment-requests/:id` | 1 payment request | `payment.read` |
| PUT | `/api/payment-requests/:id` | update payment request | `payment.update` |

#### KPI (2)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/kpi-targets` | list KPIs (filter by period_lock) | `kpi.read` |
| PUT | `/api/kpi-targets/:id` | update KPI | `kpi.update` |

#### Sync (2)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/sync/queue` | list offline sync queue | `sync.read` |
| POST | `/api/sync/resolve` | resolve conflict | `sync.update` |

#### Areas (1)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/projects/:id/area-hierarchy` | tree: Project→Building→Zone→Floor→Area→WorkItem | `project.read` |

#### Permissions (1)
| Method | Path | Handler | Permission |
|---|---|---|---|
| GET | `/api/me/permissions` | full matrix for current user | auth |

#### Static serve (lines 945-954)
```js
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const __dirname = dirname(fileURLToPath(import.meta.url));
const frontendDist = join(__dirname, '..', '..', 'frontend', 'dist');
if (existsSync(frontendDist)) {
  app.use(express.static(frontendDist));
  app.get('*', (req, res) => res.sendFile(join(frontendDist, 'index.html')));
}
```

This means in production, **port 3000 serves both API and the built React app** (Vite `dist/`). Catch-all `*` returns `index.html` for client-side routing.

#### Server start (lines 956-959)
```js
const server = app.listen(PORT, () => {
  console.log(`🚀 PMO Backend running on http://localhost:${PORT}`);
  console.log(`   API: http://localhost:${PORT}/api/health`);
});
```

#### Graceful shutdown (lines 961-962)
```js
process.on('SIGINT', () => { closeDb(); server.close(); process.exit(0); });
process.on('SIGTERM', () => { closeDb(); server.close(); process.exit(0); });
```

---

### Database Layer

#### `backend/src/db/index.js` (3 KB)
**Functions:**
- `getSqlite()` → SQLite `Database` instance (singleton via `getDb`)
- `getPgPool()` → PostgreSQL pool (lazy init, used when `DB_DRIVER=postgres`)
- `convertSql(sql)` → rewrites SQLite-style params to PG-style
- `getDb()` → returns active DB based on env

**Logic:**
- Read `process.env.DB_DRIVER` (`sqlite` | `postgres`)
- If `sqlite`: use `better-sqlite3`, return `getSqlite()`
- If `postgres`: use `pg`, return `getPgPool()` wrapper

**Key exports:**
- `getDb()`, `closeDb()`, `convertSql()`

#### `backend/src/db/init.js` (3.5 KB)
**Functions:**
- `initSchema(db, driver)` → create all tables if not exist (idempotent)
- Calls schema-pg.js for PG or runs inline SQL for SQLite

#### `backend/src/db/pg.js` (775 B)
**Functions:**
- `initPgPool(config)` → create `pg.Pool` with retry
- `getPool()` → return existing pool
- `query(text, params)` → wrapped query

#### `backend/src/db/schema-pg.js` (37 KB)
The full PostgreSQL schema. **40+ tables** defined using Drizzle ORM (or raw SQL).

**Tables (in order):**
- `tenants`, `users`, `projects`, `zones`, `areaLevelEnum`, `areaHierarchy`, `wbs`
- `businessProcesses`, `businessProcessSteps`
- `dailyReports`, `dailyWorkItems`, `dailyManpower`, `dailyMaterials`, `dailyAcceptance`, `dailyRecommendations`, `dailySafety`, `dailyInfos`
- `shopDrawings`, `constructionScheduleItems`, `scheduleBaselines`
- `materials`, `materialSubmittals`
- `rfaLog`
- `subcontractors`, `suppliers`
- `notifications`, `auditLog`
- `fileUploads`, `genericSheets`
- `vendors`, `teams`, `workers`, `costCodes`, `resources`, `workItems`
- `contracts`, `invoices`, `paymentRequests`, `payments`
- `kpiTargets`
- `offlineSyncQueue`

**Enums:**
- `healthStatusEnum` (HEALTHY, AT_RISK, CRITICAL, ...)
- `workflowStatusEnum` (DRAFT, SUBMITTED, REVIEW, APPROVED, REJECTED, ...)
- `masterStatusEnum` (ACTIVE, INACTIVE, ARCHIVED)
- `userRoleEnum` (admin, ceo, pm, pmo, site, procurement, accounting)
- `notificationChannelEnum` (in_app, email, sms)
- `notificationStatusEnum` (pending, sent, failed)
- `syncConflictEnum` (server_wins, client_wins, manual)

**SQLite schema (defined inline in `index.js` or `init.js`):** mirrors PG, but simpler (no enums, no FK constraints in some cases).

---

### Backend Libraries

#### `backend/src/lib/auth.js` (2 KB)
**Exports:**
- `authMiddleware(req, res, next)` → reads `Authorization: Bearer <token>`, decodes, sets `req.user`

**Internal:**
- `loadUser(token)` → look up user in `users` table by token
- Token is a 32-char hex string (no JWT, just a session token stored in-memory or DB)

#### `backend/src/lib/permissions.js` (7 KB)
**Exports:**
- `PERMISSION_MATRIX` (object): 6 roles × 14 modules × 3 actions
- `FULL_ACCESS_ROLES` (set): `['admin', 'ceo']`
- `getPermissions(role)` → return full matrix for role
- `decidePermission(user, module, action)` → boolean
- `requirePerm(module, action)` → Express middleware factory

**Matrix structure:**
```js
{
  admin: {
    project: { read: true, write: true, approve: true },
    shop: { read: true, write: true, approve: true },
    // ... 14 modules
  },
  pm: {
    project: { read: true, write: true, approve: false },
    contract: { read: true, write: true, approve: false },
    // ... etc
  },
  // ... ceo, pmo, site, procurement, accounting
}
```

#### `backend/src/lib/permission-middleware.js` (4.7 KB)
**Exports:**
- `permissionMiddleware(req, res, next)` → attaches `req.permissions` to every request

**Logic:**
- Reads `req.user` (set by authMiddleware)
- For unauthenticated users: `req.permissions = {}` (empty)
- For authenticated: `req.permissions = getPermissions(user.role)`
- This makes per-request checks trivial in routes: `if (req.permissions.shop.read) { ... }`

#### `backend/src/lib/excel.js` (5 KB)
**Exports:**
- `detectDocType(filename)` → string
- `listSheets(filePath)` → string[]
- `readSheet(filePath, sheetName)` → `rows[][]` (2D array)
- `toInt(value)` → number | 0
- `toFloat(value)` → number | 0
- `toText(value)` → string | ''
- `toDate(value)` → ISO string | null

**`detectDocType` keywords (order matters):**
- `'thanh toán'` / `'payment'` / `'hstt'` → `payment_progress`
- `'quy trình thực hiện'` → `business_process`
- `'thầu phụ'` / `'tổ đội'` → `subcontractor_directory`
- `'shop '` / starts with `shop` → `shop_drawing`
- `'vật tư'` / `'vat tu'` → `material_supply`
- `'tđ '` / `'tiến độ'` → `construction_schedule`
- `'báo cáo công việc'` / `'daily'` → `daily_report`
- `'mcr-mm'` / `'rfa'` → `rfa_log`
- `'mcr-mpm'` → `manpower_master_plan`
- `'bte-mshop'` → `shop_master`
- `'bte-wm'` → `work_management`
- `'sơ đồ cây'` → `work_breakdown`
- `'sơ đồ' + 'khu vực'` → `zone_map`
- `'file start'` → `file_index`
- `'nguồn lực'` → `resource_directory`
- `'duyệt khác'` → `other_approved`
- else → `unknown`

#### `backend/src/lib/storage.js` (1 KB)
**Exports:**
- `saveFile(buffer, originalName)` → `{key, fullPath, hash, size}`
- `getFilePath(key)` → full path
- `fileExists(key)` → boolean

**Storage location:** `backend/uploads/<hash>_<timestamp>.<ext>`

**Hash:** SHA-256 of buffer (used for idempotency check)

#### `backend/src/lib/validation.js` (7 KB)
**Exports:**
- `SHOP_DRAWING_STATE_MACHINE` (object): valid state transitions
- `MAT_SUBMITTAL_STATE_MACHINE` (object)
- `PAYMENT_STATE_MACHINE` (object)
- `validateTransition(currentState, nextState, machine)` → throws if invalid

**State machine format:**
```js
{
  DRAFT: ['SUBMITTED'],
  SUBMITTED: ['REVIEW', 'DRAFT'],
  REVIEW: ['APPROVED', 'REJECTED'],
  APPROVED: [],
  REJECTED: ['DRAFT'],
}
```

#### `backend/src/lib/zone_matcher.js` (2.5 KB)
**Exports:**
- `findZoneByName(name, zones)` → zoneId | null

**Logic:**
- Lowercase, trim, normalize spaces & dashes
- Check `ZONE_ALIASES` dict (~80 aliases)
- Fallback: direct code match, then partial match

**Zone codes:** BOH, BPV, BPV-1BR, BPV-2BR, BSN, BUT, BZONE, CLU, GEN, HPV, HPV-1BR, HPV-2BR, INF, KID, LOB-SPA, RES, RES-3BR, RES-4BR, VNR

**Aliases (sample):**
- `'beach pool villa'` → `'BPV'`
- `'business center'` → `'BSN'`
- `'cluster villa'` → `'CLU'`
- `'fitness'`, `'gym'`, `'fitnes'`, `'fit'` → `'GEN'`
- `'lobby'`, `'spa'`, `'loby'`, `'lobby spa'` → `'LOB-SPA'`
- `'hạ tầng'`, `'infrastructure'` → `'INF'`
- `'resort'`, `'res villas'`, `'resvillas'` → `'RES'`
- `'vn res'`, `'vietnam residences'` → `'VNR'`

---

### Backend Services

#### `backend/src/services/export.js` (5 KB)
**Exports:**
- `exportDailyReport(id)` → Buffer (XLSX)
- `exportConstructionSchedule(projectId)` → Buffer
- `exportShopDrawings(projectId)` → Buffer

**Logic:**
- Load data via SQL joins
- Build workbook with `xlsx` package
- Multi-sheet: 1 sheet per zone + 1 summary sheet

---

### Backend Ingestors

All ingestors live in `backend/src/services/ingest/`. Each exports a function that takes `(filePath, projectId, ...)` and returns `{ok, errors, items, doc_type}`.

#### `index.js` (dispatcher)
**Exports:**
- `ingest(filePath, docType, opts)` → dispatches to per-type handler
- `ingestProjectLevelFile(filePath, projectId, docType)` → for multi-zone files
- `findOrCreateProject(tenantId, projectCode)` → project record

**Dispatch table:**
```js
case 'shop_drawing'          → ingestShopDrawing(file, projectId, zoneCode)
case 'construction_schedule' → ingestConstructionSchedule(file, projectId, zoneCode)
case 'material_supply'       → ingestMaterialSupply(file, projectId, zoneCode)
case 'daily_report'          → ingestDailyReport(file, projectId)
case 'business_process'      → ingestBusinessProcess(file, tenantId, code)
case 'subcontractor_directory' → ingestSubcontractorDirectory(file, projectId)
case 'resource_directory'    → ingestResourceDirectory(file, tenantId)
case 'rfa_log'               → ingestRFALog(file, projectId)
case 'payment_progress'      → ingestGenericTabular(file, projectId, { docType })
default                      → ingestGenericTabular or throw
```

#### `shop_drawing.js` (3.6 KB)
**Export:** `ingestShopDrawing(filePath, projectId, zoneCode)`
**Logic:**
1. Look up zone by code
2. Read all sheets
3. For each sheet, find data start (skip header), INSERT each row as `shop_drawings(project_id, zone_id, source_sheet, drawing_code, name_vi, ...)`
4. Uses `INSERT OR REPLACE` for idempotency
5. Status default: `DRAFT`

**DB columns used:** `project_id, zone_id, source_sheet, drawing_code, name_vi, name_en, progress_pct, status, bql_l1_response, bql_l1_comment, bql_l2_response, bql_l2_comment, approval_date, rejection_reason`

#### `construction_schedule.js` (3.5 KB)
**Export:** `ingestConstructionSchedule(filePath, projectId, zoneCode)`
**Internal:** `parseLevel(value)` (handles "I.", "II.", "1", "1.2.3"), `mapStatus(value)`
**Logic:**
- Insert `construction_schedule_items` with `level_roman`, `level_arabic`, `sublevel`, `ordinal`
- Tracks parent-child relationships via levels
- Status: PLANNED / IN_PROGRESS / DONE

#### `material_supply.js` (2.2 KB)
**Export:** `ingestMaterialSupply(filePath, projectId, zoneCode)`
**Logic:**
- Insert `materials` with 4 request dates (1, 2, 3, actual)
- Status: REQUESTED / ORDERED / DELIVERED / INSTALLED

#### `daily_report.js` (8.5 KB) - **most complex**
**Export:** `ingestDailyReport(filePath, projectId)`
**Internal:** `parseSheetDate(value)`, `ingestOneSheet(filePath, sheetName, projectId)`
**Logic:**
- Each sheet = 1 day
- Inserts into 5 tables: `daily_reports` (1 row), `daily_work_items` (parent + children), `daily_manpower` (per team), `daily_materials` (per item), `daily_acceptance` (per record)
- Also: `daily_recommendations`, `daily_safety`, `daily_infos`
- Returns full breakdown

#### `business_process.js` (1.6 KB)
**Export:** `ingestBusinessProcess(filePath, tenantId, processCode)`
**Logic:**
- Read steps (sequence, name, owner_role, sla_days)
- Insert into `business_processes` (1) + `business_process_steps` (N)

#### `rfa_log.js` (2 KB)
**Export:** `ingestRFALog(filePath, projectId)`
**Logic:**
- Request for Approval entries
- Insert into `rfa_log` with status, requestor, approver, dates

#### `resource_directory.js` (2.4 KB)
**Export:** `ingestResourceDirectory(filePath, tenantId)`
**Logic:**
- Company-level (not per-project)
- Insert into `resources` table

#### `subcontractor_directory.js` (1.7 KB)
**Export:** `ingestSubcontractorDirectory(filePath, projectId)`
**Logic:**
- Per-project sub list
- Insert into `subcontractors`

#### `project_level.js` (6.7 KB) - **multi-zone rollup**
**Export:** `ingestProjectLevel(filePath, projectId, options)`
**Logic:**
- For each sheet:
  - Skip "Sơ đồ" / "Index" / "Tổng" sheets
  - Extract zone from sheet name: "TĐ BPV-1BR" → "BPV-1BR"
  - `findZoneByName(zoneName, zones)` → zoneId
  - Find data start (skip header section, typically rows 0-17)
  - For construction_schedule: parse Roman numerals (I., II., III.) as parent levels, numbers (1, 2, 3) as children
  - DELETE old rows for that project+zone+sheet (clean re-import)
  - INSERT all rows
- Returns `{ok, errors, items, zone_splits: {zoneName: count}}`

**Key improvements (vòng 8):**
- Skip rows where name/code is purely numeric (`/^[0-9.]+$/`)
- Detect ordinal from Roman numerals (I.=1, II.=2, etc.)
- Find dataStart by Stt col[3] presence (not just integer check)

#### `generic_tabular.js` (1.9 KB)
**Export:** `ingestGenericTabular(filePath, projectId, { docType })`
**Logic:**
- Catch-all: read all sheets, insert as `generic_sheets(project_id, doc_type, source_sheet, zone_id, ordinal, col_1..col_5)`
- Used for: `payment_progress`, `manpower_master_plan`, `shop_master`, `work_management`, `other_approved`, `file_index`, `zone_map`

---

## Frontend

### Frontend Root

#### `frontend/src/main.jsx` (247 B)
**Exports:** default function `main()`
- `ReactDOM.createRoot(document.getElementById('root')).render(<App />)`

#### `frontend/src/App.jsx` (5 KB)
**Exports:** default function `App()`
**Internal:**
- `Protected({children, role})` - redirect to /login if not auth
- `ProjectsList()` - list user's projects (auto-select first)

**Wraps everything in:**
- `<ConfirmProvider>` from `components/Confirm.jsx` (modal context)
- `<BrowserRouter>` from react-router-dom v7
- `<Routes>` with all routes

**Routes (~25):**
- `/login` → `<Login />`
- `/hq/*` → `<HqShell />` with nested routes:
  - `/hq` (index) → `<ProjectOverview />` (was ControlCenter)
  - `/hq/control` → `<ControlCenter />`
  - `/hq/progress` → `<ProgressDetail />`
  - `/hq/progress/:itemId` → `<ProgressDetail />` (deep link)
  - `/hq/shop` → `<ShopList />`
  - `/hq/shop/:id` → `<ShopDetail />`
  - `/hq/materials` → `<Materials />`
  - `/hq/payment` → `<Payment />`
  - `/hq/manpower` → `<Manpower />`
  - `/hq/issues` → `<Issues />`
  - `/hq/issues/:id` → `<IssueDetail />`
  - `/hq/notification` → `<NotificationCenter />`
  - `/hq/kpi` → `<ProjectKpi />`
  - `/hq/daily` → `<DailyReportView />`
  - `/hq/area` → `<AreaHierarchy />`
  - `/hq/placeholders` → `<Placeholders />` (dev only)
- `/governance/*` → `<Approval />`, `<AuditLog />`, `<MasterDataList />`, `<MasterDataEdit />`
- `/field/*` → `<FieldShell />` with `<FieldHome />`, `<DailyProgress />`, `<FieldStubs />`

---

### Frontend API client

#### `frontend/src/api/index.js` (6.7 KB)
**Exports (one per domain):**
- `auth` - `login`, `logout`, `me`
- `projects` - `list`, `get`, `zones`, `areaHierarchy`
- `shop` (also `shopApi`) - `list`, `get`, `transition`
- `materials` - `list`, `breakdown`, `submittals`, `submit`, `approve`, `reject`
- `construction` - `schedule`, `baselines`
- `daily` - `list`, `getFull`
- `businessProcess` - `get`
- `issues` - `list`, `get`, `create`
- `directives` - `list`, `create`
- `notifications` - `list`, `markRead`, `markAllRead`
- `audit` - `list`
- `uploads` - `list`
- `exportApi` - `dailyReport(id)`, `constructionSchedule(projectId)`, `shopDrawings(projectId)`
- `masterData` - `list(resource)`
- `kpi` - `list(projectId)`, `update(id, data)`
- `payments` - `contracts`, `invoices`, `requests`, `update`
- `sync` - `queue`, `resolve`
- `permissions` - `me`
- `api` (default) - raw `request(method, path, body)`

**Internal:**
- `authHeaders()` → add Bearer token from localStorage
- `req(method, path, body)` → fetch with auth, parse JSON
- `request(method, path, body)` → wrapper, handles errors

**Base URL:** `import.meta.env.VITE_API_BASE || ''` (empty = same origin = Vite proxy in dev)

---

### Frontend Components

#### `Login.jsx` (4.3 KB)
- Email/password form
- On submit: `auth.login(email, password)` → save token to localStorage
- Show 7 demo accounts as quick-fill buttons
- 6 role-based redirect: CEO→/hq, Site→/field, etc.

#### `HqShell.jsx` (6.6 KB) - **Layout shell**
- Left sidebar (220px): menu items, filtered by `/api/me/permissions`
- Top bar: project selector, user menu, notification bell
- Mobile <768px: hamburger button → drawer overlay
- `<Outlet />` for nested routes

**State:**
- `permissions` (from API)
- `selectedProject` (from URL query or localStorage)
- `drawerOpen` (mobile)
- `user` (from /api/auth/me)

#### `FieldShell.jsx` (2.4 KB)
- Mobile-first layout
- Top bar: project, weather, sync status
- Bottom tab bar: Home / Daily / Manpower / Shop / Photo / Review
- `SyncStatusBar` component: shows online/offline + pending sync count

#### `PieChart.jsx` (4.9 KB) - **Custom SVG**
- Props: `data[{label, value, color}]`, `size`, `donutHole`
- Computes % per slice, cumulative angles
- Renders `<path>` for each slice
- onMouseEnter → show `CursorTooltip` at fixed position (offset 18px from cursor)
- onMouseLeave → hide
- Center text: optional `${total} items` or `${pct}%`

#### `PieTooltip.jsx` (2 KB) - **LEGACY, removed in vòng 6**
- Old version of cursor tooltip, kept for reference
- Currently unused (PieChart uses CursorTooltip directly)

#### `CursorTooltip.jsx` (1.6 KB)
- Global singleton tooltip
- Portal-based, position: fixed
- Used by PieChart, hover cards

#### `Toast.jsx` (2.1 KB) - **Toast notifications**
- `toast.show(message, type)` - type: 'success' | 'error' | 'info' | 'warning'
- `toast.success(msg)`, `toast.error(msg)` - shortcuts
- Context provider with auto-dismiss (4s)
- Fixed bottom-left
- Stack: max 5 toasts

#### `Confirm.jsx` (2.2 KB) - **Confirm modal**
- `useConfirm()` hook returns `confirm({title, message, confirmText, cancelText, danger})`
- Returns `Promise<boolean>`
- Used before Approve/Reject/Submit/Delete

#### `BellDropdown.jsx` (5.5 KB) - **Notifications**
- Bell icon with unread count badge
- Dropdown shows recent 20 notifications
- Mark as read on click
- `relativeTime(date)` helper
- `navTargetFor(notif)` - returns route based on notification type

#### `icons.jsx` (4.2 KB) - **SVG icon library**
- Exports `ICON` object: `ICON.menu`, `ICON.close`, `ICON.bell`, `ICON.user`, `ICON.check`, ...
- ~30 monochrome SVG icons
- Stroke-based, 18x18 viewBox
- Inherits `currentColor` for theme support

#### `constants.js` (2 KB)
**Exports:**
- `HEALTH` - color codes: GREEN, YELLOW, RED, GRAY
- `WORKFLOW` - status codes: DRAFT, SUBMITTED, REVIEW, ...
- `MASTER` - master status: ACTIVE, INACTIVE, ARCHIVED
- `ROLES` - 6 roles: admin, ceo, pm, pmo, site, procurement, accounting
- `HEALTH_COLORS` - badge color map
- `WORKFLOW_COLORS` - workflow color map

---

### Frontend HQ Screens

All in `frontend/src/hq/`. ~20 files, each follows pattern:
- Fetch data on mount + when filters change
- Render: filter bar + table/chart
- Mutations: update local state + call API + toast

| File | LOC | Endpoint | Features |
|---|---|---|---|
| `ControlCenter.jsx` | 28K | GET 5 endpoints | 4 pillars (PieChart), project selector, recent activity |
| `ProjectOverview.jsx` | 6.3K | `/api/projects` | Project cards, KPIs, status |
| `ShopList.jsx` | 6.2K | `/shop-drawings` | 5-status filter, zone filter, table |
| `ShopDetail.jsx` | (in ShopList) | `/shop-drawings/:id` | Detail view (or modal) |
| `Materials.jsx` | 10.3K | `/materials`, `/material-breakdown` | Submittals list, status, overdue |
| `Payment.jsx` | 14K | `/payments`, `/contracts`, `/invoices` | Multi-tab: contracts, invoices, milestones, requests |
| `Manpower.jsx` | 10.1K | `/master-data/manpower` | Team list, allocation, OT |
| `Issues.jsx` | 10.9K | `/issues` | 4 severity × status filter, directive tagging |
| `IssueDetail.jsx` | 7.9K | `/issues/:id` | Full detail, comments, status update |
| `ProgressDetail.jsx` | 7.3K | `/construction-schedule` | Gantt-like view, filter by zone, progress |
| `ProjectKpi.jsx` | (in Placeholders) | `/kpi-targets` | KPI table, period lock, actual vs target |
| `NotificationCenter.jsx` | 6.1K | `/notifications` | Full list, severity filter, mark all read |
| `DailyReportView.jsx` | (in Placeholders) | `/daily-reports` | Calendar + list, click → full report |
| `AreaHierarchy.jsx` | (in Placeholders) | `/area-hierarchy` | Tree view: Building→Zone→Floor→Area→WorkItem |
| `Placeholders.jsx` | 1.3K | n/a | Stub screens for routes not yet built |

---

### Frontend Field Screens

`frontend/src/field/`:

| File | LOC | Features |
|---|---|---|
| `FieldHome.jsx` | 2.9K | Site overview, weather, today's tasks |
| `DailyProgress.jsx` | 4K | Submit daily report (work items, manpower, materials, photos) |
| `FieldStubs.jsx` | 10.4K | Stub screens: Manpower, Shop, Photo, Review |

---

### Frontend Governance Screens

`frontend/src/governance/`:

| File | LOC | Features |
|---|---|---|
| `Approval.jsx` | 15.7K | List pending approvals, **inline expand** details, Approve/Reject with confirm |
| `AuditLog.jsx` | 929 B | Simple list of audit entries |
| `MasterDataList.jsx` | 4.4K | Generic list (subcontractors, suppliers, etc.) |
| `MasterDataEdit.jsx` | 991 B | Edit form for master data |

---

### Frontend CSS

`frontend/src/styles/`:

| File | Size | Coverage |
|---|---|---|
| `global.css` | 20.7K | CSS vars (light + dark theme), reset, base elements, badges, forms, tables |
| `hq.css` | 13K | HQ layout (shell, sidebar, topbar), mobile <768px media query, dark mode overrides |
| `field.css` | 4.7K | Field layout, mobile-first, cards, lists |
| `login.css` | 3.4K | Login page gradient, form, 7 quick-account buttons |

**Key CSS vars (global.css):**
```css
:root {
  --c-bg, --c-bg-2, --c-bg-3
  --c-text, --c-text-2, --c-text-3
  --c-border, --c-border-2
  --c-primary, --c-primary-2
  --c-draft-bg, --c-approved, --c-rejected, --c-overdue
  --shadow-sm, --shadow-md, --shadow-lg
  --radius-sm, --radius-md, --radius-lg
}
body.theme-dark { /* dark overrides */ }
```

---

## Scripts

### Backend scripts (`backend/scripts/`)

| File | Purpose |
|---|---|
| `seed-test-master-business.mjs` | Initial demo data: 1 project (BTE-WP4-HBC), 19 zones, ~100 shop drawings, ~500 schedule items, master data, 7 user accounts |
| `seed-demo-data-enrich.mjs` | Adds more data for TEST-MASTER-01: shop 5-status, submittals, payment milestones, issues, KPI, areas, notifications |
| `test-admin-full-access.mjs` | Verify admin can do everything (no 403) |
| `test-role-permissions.mjs` | 130 tests: 6 roles × 14 modules × write/approve. Verifies permission matrix |
| `init-schema.mjs` | Create all tables (alternative to Docker entrypoint) |
| `generate-test-excel.mjs` | Generate sample xlsx for testing ingest |
| `upload-test-pipeline.mjs` | End-to-end test: upload → ingest → query |
| `archive/migrate-sqlite-to-pg.mjs` | One-time migration to PostgreSQL |
| `archive/migrate-zones-to-area-hierarchy.mjs` | Restructure zones into Building→Zone→Floor→Area |
| `archive/sync-new-data-to-pg.mjs` | Bidirectional sync SQLite ↔ PG |
| `archive/reinit-db.mjs` | Drop + recreate DB (DESTRUCTIVE) |

### Playwright scripts (`scripts/`)

| File | Purpose |
|---|---|
| `ui-verify.mjs` | Original full E2E test |
| `ui-verify-v6.mjs` | vòng 6 tests (mobile, permission, tooltip, dark mode) |
| `ui-verify-v6-quick.mjs` | Fast subset of v6 |
| `ui-verify-v7.mjs` | vòng 7 full: mobile 20 screens + dashboard + approval |
| `ui-verify-v7-mobile.mjs` | Mobile-only |
| `ui-verify-v7-dashboard-approval.mjs` | Dashboard + approval only |
| `ui-verify-v7-pie.mjs` | Pie chart % verify |
| `ui-verify-deep.mjs` | Deep checks (KPIs, payment) |
| `ui-verify-tooltip.mjs` | Tooltip hover test |
| `ui-verify-detail-nav.mjs` | A→A, B→B detail navigation |

---

## Deploy files

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build (frontend → backend) |
| `docker-entrypoint.sh` | Container start: migrate → start node |
| `.dockerignore` | Exclude node_modules, dist, .git, etc. |
| `.gitignore` | Exclude data/pmo.db, uploads, node_modules |

---

## Cross-cutting concepts

### State machines
Defined in `backend/src/lib/validation.js`. Used by:
- Shop drawing: DRAFT → SUBMITTED → REVIEW → APPROVED/REJECTED
- Material submittal: DRAFT → PENDING → SUBMITTED → APPROVED/REJECTED
- Payment: PLANNED → SUBMITTED → APPROVED → PAID
- Issue: OPEN → IN_PROGRESS → RESOLVED → CLOSED (or ESCALATED)

### Idempotency
Every upload computes `SHA-256(buffer)`, stores in `file_uploads.content_hash`. Re-upload of same file returns cached report without re-running ingest.

### Permissions flow
```
authMiddleware       → sets req.user (from Bearer token)
permissionMiddleware → sets req.permissions (matrix for user.role)
route handler        → checks req.permissions.module.action
                       403 if not allowed
                       audit(userId, action, resource) on success
```

### Theme
- CSS vars in `global.css` (`:root` for light, `body.theme-dark` for dark)
- Toggle button in HqShell topbar adds/removes `theme-dark` class on body
- No JS theme manager - pure CSS

### Mobile responsive
- Breakpoint: 768px
- Below: sidebar becomes drawer with hamburger
- Tables: compact 2-col layout
- KPI strip: 2 cols instead of 4

### Vietnamese-aware
- All DB columns: `name_vi`, `name_en` (vi primary)
- All dates: `DD/MM/YYYY` format
- Money: `VNĐ` symbol, no decimals
- Status labels: Vietnamese
- Mojibake fix in upload handler (Latin-1 → UTF-8 re-decode)
</content>
