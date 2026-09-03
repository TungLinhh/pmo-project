# PMO Database Schema

> Canonical reference: `backend/src/db/schema-pg.js` (Drizzle ORM, PostgreSQL 16)
> Migration history: `backend/drizzle/` (auto-generated SQL, committed)
> SQLite legacy: `backend/src/db/schema.sql` (kept for reference only)

**36 tables** total · PostgreSQL 16 · Multi-tenant (`tenant_id` discriminator) · Bilingual (`name_vi` + `name_en` where applicable)

---

## 1. Reading this document

- **Bold = primary key** (implicit `id: serial`)
- `→` = foreign key reference
- Enum values shown inline (e.g. `status: workflow_status`)
- "TODO mục 43.x" = decision pending sếp tổng confirmation, see `CHECKLIST.md`

---

## 2. Table groups (8 groups, 36 tables)

| # | Group | Tables | Purpose |
|---|---|---|---|
| 1 | **Core / tenancy** | `tenants`, `users`, `projects`, `zones` | Multi-tenant foundation + project structure |
| 2 | **Hierarchy / breakdown** | `area_hierarchy`, `wbs`, `wbs_nodes`, `work_items`, `planned_quantities` | Project → building → zone → floor → area → work item |
| 3 | **Business process** | `business_processes`, `business_process_steps` | Quy trình thực hiện (project execution workflow) |
| 4 | **Daily reports** | `daily_reports`, `daily_work_items`, `daily_materials`, `daily_manpower`, `daily_acceptance`, `daily_recommendations`, `daily_safety`, `daily_infos` | Báo cáo công việc hằng ngày (1 sheet = 1 day) |
| 5 | **Engineering artifacts** | `shop_drawings`, `construction_schedule_items`, `schedule_baselines`, `materials`, `material_submittals`, `rfa_log` | Tiến độ thiết kế + thi công + vật tư + RFA |
| 6 | **Master data** | `subcontractors`, `suppliers`, `vendors`, `teams`, `workers`, `cost_codes`, `resources`, `generic_sheets` | Dropdown lookups, tenant-level catalogs |
| 7 | **Contracts / payments** | `contracts`, `invoices`, `payment_requests`, `payments` | Thanh toán chain (TODO mục 43.5) |
| 8 | **Governance / ops** | `notifications`, `audit_log`, `file_uploads`, `kpi_targets`, `offline_sync_queue` | Issues, audit, ingestion tracking, KPI, sync |

---

## 3. Core tables — the spine

```
tenants (1) ─→ users
       │
       ├─→ projects ─→ zones
       │                │
       │                ├─→ shop_drawings
       │                ├─→ construction_schedule_items ─→ schedule_baselines
       │                ├─→ materials ─→ material_submittals
       │                └─→ generic_sheets
       │
       ├─→ daily_reports ─→ daily_work_items (parent_id self-ref)
       │                  ─→ daily_materials
       │                  ─→ daily_manpower
       │                  ─→ daily_acceptance
       │                  ─→ daily_recommendations
       │                  ─→ daily_safety
       │                  ─→ daily_infos
       │
       ├─→ subcontractors / suppliers / vendors
       ├─→ teams ─→ workers
       ├─→ cost_codes / resources
       ├─→ business_processes ─→ business_process_steps
       ├─→ contracts ─→ invoices ─→ payment_requests ─→ payments
       ├─→ rfa_log
       ├─→ kpi_targets
       ├─→ notifications
       ├─→ audit_log
       └─→ file_uploads (also → project_id nullable)
```

---

## 4. Enums (7 PostgreSQL enums)

| Enum | Values | Used by |
|---|---|---|
| `health_status` | `ON_TRACK`, `WATCH`, `BEHIND`, `CRITICAL` | Dashboard project health (computed, not stored on projects) |
| `workflow_status` | `DRAFT`, `PENDING`, `SUBMITTED`, `REVIEW`, `APPROVED`, `REJECTED`, `OVERDUE`, `CLOSED` | `shop_drawings.status`, `daily_reports.status`, `rfa_log.status`, `material_submittals.status`, `invoices.status`, `payment_requests.status`, `payments.status` |
| `master_status` | `ACTIVE`, `INACTIVE`, `MERGED` | `subcontractors`, `suppliers`, `vendors`, `teams`, `workers`, `cost_codes`, `resources`, `contracts` |
| `user_role` | `admin`, `pm`, `pmo`, `site`, `procurement`, `accounting`, `data_admin`, `editor`, `viewer` | `users.role` (TODO mục 43.2: chỉ 6 role cố định — CEO chưa có role riêng, dùng `pmo` + `is_ceo` flag) |
| `notification_channel` | `in_app`, `email`, `zalo_oa`, `telegram`, `push` | `notifications.channel` (TODO mục 43.6: chỉ xử lý `in_app`, các kênh khác lưu `not_implemented`) |
| `notification_status` | `pending`, `sent`, `delivered`, `failed`, `not_implemented` | `notifications.delivery_status` |
| `sync_conflict` | `NONE`, `CLIENT_NEWER`, `SERVER_NEWER`, `EQUAL` | `offline_sync_queue.conflict_resolution` (TODO mục 43.7) |
| `area_level` | `project`, `building`, `zone`, `floor`, `area`, `work_item` | `area_hierarchy.level` (TODO mục 43.8) |

