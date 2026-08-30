-- PMO System - SQLite schema (MVP)
-- Compatible with PostgreSQL syntax for future migration

-- ============================================================
-- 1. Tenants (1 tenant = 1 khách hàng/công ty, vd: 'hbg')
-- ============================================================
CREATE TABLE IF NOT EXISTS tenants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 2. Users (simple auth for MVP - BetterAuth later)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  email TEXT NOT NULL,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'viewer',  -- admin, editor, viewer
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, email),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ============================================================
-- 3. Projects (1 project per tenant)
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  code TEXT NOT NULL,           -- "BTE-WP4-HBC"
  name_vi TEXT,
  name_en TEXT,
  package TEXT,                 -- "MEP" (single package)
  rev_prefix TEXT,              -- "BTE-HBG-SHD-..."
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, code),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ============================================================
-- 4. Zones (khu vực trong dự án: BOH, BPV, ...)
-- ============================================================
CREATE TABLE IF NOT EXISTS zones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  code TEXT NOT NULL,            -- "BOH", "BPV", "BPV-1BR"
  name_vi TEXT,
  name_en TEXT,
  is_br_split INTEGER DEFAULT 0, -- 1 nếu là zone tách theo số phòng ngủ
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, code),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- ============================================================
-- 5. Business process steps (8 bước quy trình)
-- ============================================================
CREATE TABLE IF NOT EXISTS business_process_steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  process_code TEXT NOT NULL,    -- "project_execution"
  ordinal INTEGER NOT NULL,      -- 1..8
  name_vi TEXT,
  name_en TEXT,
  content_vi TEXT,
  responsibility_vi TEXT,
  verification_vi TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, process_code, ordinal),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ============================================================
-- 6. Subcontractors
-- ============================================================
CREATE TABLE IF NOT EXISTS subcontractors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  capability_summary TEXT,
  status TEXT DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE
  is_internal_team INTEGER DEFAULT 0, -- 1 nếu là tổ đội nội bộ
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, name),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ============================================================
-- 7. Suppliers (nhà cung cấp)
-- ============================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  system TEXT,                  -- "Cấp thoát nước", "Điện", ...
  category TEXT,
  past_projects TEXT,
  location TEXT,
  price_rating TEXT,            -- HIGH, MEDIUM, LOW
  quality_rating TEXT,          -- PASS, FAIL
  warranty_rating TEXT,         -- GOOD
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, name),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- ============================================================
-- 8. Task assignments (ma trận giao việc)
-- ============================================================
CREATE TABLE IF NOT EXISTS task_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  system_code TEXT,             -- "I", "II", "III"
  subtask_code TEXT,            -- "1.1", "1.2"
  team_id INTEGER,              -- FK subcontractors (tổ đội nội bộ)
  subcontractor_id INTEGER,     -- FK subcontractors
  assignee_name TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (team_id) REFERENCES subcontractors(id),
  FOREIGN KEY (subcontractor_id) REFERENCES subcontractors(id)
);

-- ============================================================
-- 9. Shop drawings (bản vẽ shop)
-- ============================================================
CREATE TABLE IF NOT EXISTS shop_drawings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  zone_id INTEGER NOT NULL,
  drawing_code TEXT NOT NULL,    -- "BTE-WP4-HBC-SHD-MEP-HVAC-HVA-BOH-001"
  name_vi TEXT,
  name_en TEXT,
  progress_pct REAL,            -- 0-100
  planned_submit_date TEXT,     -- ISO date
  actual_submit_date TEXT,
  bql_l1_response TEXT,         -- "R" (Rejected?) / "A" (Approved?)
  bql_l1_date TEXT,
  bql_l1_comment TEXT,
  bql_l2_response TEXT,
  bql_l2_date TEXT,
  bql_l2_comment TEXT,
  bql_l3_response TEXT,
  bql_l3_date TEXT,
  bql_l3_comment TEXT,
  bql_l4_response TEXT,
  bql_l4_date TEXT,
  bql_l4_comment TEXT,
  bql_l5_response TEXT,
  bql_l5_date TEXT,
  bql_l5_comment TEXT,
  resubmit_planned_date_1 TEXT,
  resubmit_actual_date_1 TEXT,
  resubmit_planned_date_2 TEXT,
  resubmit_actual_date_2 TEXT,
  approval_date TEXT,           -- ISO date or NULL
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, zone_id, drawing_code),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (zone_id) REFERENCES zones(id)
);

