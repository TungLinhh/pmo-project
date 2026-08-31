# PMO MVP - Complete Pipeline Architecture

> **One-file reference:** PostgreSQL/SQLite schema + source code pipeline + code reference for ingest → process → visualize.

**Generated:** 2026-08-31
**Scope:** Mọi file, mọi function, mọi table, mọi API route, mọi state machine.

---

## 📋 TABLE OF CONTENTS

1. [System overview](#1-system-overview)
2. [PostgreSQL schema (40+ tables)](#2-postgresql-schema)
3. [SQLite schema (mirror)](#3-sqlite-schema)
4. [Backend source code pipeline](#4-backend-source-code-pipeline)
5. [Frontend source code pipeline](#5-frontend-source-code-pipeline)
6. [Phase 1: INGEST (Excel → DB) - code reference](#6-phase-1-ingest)
7. [Phase 2: PROCESS (per-doc-type) - code reference](#7-phase-2-process)
8. [Phase 3: VISUALIZE (FE render) - code reference](#8-phase-3-visualize)
9. [End-to-end sequence diagram](#9-end-to-end-sequence)
10. [State machines](#10-state-machines)
11. [Permission matrix](#11-permission-matrix)
12. [Index of all files](#12-index-of-all-files)

---

## 1. System overview

```
┌──────────────────────────────────────────────────────────────────────┐
│  BROWSER (React 19 SPA)                                              │
│  • HQ (20 screens), Field (9), Governance (4)                       │
│  • Token in localStorage, sent as Bearer                             │
│  • Vite build served by Express (port 3000)                          │
└──────────────────────────────┬───────────────────────────────────────┘
                               │ HTTPS / Bearer
                               ▼
┌──────────────────────────────────────────────────────────────────────┐
│  EXPRESS SERVER (Node 20, port 3000)                                 │
│  • 60+ REST endpoints                                                 │
│  • Rate limit: 5 login/min, 100 API/min, 20 upload/hr                │
│  • authMiddleware + permissionMiddleware (6 roles × 14 modules)     │
│  • multer + xlsx → ingest pipeline                                   │
│  • Static serve frontend/dist + catch-all → index.html               │
└──────────┬────────────────────────────────────────────┬──────────────┘
           │                                            │
           ▼                                            ▼
┌──────────────────────┐                  ┌────────────────────────────┐
│  SQLite (default)    │                  │  PostgreSQL 16 (optional)  │
│  better-sqlite3      │                  │  pg.Pool (max 10)          │
│  backend/data/pmo.db │                  │  Drizzle ORM schema        │
│  40+ tables (mirror) │                  │  40+ tables + 6 enums      │
└──────────────────────┘                  └────────────────────────────┘
           ▲                                            ▲
           │                                            │
           └────── DB DRIVER env (sqlite|postgres) ────┘

       Upload (Excel)        Ingest pipeline           Read/Write
       ─────────────         ───────────────           ──────────
       POST /api/upload  →   detectDocType       →     INSERT INTO
       (multipart)           findZoneByName             ...
                              ingestProjectLevel
                              ingestShopDrawing
                              ingestDailyReport
                              ...
```

### Driver switch
```js
// backend/src/db/index.js:7
const DRIVER = process.env.DB_DRIVER || 'sqlite';
// → wraps both in same DbWrapper.prepare(sql).run/get/all API
```

---

## 2. PostgreSQL schema

**File:** `backend/src/db/schema-pg.js` (762 lines, Drizzle ORM)

### 2.1 Enums (6 total)

```js
// backend/src/db/schema-pg.js:16-27
export const healthStatusEnum = pgEnum('health_status',
  ['ON_TRACK', 'WATCH', 'BEHIND', 'CRITICAL']);

export const workflowStatusEnum = pgEnum('workflow_status',
  ['DRAFT', 'PENDING', 'SUBMITTED', 'REVIEW', 'APPROVED', 'REJECTED', 'OVERDUE', 'CLOSED']);

export const masterStatusEnum = pgEnum('master_status',
  ['ACTIVE', 'INACTIVE', 'MERGED']);

export const userRoleEnum = pgEnum('user_role',
  ['admin', 'pm', 'pmo', 'site', 'procurement', 'accounting', 'data_admin', 'editor', 'viewer']);

export const notificationChannelEnum = pgEnum('notification_channel',
  ['in_app', 'email', 'zalo_oa', 'telegram', 'push']);

export const notificationStatusEnum = pgEnum('notification_status',
  ['pending', 'sent', 'delivered', 'failed', 'not_implemented']);

export const syncConflictEnum = pgEnum('sync_conflict',
  ['NONE', 'CLIENT_NEWER', 'SERVER_NEWER', 'EQUAL']);
```

### 2.2 Tables (40+)

#### Core (5)
| Table | Schema | Description |
|---|---|---|
| `tenants` | `id, code UNIQUE, name, created_at` | Multi-tenant root |
| `users` | `id, tenant_id FK, email, name, role ENUM, is_ceo, created_at` | 6 roles, indexed by (tenant, email) |
| `projects` | `id, tenant_id FK, code, name_vi, name_en, package, rev_prefix, start_date, ...` | Project metadata |
| `zones` | `id, project_id FK, code, name_en, name_vi` | 19 codes (BOH, BPV-1BR, ...) |
| `area_hierarchy` | `id, project_id FK, parent_id FK, code, name_vi, name_en, level_type` | Tree: Building→Floor→Area→WorkItem |

#### Daily Reports (8)
| Table | Schema |
|---|---|
| `daily_reports` | `id, project_id FK, report_date, weather, status, total_workers, ...` |
| `daily_work_items` | `id, daily_report_id FK, parent_id FK (self), code, name_vi, unit, qty_planned, qty_actual, progress_pct, wbs_id` |
| `daily_manpower` | `id, daily_report_id FK, team_id, worker_count, hours_regular, hours_overtime` |
| `daily_materials` | `id, daily_report_id FK, material_code, name_vi, unit, qty_used, qty_received` |
| `daily_acceptance` | `id, daily_report_id FK, item_code, name_vi, qty, acceptance_status, accepted_by` |
| `daily_recommendations` | `id, daily_report_id FK, content, priority, assigned_to` |
| `daily_safety` | `id, daily_report_id FK, incident_type, severity, description, action_taken` |
| `daily_infos` | `id, daily_report_id FK, info_type, content, author_id` |

#### Construction (3)
| Table | Schema |
|---|---|
| `construction_schedule_items` | `id, project_id FK, zone_id FK, source_sheet, level_roman, level_arabic, sublevel, ordinal, name_vi, name_en, progress_pct, status, plan_start_date, actual_start_date, plan_end_date, actual_end_date, plan_duration_days, baseline_version, baseline_id` |
| `schedule_baselines` | `id, project_id FK, version, created_by, created_at, notes` |
| `wbs` | `id, project_id FK, code, name_vi, parent_id FK, level` |

#### Procurement (4)
| Table | Schema |
|---|---|
| `materials` | `id, project_id FK, zone_id FK, source_sheet, material_code, name_vi, name_en, progress_pct, request_date_1/2/3/4, status, unit, quantity` |
| `material_submittals` | `id, project_id FK, material_code, name_vi, revision_number, status ENUM, sla_deadline, submitted_at, approved_at, rejected_at, reason` |
| `rfa_log` | `id, project_id FK, rfa_code, subject, requestor, approver, status, submitted_at, responded_at` |
| `rfa_log_entries` | `id, rfa_log_id FK, action, comment, by_user, at_time` |

#### Work (2)
| Table | Schema |
|---|---|
| `shop_drawings` | `id, project_id FK, zone_id FK, source_sheet, drawing_code, name_vi, name_en, progress_pct, status ENUM, bql_l1_response, bql_l1_comment, bql_l2_response, bql_l2_comment, approval_date, rejection_reason, submitted_at, reviewed_at, approved_at` |
| `business_processes` | `id, code, name_vi, name_en, owner_role, sla_days` |
| `business_process_steps` | `id, business_process_id FK, sequence, name_vi, owner_role, sla_days, depends_on_step_id` |

#### Human Resources (3)
| Table | Schema |
|---|---|
| `workers` | `id, tenant_id FK, code, full_name, role, team_id, phone, id_card` |
| `teams` | `id, project_id FK, code, name_vi, leader_id, sub_count, type` |
| `subcontractors` | `id, project_id FK, code, name_vi, scope, contact_name, phone, status` |
| `suppliers` | `id, tenant_id FK, code, name_vi, contact_name, phone, tax_code, status` |

#### Finance (4)
| Table | Schema |
|---|---|
| `contracts` | `id, project_id FK, code, name_vi, vendor_id, total_value, retention_pct, vat_pct, start_date, end_date, status` |
| `invoices` | `id, contract_id FK, code, amount_net, vat_amount, retention_amount, amount_gross, invoice_date, due_date, status` |
| `payment_requests` | `id, invoice_id FK, code, requested_amount, approved_amount, paid_amount, request_date, approval_date, payment_date, status, reason` |
| `payments` | `id, project_id FK, contract_id FK, code, milestone_name, planned_date, actual_date, amount, status, retention_amount, vat_amount, due_date` |

#### Master (5)
| Table | Schema |
|---|---|
| `resources` | `id, tenant_id FK, code, name_vi, type, unit, cost_per_unit` |
| `cost_codes` | `id, tenant_id FK, code, name_vi, category` |
| `work_items` | `id, project_id FK, code, name_vi, unit, quantity, cost_code_id` |
| `kpi_targets` | `id, project_id FK, kpi_code, name_vi, target_value, actual_value, unit, period_start, period_end, period_lock, owner_role` |
| `directives` | `id, tenant_id FK, project_id FK, from_user_id, to_user_id, content, issued_at, priority, status` |

#### Issues (1)
| Table | Schema |
|---|---|
| `issues` | `id, project_id FK, source_resource, source_id, severity ENUM, status ENUM, title, description, created_by, created_at, resolved_at, directive_id FK` |

#### System (5)
| Table | Schema |
|---|---|
| `notifications` | `id, tenant_id FK, user_id, project_id, issue_id, channel ENUM, delivery_status ENUM, severity, title, body, resource_type, resource_id, sent_at, created_at, read_at` |
| `audit_log` | `id, user_id, action, resource_type, resource_id, payload JSONB, created_at, ip_address` |
| `file_uploads` | `id, content_hash, original_filename, stored_filename, project_id, expected_doc_type, zone_code, multi_zone, status, ok_rows, error_rows, report_json, created_at` |
| `generic_sheets` | `id, project_id, doc_type, source_sheet, zone_id, ordinal, col_1, col_2, col_3, col_4, col_5` |
| `offline_sync_queue` | `id, client_id, resource_type, resource_id, payload JSONB, conflict ENUM, created_at, resolved_at` |

#### Vendors (1)
| Table | Schema |
|---|---|
| `vendors` | `id, tenant_id FK, code, name_vi, tax_code, contact_name, phone, status` |

### 2.3 Example: shop_drawings DDL (PG)

```js
// backend/src/db/schema-pg.js (extract)
export const shopDrawings = pgTable('shop_drawings', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  zoneId: integer('zone_id').notNull().references(() => zones.id),
  sourceSheet: text('source_sheet'),
  drawingCode: varchar('drawing_code', { length: 100 }),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  progressPct: real('progress_pct').default(0),
  status: workflowStatusEnum('status').default('DRAFT'),
  bqlL1Response: varchar('bql_l1_response', { length: 10 }),
  bqlL1Comment: text('bql_l1_comment'),
  bqlL2Response: varchar('bql_l2_response', { length: 10 }),
  bqlL2Comment: text('bql_l2_comment'),
  approvalDate: date('approval_date'),
  rejectionReason: text('rejection_reason'),
  submittedAt: timestamp('submitted_at'),
  reviewedAt: timestamp('reviewed_at'),
  approvedAt: timestamp('approved_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('shop_drawings_project_zone_code_idx').on(t.projectId, t.zoneId, t.drawingCode),
  idxStatus: index('shop_drawings_status_idx').on(t.status),
}));
```

---

## 3. SQLite schema

**File:** `backend/src/db/schema.sql` (referenced from `init.js`)

Mirrors PG schema but with SQLite syntax. Same 40+ tables, no enums (uses TEXT), no JSONB (uses TEXT). Loaded via:

```js
// backend/src/db/init.js:6-8
const schemaPath = join(__dirname, 'schema.sql');
const schema = readFileSync(schemaPath, 'utf8');
db.exec(schema);
```

**Driver switch** in `db/index.js`:
```js
const DRIVER = process.env.DB_DRIVER || 'sqlite';
// → getDb() returns DbWrapper that wraps better-sqlite3 OR pg.Pool
```

---

## 4. Backend source code pipeline

### 4.1 File map

```
backend/src/
├── index.js                    # 60+ routes, middleware chain
├── db/
│   ├── index.js                # Driver switch (SQLite/PG)
│   ├── pg.js                   # Drizzle ORM init for PG
│   ├── init.js                 # Schema loader + demo seed
│   └── schema-pg.js            # 762 lines, 40+ tables, 6 enums
├── lib/
│   ├── auth.js                 # authMiddleware
│   ├── excel.js                # detectDocType, readSheet, toInt/Text/Date
│   ├── permissions.js          # 6×14×3 matrix, getPermissions, requirePerm
│   ├── permission-middleware.js # attach req.permissions
│   ├── storage.js              # saveFile, getFilePath
│   ├── validation.js           # 3 state machines (SHOP/MAT/PAYMENT)
│   └── zone_matcher.js         # fuzzy zone name → DB code
└── services/
    ├── export.js               # XLSX export
    └── ingest/
        ├── index.js            # Dispatcher
        ├── shop_drawing.js     # Per-zone ingest
        ├── construction_schedule.js
        ├── material_supply.js
        ├── daily_report.js     # Multi-table
        ├── business_process.js
        ├── rfa_log.js
        ├── resource_directory.js
        ├── subcontractor_directory.js
        ├── project_level.js    # Multi-zone rollup
        └── generic_tabular.js  # Catch-all
```

### 4.2 Express middleware chain

```js
// backend/src/index.js:17-22
app.use(cors());
app.use(express.json());
app.use(authMiddleware);         // decodes Bearer → req.user
app.use(permissionMiddleware);   // attaches req.permissions

// Rate limiters
const authLimiter = rateLimit({ windowMs: 60*1000, max: 5 });    // 5/min
const apiLimiter = rateLimit({ windowMs: 60*1000, max: 100 });   // 100/min
const uploadLimiter = rateLimit({ windowMs: 60*60*1000, max: 20 }); // 20/hr
```

### 4.3 Upload route (entry to ingest pipeline)

```js
// backend/src/index.js: POST /api/upload
app.post('/api/upload', uploadLimiter, requireAuth, requirePerm('upload', 'create'),
  multer({ storage: multer.memoryStorage(), limits: { fileSize: 50*1024*1024 } })
    .single('file'),
  async (req, res) => {
    // 1. Multer gives req.file { buffer, originalname, size }
    // 2. Mojibake fix (Latin-1 → UTF-8 if no Vietnamese)
    // 3. detectDocType(originalName)
    // 4. saveFile(buffer, name) → hash, key
    // 5. Idempotency check (SELECT by content_hash)
    // 6. Zone extraction (regex or multiZone flag)
    // 7. ingest(filePath, docType, opts)
    // 8. UPDATE file_uploads SET status, ok_rows, report_json
    // 9. Return JSON
  });
```

---

## 5. Frontend source code pipeline

### 5.1 File map

```
frontend/src/
├── main.jsx                    # ReactDOM entry
├── App.jsx                     # Router + Providers
├── api/index.js                # API client (20+ domains)
├── components/                 # 10 shared
│   ├── Login.jsx
│   ├── HqShell.jsx             # Layout (sidebar, mobile drawer)
│   ├── FieldShell.jsx          # Mobile layout
│   ├── PieChart.jsx            # Custom SVG
│   ├── PieTooltip.jsx          # Legacy
│   ├── CursorTooltip.jsx       # Portal-based tooltip
│   ├── BellDropdown.jsx        # Notifications
│   ├── Toast.jsx               # Action feedback
│   └── Confirm.jsx             # Confirm modal
├── hq/                         # 20 HQ screens
├── field/                      # 9 Field screens
├── governance/                 # 4 Governance screens
├── styles/
│   ├── global.css              # CSS vars, dark mode
│   ├── hq.css                  # HQ layout, mobile <768px
│   ├── field.css
│   └── login.css
├── constants.js                # HEALTH, WORKFLOW, ROLES, COLORS
└── icons.jsx                   # ~30 SVG icons
```

### 5.2 React Router structure

```jsx
// frontend/src/App.jsx
<BrowserRouter>
  <Routes>
    <Route path="/login" element={<Login />} />
    <Route path="/hq" element={<RequireAuth><HqShell /></RequireAuth>}>
      <Route index element={<ProjectOverview />} />
      <Route path="control" element={<ControlCenter />} />
      <Route path="progress" element={<ProgressDetail />} />
      <Route path="shop" element={<ShopList />} />
      <Route path="materials" element={<Materials />} />
      <Route path="payment" element={<Payment />} />
      <Route path="manpower" element={<Manpower />} />
      <Route path="issues" element={<Issues />} />
      <Route path="notification" element={<NotificationCenter />} />
      <Route path="kpi" element={<ProjectKpi />} />
      <Route path="daily" element={<DailyReportView />} />
      <Route path="area" element={<AreaHierarchy />} />
    </Route>
    <Route path="/governance/*" element={...} />
    <Route path="/field/*" element={<RequireAuth><FieldShell /></RequireAuth>}>
      <Route index element={<FieldHome />} />
      <Route path="daily" element={<DailyProgress />} />
    </Route>
  </Routes>
</BrowserRouter>
```

### 5.3 API client

```js
// frontend/src/api/index.js
// ~20 API clients, each wraps fetch + token + error handling

export const auth = {
  login: (email, password) => req('POST', '/api/auth/login', { email, password }),
  me: () => req('GET', '/api/auth/me'),
  logout: () => req('POST', '/api/auth/logout'),
};

export const shop = {
  list: (params) => req('GET', '/api/projects/:id/shop-drawings', null, params),
  get: (id) => req('GET', `/api/shop-drawings/${id}`),
  transition: (id, data) => req('POST', `/api/shop-drawings/${id}/transition`, data),
};

// ... 20 more domains
```

---

## 6. Phase 1: INGEST (Excel → DB)

### 6.1 Entry: `POST /api/upload`

```js
// backend/src/index.js (line ~110-180)
app.post('/api/upload', uploadLimiter, requireAuth, requirePerm('upload', 'create'),
  upload.single('file'),
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ error: 'No file' });

      // ===== STEP 1: Mojibake fix =====
      let originalName = req.file.originalname;
      const hasVietChars = /[áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđĐ]/.test(originalName);
      if (!hasVietChars) {
        const decoded = Buffer.from(originalName, 'latin1').toString('utf8');
        if (/[áàảãạ...]/.test(decoded)) originalName = decoded;
      }

      // ===== STEP 2: Detect doc type =====
      const { key, fullPath, hash } = saveFile(req.file.buffer, originalName);
      let expectedDocType = req.body.doc_type || detectDocType(originalName.toLowerCase());
      if (expectedDocType === 'unknown') {
        // try mojibake-decoded version
        const redecoded = Buffer.from(originalName, 'latin1').toString('utf8');
        const altType = detectDocType(redecoded.toLowerCase());
        if (altType !== 'unknown') {
          expectedDocType = altType;
          originalName = redecoded;
        }
      }

      // ===== STEP 3: Idempotency check =====
      const db = getDb();
      const existing = db.prepare(
        'SELECT * FROM file_uploads WHERE content_hash = ?'
      ).get(hash);
      if (existing) {
        return res.json({
          upload_id: existing.id,
          status: existing.status,
          message: 'File already processed (idempotent)',
          content_hash: hash,
        });
      }

      // ===== STEP 4: Find or create project =====
      const projectCode = req.body.project_code || extractProjectCode(originalName) || 'BTE-WP4-HBC';
      const project = findOrCreateProject(1, projectCode);

      // ===== STEP 5: Extract zone =====
      const ingestOpts = { projectId: project.id, tenantId: 1 };
      if (['shop_drawing', 'construction_schedule', 'material_supply'].includes(expectedDocType)) {
        const m = originalName.match(/(?:Shop|TĐ|Vật tư|Vat tu|VT|MEP)\s+(.+?)\.xlsx?$/i);
        if (m) {
          const rawZone = m[1].trim();
          // Multi-zone rollup patterns
          if (/TỔNG THỂ CÁC KHU VỰC|HẠNG MỤC|TỔNG THỂ/i.test(rawZone)) {
            ingestOpts.multiZone = true;
            ingestOpts.zoneCode = null;
          } else {
            // Fuzzy zone matcher
            const zones = db.prepare('SELECT id, code FROM zones WHERE project_id = ?').all(project.id);
            const zoneId = findZoneByName(rawZone, zones);
            if (zoneId) {
              const matchedZone = zones.find(z => z.id === zoneId);
              ingestOpts.zoneCode = matchedZone ? matchedZone.code : rawZone;
            } else {
              ingestOpts.zoneCode = rawZone.toUpperCase().replace(/\s+/g, '').replace(/[-_]/g, '');
            }
          }
        }
        // Match "Tiến độ thi công tổng thể các khu vực" (no Shop/TĐ prefix)
        else if (/tổng thể|hạng mục|tổng hợp/i.test(originalName)) {
          ingestOpts.multiZone = true;
          ingestOpts.zoneCode = null;
        }
      }

      // ===== STEP 6: Save to file_uploads =====
      const uploadResult = db.prepare(`
        INSERT INTO file_uploads (content_hash, original_filename, stored_filename, project_id, expected_doc_type, zone_code, multi_zone, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, 'PROCESSING')
      `).run(hash, originalName, key, project.id, expectedDocType, ingestOpts.zoneCode || null, ingestOpts.multiZone ? 1 : 0);
      const uploadId = Number(uploadResult.lastInsertRowid);

      // ===== STEP 7: Run ingest =====
      let ingestResult;
      try {
        if (ingestOpts.multiZone) {
          ingestResult = await ingestProjectLevelFile(fullPath, project.id, expectedDocType);
        } else {
          ingestResult = await ingest(fullPath, expectedDocType, ingestOpts);
        }
        // Mark complete
        db.prepare(`
          UPDATE file_uploads SET status = ?, ok_rows = ?, error_rows = ?, report_json = ?
          WHERE id = ?
        `).run('SUCCESS', ingestResult.ok || 0, ingestResult.errors || 0, JSON.stringify(ingestResult), uploadId);
      } catch (e) {
        console.error('Ingest failed:', e);
        db.prepare(`
          UPDATE file_uploads SET status = 'FAILED', report_json = ? WHERE id = ?
        `).run(JSON.stringify({ error: e.message }), uploadId);
        return res.status(500).json({ error: e.message, upload_id: uploadId });
      }

      res.json({
        upload_id: uploadId,
        status: 'SUCCESS',
        content_hash: hash,
        project_id: project.id,
        project_code: projectCode,
        doc_type: expectedDocType,
        ...ingestResult,
      });
    } catch (e) {
      console.error('Upload error:', e);
      res.status(500).json({ error: e.message });
    }
  });
```

### 6.2 `detectDocType` (keyword-based)

```js
// backend/src/lib/excel.js:99-132
export function detectDocType(filename) {
  const f = filename.toLowerCase().replace(/\s+/g, ' ').trim();

  // Order matters: more specific patterns first
  if (f.includes('thanh toán') || f.includes('payment') || f.includes('hstt')) return 'payment_progress';
  if (f.includes('quy trình thực hiện')) return 'business_process';
  if (f.includes('thầu phụ') || f.includes('tổ đội')) return 'subcontractor_directory';
  if (f.includes('shop ') || f.startsWith('shop')) return 'shop_drawing';
  if (f.includes('vật tư') || f.includes('vat tu')) return 'material_supply';
  if (f.includes('tiến độ') || f.includes('tđ ')) return 'construction_schedule';
  if (f.includes('báo cáo công việc') || f.includes('daily')) return 'daily_report';
  if (f.includes('mcr-mm') || f.includes('rfa')) return 'rfa_log';
  if (f.includes('mcr-mpm')) return 'manpower_master_plan';
  if (f.includes('bte-mshop')) return 'shop_master';
  if (f.includes('bte-wm')) return 'work_management';
  if (f.includes('sơ đồ') && f.includes('khu vực')) return 'zone_map';
  if (f.includes('nguồn lực')) return 'resource_directory';
  if (f.includes('duyệt khác')) return 'other_approved';
  return 'unknown';
}
```

### 6.3 `findZoneByName` (fuzzy)

```js
// backend/src/lib/zone_matcher.js:24-49
const ZONE_ALIASES = {
  'boh': 'BOH', 'back of house': 'BOH',
  'bpv': 'BPV', 'bpv-1br': 'BPV-1BR', 'bpv-2br': 'BPV-2BR',
  'beach pool villa': 'BPV',
  'bsn': 'BSN', 'business center': 'BSN',
  'but': 'BUT', 'butler': 'BUT', 'bulter': 'BUT',
  'bzone': 'BZONE', 'zone b': 'BZONE',
  'beach zone': 'BZONE', 'beach': 'BZONE',
  'clu': 'CLU', 'cluster villa': 'CLU', 'cul': 'CLU',
  'gen': 'GEN', 'fitness': 'GEN', 'fitnes': 'GEN', 'gym': 'GEN',
  'hpv': 'HPV', 'hpv-1br': 'HPV-1BR', 'hpv-2br': 'HPV-2BR',
  'hạ tầng': 'INF', 'infrastructure': 'INF',
  'kid': 'KID', 'kid club': 'KID',
  'lob-spa': 'LOB-SPA', 'lobby': 'LOB-SPA', 'loby': 'LOB-SPA', 'spa': 'LOB-SPA',
  'res': 'RES', 'res-3br': 'RES-3BR', 'res-4br': 'RES-4BR',
  'resort': 'RES', 'res villas': 'RES',
  'vnr': 'VNR', 'vn res': 'VNR', 'vietnam residences': 'VNR',
};

export function findZoneByName(name, zones) {
  if (!name) return null;
  const n = name.toLowerCase().trim()
    .replace(/\s*&\s*/g, '-')
    .replace(/\s+/g, ' ')
    .replace(/-/g, ' ');

  // Try alias
  const alias = ZONE_ALIASES[n] || ZONE_ALIASES[n.replace(/\s+/g, '')];
  if (alias) {
    const z = zones.find(z => z.code === alias);
    if (z) return z.id;
  }
  // Direct match
  const direct = zones.find(z => z.code.toLowerCase() === name.toLowerCase().trim());
  if (direct) return direct.id;
  // Partial
  for (const z of zones) {
    const code = z.code.toLowerCase();
    if (n.includes(code) || code.includes(n)) return z.id;
  }
  return null;
}
```

### 6.4 `saveFile` (idempotency hash)

```js
// backend/src/lib/storage.js
import { createHash } from 'node:crypto';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const UPLOADS_DIR = join(process.cwd(), 'uploads');

export function saveFile(buffer, originalName) {
  if (!existsSync(UPLOADS_DIR)) mkdirSync(UPLOADS_DIR, { recursive: true });
  const hash = createHash('sha256').update(buffer).digest('hex');
  const ext = originalName.split('.').pop();
  const key = `${hash}_${Date.now()}.${ext}`;
  const fullPath = join(UPLOADS_DIR, key);
  writeFileSync(fullPath, buffer);
  return { key, fullPath, hash, size: buffer.length };
}
```

---

## 7. Phase 2: PROCESS (per-doc-type)

### 7.1 Dispatcher

```js
// backend/src/services/ingest/index.js
export async function ingest(filePath, docType, opts) {
  switch (docType) {
    case 'daily_report':
      return await ingestDailyReport(filePath, opts.projectId);
    case 'business_process':
      return await ingestBusinessProcess(filePath, opts.tenantId, opts.processCode || 'project_execution');
    case 'shop_drawing':
      return await ingestShopDrawing(filePath, opts.projectId, opts.zoneCode);
    case 'construction_schedule':
      return await ingestConstructionSchedule(filePath, opts.projectId, opts.zoneCode);
    case 'material_supply':
      return await ingestMaterialSupply(filePath, opts.projectId, opts.zoneCode);
    case 'subcontractor_directory':
      return await ingestSubcontractorDirectory(filePath, opts.projectId);
    case 'resource_directory':
      return await ingestResourceDirectory(filePath, opts.tenantId);
    case 'rfa_log':
      return await ingestRFALog(filePath, opts.projectId);
    case 'payment_progress':
      return await ingestGenericTabular(filePath, opts.projectId, { docType: 'payment_progress' });
    default:
      if (GENERIC_TYPES.has(docType)) {
        return await ingestGenericTabular(filePath, opts.projectId, { docType });
      }
      throw new Error(`Doc type '${docType}' not yet supported. Add an ingestor.`);
  }
}

// Special for multi-zone (rollup) files
export async function ingestProjectLevelFile(filePath, projectId, docType) {
  if (!PROJECT_LEVEL_TYPES.has(docType)) {
    throw new Error(`Doc type '${docType}' not supported for project-level ingestion`);
  }
  return await ingestProjectLevel(filePath, projectId, { docType });
}
```

### 7.2 Per-zone example: `shop_drawing.js`

```js
// backend/src/services/ingest/shop_drawing.js
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat } from '../../lib/excel.js';

export async function ingestShopDrawing(filePath, projectId, zoneCode) {
  const db = getDb();
  const report = { doc_type: 'shop_drawing', zone: zoneCode, ok: 0, errors: 0, items: [] };

  // 1. Look up zone
  const zone = db.prepare(
    'SELECT id FROM zones WHERE project_id = ? AND code = ?'
  ).get(projectId, zoneCode);
  if (!zone) {
    report.items.push({ error: `Zone '${zoneCode}' not found` });
    report.errors = 1;
    return report;
  }
  const zoneId = zone.id;

  // 2. Read all sheets
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    // Skip non-data sheets
    if (rows.length < 2) continue;

    // 3. Find data start (skip header rows)
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      const code = toText(rows[i]?.[1]) || toText(rows[i]?.[0]);
      if (code && code.trim()) { dataStart = i; break; }
    }

    // 4. Clean re-import
    db.prepare('DELETE FROM shop_drawings WHERE project_id = ? AND zone_id = ? AND source_sheet = ?')
      .run(projectId, zoneId, sheetName);

    // 5. Insert each row
    const insert = db.prepare(`
      INSERT INTO shop_drawings (project_id, zone_id, source_sheet, drawing_code, name_vi, name_en, progress_pct, status)
      VALUES (?,?,?,?,?,?,?,?)
    `);
    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const code = toText(row[1]) || toText(row[0]);
      const name = toText(row[2]) || toText(row[3]);
      const progress = toFloat(row[4]) || 0;
      if (!code && !name) continue;
      try {
        insert.run(projectId, zoneId, sheetName, code, name, null, progress, 'DRAFT');
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r, error: e.message });
      }
    }
  }
  return report;
}
```

### 7.3 Multi-zone: `project_level.js`

```js
// backend/src/services/ingest/project_level.js
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';
import { findZoneByName } from '../../lib/zone_matcher.js';

export async function ingestProjectLevel(filePath, projectId, options = {}) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: options.docType, ok: 0, errors: 0, items: [], zone_splits: {} };

  const zones = db.prepare('SELECT id, code FROM zones WHERE project_id = ?').all(projectId);

  for (const sheetName of wb.SheetNames) {
    // Skip non-data sheets
    if (sheetName.toLowerCase().includes('sơ đồ') || sheetName.toLowerCase().includes('index')) continue;

    // Extract zone from sheet name: "TĐ BPV-1BR" → "BPV-1BR"
    const m = sheetName.match(/(?:TĐ|Shop|Vật tư)\s+(.+)/i);
    if (!m) continue;
    const zoneName = m[1].trim();
    const zoneId = findZoneByName(zoneName, zones);
    if (!zoneId) {
      report.errors++;
      report.items.push({ sheet: sheetName, error: `Zone '${zoneName}' not found` });
      continue;
    }

    const rows = readSheet(filePath, sheetName);
    // Find data start
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      const stt = toText(rows[i]?.[3]) || toText(rows[i]?.[0]);
      if (stt && stt.trim()) { dataStart = i; break; }
    }

    if (options.docType === 'shop_drawing') {
      // ... similar to per-zone but using source_sheet for idempotency
    } else if (options.docType === 'construction_schedule') {
      // Cols: 3=Stt, 4=%, 5=Hạng mục, 6=Khu vực, 7=% chi tiết, 8=% thi công, 9=% hoàn thành
      db.prepare('DELETE FROM construction_schedule_items WHERE project_id = ? AND zone_id = ? AND source_sheet = ?')
        .run(projectId, zoneId, sheetName);
      const insert = db.prepare(`
        INSERT INTO construction_schedule_items
        (project_id, zone_id, source_sheet, name_vi, progress_pct, plan_start_date, plan_end_date, ordinal)
        VALUES (?,?,?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const stt = toText(row[3]) || toText(row[0]);
        const name = toText(row[5]) || toText(row[4]);
        if (!stt && !name) continue;
        if (name && /^[0-9.]+$/.test(name)) continue;  // skip numeric
        if (stt && /^(Stt|Hạng|%)\b/i.test(stt)) continue;  // skip header

        // Roman → ordinal
        let ordinal = null;
        const romanMatch = stt.match(/^([IVX]+)\.?$/);
        if (romanMatch) {
          const romanMap = { I: 1, II: 2, III: 3, IV: 4, V: 5, VI: 6, VII: 7, VIII: 8, IX: 9, X: 10 };
          ordinal = romanMap[romanMatch[1]] || null;
        } else {
          ordinal = toInt(stt);
        }
        try {
          insert.run(projectId, zoneId, sheetName, name || stt,
            toFloat(row[9]) || toFloat(row[8]) || toFloat(row[7]) || toFloat(row[2]),
            toDate(row[6]) || toDate(row[3]),
            toDate(row[10]) || toDate(row[7]),
            ordinal);
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) {
          report.errors++;
          report.items.push({ sheet: sheetName, row: r, error: e.message });
        }
      }
    }
  }
  return report;
}
```

### 7.4 Multi-table: `daily_report.js`

```js
// backend/src/services/ingest/daily_report.js (excerpt)
export async function ingestDailyReport(filePath, projectId) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'daily_report', ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    // 1. Parse report date from header
    const reportDate = parseSheetDate(sheetName);  // "22.5.2021" → "2021-05-22"
    if (!reportDate) continue;

    // 2. Insert daily_reports (1 row)
    const insertReport = db.prepare(`
      INSERT INTO daily_reports (project_id, report_date, status, total_workers)
      VALUES (?, ?, 'SUBMITTED', 0)
    `);
    const r = insertReport.run(projectId, reportDate);
    const dailyReportId = Number(r.lastInsertRowid);

    // 3. Read rows, classify into work_items/manpower/materials/acceptance
    const rows = readSheet(filePath, sheetName);
    for (const row of rows) {
      if (row.work_item_code) {
        // Insert into daily_work_items (parent + children)
        db.prepare(`
          INSERT INTO daily_work_items (daily_report_id, code, name_vi, unit, qty_planned, qty_actual, progress_pct)
          VALUES (?,?,?,?,?,?,?)
        `).run(dailyReportId, row.work_item_code, row.name, row.unit, row.qty_planned, row.qty_actual, row.progress);
        report.ok++;
      } else if (row.team_code) {
        // Insert into daily_manpower
        db.prepare(`
          INSERT INTO daily_manpower (daily_report_id, team_id, worker_count, hours_regular, hours_overtime)
          VALUES (?, (SELECT id FROM teams WHERE code = ?), ?, ?, ?)
        `).run(dailyReportId, row.team_code, row.count, row.hours, row.ot);
        report.ok++;
      } else if (row.material_code) {
        // Insert into daily_materials
        db.prepare(`
          INSERT INTO daily_materials (daily_report_id, material_code, name_vi, unit, qty_used)
          VALUES (?,?,?,?,?)
        `).run(dailyReportId, row.material_code, row.name, row.unit, row.qty);
        report.ok++;
      } else if (row.acceptance_code) {
        // Insert into daily_acceptance
        db.prepare(`
          INSERT INTO daily_acceptance (daily_report_id, item_code, name_vi, qty, acceptance_status)
          VALUES (?,?,?,?,?)
        `).run(dailyReportId, row.code, row.name, row.qty, row.status);
        report.ok++;
      }
    }
  }
  return report;
}
```

### 7.5 Generic tabular (catch-all)

```js
// backend/src/services/ingest/generic_tabular.js
export async function ingestGenericTabular(filePath, projectId, { docType }) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: docType, ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    if (rows.length < 2) continue;
    // Find data start
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      if (toInt(rows[i]?.[0])) { dataStart = i; break; }
    }
    const insert = db.prepare(`
      INSERT OR REPLACE INTO generic_sheets
      (project_id, doc_type, source_sheet, ordinal, col_1, col_2, col_3, col_4, col_5)
      VALUES (?,?,?,?,?,?,?,?,?)
    `);
    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const ordinal = toInt(row[0]);
      if (!ordinal) continue;
      try {
        insert.run(projectId, docType, sheetName, ordinal,
          toText(row[1]), toText(row[2]), toText(row[3]), toText(row[4]), toText(row[5]));
        report.ok++;
      } catch (e) { report.errors++; }
    }
  }
  return report;
}
```

---

## 8. Phase 3: VISUALIZE (FE render)

### 8.1 Component pattern (every screen follows this)

```jsx
// frontend/src/hq/ControlCenter.jsx (abbreviated)
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { projects, construction, shop, materials, payments, toast } from '../api';
import PieChart from '../components/PieChart';
import Toast from '../components/Toast';

export default function ControlCenter() {
  const nav = useNavigate();
  const [projectList, setProjectList] = useState([]);
  const [selectedProject, setSelectedProject] = useState(null);
  const [data, setData] = useState({ schedule: [], shop: [], material: [], payment: [] });
  const [loading, setLoading] = useState(true);

  // 1. Load projects on mount
  useEffect(() => {
    projects.list().then(p => {
      setProjectList(p);
      if (p.length > 0) setSelectedProject(p[0].id);
    });
  }, []);

  // 2. Load data when project changes
  useEffect(() => {
    if (!selectedProject) return;
    setLoading(true);
    Promise.all([
      construction.schedule(selectedProject),
      shop.list({ project_id: selectedProject }),
      materials.list(selectedProject),
      payments.milestones(selectedProject),
    ]).then(([schedule, shopData, materialData, paymentData]) => {
      setData({ schedule, shop: shopData, material: materialData, payment: paymentData });
    }).catch(e => toast.error('Lỗi: ' + e.message))
      .finally(() => setLoading(false));
  }, [selectedProject]);

  // 3. Aggregate in FE
  const constructionDone = data.schedule.filter(s => s.progressPct >= 100).length;
  const constructionTotal = data.schedule.length;
  const shopApproved = data.shop.filter(s => s.status === 'APPROVED').length;
  const shopTotal = data.shop.length;
  const materialCount = data.material.length;
  const paymentPaid = data.payment.filter(p => p.status === 'PAID').length;
  const paymentTotal = data.payment.length;

  // 4. Render
  return (
    <div className="control-center">
      {/* Project selector */}
      <select value={selectedProject} onChange={e => setSelectedProject(Number(e.target.value))}>
        {projectList.map(p => <option key={p.id} value={p.id}>{p.nameVi}</option>)}
      </select>

      {/* 4 pillar cards */}
      <div className="pillars">
        <div className="pillar-card" onClick={() => nav(`/hq/progress?project_id=${selectedProject}`)}>
          <PieChart data={[
            { label: 'Done', value: constructionDone, color: '#10b981' },
            { label: 'WIP', value: constructionTotal - constructionDone, color: '#f59e0b' },
          ]} />
          <div>Construction: {Math.round(constructionDone / Math.max(1, constructionTotal) * 100)}%</div>
        </div>
        {/* ... 3 more pillar cards */}
      </div>
    </div>
  );
}
```

### 8.2 PieChart (custom SVG)

```jsx
// frontend/src/components/PieChart.jsx (abbreviated)
export default function PieChart({ data, size = 80, donutHole = 0.5, onHover }) {
  const [tooltip, setTooltip] = useState(null);
  const total = data.reduce((sum, d) => sum + d.value, 0);
  let angle = 0;

  const handleMove = (e, item) => {
    setTooltip({ x: e.clientX, y: e.clientY, item });
  };

  return (
    <div className="pie-wrap" style={{ width: size, height: size, position: 'relative' }}>
      <svg viewBox="0 0 100 100" width={size} height={size}>
        {data.map((slice, i) => {
          const sliceAngle = (slice.value / total) * 360;
          const path = describeArc(50, 50, 40, angle, angle + sliceAngle);
          angle += sliceAngle;
          return (
            <path key={i} d={path} fill={slice.color}
              onMouseEnter={e => handleMove(e, slice)}
              onMouseMove={e => handleMove(e, slice)}
              onMouseLeave={() => setTooltip(null)}
            />
          );
        })}
        {/* Center text */}
        <text x="50" y="50" textAnchor="middle" dominantBaseline="middle">
          {total} items
        </text>
      </svg>
      {tooltip && (
        <CursorTooltip x={tooltip.x + 18} y={tooltip.y + 18}>
          <div className="tt-label">{tooltip.item.label}: {tooltip.item.value}</div>
        </CursorTooltip>
      )}
    </div>
  );
}
```

### 8.3 Approval flow (governance/Approval.jsx)

```jsx
// frontend/src/governance/Approval.jsx (excerpt)
import { useState, useEffect } from 'react';
import { shop, materials, payments, audit } from '../api';
import { toast, confirm } from '../components/Confirm';

export default function Approval() {
  const [pending, setPending] = useState([]);
  const [expandedId, setExpandedId] = useState(null);
  const [detailCache, setDetailCache] = useState({});

  const load = async () => {
    const [s, m, p] = await Promise.all([
      shop.list({ status: 'SUBMITTED' }),
      materials.submittals({ status: 'PENDING' }),
      payments.requests({ status: 'SUBMITTED' }),
    ]);
    setPending([...s, ...m, ...p].map(x => ({ ...x, type: x.drawingCode ? 'shop' : x.materialCode ? 'material' : 'payment' })));
  };

  useEffect(() => { load(); }, []);

  // Approve with confirm
  const approveItem = async (item) => {
    const ok = await confirm({
      title: 'Duyệt mục này?',
      message: `Bạn có chắc chắn muốn DUYỆT ${item.type} #${item.id}?`,
      confirmText: 'Duyệt',
    });
    if (!ok) return;

    try {
      if (item.type === 'shop') {
        await shop.transition(item.id, { action: 'APPROVE' });
      } else if (item.type === 'material') {
        await materials.approve(item.id);
      } else {
        await payments.approve(item.id);
      }
      toast.success('Đã duyệt');
      load();  // refresh
    } catch (e) {
      toast.error('Lỗi: ' + e.message);
    }
  };

  // Reject with reason modal
  const [rejecting, setRejecting] = useState(null);
  const [reason, setReason] = useState('');

  const rejectItem = (item) => {
    setRejecting(item);
    setReason('');
  };

  const confirmReject = async () => {
    if (!reason.trim()) {
      toast.error('Vui lòng nhập lý do');
      return;
    }
    try {
      if (rejecting.type === 'shop') {
        await shop.transition(rejecting.id, { action: 'REJECT', reason });
      } else if (rejecting.type === 'material') {
        await materials.reject(rejecting.id, { reason });
      } else {
        await payments.reject(rejecting.id, { reason });
      }
      toast.error('Đã từ chối');
      setRejecting(null);
      load();
    } catch (e) {
      toast.error('Lỗi: ' + e.message);
    }
  };

  return (
    <div>
      <h1>Approval Center</h1>
      {pending.map(item => (
        <div key={item.id} className="approval-row">
          <div className="row-summary" onClick={() => setExpandedId(expandedId === item.id ? null : item.id)}>
            <span>{item.type} #{item.id}</span>
            <span>{item.drawingCode || item.materialCode || item.code}</span>
            <span>{item.nameVi}</span>
            <span className="status-badge">{item.status}</span>
          </div>
          {expandedId === item.id && (
            <div className="row-detail-inline">
              <pre>{JSON.stringify(item, null, 2)}</pre>
              <button onClick={() => approveItem(item)}>Approve</button>
              <button onClick={() => rejectItem(item)}>Reject</button>
            </div>
          )}
        </div>
      ))}

      {rejecting && (
        <div className="modal-backdrop">
          <div className="modal">
            <h3>Từ chối {rejecting.type} #{rejecting.id}</h3>
            <textarea value={reason} onChange={e => setReason(e.target.value)} placeholder="Lý do (bắt buộc)..." />
            <button onClick={confirmReject}>Từ chối</button>
            <button onClick={() => setRejecting(null)}>Hủy</button>
          </div>
        </div>
      )}
    </div>
  );
}
```

### 8.4 Toast & Confirm (shared)

```jsx
// frontend/src/components/Toast.jsx
import { createContext, useContext, useState, useCallback } from 'react';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [items, setItems] = useState([]);

  const show = useCallback((message, type = 'info', duration = 4000) => {
    const id = Date.now() + Math.random();
    setItems(prev => [...prev.slice(-4), { id, message, type }]);
    setTimeout(() => setItems(prev => prev.filter(i => i.id !== id)), duration);
  }, []);

  return (
    <ToastContext.Provider value={{ show, success: (m) => show(m, 'success'), error: (m) => show(m, 'error') }}>
      {children}
      <div className="toast-container" style={{ position: 'fixed', bottom: 16, left: 16, zIndex: 9999 }}>
        {items.map(i => (
          <div key={i.id} className={`toast toast-${i.type}`}>{i.message}</div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export const toast = {
  show: (msg, type) => useContext(ToastContext)?.show(msg, type),
  success: (msg) => useContext(ToastContext)?.success(msg),
  error: (msg) => useContext(ToastContext)?.error(msg),
};
```

```jsx
// frontend/src/components/Confirm.jsx
import { createContext, useContext, useState, useCallback } from 'react';

const ConfirmContext = createContext(null);

export function ConfirmProvider({ children }) {
  const [dialog, setDialog] = useState(null);
  const [resolver, setResolver] = useState(null);

  const confirm = useCallback((opts) => {
    return new Promise(resolve => {
      setDialog(opts);
      setResolver(() => resolve);
    });
  }, []);

  const handle = (result) => {
    if (resolver) resolver(result);
    setDialog(null);
    setResolver(null);
  };

  return (
    <ConfirmContext.Provider value={confirm}>
      {children}
      {dialog && (
        <div className="confirm-backdrop" onClick={() => handle(false)}>
          <div className="confirm-modal" onClick={e => e.stopPropagation()}>
            <h3>{dialog.title}</h3>
            <p>{dialog.message}</p>
            <button onClick={() => handle(false)}>{dialog.cancelText || 'Hủy'}</button>
            <button onClick={() => handle(true)} className="danger">{dialog.confirmText || 'Đồng ý'}</button>
          </div>
        </div>
      )}
    </ConfirmContext.Provider>
  );
}

export const useConfirm = () => useContext(ConfirmContext);
```

---

## 9. End-to-end sequence diagram

### 9.1 Upload + Ingest (one file)

```
User          Browser              Express              SQLite/PG          Ingestor
 │               │                    │                      │                  │
 │ 1. Select xlsx│                    │                      │                  │
 │──────────────>│                    │                      │                  │
 │               │ POST /api/upload   │                      │                  │
 │               │ (multipart)        │                      │                  │
 │               │───────────────────>│                      │                  │
 │               │                    │ multer parses file   │                  │
 │               │                    │ detectDocType()      │                  │
 │               │                    │ findZoneByName()     │                  │
 │               │                    │ saveFile()           │                  │
 │               │                    │─────────────────────>│                  │
 │               │                    │   INSERT file_uploads│                  │
 │               │                    │<─────────────────────│                  │
 │               │                    │ ingest()                              │
 │               │                    │───────────────────────────────────────>│
 │               │                    │                      │   readSheet()    │
 │               │                    │                      │<─────────────────│
 │               │                    │                      │   INSERT/UPDATE  │
 │               │                    │                      │<─────────────────│
 │               │                    │                      │   return report  │
 │               │                    │<───────────────────────────────────────│
 │               │                    │ UPDATE file_uploads                    │
 │               │                    │─────────────────────────────────────>│
 │               │                    │   return JSON                         │
 │               │<───────────────────│                      │                  │
 │ 2. Toast:     │                    │                      │                  │
 │ "Upload thành │                    │                      │                  │
 │  công"        │                    │                      │                  │
 │<──────────────│                    │                      │                  │
```

### 9.2 Visualize (one screen)

```
User          Browser            HqShell.jsx           Screen.jsx           API                SQLite/PG
 │               │                    │                      │                  │                  │
 │ Open /hq      │                    │                      │                  │                  │
 │──────────────>│                    │                      │                  │                  │
 │               │ render              │                      │                  │                  │
 │               │───────────────────>│                      │                  │                  │
 │               │                    │ useEffect            │                  │                  │
 │               │                    │ GET /api/auth/me     │                  │                  │
 │               │                    │───────────────────────────────────────>│                  │
 │               │                    │<──────────────────────────────────────│                  │
 │               │                    │ GET /api/me/permissions              │                  │
 │               │                    │──────────────────────────────────────>│                  │
 │               │                    │ GET /api/projects                     │                  │
 │               │                    │──────────────────────────────────────>│                  │
 │               │                    │ <Outlet />                             │                  │
 │               │                    │──────────────────>│                  │                  │
 │               │                    │                    │ useEffect        │                  │
 │               │                    │                    │ GET /api/projects/3/construction-schedule│
 │               │                    │                    │──────────────────────────────────────>│
 │               │                    │                    │ <─────────────────────────────────────│
 │               │                    │                    │ setData(items)  │                  │
 │               │                    │                    │ render <PieChart data={...}/>        │
 │               │                    │<──────────────────│                  │                  │
 │               │                    │ render shell       │                  │                  │
 │<──────────────│                    │                    │                  │                  │
 │               │                    │                    │                  │                  │
 │ Hover pie     │                    │                    │ onMouseEnter     │                  │
 │──────────────>│                    │                    │ show tooltip     │                  │
 │               │                    │                    │                  │                  │
```

### 9.3 Approve flow

```
User          Approval.jsx           Confirm              API                SQLite         Toast
 │               │                    │                    │                  │               │
 │ Click Approve │                    │                    │                  │               │
 │──────────────>│                    │                    │                  │               │
 │               │ confirm({...})     │                    │                  │               │
 │               │───────────────────>│                    │                  │               │
 │               │                    │ show modal         │                  │               │
 │               │<───────────────────│                    │                  │               │
 │ Click "Đồng ý"│                    │                    │                  │               │
 │──────────────>│                    │                    │                  │               │
 │               │ resolve(true)      │                    │                  │               │
 │               │<───────────────────│                    │                  │               │
 │               │ POST /api/shop-drawings/123/transition                  │               │
 │               │   {action: 'APPROVE'}                                   │               │
 │               │───────────────────────────────────────>│                  │               │
 │               │                    │                    │  state machine  │               │
 │               │                    │                    │  validate       │               │
 │               │                    │                    │─────────────────>│               │
 │               │                    │                    │  UPDATE status  │               │
 │               │                    │                    │<────────────────│               │
 │               │                    │                    │  INSERT audit   │               │
 │               │                    │                    │─────────────────>│               │
 │               │<──────────────────────────────────────│                  │               │
 │               │ toast.success('Đã duyệt')                                │               │
 │               │─────────────────────────────────────────────────────────>│               │
 │               │ load() refresh     │                    │                  │               │
 │<──────────────│                    │                    │                  │               │
```

---

## 10. State machines

### 10.1 Shop Drawing

```js
// backend/src/lib/validation.js
export const SHOP_DRAWING_STATE_MACHINE = {
  DRAFT: ['SUBMITTED'],
  SUBMITTED: ['REVIEW', 'DRAFT'],     // can pull back to draft
  REVIEW: ['APPROVED', 'REJECTED'],
  APPROVED: [],                         // terminal
  REJECTED: ['DRAFT'],                  // can resubmit
};
```

### 10.2 Material Submittal

```js
export const MAT_SUBMITTAL_STATE_MACHINE = {
  DRAFT: ['PENDING'],
  PENDING: ['SUBMITTED', 'DRAFT'],
  SUBMITTED: ['APPROVED', 'REJECTED'],
  APPROVED: [],
  REJECTED: ['DRAFT'],
};
```

### 10.3 Payment

```js
export const PAYMENT_STATE_MACHINE = {
  PLANNED: ['SUBMITTED'],
  SUBMITTED: ['APPROVED', 'REJECTED'],
  APPROVED: ['PAID'],
  PAID: [],                            // terminal
  REJECTED: ['PLANNED'],
  // OVERDUE is derived from SUBMITTED + due_date < today
};
```

### 10.4 Issue

```
OPEN → IN_PROGRESS → RESOLVED → CLOSED
                                 ↓
                              ESCALATED (any time, severity=CRITICAL)
```

---

## 11. Permission matrix (6 roles × 14 modules × 3 actions)

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

```js
// backend/src/lib/permissions.js
export const PERMISSION_MATRIX = {
  admin: { /* full R/W/A on all 14 modules */ },
  ceo:   { /* R on all, R/W/A on issue/directive/notification */ },
  pm:    { /* R/W on project/shop/material/construction/daily_report/issue, R on audit, etc. */ },
  // ... etc
};

export const FULL_ACCESS_ROLES = new Set(['admin', 'ceo']);

export function getPermissions(role) {
  if (FULL_ACCESS_ROLES.has(role)) {
    return Object.fromEntries(
      Object.keys(PERMISSION_MATRIX.pm).map(mod => [mod, { read: true, write: true, approve: true }])
    );
  }
  return PERMISSION_MATRIX[role] || {};
}

export function decidePermission(user, module, action) {
  if (!user) return false;
  if (FULL_ACCESS_ROLES.has(user.role)) return true;
  return PERMISSION_MATRIX[user.role]?.[module]?.[action] === true;
}

export function requirePerm(module, action) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'Auth required' });
    if (FULL_ACCESS_ROLES.has(req.user.role)) return next();
    const allowed = PERMISSION_MATRIX[req.user.role]?.[module]?.[action];
    if (!allowed) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}
```

---

## 12. Index of all files

### Backend (25 source files)
```
backend/src/index.js                    60+ API routes, middleware chain, static serve
backend/src/db/index.js                 Driver switch (SQLite ↔ PG), DbWrapper
backend/src/db/init.js                  Schema loader, demo seed (tenant, projects, zones)
backend/src/db/pg.js                    Drizzle ORM init (pg.Pool)
backend/src/db/schema-pg.js             762 lines, 40+ tables, 6 enums (Drizzle)

backend/src/lib/auth.js                 authMiddleware (Bearer → req.user)
backend/src/lib/excel.js                detectDocType, readSheet, toInt/Text/Date/Float
backend/src/lib/permissions.js          6×14×3 matrix, requirePerm, decidePermission
backend/src/lib/permission-middleware.js attach req.permissions to every request
backend/src/lib/storage.js              saveFile (SHA-256), getFilePath
backend/src/lib/validation.js           3 state machines (SHOP/MAT/PAYMENT)
backend/src/lib/zone_matcher.js         ~80 aliases, fuzzy match

backend/src/services/export.js          XLSX export (3 endpoints)
backend/src/services/ingest/index.js    Dispatcher (10 cases)
backend/src/services/ingest/shop_drawing.js   Per-zone ingest
backend/src/services/ingest/construction_schedule.js
backend/src/services/ingest/material_supply.js
backend/src/services/ingest/daily_report.js     Multi-table
backend/src/services/ingest/business_process.js
backend/src/services/ingest/rfa_log.js
backend/src/services/ingest/resource_directory.js
backend/src/services/ingest/subcontractor_directory.js
backend/src/services/ingest/project_level.js   Multi-zone rollup
backend/src/services/ingest/generic_tabular.js Catch-all

backend/scripts/seed-test-master-business.mjs   Initial demo data
backend/scripts/seed-demo-data-enrich.mjs       vòng 7+ enrichment
backend/scripts/test-admin-full-access.mjs      Admin tests
backend/scripts/test-role-permissions.mjs       130/130 permission tests
backend/scripts/generate-test-excel.mjs         Generate xlsx
backend/scripts/init-schema.mjs                 Alternative schema init
backend/scripts/upload-test-pipeline.mjs        E2E upload test
backend/scripts/archive/                        Old migrations
```

### Frontend (50+ files)
```
frontend/src/main.jsx                   ReactDOM entry
frontend/src/App.jsx                    Router + Providers
frontend/src/api/index.js               20+ API clients (auth, projects, shop, materials, etc.)
frontend/src/constants.js               HEALTH, WORKFLOW, ROLES, COLORS
frontend/src/icons.jsx                  ~30 SVG icons (ICON.menu, ICON.bell, ...)

frontend/src/components/Login.jsx       7 quick-account buttons
frontend/src/components/HqShell.jsx      Layout shell (sidebar, mobile drawer)
frontend/src/components/FieldShell.jsx   Mobile layout (bottom tabs)
frontend/src/components/PieChart.jsx     Custom SVG pie + tooltip
frontend/src/components/PieTooltip.jsx   Legacy (deprecated)
frontend/src/components/CursorTooltip.jsx Portal-based
frontend/src/components/BellDropdown.jsx Notifications dropdown
frontend/src/components/Toast.jsx        Action feedback (toast.show, .success, .error)
frontend/src/components/Confirm.jsx      Confirm modal (useConfirm hook)

frontend/src/hq/ControlCenter.jsx       4 pillars dashboard
frontend/src/hq/ProjectOverview.jsx
frontend/src/hq/ProgressDetail.jsx
frontend/src/hq/ShopList.jsx
frontend/src/hq/Materials.jsx
frontend/src/hq/Payment.jsx
frontend/src/hq/Manpower.jsx
frontend/src/hq/Issues.jsx
frontend/src/hq/IssueDetail.jsx
frontend/src/hq/NotificationCenter.jsx
frontend/src/hq/Placeholders.jsx        Stub screens
(Plus: ProjectKpi, DailyReportView, AreaHierarchy)

frontend/src/field/FieldHome.jsx
frontend/src/field/DailyProgress.jsx
frontend/src/field/FieldStubs.jsx       Stub screens (Manpower, Shop, Photo, Review)

frontend/src/governance/Approval.jsx    Inline expand + confirm
frontend/src/governance/AuditLog.jsx
frontend/src/governance/MasterDataList.jsx
frontend/src/governance/MasterDataEdit.jsx

frontend/src/styles/global.css          20.7 KB - CSS vars, dark mode
frontend/src/styles/hq.css              13 KB - HQ layout, mobile <768px
frontend/src/styles/field.css           4.7 KB
frontend/src/styles/login.css           3.4 KB
```

### Test scripts (10 files)
```
scripts/ui-verify.mjs                   Original E2E
scripts/ui-verify-deep.mjs              Deep checks
scripts/ui-verify-tooltip.mjs           Tooltip
scripts/ui-verify-detail-nav.mjs        A→A nav
scripts/ui-verify-v6.mjs                vòng 6
scripts/ui-verify-v6-quick.mjs          Fast v6
scripts/ui-verify-v7.mjs                vòng 7 full
scripts/ui-verify-v7-mobile.mjs         Mobile only
scripts/ui-verify-v7-dashboard-approval.mjs
scripts/ui-verify-v7-pie.mjs            Pie % test
```

### Deploy / docs
```
Dockerfile                              Multi-stage build
docker-entrypoint.sh                    Container init
docs/README.md                          Index
docs/CODEBASE.md                        File/function reference
docs/ARCHITECTURE.md                    System design
docs/SETUP_FOR_CLIENT.md                Deploy guide
docs/OPERATIONS.md                      Runbook
docs/USER_GUIDE.md                      End-user
docs/DEVELOPER_GUIDE.md                 Dev workflow
demo_script.md                          30-min demo
CHECKLIST.md                            Per-vòng progress
```

---

## Appendix: SQLite vs PostgreSQL switching

### How to switch
```bash
# Use SQLite (default)
cd backend
node src/index.js

# Use PostgreSQL
DB_DRIVER=postgres DATABASE_URL=postgresql://user:pass@host:5432/db node src/index.js
```

### What changes
```js
// backend/src/db/index.js
class DbWrapper {
  prepare(sql) {
    if (this.driver === 'postgres') return new PgStatement(getPgPool(), sql);
    return new SqliteStatement(getSqlite(), sql);
  }
  // Both expose .run/.get/.all
  // PG: also has .runAsync/.getAsync/.allAsync
}
```

### Migrations
- **SQLite** → `backend/src/db/schema.sql` (auto-loaded by `init.js`)
- **PostgreSQL** → `backend/src/db/schema-pg.js` (Drizzle, run via `drizzle-kit push`)
- One-time migration SQLite → PG: `backend/scripts/archive/migrate-sqlite-to-pg.mjs`

### Performance
- **SQLite:** 1 writer, ~500 inserts/s, ideal for 1-10 users
- **PostgreSQL:** 10-100 concurrent connections, 10K+ inserts/s, ideal for 50+ users

---

**End of file.** Total: ~1500 lines. Covers: 40+ DB tables, 6 enums, 60+ API routes, 25+ backend files, 50+ frontend files, 11 ingestor functions, 3 state machines, 6 roles × 14 modules permission matrix, full sequence diagrams for upload/injest/visualize/approve.
</content>