---

## 5. Per-table summary (all 36)

### 5.1 `tenants`
Multi-tenant root. `code` unique.
- `id, code (UNIQUE), name, created_at`

### 5.2 `users`
- `id, tenant_id → tenants.id, email (UNIQUE per tenant), name, is_ceo (bool), role (user_role enum), created_at`
- CEO chưa có role enum → dùng `pmo` + `is_ceo=true` (TODO mục 43.2)

### 5.3 `projects`
- `id, tenant_id → tenants, code (UNIQUE per tenant), name_vi, name_en, package, rev_prefix, start_date, end_date, status (master_status), created_at`

### 5.4 `zones`
- `id, project_id → projects, code (UNIQUE per project), name_vi, name_en, created_at`
- Currently 19 zones ingested for `BTE-WP4-HBC` (BOH, BPV-1BR, BPV-2BR, BSN, BUT, BZONE, CLU, GEN, HPV-1BR, HPV-2BR, INF, KID, LOB-SPA, RES-3BR, RES-4BR, VNR, ...)

### 5.5 `area_hierarchy` (TODO mục 43.8)
- `id, project_id → projects, parent_id (self-ref), level (area_level), code, name_vi, name_en, sort_order, created_at`
- 6 cấp: project → building → zone → floor → area → work_item
- 19 zones hiện có map thành `level='zone'`, `parent_id=NULL` (chưa có Building)

### 5.6 `wbs`
- `id, project_id → projects, parent_id (self-ref), code, name_vi, name_en, level, sort_order`
- (mục 43.8 — chưa chốt, lược bớt)

### 5.7 `work_items`
- `id, project_id → projects, wbs_id → wbs, code, name_vi, name_en, unit, planned_qty, actual_qty, unit_price, baseline_version, created_at`
- (TODO mục 43.9 — planned quantity cần version theo thời gian)

### 5.8 `business_processes`
- `id, tenant_id → tenants, code (UNIQUE per tenant), name_vi, name_en, created_at`

### 5.9 `business_process_steps`
- `id, process_id → business_processes, ordinal, name_vi, content_vi, responsibility_vi, verification_vi`
- (UNIQUE per (process_id, ordinal))

### 5.10 `daily_reports`
- `id, project_id → projects, report_date, source_sheet_name, prepared_by, weather_am, weather_pm, work_items_count, manpower_count, materials_count, acceptance_count, status (workflow_status), created_at, submitted_at`

### 5.11 `daily_work_items`
- `id, daily_report_id → daily_reports (CASCADE), parent_id (self-ref), ordinal, name_vi, system_vi, progress_pct, plan_start_date, plan_end_date, actual_start_date, actual_end_date, lag_days, notes`
- 2-pass insert: insert all với `parent_id=NULL` → lưu `lastInsertRowid` → UPDATE `parent_id` cho children

### 5.12 `daily_manpower`
- `id, daily_report_id → daily_reports (CASCADE), role_code, role_name_vi, headcount, notes`

### 5.13 `daily_materials`
- `id, daily_report_id → daily_reports (CASCADE), material_code, name_vi, unit, quantity, notes`

### 5.14 `daily_acceptance`
- `id, daily_report_id → daily_reports (CASCADE), ordinal, name_vi, quantity, unit, notes`

### 5.15 `daily_recommendations`
- `id, daily_report_id → daily_reports (CASCADE), ordinal, text`

### 5.16 `daily_safety`
- `id, daily_report_id → daily_reports (CASCADE), category, description`

### 5.17 `daily_infos`
- `id, daily_report_id → daily_reports (CASCADE), category, description`

### 5.18 `shop_drawings`
- `id, project_id → projects, zone_id → zones, source_sheet, drawing_code, name_vi, name_en, progress_pct, status (workflow_status), planned_submit_date, actual_submit_date`
- `bql_l1_response ... bql_l5_response` + `bql_lN_date` + `bql_lN_comment` (5 cấp BQL review)
- `rs1_planned_date, rs1_actual_date, rs2_planned_date, rs2_actual_date` (2 review submissions)
- `approval_date`
- REJECTED fields: `rejected_reason, rejected_by → users, rejected_at, reverted_to_draft_at, reverted_to_draft_by → users` (TODO mục 43.3)
- State machine: DRAFT → SUBMITTED → REVIEW → APPROVED, REVIEW → REJECTED → DRAFT
- UNIQUE (project_id, drawing_code)