-- ============================================================
-- 10. Materials (vật tư)
-- ============================================================
CREATE TABLE IF NOT EXISTS materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  zone_id INTEGER NOT NULL,
  material_code TEXT NOT NULL,
  name_vi TEXT,
  name_en TEXT,
  progress_pct REAL,
  request_date_1 TEXT,
  request_date_2 TEXT,
  request_date_3 TEXT,
  request_date_4 TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, zone_id, material_code),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (zone_id) REFERENCES zones(id)
);

-- ============================================================
-- 11. Construction schedule items (tiến độ thi công)
-- ============================================================
CREATE TABLE IF NOT EXISTS construction_schedule_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  zone_id INTEGER NOT NULL,
  source_sheet TEXT,
  level_roman TEXT,             -- "A", "I", "II", "III"
  level_arabic INTEGER,         -- 1, 2, 3
  sublevel INTEGER,             -- 1, 2 (cho "1.1", "1.2")
  ordinal INTEGER,              -- STT trong file
  name_vi TEXT,
  name_en TEXT,
  progress_pct REAL,            -- 0-1
  status TEXT,                  -- DONE, PENDING
  plan_start_date TEXT,
  actual_start_date TEXT,
  plan_end_date TEXT,
  actual_end_date TEXT,
  plan_duration_days INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (zone_id) REFERENCES zones(id)
);

-- ============================================================
-- 12. Daily reports
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  report_date TEXT NOT NULL,    -- ISO date
  prepared_by TEXT,
  approver_role TEXT,           -- "Đại diện ban chấp hành/chủ tịch"
  source_sheet_name TEXT,       -- "23.5.2021"
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, report_date),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- 12a. Daily work items
CREATE TABLE IF NOT EXISTS daily_work_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  parent_id INTEGER,            -- self-reference
  ordinal INTEGER,
  name_vi TEXT,                 -- "KHO VÀ VĂN PHÒNG", "Thi công hệ thống kho bãi"
  blocker_notes TEXT,
  system_type TEXT,             -- "ELECTRICAL", "MECHANICAL"
  manpower_rate REAL,
  start_date TEXT,
  finish_date TEXT,
  lost_days INTEGER,
  progress_pct REAL,
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id),
  FOREIGN KEY (parent_id) REFERENCES daily_work_items(id)
);

-- 12b. Daily materials (vật tư trên công trường)
CREATE TABLE IF NOT EXISTS daily_materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  ordinal INTEGER,
  name_vi TEXT,                 -- "Ống conduit điện", "Ống cấp thoát nước"
  start_date TEXT,
  finish_date TEXT,
  lost_days INTEGER,
  progress_pct REAL,
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id)
);

-- 12c. Daily manpower (14 vai trò × 3 cột)
CREATE TABLE IF NOT EXISTS daily_manpower (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  role_name TEXT NOT NULL,      -- "Quản lý dự án", "Chỉ Huy trưởng", ...
  cumulative_qty INTEGER,
  today_qty INTEGER,
  consumed_qty INTEGER,
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id)
);

-- 12d. Daily acceptance (nghiệm thu)
CREATE TABLE IF NOT EXISTS daily_acceptance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  ordinal INTEGER,
  acceptance_type TEXT,         -- "material" / "installation"
  status INTEGER,               -- 0 = chưa cập nhật, 1 = OK
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id)
);

-- 12e. Safety observations & recommendations
CREATE TABLE IF NOT EXISTS daily_safety_observations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  category TEXT,                -- "an toàn", "thông tin khác"
  description TEXT,
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id)
);

