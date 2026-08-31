# PMO MVP - Architecture

> High-level architecture, data flow, deployment topology, and design decisions.

**Last updated:** 2026-08-31

---

## 1. System overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                          CLIENT (Browser)                            │
│  React 19 SPA, Vite build, mobile-responsive, dark/light theme      │
│  • HQ dashboard (20 screens, admin/PM/PMO/CEO)                       │
│  • Field app (9 screens, site engineers)                             │
│  • Governance (4 screens, approval workflow)                         │
└──────────────────────────────┬───────────────────────────────────────┘
                               │ HTTPS
                               │ Bearer token in localStorage
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  EXPRESS SERVER (Node 20, port 3000)                 │
│  • 60+ REST endpoints                                                │
│  • JWT-like session tokens (32 hex chars)                            │
│  • Rate limiting (5 login/min, 100 API/min)                          │
│  • 6-role permission matrix                                          │
│  • Multer upload (max 50MB) + Excel ingest (xlsx)                    │
│  • Static serve frontend/dist + catch-all → index.html               │
└──────────┬────────────────────────────────────────────┬──────────────┘
           │                                            │
           ▼                                            ▼
┌──────────────────────┐                  ┌────────────────────────────┐
│  SQLite (default)    │                  │  PostgreSQL 16 (optional)  │
│  better-sqlite3      │                  │  via pg pool, 40+ tables   │
│  backend/data/pmo.db │                  │  (Drizzle schema)          │
└──────────────────────┘                  └────────────────────────────┘

           ▲
           │ insert/select (better-sqlite3 sync API)
           │
┌──────────┴───────────────────────────────────────────────────────────┐
│                    INGEST PIPELINE (Excel → DB)                      │
│  POST /api/upload → multer → detectDocType → zone_matcher            │
│    → saveFile (SHA-256 dedup) → ingest() router → per-type handler   │
│    → INSERT OR REPLACE → file_uploads (status report)                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. Tech stack

| Layer | Tech | Version | Why |
|---|---|---|---|
| Frontend framework | React | 19.2 | Latest, concurrent rendering, smallest bundle |
| Build tool | Vite | 8.2 | Fast HMR, esbuild-based, modern |
| Routing | react-router-dom | 7.18 | Latest v7 (data router ready) |
| Charts | Custom SVG | n/a | No chart library, ~5KB vs 100KB Chart.js |
| Icons | Custom SVG | n/a | ~30 icons, monochrome, currentColor |
| Styling | Pure CSS + vars | n/a | No Tailwind, no CSS-in-JS, predictable |
| Linting | oxlint | 1.79 | Rust-fast (100x ESLint) |
| Backend | Node.js | 20 LTS | Stable, native fetch, ESM |
| Web framework | Express | 4.x | Most familiar, mature middleware |
| Database (default) | SQLite (better-sqlite3) | 3.x | Zero-config, single file, perfect for MVP |
| Database (production) | PostgreSQL | 16 | Multi-user, ACID, JSON support |
| ORM (PG) | Drizzle | latest | Type-safe, no codegen |
| Auth | Custom token | n/a | 32-char hex in localStorage, no JWT complexity |
| Excel parsing | xlsx | latest | Best browser/node compat |
| File upload | multer | latest | Standard Express middleware |
| Rate limit | express-rate-limit | 7.x | IP-based, simple |
| Container | Docker + Alpine | 20 | 200MB image, fast boot |

---

## 3. Data flow: upload → ingest → visualize

### 3.1 Upload phase