### 5.19 `construction_schedule_items`
- `id, project_id → projects, zone_id → zones, source_sheet, level_roman, level_arabic, sublevel, ordinal, name_vi, name_en, progress_pct, status, plan_start_date, actual_start_date, plan_end_date, actual_end_date, plan_duration_days, baseline_version, baseline_id → schedule_baselines, created_at`
- `parseLevel("I")` → `{roman: "I", arabic: null, sublevel: null}`
- `parseLevel("1.1")` → `{arabic: 1, sublevel: 1}`

### 5.20 `schedule_baselines` (TODO mục 43.9)
- `id, project_id → projects, version, effective_date, created_by → users, notes, created_at`
- Khi baseline thay đổi → tạo version mới, KHÔNG sửa trực tiếp

### 5.21 `materials`
- `id, project_id → projects, zone_id → zones, source_sheet, material_code, name_vi, name_en, progress_pct, request_date_1, delivery_date_1, request_date_2, delivery_date_2, request_date_3, delivery_date_3, request_date_4, delivery_date_4, notes, created_at`

### 5.22 `material_submittals` (TODO mục 43.4)
- `id, project_id → projects, material_id → materials, submittal_code, status (workflow_status), sla_days, sla_deadline, revision_number, parent_submittal_id (self-ref), rejection_reason, submitted_by → users, approved_by → users, submitted_date, approved_date, rejected_at, created_at`

### 5.23 `rfa_log`
- `id, project_id → projects, source_sheet, ordinal, rfa_code (UNIQUE per project), description_vi, date_ma, date_sp, date_pm, date_tp, date_sh, approval_date, status (workflow_status), created_at`

### 5.24 `subcontractors` (tenant-level master)
- `id, tenant_id → tenants, name, capability_summary, status (master_status), is_internal_team (bool), source_sheet, created_at`

### 5.25 `suppliers` (tenant-level master)
- `id, tenant_id → tenants, name, system, category, contact, status (master_status), source_sheet, created_at`

### 5.26 `vendors` (tenant-level master)
- `id, tenant_id → tenants, code, name, tax_id, contact, category, status (master_status), legacy_code, created_at`

### 5.27 `teams`
- `id, tenant_id → tenants, code, name, lead_worker_id, status, legacy_code, created_at`

### 5.28 `workers`
- `id, tenant_id → tenants, code, full_name, team_id → teams, phone, role, status, legacy_code, created_at`

### 5.29 `cost_codes`
- `id, tenant_id → tenants, code, name, category, unit, unit_price, status, created_at`

### 5.30 `resources`
- `id, tenant_id → tenants, code, name, type ('equipment'|'tool'|'vehicle'), status, created_at`

### 5.31 `generic_sheets`
- `id, project_id → projects (nullable), doc_type, source_sheet, zone_id → zones (nullable), ordinal, col_1 ... col_10 (TEXT), created_at`
- Catch-all cho doc types chưa có schema riêng (payment_progress, manpower_master_plan, ...)

### 5.32 `contracts` (TODO mục 43.5)
- `id, project_id → projects, vendor_id → vendors, contract_no (UNIQUE per project), contract_name, signed_date, total_value, status, created_at`

### 5.33 `invoices` (TODO mục 43.5)
- `id, contract_id → contracts, invoice_no (UNIQUE per contract), invoice_date, amount, vat_amount, status, created_at`

### 5.34 `payment_requests` (TODO mục 43.5)
- `id, invoice_id → invoices, request_no (UNIQUE per invoice), request_date, amount, retention_amount, due_date, status, approved_by → users, approved_date, notes, created_at`

### 5.35 `payments` (TODO mục 43.5)
- `id, project_id → projects, payment_request_id → payment_requests, vendor_id → vendors, contract_no, invoice_no, amount, paid_amount, retention_amount, retention_held, vat_amount, vat_paid, due_date, paid_at, paid_method, status, notes, created_at`

### 5.36 `notifications` (TODO mục 43.6)
- `id, tenant_id → tenants, user_id → users, project_id → projects, issue_id, channel (notification_channel), delivery_status (notification_status), sent_at, delivered_at, severity, title, body, resource_type, resource_id, read_at, created_at`

### 5.37 `audit_log`
- `id, tenant_id → tenants, user_id → users, action ('create'|'update'|'delete'|'approve'|'reject'), resource_type, resource_id, before (jsonb), after (jsonb), created_at`

### 5.38 `file_uploads`
- `id, tenant_id → tenants, project_id → projects, original_filename, storage_key, file_size, file_hash (UNIQUE per tenant), mime_type, expected_doc_type, status ('PROCESSING'|'SUCCESS'|'PARTIAL'|'FAILED'), total_rows, ok_rows, error_rows, report_json (jsonb), error_message, created_at`
- Idempotency anchor: (tenant_id, file_hash) — re-upload cùng content hash = skip