CREATE TABLE IF NOT EXISTS daily_recommendations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  daily_report_id INTEGER NOT NULL,
  ordinal INTEGER,
  text TEXT,
  FOREIGN KEY (daily_report_id) REFERENCES daily_reports(id)
);

-- ============================================================
-- 13. RFA log (file HBG-MCR-MM-01 - 1397 rows)
-- ============================================================
CREATE TABLE IF NOT EXISTS rfa_log_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  rfa_code TEXT,                -- unique code
  rfa_type TEXT,                -- MAA / SHD / RFA / OTH
  submission_date TEXT,
  approval_date TEXT,
  status TEXT,                  -- SUBMITTED, APPROVED, REJECTED, RESUBMIT
  raw_data TEXT,                -- JSON
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, rfa_code),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- ============================================================
-- 14. Payment milestones
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_milestones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  ordinal INTEGER,
  description TEXT,
  volume REAL,
  value_vnd REAL,
  approval_status TEXT,
  quality_docs_status TEXT,
  overall_status TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- ============================================================
-- 15. File uploads (audit log + idempotency)
-- ============================================================
CREATE TABLE IF NOT EXISTS file_uploads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  project_id INTEGER,
  original_filename TEXT NOT NULL,
  storage_key TEXT NOT NULL,    -- local path or MinIO key
  content_hash TEXT NOT NULL,
  file_size INTEGER,
  expected_doc_type TEXT,       -- business_process, shop_drawing, ...
  uploader_user_id INTEGER,
  status TEXT NOT NULL DEFAULT 'UPLOADED', -- UPLOADED, PROCESSING, SUCCESS, PARTIAL, FAILED
  total_rows INTEGER,
  ok_rows INTEGER,
  error_rows INTEGER,
  report_json TEXT,             -- JSON báo cáo chi tiết
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, content_hash),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- ============================================================
-- 16. Column mappings (config per tenant - dùng sau MVP)
-- ============================================================
CREATE TABLE IF NOT EXISTS column_mappings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  source_doc_type TEXT NOT NULL,
  raw_header_vi TEXT,
  raw_header_en TEXT,
  system_field TEXT,
  data_type TEXT,
  is_required INTEGER DEFAULT 0,
  is_user_confirmed INTEGER DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, source_doc_type, raw_header_vi),
  FOREIGN KEY (tenant_id) REFERENCES tenants(id)
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_shop_drawings_project_zone ON shop_drawings(project_id, zone_id);
CREATE INDEX IF NOT EXISTS idx_construction_project_zone ON construction_schedule_items(project_id, zone_id);
CREATE INDEX IF NOT EXISTS idx_daily_reports_project ON daily_reports(project_id, report_date);
CREATE INDEX IF NOT EXISTS idx_file_uploads_tenant ON file_uploads(tenant_id, created_at);

-- ============================================================
-- 17. Subcontractors
-- ============================================================
CREATE TABLE IF NOT EXISTS subcontractors (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  project_id INTEGER,
  source_sheet TEXT,
  ordinal INTEGER,
  name_vi TEXT NOT NULL,
  scope_of_work TEXT,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  contract_date TEXT,
  contract_value_vnd REAL,
  status TEXT,
  rating TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, source_sheet, name_vi)
);

-- ============================================================
-- 18. Suppliers (tenant-level)
-- ============================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  source_sheet TEXT,
  ordinal INTEGER,
  name_vi TEXT NOT NULL,
  scope_or_product TEXT,
  contact_info TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(tenant_id, source_sheet, name_vi)
);

-- ============================================================
-- 19. Materials
-- ============================================================
CREATE TABLE IF NOT EXISTS materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  zone_id INTEGER,
  source_sheet TEXT,
  ordinal INTEGER,
  material_code TEXT,
  name_vi TEXT,
  name_en TEXT,
  unit TEXT,
  required_qty REAL,
  supplied_qty REAL,
  unit_price_vnd REAL,
  supplier_name TEXT,
  expected_delivery_date TEXT,
  status TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, zone_id, source_sheet, material_code, name_vi)
);