```
User (browser)
   │
   │  1. Select file in <UploadButton>
   │  2. FormData.append('file', file)
   │  3. fetch('POST /api/upload', { body: formData })
   │
   ▼
Express middleware chain
   │
   ├─ cors()
   ├─ express.json() (skipped for multipart)
   ├─ authMiddleware → req.user
   ├─ permissionMiddleware → req.permissions
   ├─ rateLimit (100/min/IP)
   └─ multer.single('file') → req.file { buffer, originalname }
       │
       ▼
Upload route handler (backend/src/index.js: POST /api/upload)
   │
   │  4. Mojibake fix: re-decode Latin-1 → UTF-8 if no Vietnamese
   │  5. detectDocType(filename) → 'shop_drawing' / 'construction_schedule' / ...
   │  6. findOrCreateProject(tenantId=1, projectCode='BTE-WP4-HBC')
   │     (extract from filename or default)
   │  7. Zone extraction: regex / findZoneByName()
   │     or multiZone=true for "tổng thể" files
   │  8. saveFile(buffer, name)
   │     → hash = SHA-256(buffer)
   │     → key = `${hash}_${Date.now()}.xlsx`
   │     → fs.writeFileSync(backend/uploads/<key>, buffer)
   │     → INSERT INTO file_uploads (content_hash, original_filename, status='PROCESSING')
   │  9. Idempotency check:
   │     SELECT * FROM file_uploads WHERE content_hash = ?
   │     if exists & status=SUCCESS: return cached report
   │ 10. ingest(filePath, docType, opts)
```

### 3.2 Ingest phase

```
ingest() router (services/ingest/index.js)
   │
   ├─ case 'shop_drawing'         → ingestShopDrawing(file, projectId, zoneCode)
   ├─ case 'construction_schedule' → ingestConstructionSchedule(file, projectId, zoneCode)
   ├─ case 'material_supply'      → ingestMaterialSupply(file, projectId, zoneCode)
   ├─ case 'daily_report'         → ingestDailyReport(file, projectId)
   ├─ case 'business_process'     → ingestBusinessProcess(file, tenantId, code)
   ├─ case 'rfa_log'              → ingestRFALog(file, projectId)
   ├─ case 'payment_progress'     → ingestGenericTabular(file, projectId, {docType})
   └─ default                     → ingestGenericTabular or throw

ingestShopDrawing (example for per-zone)
   │
   │  1. db.prepare('SELECT id FROM zones WHERE project_id=? AND code=?').get(...)
   │  2. listSheets(file) → ['BOH', 'BPV', 'BPV-1BR', ...]
   │  3. For each sheet:
   │     a. readSheet(file, sheetName) → rows[][]
   │     b. Find dataStart (skip header, look for Stt column)
   │     c. For each row from dataStart:
   │        - toText(row[5])  → drawing_code (e.g. "SD-BOH-001")
   │        - toText(row[6])  → name_vi
   │        - toFloat(row[7]) → progress_pct
   │        - status = 'DRAFT' (default)
   │        - INSERT OR REPLACE INTO shop_drawings (...)
   │  4. Return { ok: N, errors: 0, items: [], doc_type: 'shop_drawing' }
   │
   ▼
ingestProjectLevel (multi-zone rollup)
   │
   │  1. listSheets(file) → ['TỔNG', 'TĐ BPV-1BR', 'TĐ KID CLUB', ...]
   │  2. For each sheet:
   │     a. Skip 'TỔNG' / 'Sơ đồ' / 'Index' / 'Total' sheets
   │     b. Extract zone from sheet name: 'TĐ BPV-1BR' → 'BPV-1BR'
   │     c. findZoneByName('BPV-1BR', zones) → zoneId
   │     d. DELETE FROM construction_schedule_items
   │        WHERE project_id=? AND zone_id=? AND source_sheet=?
   │     e. Find dataStart (first row with Stt col[3] non-empty)
   │     f. For each row:
   │        - Skip if name is purely numeric
   │        - Detect ordinal: 'I.' → 1, 'II.' → 2, '1' → 1
   │        - INSERT INTO construction_schedule_items (..., ordinal)
   │  3. Return { ok: N, errors: 0, items, zone_splits: { 'BPV-1BR': 25, ... } }
   │
   ▼
After ingest
   │
   │  UPDATE file_uploads SET status='SUCCESS', ok_rows=?, error_rows=?,
   │    report_json=JSON.stringify(report) WHERE id=?
   │
   │  Return JSON to browser
```

### 3.3 Visualize phase

