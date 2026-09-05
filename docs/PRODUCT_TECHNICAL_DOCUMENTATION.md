# PMO MVP — Product Technical Documentation

> **Version**: 0.3.0 · **Last updated**: 2026-09-05 · **Audience**: Engineers, technical PMs, integrators
>
> This document is the **single source of truth** for the PMO MVP. It replaces the previous collection of scattered docs (ARCHITECTURE, CODEBASE, USER_GUIDE, OPERATIONS, etc.). UML diagrams referenced from `docs/srs/`.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Architecture](#2-architecture)
3. [Data Model](#3-data-model)
4. [Backend Reference](#4-backend-reference)
5. [Frontend Reference](#5-frontend-reference)
6. [Authentication & Permissions](#6-authentication--permissions)
7. [Business Workflows](#7-business-workflows)
8. [API Reference](#8-api-reference)
9. [Excel Upload Pipeline](#9-excel-upload-pipeline)
10. [Notifications](#10-notifications)
11. [Background Jobs](#11-background-jobs)
12. [Local Development](#12-local-development)
13. [Testing](#13-testing)
14. [Deployment](#14-deployment)
15. [Operations & Troubleshooting](#15-operations--troubleshooting)
16. [Appendix: Migration History](#16-appendix-migration-history)

---

## 1. Product Overview

### 1.1 What it is

PMO MVP is a **construction project management system** built for a multi-zone construction company. It centralizes the data that was previously scattered across 9+ Excel templates per project, providing:

- **Single source of truth** for project state (construction schedule, shop drawings, materials, payments, issues, manpower)
- **Role-based dashboards** for 7 personas (admin, CEO, PM, PMO, site, procurement, accounting)
- **Approval workflows** with multi-level routing (L1-L5 for shop drawings, 4-step chain for payments)
- **SLA tracking** for material submittals (TVGS = Technical Validation & General Survey, 3-day supervisor deadline)
- **OTD KPI** (On-Time Delivery) measuring schedule adherence per project
- **Photo gallery** for daily site reports
- **Audit log** of every business action with before/after diffs

### 1.2 Who uses it

| Persona | Primary workflows | Key screens |
|---------|-------------------|-------------|
| **Admin** | System config, user management, all projects | All screens |
| **CEO** | Portfolio overview, KPI trends, approve high-value payments | Control Center, Dashboard, Payment |
| **PM** | Manage assigned project: schedule, issues, materials | Control Center, Issues, Manpower, Materials |
| **PMO** | Cross-project monitoring, KPI targets, governance | Control Center, Audit Log, KPI |
| **Site engineer** | Daily reports (manpower, photos, weather), field issues | Field Home, Daily Report, Photo Upload |
| **Procurement** | Material submittals, contracts, vendor management | Materials, Material Submittal, Master Data |
| **Accounting** | Payment chain (contract → invoice → request → payment) | Payment, Contracts, Invoices |

### 1.3 Out of scope (v0.3.0)

- Native mobile apps (web-responsive only)
- Multi-tenant SaaS (single-tenant with optional `tenant_id` for future)
- Real-time collaboration (CRDTs, presence)
- Gantt chart auto-scheduling (manual entry only)
- BIM / 3D model viewer

---

## 2. Architecture

### 2.1 System diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Browser (React SPA)                        │
│  Vite + React 19 + React Router 7                                   │
│  ─ App.jsx (Router + Auth)                                          │
│  ─ HqShell (CEO/PM/PMO)  ─ FieldShell (Site)                        │
│  ─ 12 HQ screens + 4 Field screens + 3 Governance screens           │
│  ─ 10 reusable components                                           │
└──────────────────┬──────────────────────────────────────────────────┘
                   │ HTTP (Bearer token in localStorage)
                   │ XHR/fetch
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  Express 4 Backend (Node.js 20)                      │
│  backend/src/index.js (130 LOC composition)                          │
│  ─ 22 route files in routes/                                        │
│  ─ 3 lib helpers (auth, tx, with-audit) + 6 utility libs            │
│  ─ 1 service layer (ingest/, notify.js, export.js)                  │
│  ─ static SPA serving in production (dist/)                         │
└─────┬─────────────────────┬──────────────────┬──────────────────────┘
      │                     │                  │
      ▼                     ▼                  ▼
┌─────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ PostgreSQL  │  │ Local FS         │  │ Background jobs │
│ 16 (raw pg) │  │ data/uploads/    │  │ (setInterval)   │
│ 43 tables   │  │ (Excel, photos)  │  │ TVGS escalation │
└─────────────┘  └──────────────────┘  └─────────────────┘
```

### 2.2 Tech stack rationale

| Choice | Why |
|--------|-----|
| **PostgreSQL (raw `pg`)** | Schema is mature (43 tables, 75 FKs, 105 indexes). Drizzle/Prisma add indirection without value at this size. Raw SQL gives full control over CTEs, window functions, `RETURNING`, `ON CONFLICT`. |
| **Express (not Fastify/Nest)** | Team familiarity, middleware ecosystem, simple. ~3k req/s is sufficient. |
| **React + Vite (not Next.js)** | SPA with role-based routing; no SSR needed (internal tool). Vite gives fast dev loop + small bundle. |
| **Bearer token (in-memory)** | Single-server deploy, no Redis needed. 32-char hex token stored in `Map<token, user>`. Logout invalidates immediately. |
| **multer (not busboy)** | Battle-tested, simple, sufficient for ≤20 file uploads per request. |
| **Docker Compose** | Local dev parity. One command brings up PG + backend. |

### 2.3 Request lifecycle

```
HTTP request
    │
    ▼
[1] CORS + body parsing
    │
    ▼
[2] Router matched (e.g. POST /api/projects/:id/issues)
    │
    ▼
[3] Sub-router (e.g. /api/projects/:id mounted router) ← mergeParams: true
    │
    ▼
[4] requireAuth middleware → looks up token in Map → sets req.user
    │
    ▼
[5] requireRole(...) (if applied) → checks req.user.role
    │
    ▼
[6] Handler:
    ├── db.prepare(sql).runAsync/getAsync/allAsync
    ├── withAudit(req, {...}, async (client) => {...})  ← atomic business + audit log
    │       │
    │       ├── BEGIN
    │       ├── business action
    │       ├── INSERT INTO audit_log (...)
    │       └── COMMIT (or ROLLBACK on throw)
    │
    ▼
[7] Response: res.json(...) or res.status(4xx).json({error})
    │
    ▼
[8] (if error) Error caught by tx wrapper → ROLLBACK → 500 with error message
```

### 2.4 File organization

```
backend/
├── src/
│   ├── index.js                # 130 LOC — Express composition (mounts 22 routers + serves SPA)
│   ├── lib/
│   │   ├── auth.js             # requireAuth, requireRole, currentUser, in-memory token Map
│   │   ├── tx.js               # withTransaction(client => ...) — BEGIN/COMMIT/ROLLBACK
│   │   ├── with-audit.js       # withAudit(req, {action, resourceType, ...}, fn) — atomic + audit
│   │   ├── validation.js       # validateShopDrawingTransition, validatePaymentChain, etc.
│   │   ├── permissions.js      # role → permission matrix
│   │   ├── permission-middleware.js
│   │   ├── storage.js          # file upload paths, multipart config
│   │   ├── excel.js            # xlsx parsing helpers
│   │   └── zone_matcher.js     # normalize zone names (BOH → BOH, "Back of House" → BOH)
│   ├── routes/                 # 22 files — see §4.4
│   ├── db/
│   │   ├── index.js            # Pool, prepare/upsert helpers
│   │   └── init.js             # applies drizzle migrations + creates indexes + seeds
│   └── services/
│       ├── notify.js           # notify(user, payload), notifyMany(...)
│       ├── export.js           # CSV export
│       └── ingest/             # 10 parsers — see §9
├── drizzle/                    # SQL migrations
└── scripts/
    └── pg-ctl.sh               # local PG start/stop/backup (WSL/Linux)
```

```
frontend/
└── src/
    ├── App.jsx                 # Router + Protected + 2 shells (HqShell, FieldShell)
    ├── main.jsx                # Vite entry, imports global.css
    ├── api/
    │   └── index.js            # 240 LOC — typed API client (projects, issues, daily, ...)
    ├── components/             # 10 reusable (BellDropdown, ProjectPicker, DailyReportForm, ...)
    ├── hq/                     # 12 HQ screens
    ├── field/                  # 4 Field screens
    ├── governance/             # 3 screens (Approval, Audit, MasterData)
    ├── styles/                 # design system + dark mode
    └── icons.jsx               # 50+ inline SVG icons
```

---

## 3. Data Model

### 3.1 Tables (43 total)

**Core (multi-tenant base)**
- `tenants` — top-level org (e.g. `hbg = HBG Construction`)
- `users` — login accounts, 7 roles
- `projects` — top-level project (`BTE-WP4-HBC`, `LAWRENCE-STING-2`)
- `zones` — sub-areas within a project (`BOH`, `BPV`, `HPV-1BR`, etc.)

**Construction**
- `construction_schedule_items` — Gantt rows per zone (`plan_start_date`, `actual_end_date`, `progress_pct`, `baseline_version`)
- `schedule_baselines` — versioned snapshots of plan for diff/history
- `wbs` — Work Breakdown Structure (hierarchical)
- `work_items` — individual tasks under WBS
- `area_hierarchy` — geo/area tree
- `rfa_log` — Request For Approval events

**Shop drawings**
- `shop_drawings` — drawing records with **L1-L5 approval columns** (`bql_l1_response`..`bql_l5_response`, `_date`, `_comment`), `status`, `planned_submit_date`, `actual_submit_date`

**Materials**
- `materials` — material catalog per project/zone (`material_code`, `progress_pct`, 4 request/delivery dates)
- `material_submittals` — submittal workflow with **TVGS** (`supervisor_approval_days=3`, `sla_deadline`, `supervisor_deadline`, `escalated_at`)
- `vendors` / `suppliers` / `subcontractors` / `cost_codes` / `workers` / `teams` / `resources` — master data

**Payments (4-step chain)**
- `contracts` — contract with vendor (`amount`, `retention_pct`)
- `invoices` — invoice against contract
- `payment_requests` — request to pay invoice (status: DRAFT → SUBMITTED → APPROVED → PAID)
- `payments` — actual payment record (bank ref, paid_date)

**Daily reports (field)**
- `daily_reports` — header (`report_date`, `weather_am/pm`, `prepared_by`, counters)
- `daily_work_items` — tasks done today
- `daily_manpower` — workers count by role
- `daily_materials` — materials used
- `daily_acceptance` — accepted items
- `daily_safety` — safety incidents
- `daily_recommendations` — site recommendations
- `daily_infos` — info notes
- `daily_photos` — uploaded photos (`file_path`, `caption`, `uploaded_by`)

**KPI & governance**
- `kpi_targets` — current/effective KPI targets per code (`effective_from`, `effective_to`)
- `issues` — issue tracker (`severity`, `owner_user_id`, `project_id`, `status`)
- `directives` — CEO/PMO directives on issues (`notify_to_user_ids[]`, `from_user_id`)
- `audit_log` — universal audit trail (43 columns, JSONB `before/after/context/field_changes`)
- `notifications` — in-app + email notifications (`read_at`, `severity`, `resource_type`)
- `offline_sync_queue` — field offline queue
- `generic_sheets` — catch-all for unknown doc types
- `business_processes` + `business_process_steps` — BP templates (`process_id`, `ordinal`, `name_vi`, `content_vi`)

**Ingest support**
- `file_uploads` — upload history (`original_filename`, `storage_key`, `status`, `report_json`)

### 3.2 Enums

| Enum | Values | Used in |
|------|--------|---------|
| `workflow_status` | `DRAFT, SUBMITTED, REVIEW, APPROVED, REJECTED, CLOSED, PAID` | shop_drawings, material_submittals, payment_requests |
| `master_status` | `ACTIVE, INACTIVE, CLOSED` | projects, contracts |
| `notification_channel` | `in_app, email` | notifications |
| `notification_status` | `pending, sent, delivered, failed` | notifications |
| `user_role` | `admin, ceo, pm, pmo, site, procurement, accounting, bql` | users (note: `ceo` is also `is_ceo=true`) |

### 3.3 Schema migrations

Located in `backend/drizzle/`:

| File | Purpose |
|------|---------|
| `0000_naive_nick_fury.sql` | Base schema (Drizzle-generated, 40+ tables) |
| `9998_align_schema_with_routes.sql` | Patches: add `projects.pm_user_id`, `material_submittals.escalated_at`, drop NOT NULL on `materials.zone_id`, create `daily_photos` table + indexes, create `directives` table, create unique indexes for `db.upsert()` |
| `9999_add_issues_table.sql` | Creates `issues` + `daily_infos` (not in initial Drizzle schema) |

**Why `9998` and `9999`?** Convention: regular migrations are `0000-9997`, patches are `9998+`. Patches run after the base, regardless of file order. See `db/init.js`.

### 3.4 Multi-tenant readiness

Every business table has `tenant_id` (or inherits via FK). Currently single-tenant (all `tenant_id = 1` = `hbg`). Code is multi-tenant-ready: `req.user.tenant_id` propagates through queries.

---

## 4. Backend Reference

### 4.1 Composition (`src/index.js`)

130 LOC. Pure composition layer. Mounts 22 routers + 3 middlewares + serves SPA in production.

```js
import express from 'express';
import cors from 'cors';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

// 22 routers imported + mounted
app.use('/api/auth', authRouter);
app.use('/api/me', meRouter);
app.use('/api/projects', projectsRouter);
app.use('/api/projects/:id/kpi-targets', kpiTargetsRouter);
app.use('/api/projects/:id/otd', otdRouter);
// ... 17 more

// Static SPA (production only)
app.use(express.static(join(__dirname, '..', '..', 'frontend', 'dist')));
app.get('*', (req, res) => res.sendFile(join(__dirname, '..', '..', 'frontend', 'dist', 'index.html')));
```

### 4.2 Lib helpers

#### `lib/auth.js` (115 LOC)

```js
export function requireAuth(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  const user = token ? tokenMap.get(token) : null;
  if (!user) return res.status(401).json({ error: 'Unauthorized' });
  req.user = user;
  req.token = token;
  next();
}

export function requireRole(...allowed) {
  return (req, res, next) => {
    if (!allowed.includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}
```

**`tokenMap`** is in-memory `Map<token, user>`. Cleared on process restart. Sufficient for single-server deploy.

#### `lib/tx.js` (49 LOC)

```js
export async function withTransaction(fn) {
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}
```

#### `lib/with-audit.js` (49 LOC)

Combines business action + audit log in one transaction. **Use this for any state-changing operation.**

```js
export async function withAudit(req, { action, resourceType, resourceId, before, after, context, fieldChanges, note }, fn) {
  return withTransaction(async (client) => {
    const result = await fn(client);
    await client.query(
      `INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, before, after, context, field_changes, note, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, now())`,
      [req.user.tenant_id, req.user.id, req.user.name, action, resourceType, resourceId,
       JSON.stringify(before || null), JSON.stringify(after || null), JSON.stringify(context || null),
       JSON.stringify(fieldChanges || null), note]
    );
    return result;
  });
}
```

#### `lib/db/index.js` — DB abstraction

```js
const stmt = db.prepare('SELECT * FROM users WHERE id = $1');
const user = await stmt.getAsync(42);         // first row or undefined
const users = await stmt.allAsync(42);        // rows[]
const result = await stmt.runAsync(42, 'x');  // { lastInsertRowid, changes }

const result = await db.upsert('projects', {
  conflictCols: ['tenant_id', 'code'],
  row: { tenant_id: 1, code: 'X', name_vi: 'X' }
});
// → INSERT ... ON CONFLICT (tenant_id, code) DO UPDATE SET ...
```

**Helper: `convertSql`**. Detects `?` placeholders and converts to `$1, $2, ...` for `pg`. Skips if SQL already has `$N` (avoids double-conversion).

### 4.3 Database (`src/db/`)

- **`index.js`** — Pool config, `prepare()`, `upsert()`, transaction
- **`init.js`** — apply migrations, create unique indexes, seed tenant/users/projects/zones

### 4.4 Routes (22 files)

| File | Mount | Endpoints | Purpose |
|------|-------|-----------|---------|
| `auth.js` | `/api/auth` | `POST /login`, `POST /logout`, `GET /me` | Login (returns 32-char token), logout, current user |
| `me.js` | `/api/me` | `GET /`, `GET /permissions`, `GET /notification-prefs`, `PUT /notification-prefs` | Self-service: whoami, my permissions, notification preferences |
| `projects.js` | `/api/projects` | 14 endpoints | List, close/revoke, zones, materials, contracts, payments, daily-reports, issues, construction-schedule, shop-drawings, material-breakdown, submittals (overdue/pending-supervisor), schedule-baselines |
| `kpi.js` | `/api/kpis` | `GET /`, `POST /`, `GET /:kpi_code/history` | KPI current values + history |
| `kpi-targets.js` | `/api/projects/:id/kpi-targets` | `PUT /:id` | Update target (auto-creates history row) |
| `issues.js` | `/api/issues` | `GET /`, `GET /:id`, `POST /` | Issue list, detail, create |
| `audit.js` | `/api/audit` | `GET /`, `GET /export` | Audit log with filters, CSV export |
| `shop.js` | `/api/shop-drawings` | 8 endpoints | Create, list, get, patch, transition, **L1-L5 approve-level**, **approval-state**, **history** |
| `material-submittals.js` | `/api/material-submittals` | 6 endpoints | CRUD + submit/reject/approve |
| `payment.js` | `/api/payment*` | 8 endpoints | 4-step chain: contracts → invoices → payment_requests → payments |
| `notifications.js` | `/api/notifications` | 4 endpoints | List (with `unread=1` filter), mark read, mark all read, admin create |
| `directives.js` | `/api/directives` | `GET /`, `POST /` | CEO/PMO directives on issues |
| `materials.js` | `/api/materials` | `POST /` | Create material |
| `daily.js` | `/api/daily*` | 6 endpoints | Daily reports CRUD, add manpower, **upload photos (multipart)**, **list photos**, **manpower rollup** |
| `sync.js` | `/api/sync` | `GET /queue`, `POST /resolve` | Offline queue (field) |
| `dashboard.js` | `/api/dashboard` | `GET /`, `GET /portfolio-kpi` | Tenant portrait + cross-project KPI |
| `master-data.js` | `/api/master-data/:resource` | `GET /:resource`, `POST /:resource` | Generic CRUD for vendors/subcontractors/suppliers/workers/teams/cost_codes |
| `business-process.js` | `/api/business-process/:code` | `GET /:code` | BP template by code |
| `upload.js` | `/api/upload`, `/api/uploads` | `POST /` (multipart), `GET /` | Upload Excel, list uploads |
| `wizard.js` | `/api/wizard*` | (see code) | 4-step Excel ingest wizard (analyze → map → commit → report) |
| `otd.js` | `/api/projects/:id/otd` | `GET /?grace_days=0` | OTD KPI: on-time / late / total / by_zone / 6mo trend |
| `jobs.js` | `/api/jobs` | `POST /escalate-tvgs`, `GET /escalate-tvgs/status` | TVGS escalation trigger + status |

**Note**: Many routes use `Router({ mergeParams: true })` because they're mounted under `/api/projects/:id/...` and need `req.params.id` to be visible inside the sub-router. **This is the #1 source of "missing param" bugs** — never forget it.

### 4.5 Services

#### `services/notify.js`

```js
export async function notify(req, userId, { title, body, severity, resourceType, resourceId, projectId, issueId }) {
  await db.prepare(`
    INSERT INTO notifications (tenant_id, user_id, project_id, issue_id, channel, delivery_status, severity, title, body, resource_type, resource_id)
    VALUES ($1, $2, $3, $4, 'in_app', 'pending', $5, $6, $7, $8, $9)
  `).runAsync(req.user.tenant_id, userId, projectId || null, issueId || null,
              severity || 'INFO', title, body || null, resourceType || null, resourceId || null);
}
```

Note: **no `link` or `is_read` columns**. Use `read_at IS NULL` for unread check, `resource_type` + `resource_id` for navigation target.

#### `services/ingest/` (10 parsers)

| File | Doc type | Source sheets |
|------|----------|---------------|
| `shop_drawing.js` | Shop drawings | "Shop drawing", "Drawing" |
| `construction_schedule.js` | Construction schedule | Multi-zone, multi-sheet |
| `material_supply.js` | Material supply | Material sheets |
| `subcontractor_directory.js` | Subcontractor list | Subcontractor sheets |
| `resource_directory.js` | Workers/machinery | Resource sheets |
| `daily_report.js` | Daily report (work items, manpower, materials, photos) | 1 sheet per report |
| `rfa_log.js` | RFA log | RFA sheets |
| `business_process.js` | BP templates | BP sheets |
| `project_level.js` | Project meta | Project info sheet |
| `generic_tabular.js` | Catch-all | Any other sheet |

Each parser: `parseSheet(sheet, ctx) → { rows[], errors[] }` → `commit(rows, ctx) → { inserted, updated, skipped }`.

---

## 5. Frontend Reference

### 5.1 Entry & routing

`App.jsx`:
- `BrowserRouter` + `ConfirmProvider` + style injection
- `<Protected>` wraps `<HqShell>` or `<FieldShell>` based on role
- Routes:
  - `/login` (public)
  - `/hq/*` — HQ shell (CEO, PM, PMO, admin, procurement, accounting)
  - `/field/*` — Field shell (site)
  - `/governance/*` — Audit + MasterData
  - `/audit` — Audit log
  - `/otd` — OTD KPI page

### 5.2 Shells

#### `HqShell.jsx` (HQ + admin + procurement + accounting)
- Sidebar nav (collapsible)
- Header with BellDropdown + theme toggle
- Outlet for child routes

#### `FieldShell.jsx` (site engineer)
- Bottom tab bar (mobile-first)
- Top bar with project selector + BellDropdown
- Outlet for field pages

### 5.3 HQ screens (12)

| File | Route | Purpose |
|------|-------|---------|
| `ControlCenter.jsx` | `/hq` | 4-pillar dashboard (Construction / Shop / Material / Payment) with pie chart + hover tooltip |
| `ProjectOverview.jsx` | `/hq/overview/:projectId` | Single project: KPIs, schedule, contacts |
| `ProgressDetail.jsx` | `/hq/progress/:projectId` | Gantt chart view |
| `ShopList.jsx` | `/hq/shop` | Shop drawing list + L1-L5 approve UI |
| `Issues.jsx` | `/hq/issues` | Issue list with filters |
| `IssueDetail.jsx` | `/hq/issues/:id` | Issue detail + directive form |
| `Materials.jsx` | `/hq/materials` | Material catalog |
| `Manpower.jsx` | `/hq/manpower` | Manpower rollup (4 tabs: Workers/Machinery/Teams/Suppliers) |
| `Payment.jsx` | `/hq/payment` | 4-step payment chain UI |
| `OTDPage.jsx` | `/hq/otd` | OTD KPI (on-time / late / by_zone / trend) |
| `NotificationCenter.jsx` | `/hq/notifications` | All notifications with filters |
| `Placeholders.jsx` | `/hq/*` | Stub pages for nav items not yet built |

### 5.4 Field screens (4)

| File | Route | Purpose |
|------|-------|---------|
| `FieldHome.jsx` | `/field` | Field home with shortcuts |
| `DailyProgress.jsx` | `/field/progress` | Daily progress entry |
| `DailyReportForm.jsx` | `/field/daily-report` | **NEW** — full daily report with photo upload + manpower |
| `FieldStubs.jsx` | `/field/*` | Stubs for materials / shopdrawing / issues / sync |

### 5.5 Governance screens (3)

| File | Route | Purpose |
|------|-------|---------|
| `AuditLog.jsx` | `/audit` | Audit log with filters + CSV export |
| `MasterDataList.jsx` | `/governance/master-data` | List vendors/subcontractors/... |
| `MasterDataEdit.jsx` | `/governance/master-data/:resource/:id?` | Edit form |
| `Approval.jsx` | `/hq/approval` | Pending approvals hub |

### 5.6 Reusable components (10)

| File | Purpose |
|------|---------|
| `Login.jsx` | Email/password + 7 demo chips |
| `BellDropdown.jsx` | Notification bell with unread badge + panel |
| `ProjectPicker.jsx` | Reusable project selector (replaces `<select>`) |
| `ProjectOverview.jsx` | (also a screen) |
| `PieChart.jsx` + `PieTooltip.jsx` | Custom SVG pie chart |
| `CursorTooltip.jsx` | Hover tooltip |
| `Toast.jsx` | Toast notifications |
| `Confirm.jsx` | Confirm dialog |
| `UploadWizard.jsx` | 4-step Excel upload wizard |
| `DailyReportForm.jsx` | Daily report form with photo upload |
| `SubmittalHistory.jsx` | Modal showing audit history of a submittal |

### 5.7 API client (`api/index.js`, 240 LOC)

Typed-ish API client. Example:

```js
export const projects = {
  list: () => request('/projects'),
  get: (id) => request(`/projects/${id}`),
  close: (id) => request(`/projects/${id}/close`, { method: 'POST' }),
  issues: (id) => request(`/projects/${id}/issues`),
  createIssue: (id, data) => request(`/projects/${id}/issues`, { method: 'POST', body: JSON.stringify(data) }),
  // ...
};

export const daily = {
  reports: (projectId) => request(`/projects/${projectId}/daily-reports`),
  create: (projectId, data) => request(`/projects/${projectId}/daily-reports`, { method: 'POST', ... }),
  addManpower: (id, data) => request(`/daily-reports/${id}/manpower`, { method: 'POST', ... }),
  listPhotos: (id) => request(`/daily-reports/${id}/photos`),
  uploadPhotos: (id, files) => { /* FormData */ },
};

export const materialSubmittals = {
  list: (params) => request(`/material-submittals${params ? '?' + new URLSearchParams(params) : ''}`),
  get: (id) => request(`/material-submittals/${id}`),
  submit: (id) => request(`/material-submittals/${id}/submit`, { method: 'POST' }),
  approve: (id) => request(`/material-submittals/${id}/approve`, { method: 'POST' }),
  reject: (id, reason) => request(`/material-submittals/${id}/reject`, { method: 'POST', body: JSON.stringify({ reason }) }),
  history: (id) => request(`/material-submittals/${id}/history`),
};

export const otd = {
  get: (projectId, graceDays = 0) => request(`/projects/${projectId}/otd?grace_days=${graceDays}`),
};
```

Auto-includes `Authorization: Bearer <token>` from `localStorage.pmo_token`.

---

## 6. Authentication & Permissions

### 6.1 Login flow

1. `POST /api/auth/login { email, password }` → `users WHERE email = ?` → check `is_ceo OR role` (dev mode: no password hash check)
2. Generate 32-char hex token
3. `tokenMap.set(token, { id, email, name, role, is_ceo, tenant_id })`
4. Return `{ token, user: { id, email, name, role, is_ceo, tenant_id } }`
5. Frontend stores in `localStorage.pmo_token`
6. Subsequent requests: `Authorization: Bearer <token>`
7. `POST /api/auth/logout` → `tokenMap.delete(token)`

### 6.2 7 demo accounts

| Email | Password | Role | `is_ceo` |
|-------|----------|------|----------|
| `admin@hbg.com` | `admin123` | `admin` | false |
| `ceo@hbg.com` | `ceo123` | `ceo` | true |
| `pm@hbg.com` | `pm123` | `pm` | false |
| `pmo@hbg.com` | `pmo123` | `pmo` | false |
| `site@hbg.com` | `site123` | `site` | false |
| `procurement@hbg.com` | `proc123` | `procurement` | false |
| `accounting@hbg.com` | `acc123` | `accounting` | false |

**Note**: as of v0.3.0, passwords are NOT hashed (dev-only). All accounts use the plain password. **MUST be fixed before production deploy.**

### 6.3 Permission matrix

| Action | admin | ceo | pm | pmo | site | procurement | accounting |
|--------|:-----:|:---:|:--:|:---:|:----:|:-----------:|:----------:|
| View all projects | ✅ | ✅ | own | ✅ | assigned | assigned | ✅ |
| Close project | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Edit KPI target | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Create issue | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Resolve issue | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Create directive | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Approve shop L1-L5 | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Submit material submittal | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Approve material submittal | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ |
| Create contract | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Approve payment request | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Record payment | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Upload Excel | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| View audit log | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Field daily report | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |

### 6.4 Middleware

```js
// Apply to route
router.use(requireAuth);              // all routes need auth
router.post('/critical', requireRole('admin', 'ceo'), handler);  // role check
```

---

## 7. Business Workflows

### 7.1 Shop Drawing L1-L5 Approval

**State machine**:

```
DRAFT
  ├─ POST /transition { to_status: 'SUBMITTED' } → SUBMITTED
  │     ├─ POST /approve-level { level: 1, response: 'P' } → next level (or APPROVED if max)
  │     │     ├─ 'P' (Pass) → status = 'IN_REVIEW_L<n+1>' or 'APPROVED' (if n === MAX_LEVEL)
  │     │     ├─ 'F' (Fail) → status = 'REJECTED' → can be reverted to DRAFT
  │     │     └─ 'C' (Comment) → status = 'IN_REVIEW_L<n>' (awaiting more)
  │     └─ POST /approve-level { level: 1, response: 'F' } → REJECTED
  └─ PATCH (only in DRAFT or REJECTED) → edit fields

REJECTED
  └─ POST /transition { to_status: 'DRAFT' } → DRAFT (re-edit)
```

**MAX_LEVEL = 5** (configurable in `routes/shop.js`). Schema uses `bql_l1_response`..`bql_l5_response`, `_date`, `_comment` columns.

**GET /:id/approval-state** returns:
```json
{
  "current_level": 2,
  "is_fully_approved": false,
  "levels": {
    "1": { "response": "P", "date": "2026-09-01", "comment": "OK", "approver": "pm@hbg.com" },
    "2": { "response": "P", "date": "2026-09-03", "comment": "OK", "approver": "pmo@hbg.com" },
    "3": null,
    "4": null,
    "5": null
  }
}
```

### 7.2 Material Submittal + TVGS

**Flow**:
1. Procurement creates `material_submittal` (status: `DRAFT`)
2. `POST /:id/submit` → status: `REVIEW`, set `submit_date = now()`, compute `sla_deadline = submit_date + sla_days` (default 7)
3. **TVGS**: supervisor must approve within `supervisor_approval_days` (default 3)
   - `supervisor_deadline = submit_date + 3 days`
   - If `supervisor_deadline < today` → escalate (see §11)
4. `POST /:id/approve` → status: `APPROVED`, set `approved_by`, `approved_date`
5. `POST /:id/reject { reason }` → status: `REJECTED`, set `rejected_by`, `rejected_at`, `rejected_reason`

**Overdue detection**: `status NOT IN ('APPROVED', 'CLOSED') AND (sla_deadline < today OR supervisor_deadline < today)`.

### 7.3 Payment 4-step chain

```
CONTRACT (vendor agreement, amount, retention_pct)
  └─ POST /:id/invoices { amount, due_date } → INVOICE
       └─ POST /:id/payment-requests { amount, retention_amount, due_date } → PAYMENT_REQUEST (status: DRAFT → SUBMITTED)
            └─ PUT /:id { status: 'APPROVED' } (role: admin/ceo/accounting) → APPROVED
                 └─ POST /:id/payments { bank_ref, paid_date, amount } → PAYMENT
```

**Strict**: cannot skip steps. `payment-requests` requires `invoices.status = 'SUBMITTED'`. `payments` requires `payment_requests.status = 'APPROVED'`.

### 7.4 OTD (On-Time Delivery)

**Definition**: `actual_end_date ≤ planned_end_date + grace_days`

**API**: `GET /api/projects/:id/otd?grace_days=0`

**Response**:
```json
{
  "project_id": 1,
  "grace_days": 0,
  "total_items": 47,
  "on_time": 32,
  "late": 15,
  "otd_pct": 68.1,
  "by_zone": [
    { "zone_id": 1, "zone_code": "BOH", "total": 8, "on_time": 6, "otd_pct": 75 },
    ...
  ],
  "trend_6mo": [
    { "month": "2026-04", "total": 5, "on_time": 4, "otd_pct": 80 },
    ...
  ]
}
```

**Threshold (UI color)**: ≥90% green, ≥70% yellow, <70% red.

### 7.5 Issues + Directives

- **Issue**: created with `severity` (NORMAL/HIGH/CRITICAL), `owner_user_id`
- **Directive**: CEO/PMO can attach a directive to an issue, which notifies specific users (`notify_to_user_ids[]`)
- **Status flow**: `OPEN → IN_PROGRESS → RESOLVED → CLOSED`

### 7.6 Daily Report (field)

- `POST /api/projects/:id/daily-reports` (header: date, weather_am/pm)
- `POST /api/daily-reports/:id/manpower { role_code, headcount }` (add multiple)
- `POST /api/daily-reports/:id/photos` (multipart, ≤20 files)
- Counters auto-incremented (`work_items_count`, `manpower_count`, etc.)

---

## 8. API Reference

**Base URL**: `http://localhost:3000/api` (or your server's URL)

**Auth header**: `Authorization: Bearer <token>` (required for all except `/auth/login` and `/health`)

### 8.1 Auth

```http
POST /auth/login
Body: { email: "admin@hbg.com", password: "admin123" }
→ 200 { token: "abc123...", user: { id, email, name, role, is_ceo, tenant_id } }
→ 401 { error: "Invalid credentials" }

POST /auth/logout              (auth)
→ 200 { ok: true }

GET /auth/me                   (auth) → user object
```

### 8.2 Me

```http
GET /me                        (auth) → { id, email, name, role, is_ceo, tenant_id }
GET /me/permissions            (auth) → { role, matrix: {...} }
GET /me/notification-prefs     (auth) → { email: true, in_app: true }
PUT /me/notification-prefs     (auth) Body: { email, in_app }
```

### 8.3 Projects

```http
GET    /projects                                      → [{ id, code, name_vi, name_en, status, ... }]
GET    /projects/:id                                  → full project + zones
POST   /projects/:id/close                            (admin/ceo) → close project
POST   /projects/:id/revoke-close                     (admin/ceo) → reopen
GET    /projects/:id/zones                            → [{ id, code, name_vi, name_en }]
GET    /projects/:id/construction-schedule            → ordered by plan_start_date
GET    /projects/:id/shop-drawings                    → list
GET    /projects/:id/materials                       → list
GET    /projects/:id/contracts                       → list
GET    /projects/:id/payments                        → list
GET    /projects/:id/daily-reports                   → list
GET    /projects/:id/issues                          → list
POST   /projects/:id/issues                          → create issue
GET    /projects/:id/material-breakdown              → [{ zone_id, count }]
GET    /projects/:id/material-submittals/overdue     → list
GET    /projects/:id/material-submittals/pending-supervisor → list
GET    /projects/:id/schedule-baselines              → versions
POST   /projects/:id/schedule-baselines              → create baseline
GET    /projects/:id/schedule-baselines/:version     → get baseline
```

### 8.4 OTD

```http
GET /projects/:id/otd?grace_days=0
→ { project_id, grace_days, total_items, on_time, late, otd_pct, by_zone[], trend_6mo[] }
```

### 8.5 Shop Drawings

```http
POST   /shop-drawings                    → create
GET    /shop-drawings                    → list
GET    /shop-drawings/:id                → detail (with zone_code, history_count)
PATCH  /shop-drawings/:id                → edit (only DRAFT/REJECTED)
POST   /shop-drawings/:id/transition     Body: { to_status, rejection_reason? } → state transition
POST   /shop-drawings/:id/approve-level  (admin/ceo/pm/pmo) Body: { level: 1-5, response: 'P'|'F'|'C', comment? }
GET    /shop-drawings/:id/approval-state → current state per level
GET    /shop-drawings/:id/history        → audit log entries
```

### 8.6 Material Submittals

```http
POST   /material-submittals                 → create (procurement/pm)
GET    /material-submittals?project_id=&status=  → list with filters
GET    /material-submittals/:id             → detail
POST   /material-submittals/:id/submit      → move to REVIEW
POST   /material-submittals/:id/approve     → move to APPROVED
POST   /material-submittals/:id/reject      Body: { reason } → REJECTED
```

### 8.7 Payment chain

```http
POST /payment/projects/:id/contracts          Body: { vendor_id, amount, retention_pct, ... }
GET  /payment/invoices/:id/payment-requests
POST /payment/invoices/:id/payment-requests   Body: { amount, retention_amount, due_date }
GET  /payment/payment-requests/:id
PUT  /payment/payment-requests/:id            (admin/ceo/accounting) Body: { status: 'APPROVED', notes? }
POST /payment/payment-requests/:id/payments   (admin/ceo/accounting) Body: { bank_ref, paid_date, amount }
```

### 8.8 Notifications

```http
GET    /notifications?unread=1&limit=50
POST   /notifications/:id/read                → mark 1 as read
POST   /notifications/mark-all-read           → mark all as read
POST   /notifications                         (admin) Body: { user_ids: [...], title, body, severity }
```

### 8.9 KPI

```http
GET    /kpis                                  → current values per code
POST   /kpis                                  Body: { kpi_code, value, period }
GET    /kpis/:kpi_code/history                → all values over time
PUT    /projects/:id/kpi-targets/:id          Body: { value, note? } → updates + creates history
```

### 8.10 Daily Reports

```http
GET    /projects/:id/daily-reports            → list
POST   /projects/:id/daily-reports            Body: { report_date, weather_am, weather_pm, source_sheet_name }
GET    /daily-reports/:id/full                → header + work_items + manpower + materials + photos
POST   /daily-reports/:id/manpower            Body: { role_code, role_name_vi, headcount, notes }
POST   /daily-reports/:id/photos              (multipart, field name: photos) → uploads ≤20 files
GET    /daily-reports/:id/photos              → list photos
GET    /manpower/rollup?from=&to=&group_by=week|month  → cross-project rollup
```

### 8.11 Issues & Directives

```http
GET    /issues?project_id=&status=&severity=
GET    /issues/:id
POST   /issues                                Body: { project_id, zone_id, title, description, severity, owner_user_id }

GET    /directives
POST   /directives                            (admin/ceo/pmo) Body: { issue_id, content, notify_to_user_ids[] }
```

### 8.12 Audit

```http
GET    /audit?resource_type=&resource_id=&user_id=&action=&from=&to=
GET    /audit/export                          → CSV
```

### 8.13 Dashboard

```http
GET /dashboard                                → tenant portrait { projects_active, materials_pending, ... }
GET /dashboard/portfolio-kpi                  → cross-project rollup
```

### 8.14 Upload wizard

```http
POST /upload                                  (multipart, field: file) → { id, storage_key, status: 'PENDING' }
GET  /uploads                                 → list (last 100)

POST /wizard/:uploadId/analyze                → parse Excel, detect doc type
POST /wizard/:uploadId/map                    Body: { mappings: [...] }
POST /wizard/:uploadId/commit                 → execute ingest
GET  /wizard/:uploadId/report                 → { inserted, updated, skipped, errors }
```

### 8.15 Jobs (background)

```http
POST /jobs/escalate-tvgs                      → trigger escalation now
GET  /jobs/escalate-tvgs/status               → { last_run, escalated_count }
```

### 8.16 Master data (generic)

```http
GET  /master-data/vendors                      → vendors list
POST /master-data/vendors                      → create
# Same for: subcontractors, suppliers, workers, teams, cost_codes
```

### 8.17 Business process

```http
GET /business-process/:code                    → { ...process, steps[] }
```

---

## 9. Excel Upload Pipeline

### 9.1 Supported doc types

| Doc type | Sheets expected | Parser |
|----------|-----------------|--------|
| Shop drawing | 1+ sheets named "Shop drawing" / "Drawing" | `shop_drawing.js` |
| Construction schedule | Multi-zone, multi-sheet | `construction_schedule.js` |
| Material supply | Material sheets | `material_supply.js` |
| Subcontractor directory | Subcontractor sheets | `subcontractor_directory.js` |
| Resource directory | Resource sheets | `resource_directory.js` |
| Daily report | 1 sheet per report | `daily_report.js` |
| RFA log | RFA sheets | `rfa_log.js` |
| Business process | BP sheets | `business_process.js` |
| Project level | Project info | `project_level.js` |
| Generic tabular | Anything else | `generic_tabular.js` |

### 9.2 Wizard flow

1. **Upload** (`POST /upload`): Excel file → multer stores at `data/uploads/<storage_key>` → DB row in `file_uploads` (status: PENDING)
2. **Analyze** (`POST /wizard/:id/analyze`): parse each sheet → detect doc type via header pattern match → for each, run parser → return `{ sheets: [{ name, detected_type, rows, errors }] }`
3. **Map** (`POST /wizard/:id/map`): user confirms column mappings if needed
4. **Commit** (`POST /wizard/:id/commit`): for each sheet, call `commit(rows, ctx)` → `db.upsert()` per row → atomic per sheet
5. **Report** (`GET /wizard/:id/report`): `{ inserted, updated, skipped, errors[] }`

### 9.3 Idempotency

`db.upsert()` uses unique constraints. Re-uploading same Excel updates existing rows (no duplicates). Required unique indexes:

```sql
CREATE UNIQUE INDEX construction_schedule_items_uq ON construction_schedule_items (project_id, zone_id, source_sheet, ordinal);
CREATE UNIQUE INDEX materials_project_zone_code_uq ON materials (project_id, zone_id, material_code);
CREATE UNIQUE INDEX business_process_steps_process_ord_uq ON business_process_steps (process_id, ordinal);
-- ...
```

### 9.4 Error handling

Per-row errors are collected, not thrown. Wizard report shows:
- `errors[]` with `{ row, column, message }`
- Counters: `inserted` / `updated` / `skipped`
- Valid rows still committed (unless `abort_on_error=true`)

---

## 10. Notifications

### 10.1 Schema (real)

```sql
CREATE TABLE notifications (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  project_id INTEGER,
  issue_id INTEGER,
  channel notification_channel NOT NULL,         -- 'in_app' | 'email'
  delivery_status notification_status NOT NULL,   -- 'pending' | 'sent' | 'delivered' | 'failed'
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  severity VARCHAR(20) NOT NULL,                  -- 'info' | 'warning' | 'critical'
  title TEXT NOT NULL,
  body TEXT,
  resource_type VARCHAR(50),                      -- 'issue' | 'shop_drawing' | 'material_submittal' | ...
  resource_id INTEGER,
  read_at TIMESTAMP,                              -- NULL = unread
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
```

**No `link` or `is_read` columns** — use `read_at IS NULL` and `resource_type` + `resource_id` for navigation.

### 10.2 Sending

```js
import { notify, notifyMany } from './services/notify.js';

await notify(req, userId, {
  title: 'Submittal rejected',
  body: 'Reason: ...',
  severity: 'warning',
  resourceType: 'material_submittal',
  resourceId: 42,
  projectId: 1,
});

await notifyMany(req, [userId1, userId2], { ... });
```

### 10.3 Receiving (UI)

`BellDropdown.jsx` polls `/api/notifications` every 30s, shows unread badge. Click → mark read + navigate to `resource_type` URL:

- `issue` → `/hq/issues?item={resource_id}`
- `directive` → `/hq/issues?item={issue_id}`
- `shop_drawing` → `/hq/shop?drawing={resource_id}`

---

## 11. Background Jobs

### 11.1 TVGS Auto-Escalation

Runs every 1 hour (setInterval in `src/index.js`, skipped if `NODE_ENV=test`).

```js
setInterval(async () => {
  if (process.env.NODE_ENV === 'test') return;
  await escalateOverdueTvgs();
}, 60 * 60 * 1000);
```

**Logic**:
1. Find submittals: `status NOT IN ('APPROVED', 'CLOSED') AND supervisor_deadline < CURRENT_DATE AND escalated_at IS NULL`
2. For each: notify PM (if `projects.pm_user_id` set) + all CEO users
3. Set `escalated_at = now()` (idempotent — won't re-escalate)

**Manual trigger**: `POST /api/jobs/escalate-tvgs`

---

## 12. Local Development

### 12.1 One-time setup

```bash
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project
npm install              # workspaces
cd backend && npm run init-db && cd ..
```

`init-db`:
- Applies `drizzle/0000_naive_nick_fury.sql` (if no `tenants` table)
- Applies `drizzle/9998_align_schema_with_routes.sql` (patches)
- Applies `drizzle/9999_add_issues_table.sql`
- Creates 7 unique indexes for `db.upsert()`
- Seeds: tenant `hbg`, 7 users, 2 projects, 19 zones for `BTE-WP4-HBC`

### 12.2 Daily dev

```bash
npm run dev              # backend (port 3000) + frontend (port 5173) concurrently
# OR separately:
npm run dev:backend      # node --watch
npm run dev:frontend     # vite HMR
```

### 12.3 Hot reload

- Backend: `node --watch src/index.js` — auto-restart on file change
- Frontend: Vite HMR — instant reload, preserves state

### 12.4 Database tools

```bash
# WSL/Linux local PG (port 5433)
./backend/scripts/pg-ctl.sh start
./backend/scripts/pg-ctl.sh psql
./backend/scripts/pg-ctl.sh backup
./backend/scripts/pg-ctl.sh restore <file>

# Or use system psql directly
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo
```

---

## 13. Testing

### 13.1 Test pyramid

| Level | Tool | Coverage | Speed |
|-------|------|----------|-------|
| E2E API | Node fetch (in `tests/e2e/*.mjs`) | 70 tests | ~30s |
| Schema verify | Node + `psql` | 15 tests | ~5s |
| Schema vs SQL audit | Node regex | Variable | ~2s |
| UI (Playwright) | Playwright + Chromium | Manual | ~60s |

### 13.2 E2E suites

```bash
npm test                   # all 4
npm run test:api           # 29 tests — login, projects, issues, kpi, audit, etc.
npm run test:payment       # 13 tests — payment 4-step + SLA
npm run test:shop          # 13 tests — L1-L5 + TVGS escalation
npm run test:schema        # 15 tests — tables, columns, FK, enum, indexes
npm run test:browser       # UI smoke test via Cloudflare tunnel
```

### 13.3 Schema vs SQL audit

```bash
npm run audit:schema
# Scans backend/src/routes + lib for SQL strings
# Compares column references to actual PG schema
# Reports: <file>:<line>  ❌ table.column  available: [a, b, c]
```

**Why**: catches column mismatches BEFORE runtime (which would crash → white screen). Run after editing routes.

### 13.4 CI (`.github/workflows/ci.yml`)

- `backend-lint`: `node --check` on all `lib/` + `routes/` files
- `backend-tests`: spins up PG, applies migrations, starts backend, runs 4 E2E suites
- `frontend-build`: Vite build + upload artifact
- `schema-audit`: runs `tests/tools/schema-audit.mjs`

### 13.5 Adding a new test

1. Add test function to existing file OR create `tests/e2e/<feature>.mjs`
2. Follow pattern: `const result = await api(token, '/path', { method: 'POST', body: JSON.stringify({...}) })`
3. Track `pass`/`fail` counters
4. Print `=== Results: N/M PASS ===` at end
5. Add to root `package.json` `test:xxx` script + to `test` chain
6. Add to `.github/workflows/ci.yml` `Run E2E suite` step

---

## 14. Deployment

### 14.1 Single-server (recommended for ≤100 users)

**Option A: Native**
```bash
# On server
git clone https://github.com/TungLinhh/pmo-project.git
cd pmo-project
npm install
npm run build              # frontend/dist/
DB_HOST=10.0.0.5 DB_USER=pmo_user DB_PASSWORD=<real> npm start
```

**Option B: Docker Compose**
```bash
git clone ...
cd pmo-project
docker compose up -d       # postgres + backend
# Behind nginx/cloudflare proxy
```

**Option C: Cloudflare tunnel** (current demo)
- Backend on `localhost:3000`
- `cloudflared tunnel --url http://localhost:3000` → public URL
- No domain/SSL config needed

### 14.2 Multi-server

Not supported yet. Would require:
- Redis for `tokenMap` (replace in-memory)
- `pgbouncer` for PG connection pooling
- Shared `data/uploads/` (NFS or S3)

### 14.3 Database backup

```bash
# Native
./backend/scripts/pg-ctl.sh backup
# Output: data/backups/pmo-YYYY-MM-DD-HHMM.sql.gz

# Cron (daily 2 AM)
0 2 * * * /home/vutun/pmo_project/backend/scripts/pg-ctl.sh backup
```

### 14.4 Production checklist (BEFORE real deploy)

- [ ] Hash passwords (bcrypt, currently dev-only)
- [ ] Set real `DB_PASSWORD` (not `pmo_dev_pwd`)
- [ ] HTTPS via reverse proxy (nginx + Let's Encrypt)
- [ ] Set `NODE_ENV=production`
- [ ] Enable rate limiting (currently disabled)
- [ ] Set up automated backups + test restore
- [ ] Monitor: `pm2` or `systemd` for restart on crash
- [ ] Logs: ship to centralized (ELK / Loki)
- [ ] Alerts: UptimeRobot or similar for `/api/health`
- [ ] Replace demo accounts with real users
- [ ] CORS whitelist (currently open in dev)
- [ ] File upload size limit (currently 100KB default — increase for photos)

---

## 15. Operations & Troubleshooting

### 15.1 Health check

```http
GET /api/health
→ { status: "ok", timestamp: "...", authenticated: false, user: null }
```

Use for: load balancer health, monitoring, CI smoke test.

### 15.2 Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ECONNREFUSED 127.0.0.1:5433` | PG not running | `./backend/scripts/pg-ctl.sh start` or `docker compose up -d postgres` |
| `EADDRINUSE :::3000` | Port 3000 taken | `lsof -i :3000` → `kill -9 <pid>` |
| `column "xyz" does not exist` | Schema drift | `npm run audit:schema` to find bad queries |
| `inconsistent types deduced for parameter $1` | PG can't infer type from `CASE WHEN $1 = ...` | Add explicit cast: `$1::workflow_status` |
| `relation "users" does not exist` | Migrations not applied | `cd backend && npm run init-db` |
| White screen on dashboard | Frontend runtime error | Check browser console, then `npm test` |
| `Cannot read properties of undefined (reading 'unread')` | API shape mismatch | Check `api/notifications` returns array, not `{items, counts}` |
| 502 from Cloudflare tunnel | Tunnel disconnect | Check `cloudflared` process, restart if needed |
| `npm test` fails with timeout | Backend not running | Start backend: `npm run dev:backend` |

### 15.3 Database maintenance

```bash
# Vacuum (reclaim space, update planner stats)
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "VACUUM ANALYZE"

# Reindex (after heavy writes)
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "REINDEX DATABASE pmo"

# Check table sizes
PGPASSWORD=pmo_dev_pwd psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -c "
  SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
  FROM pg_stat_user_tables
  ORDER BY pg_total_relation_size(relid) DESC
  LIMIT 10;"
```

### 15.4 Logs

- Backend: stdout (in `pm2`/`systemd` journal)
- Frontend: browser console + Vite dev server
- DB: `data/pg_log/`
- Tunnel: cloudflared process output

### 15.5 Restart recipes

```bash
# Backend only
pkill -f "node src/index.js"
cd backend && nohup node src/index.js > /tmp/pmo.log 2>&1 &

# Full stack (docker)
docker compose restart backend

# After schema change
cd backend && npm run init-db
docker compose restart backend
```

---

## 16. Appendix: Migration History

| Date | Phase | Description | Commit |
|------|-------|-------------|--------|
| 2026-08-29 | MVP launch | Initial 20-screen MVP, SQLite, 1166 LOC index.js | `6091f50` |
| 2026-09-03 | DB migration | SQLite → PostgreSQL, Drizzle setup | `5810c85` |
| 2026-09-04 | Phase 1+2 | Refactor: 22 routers + 3 lib helpers, 70/70 tests pass | `9c66506` |
| 2026-09-05 | Phase 3 | TVGS auto-escalation, L1-L5 shop approval, OTD page, photo gallery, submittal history modal | (in `9c66506`) |
| 2026-09-05 | White screen fix | 11 column mismatches fixed, schema-audit tool created | (in `9c66506`) |
| 2026-09-05 | Cleanup | Tests/ folder, Docker PG, deleted CHECKLIST, dead code removed | `5de7f0d` |
| 2026-09-05 | Docs v0.3.0 | Unified Product Technical Documentation | (this commit) |

### 16.1 Known limitations (v0.3.0)

1. **Plain-text passwords** — dev only, must hash for prod
2. **No rate limiting** — disabled for admin convenience
3. **In-memory token map** — single-server only, lost on restart
4. **Photo upload** — Express default 100KB limit; increase for production
5. **No real-time updates** — frontend polls (BellDropdown 30s)
6. **No mobile native apps** — web responsive only
7. **No multi-tenant UI** — schema supports it, UI is single-tenant
8. **No file upload to S3** — local FS only
9. **Audit log retention** — no auto-prune, grows forever
10. **No email channel** — `delivery_status` exists, but no SMTP integration

### 16.2 Roadmap (suggested)

- v0.4: password hashing + real email notifications (SMTP)
- v0.5: rate limiting + CSRF + security hardening
- v0.6: WebSocket / SSE for real-time notifications
- v0.7: S3 / Azure Blob for uploads
- v0.8: Multi-tenant UI + admin panel
- v0.9: Mobile app (React Native) for field
- v1.0: Gantt auto-scheduling + BIM viewer

---

## License

Proprietary — internal use only. © 2026 HBG Construction.

## Contact

Engineering: Tùng Linh — tunglinh@hbg.com