-- ============================================================
-- 20. RFA Log
-- ============================================================
CREATE TABLE IF NOT EXISTS rfa_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  source_sheet TEXT,
  ordinal INTEGER,
  rfa_code TEXT NOT NULL,
  description_vi TEXT,
  discipline TEXT,
  area TEXT,
  submitted_date TEXT,
  reviewer TEXT,
  reviewer_status TEXT,
  reviewer_comment TEXT,
  response_date TEXT,
  final_status TEXT,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, source_sheet, rfa_code)
);

-- ============================================================
-- 21. Generic sheets (catch-all for unmodeled doc types)
-- ============================================================
CREATE TABLE IF NOT EXISTS generic_sheets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id INTEGER NOT NULL,
  doc_type TEXT NOT NULL,
  source_sheet TEXT,
  ordinal INTEGER,
  col_1 TEXT, col_2 TEXT, col_3 TEXT, col_4 TEXT,
  col_5 TEXT, col_6 TEXT, col_7 TEXT, col_8 TEXT,
  col_9 TEXT, col_10 TEXT, col_11 TEXT, col_12 TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(project_id, doc_type, source_sheet, ordinal)
);

-- ============================================================
-- 16. Issues (Mục 4-5, mới)
-- ============================================================
CREATE TABLE IF NOT EXISTS issues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  zone_id INTEGER,
  source_resource TEXT,           -- 'construction_schedule_items' | 'shop_drawings' | 'materials' | 'payment_milestones'
  source_id INTEGER,              -- FK to source row
  title TEXT NOT NULL,
  body TEXT,
  category TEXT,                  -- 'PROGRESS' | 'QUALITY' | 'MATERIAL' | 'PAYMENT' | 'DESIGN' | 'SAFETY'
  severity TEXT NOT NULL,         -- 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  status TEXT NOT NULL DEFAULT 'OPEN',  -- 'OPEN' | 'ACK' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED'
  owner_user_id INTEGER,
  due_date TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  resolved_at TEXT,
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (owner_user_id) REFERENCES users(id)
);

-- ============================================================
-- 17. Notifications (Mục 15, mới)
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER,                -- target user (NULL = all PMs of project)
  project_id INTEGER,
  issue_id INTEGER,
  severity TEXT NOT NULL,         -- 'info' | 'warning' | 'critical'
  title TEXT NOT NULL,
  body TEXT,
  resource_type TEXT,             -- 'issue' | 'directive' | 'shop_drawing' | 'construction_item'
  resource_id INTEGER,
  is_read INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  read_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (issue_id) REFERENCES issues(id)
);

-- ============================================================
-- 18. Audit Log (Mục 20, mới)
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER,
  user_name TEXT,                 -- denormalized for display
  action TEXT NOT NULL,           -- 'CREATE' | 'UPDATE' | 'DELETE' | 'DIRECTIVE' | 'STATUS_CHANGE'
  resource_type TEXT NOT NULL,
  resource_id INTEGER,
  field_name TEXT,
  old_value TEXT,
  new_value TEXT,
  note TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============================================================
-- 19. Directives (Mục "Tính năng mới - CEO chỉ thị", mới)
-- CEO/PMO qualitative notes on issues or projects
-- ============================================================
CREATE TABLE IF NOT EXISTS directives (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tenant_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  issue_id INTEGER,               -- NULL if directive is on project-level
  from_user_id INTEGER NOT NULL,
  from_user_name TEXT,            -- denormalized
  body TEXT NOT NULL,
  notify_to_user_ids TEXT,        -- JSON array string, e.g. '[2,3]'
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (issue_id) REFERENCES issues(id),
  FOREIGN KEY (from_user_id) REFERENCES users(id)
);

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS idx_issues_project ON issues(project_id);
CREATE INDEX IF NOT EXISTS idx_issues_status ON issues(status);
CREATE INDEX IF NOT EXISTS idx_issues_severity ON issues(severity);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notif_project ON notifications(project_id);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_log(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_directives_issue ON directives(issue_id);
CREATE INDEX IF NOT EXISTS idx_directives_project ON directives(project_id);