```
Browser loads http://localhost:3000/
   │
   ▼
React app boots (frontend/src/main.jsx)
   │
   ▼
<App /> (App.jsx)
   │
   │  <ConfirmProvider>     ← global confirm modal context
   │  <BrowserRouter>
   │  <Routes>
   │    /login → <Login>
   │    /hq/*  → <RequireAuth><HqShell> ... </HqShell></RequireAuth>
   │    /field/* → <RequireAuth><FieldShell> ... </FieldShell></RequireAuth>
   │
   ▼
<HqShell /> (components/HqShell.jsx)
   │
   │  1. useEffect on mount:
   │     - GET /api/auth/me → user info
   │     - GET /api/me/permissions → permission matrix
   │     - GET /api/projects → list projects
   │  2. Filter sidebar menu by permissions
   │  3. Render <Outlet /> for current route
   │
   ▼
Screen component (e.g. <ControlCenter />)
   │
   │  1. useState for filters, data
   │  2. useEffect on mount + filter change:
   │     - GET /api/projects/:id/construction-schedule
   │     - GET /api/projects/:id/shop-drawings
   │     - GET /api/projects/:id/materials
   │     - GET /api/projects/:id/payments
   │  3. Aggregate in FE (count by status, compute %)
   │  4. Render:
   │     - Filter bar (project, zone, status)
   │     - KPI strip (4 cards)
   │     - 4 pillars (PieChart components)
   │     - Recent activity
   │
   ▼
User action (click Approve / Upload / Edit)
   │
   │  - Optimistic update OR re-fetch
   │  - toast.showSuccess / showError
   │  - if destructive: confirm() before API call
```

---

## 4. Database schema (high-level)

40+ tables organized by domain:

### Core (5)
- `tenants` - multi-tenant
- `users` - 6 roles
- `projects` - code, name, dates
- `zones` - 19 codes (BOH, BPV-1BR, ...)
- `area_hierarchy` - Building → Floor → Area → WorkItem (new structure)

### Daily reports (7)
- `daily_reports` - 1 per day per project
- `daily_work_items` - parent + children
- `daily_manpower` - per team
- `daily_materials` - per item
- `daily_acceptance` - per record
- `daily_recommendations` - text
- `daily_safety` - safety incidents
- `daily_infos` - misc info

### Construction (3)
- `construction_schedule_items` - main schedule
- `schedule_baselines` - versioned baselines
- `wbs` - work breakdown structure

### Procurement (4)
- `materials` - supply
- `material_submittals` - approval workflow
- `rfa_log` - Request for Approval
- `vendors`, `suppliers`

### Work (2)
- `shop_drawings` - design drawings, 5-state
- `business_processes` + `business_process_steps` - SOPs

### Human resources (4)
- `workers`, `teams`, `subcontractors`, `manpower` (allocations)

### Finance (4)
- `contracts`, `invoices`, `payment_requests`, `payments` (milestones)

### Master (5)
- `resources`, `cost_codes`, `work_items`, `kpi_targets`, `directives`

### System (5)
- `notifications`, `audit_log`, `file_uploads`, `generic_sheets`, `offline_sync_queue`

### Schema diagram (simplified)

```
tenants ─┬─ users
         ├─ projects ─┬─ zones
         │            ├─ area_hierarchy
         │            ├─ daily_reports ─┬─ daily_work_items
         │            │                  ├─ daily_manpower
         │            │                  ├─ daily_materials
         │            │                  ├─ daily_acceptance
         │            │                  └─ ...
         │            ├─ construction_schedule_items
         │            ├─ shop_drawings
         │            ├─ materials
         │            ├─ material_submittals
         │            ├─ payments ─┬─ contracts
         │            │            └─ invoices ─┬─ payment_requests
         │            ├─ issues ── directives
         │            ├─ kpi_targets
         │            └─ ...
         ├─ notifications
         ├─ audit_log
         └─ file_uploads
```

---

## 5. Permission matrix (6 roles × 14 modules × 3 actions)

| Module \\ Role | admin | ceo | pm | pmo | site | procurement | accounting |
|---|---|---|---|---|---|---|---|
| `project` | R/W/A | R | R/W | R | R | R | R |
| `shop` | R/W/A | R | R/W | R | R | – | – |
| `material` | R/W/A | R | R/W | R | R/W | R/W | – |
| `construction` | R/W/A | R | R/W | R | R/W | – | – |
| `daily_report` | R/W/A | R | R/W | R | R/W | – | – |
| `issue` | R/W/A | R/W/A | R/W | R/W | R | R | R |
| `directive` | R/W/A | R/W/A | R | R | – | – | – |
| `notification` | R/W/A | R/W | R/W | R/W | R/W | R/W | R/W |
| `audit` | R | R | – | – | – | – | – |
| `contract` | R/W/A | R | R/W | R | – | – | R/W |
| `payment` | R/W/A | R | R | R | – | – | R/W/A |
| `kpi` | R/W/A | R/W | R/W | R | R | – | R |
| `master` | R/W/A | R | R/W | R/W | R | R | R |
| `upload` | R/W/A | R | R/W | R | R/W | R/W | R |