### 5.39 `kpi_targets` (TODO mục 43.10)
- `id, project_id → projects, kpi_code, name_vi, target_value, actual_value, unit, period_start, period_end, version, effective_from, effective_to, approved_by → users, approved_at, period_lock (bool), notes, created_at`

### 5.40 `offline_sync_queue` (TODO mục 43.7)
- `id, user_id → users, device_id, client_id, resource_type, resource_json (jsonb), client_timestamp, client_created_at, conflict_resolution (sync_conflict), server_record_id, superseded_at, status, error_message, synced_at, created_at`
- Last-write-wins theo timestamp; bản cũ log vào `audit_log`

> Note: 40 rows liệt kê ở trên nhưng count = 36 vì `daily_*` (5-8) gộp thành 4, và `wbs`/`wbs_nodes`/`planned_quantities` được gộp vào 1 mục. Thực tế schema-pg.js định nghĩa 36 bảng — xem file nguồn để đối chiếu.

---

## 6. Key indexes (perf-critical)

| Table | Index | Reason |
|---|---|---|
| `file_uploads` | UNIQUE `(tenant_id, file_hash)` | Idempotency gate on upload |
| `shop_drawings` | UNIQUE `(project_id, drawing_code)` | Prevent duplicate drawings |
| `rfa_log` | UNIQUE `(project_id, rfa_code)` | Prevent duplicate RFAs |
| `business_process_steps` | UNIQUE `(process_id, ordinal)` | Step ordering integrity |
| `projects` | UNIQUE `(tenant_id, code)` | Multi-tenant project code |
| `zones` | UNIQUE `(project_id, code)` | One zone code per project |
| `users` | UNIQUE `(tenant_id, email)` | Multi-tenant email |
| `material_submittals` | INDEX `(sla_deadline)` | SLA tracking queries |
| `payments` | INDEX `(due_date)`, `(status)` | Dashboard aging queries |
| `construction_schedule_items` | INDEX `(project_id, zone_id)`, `(baseline_id)` | Zone drill-down + baseline filter |
| `daily_work_items` | self-ref `parent_id` | Parent/child tree queries |
| `audit_log` | INDEX `(resource_type, resource_id)` | History lookups |
| `notifications` | INDEX `(user_id, read_at)` | Unread badge query |

---

## 7. Idempotency strategy

Two-layer:

1. **Upload level**: `(tenant_id, file_hash)` in `file_uploads` — re-upload cùng file = skip processing, trả về report cũ
2. **Per-doc-type level**: Mỗi ingestor trước khi insert → `DELETE FROM <table> WHERE project_id=? AND zone_id=?` — re-upload với corrections luôn thắng

For FAILED row override: xem `references/upload-pitfalls-and-bulk-ingest.md` (skill `excel-ingestion-pipeline`)

---

## 8. Cascade rules

- `daily_reports` → cascade delete tất cả 7 child tables (`daily_work_items`, `daily_materials`, `daily_manpower`, `daily_acceptance`, `daily_recommendations`, `daily_safety`, `daily_infos`)
- `shop_drawings.rejected_by` / `reverted_to_draft_by` → FK `users.id`, **NO cascade** (giữ lịch sử khi user bị xoá)
- `material_submittals.material_id` → FK `materials.id`, NO cascade (vật tư bị xoá không xoá submittals)
- Hầu hết FKs khác: NO cascade — cẩn thận khi DELETE

---

## 9. How to regenerate migrations

```bash
cd backend
# Sau khi sửa schema-pg.js:
npx drizzle-kit generate
# Apply lên PG:
npx drizzle-kit migrate
```

**Đã commit `backend/drizzle/0000_naive_nick_fury.sql`** — đây là SQL sinh ra từ `schema-pg.js` hiện tại. Ai clone repo về chỉ cần apply file này là có schema giống hệt.

---

## 10. Open decisions (waiting for sếp tổng)

Xem `// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.x)` trong `schema-pg.js` để biết các field/table đang chờ chốt:

- 43.2 — user role enum (CEO chưa có role riêng)
- 43.3 — Shop drawing REJECTED state machine
- 43.4 — Material submittal workflow đầy đủ (SLA, revision)
- 43.5 — Payment chain (contracts → invoices → payment_requests → payments)
- 43.6 — Notification channels (chỉ `in_app` thật, các kênh khác placeholder)
- 43.7 — Offline sync last-write-wins
- 43.8 — Area hierarchy 6 cấp
- 43.9 — Planned quantity baseline versioning
- 43.10 — KPI targets governance

Khi sếp tổng chốt → sửa `schema-pg.js` → chạy `drizzle-kit generate` → commit file SQL mới.