R = read, W = write, A = approve, – = denied (403)

`admin` and `ceo` have full access. Others follow least-privilege.

---

## 6. Deployment topology

### Development (current)
```
WSL Ubuntu (Windows host)
  ├── node src/index.js (backend, port 3000) - serves FE build + API
  ├── npm run dev (Vite, port 5173) - dev mode with HMR
  └── SQLite at backend/data/pmo.db
```

### Production (Docker)
```
VPS / Cloud
  └── Docker container (node:20-alpine)
      ├── Multi-stage build: Vite build → copy dist → backend
      ├── docker-entrypoint.sh: migrate DB → start node
      ├── port 3000 exposed
      └── volume: /app/backend/data → persistent SQLite or PG
```

### Production (Cloudflare Tunnel)
```
User browser
  │
  │ https://xxx.trycloudflare.com
  ▼
Cloudflare Edge
  │
  │ QUIC tunnel
  ▼
cloudflared (on client VPS)
  │
  │ localhost:3000
  ▼
Express (port 3000, serves FE dist + API)
  │
  ▼
SQLite or PostgreSQL
```

---

## 7. State machines

### Shop drawing
```
DRAFT → SUBMITTED → REVIEW → APPROVED
                  ↓
                  REJECTED → DRAFT (resubmit)
```

### Material submittal
```
DRAFT → PENDING → SUBMITTED → APPROVED
                          ↓
                          REJECTED → DRAFT
```

### Payment
```
PLANNED → SUBMITTED → APPROVED → PAID
                              ↓
                              OVERDUE (if past due_date, status=APPROVED but date passed)
```

### Issue
```
OPEN → IN_PROGRESS → RESOLVED → CLOSED
                                 ↓
                              ESCALATED (at any time if severity=CRITICAL)
```

---

## 8. Security & limits

- **Auth:** 32-char token in `users.session_token`, sent as `Authorization: Bearer`
- **Rate limit:** 5 login/min, 100 API/min, 20 upload/hr (per IP)
- **Permissions:** checked at every route via `req.permissions.module.action`
- **Audit:** every write logged to `audit_log` (user_id, action, resource, payload, timestamp)
- **CORS:** open (`cors()`) for MVP - restrict in production
- **No CSRF:** token in header, not cookie (CSRF-safe by design)
- **No HTTPS at server:** rely on Cloudflare tunnel for TLS termination

---

## 9. Performance characteristics

- **Backend startup:** ~1 second (SQLite, 40 tables pre-created)
- **Build time:** Vite 300ms, single 372KB JS file (103KB gzip)
- **Time to interactive:** ~2 seconds on 4G
- **API latency:** <50ms for SQLite reads, <200ms for upload + ingest
- **Concurrent users:** SQLite single-writer, tested up to 10 concurrent. Use PG for 50+
- **Largest dataset tested:** 521 schedule items, 102 shop drawings, 197 materials, 89 notifications
- **Ingest rate:** ~500 rows/second for shop_drawing (per sheet)

---

## 10. Known limitations & future work

| Limitation | Workaround | Future |
|---|---|---|
| SQLite single-writer | Use PG for multi-user | Default to PG in production |
| No real-time updates | Manual refresh | Add WebSocket or SSE |
| No offline mode (FE) | n/a | Service worker + IndexedDB |
| No file delete UI | Use SQL directly | Add file manager screen |
| No export UI button | `GET /api/export/...xlsx` works | Add button in screens |
| No email notifications | Stored in DB only | Add email service |
| No multi-tenant | `TENANT_ID=1` hardcoded | Implement tenant scoping |
| No PDF generation | xlsx only | Add puppeteer for PDF |
| No 2FA | Password only | Add TOTP for admin/CEO |
</content>
