// Drizzle ORM schema for PMO - PostgreSQL
// Converted from src/db/schema.sql (SQLite) → PostgreSQL syntax
// Tables: tenants, users, projects, zones, business_processes, business_process_steps,
//   daily_reports, daily_work_items, daily_materials, daily_manpower, daily_acceptance,
//   daily_recommendations, daily_safety, daily_infos,
//   shop_drawings, construction_schedule_items, materials, material_submittals,
//   rfa_log, rfa_log_entries, subcontractors, suppliers,
//   notifications, audit_log, file_uploads,
//   generic_sheets, vendors, teams, workers, cost_codes, resources,
//   area_hierarchy, work_items, wbs, wbs_nodes, planned_quantities, kpi_targets

import { pgTable, serial, integer, bigint, text, varchar, boolean, real, doublePrecision, date, timestamp, json, jsonb, uniqueIndex, index, primaryKey, foreignKey, pgEnum, decimal } from 'drizzle-orm/pg-core';
import { sql } from 'drizzle-orm';

// ===== Enums (Global Status Language — mục 35 của UI spec) =====
export const healthStatusEnum = pgEnum('health_status', ['ON_TRACK', 'WATCH', 'BEHIND', 'CRITICAL']);
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — REJECTED state cho shop drawing, transition REJECTED → DRAFT
export const workflowStatusEnum = pgEnum('workflow_status', ['DRAFT', 'PENDING', 'SUBMITTED', 'REVIEW', 'APPROVED', 'REJECTED', 'OVERDUE', 'CLOSED']);
export const masterStatusEnum = pgEnum('master_status', ['ACTIVE', 'INACTIVE', 'MERGED']);
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) — chỉ 6 role cố định, quyền đọc/ghi theo module, không ma trận
export const userRoleEnum = pgEnum('user_role', ['admin', 'pm', 'pmo', 'site', 'procurement', 'accounting', 'data_admin', 'editor', 'viewer']);
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — chỉ in_app, các channel khác để TODO
export const notificationChannelEnum = pgEnum('notification_channel', ['in_app', 'email', 'zalo_oa', 'telegram', 'push']);
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — channel logic chỉ process in_app, các kênh khác lưu với status='not_implemented'
export const notificationStatusEnum = pgEnum('notification_status', ['pending', 'sent', 'delivered', 'failed', 'not_implemented']);
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — last-write-wins theo timestamp
export const syncConflictEnum = pgEnum('sync_conflict', ['NONE', 'CLIENT_NEWER', 'SERVER_NEWER', 'EQUAL']);

// ===== Core =====
export const tenants = pgTable('tenants', {
  id: serial('id').primaryKey(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  email: varchar('email', { length: 255 }).notNull(),
  name: text('name'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) — chỉ 6 role cố định: CEO/PM/PMO/Site/Procurement/Accounting
  // Mapping hiện tại: admin=PMO, pm=PM, pmo=PMO, site=Site, procurement=Procurement, accounting=Accounting
  // CEO hiện chưa có role enum riêng — dùng 'pmo' + flag is_ceo (tạm thời)
  isCeo: boolean('is_ceo').default(false),
  role: userRoleEnum('role').notNull().default('viewer'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueEmail: uniqueIndex('users_tenant_email_idx').on(t.tenantId, t.email),
}));

export const projects = pgTable('projects', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }).notNull(),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  package: varchar('package', { length: 100 }),
  revPrefix: varchar('rev_prefix', { length: 50 }),
  startDate: date('start_date'),
  endDate: date('end_date'),
  status: masterStatusEnum('status').default('ACTIVE'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('projects_tenant_code_idx').on(t.tenantId, t.code),
}));

export const zones = pgTable('zones', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  code: varchar('code', { length: 50 }).notNull(),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('zones_project_code_idx').on(t.projectId, t.code),
}));

// ===== Area hierarchy (mục 43.8) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.8) — 6 cấp: Project → Building → Zone → Floor → Area → Work Item
// Schema self-referential, mỗi row có parentId. Level enum để constraint.
// Data hiện có 19 zones từ ingest trước → map thành level='zone', parent_id=NULL (vì chưa có Building).
// Building/Floor/Area có thể NULL nếu data không đủ chi tiết, không bịa data.
export const areaLevelEnum = pgEnum('area_level', ['project', 'building', 'zone', 'floor', 'area', 'work_item']);
export const areaHierarchy = pgTable('area_hierarchy', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  parentId: integer('parent_id'),
  level: areaLevelEnum('level').notNull(),
  code: varchar('code', { length: 100 }),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  sortOrder: integer('sort_order').default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  parentRef: foreignKey({ columns: [t.parentId], foreignColumns: [t.id], name: 'area_parent_fk' }),
  byProject: index('area_project_idx').on(t.projectId),
  byLevel: index('area_level_idx').on(t.projectId, t.level),
}));

// ===== WBS (mục 43.8 — chưa chốt) =====
export const wbs = pgTable('wbs', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  parentId: integer('parent_id'),
  code: varchar('code', { length: 100 }),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  level: integer('level').default(0),
  sortOrder: integer('sort_order').default(0),
});

// ===== Business Process =====
export const businessProcesses = pgTable('business_processes', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 100 }).notNull(),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('bp_tenant_code_idx').on(t.tenantId, t.code),
}));

export const businessProcessSteps = pgTable('business_process_steps', {
  id: serial('id').primaryKey(),
  processId: integer('process_id').notNull().references(() => businessProcesses.id),
  ordinal: integer('ordinal').notNull(),
  nameVi: text('name_vi'),
  contentVi: text('content_vi'),
  responsibilityVi: text('responsibility_vi'),
  verificationVi: text('verification_vi'),
}, (t) => ({
  uniqueStep: uniqueIndex('bp_step_ordinal_idx').on(t.processId, t.ordinal),
}));

// ===== Daily Reports =====
export const dailyReports = pgTable('daily_reports', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  reportDate: date('report_date').notNull(),
  sourceSheetName: varchar('source_sheet_name', { length: 255 }),
  preparedBy: text('prepared_by'),
  weatherAm: text('weather_am'),
  weatherPm: text('weather_pm'),
  workItemsCount: integer('work_items_count').default(0),
  manpowerCount: integer('manpower_count').default(0),
  materialsCount: integer('materials_count').default(0),
  acceptanceCount: integer('acceptance_count').default(0),
  status: workflowStatusEnum('status').default('DRAFT'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  submittedAt: timestamp('submitted_at'),
});

export const dailyWorkItems = pgTable('daily_work_items', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  parentId: integer('parent_id'),
  ordinal: integer('ordinal'),
  nameVi: text('name_vi'),
  systemVi: text('system_vi'),
  progressPct: real('progress_pct'),
  planStartDate: date('plan_start_date'),
  planEndDate: date('plan_end_date'),
  actualStartDate: date('actual_start_date'),
  actualEndDate: date('actual_end_date'),
  lagDays: integer('lag_days'),
  notes: text('notes'),
});

export const dailyManpower = pgTable('daily_manpower', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  roleCode: varchar('role_code', { length: 50 }),
  roleNameVi: text('role_name_vi'),
  headcount: integer('headcount').default(0),
  notes: text('notes'),
});

export const dailyMaterials = pgTable('daily_materials', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  materialCode: varchar('material_code', { length: 50 }),
  nameVi: text('name_vi'),
  unit: varchar('unit', { length: 20 }),
  quantity: real('quantity'),
  notes: text('notes'),
});

export const dailyAcceptance = pgTable('daily_acceptance', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  ordinal: integer('ordinal'),
  nameVi: text('name_vi'),
  quantity: real('quantity'),
  unit: varchar('unit', { length: 20 }),
  notes: text('notes'),
});

export const dailyRecommendations = pgTable('daily_recommendations', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  ordinal: integer('ordinal'),
  text: text('text'),
});

export const dailySafety = pgTable('daily_safety', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  category: varchar('category', { length: 100 }),
  description: text('description'),
});

export const dailyInfos = pgTable('daily_infos', {
  id: serial('id').primaryKey(),
  dailyReportId: integer('daily_report_id').notNull().references(() => dailyReports.id, { onDelete: 'cascade' }),
  category: varchar('category', { length: 100 }),
  description: text('description'),
});

// ===== Shop Drawing =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — State machine:
//   DRAFT → SUBMITTED → REVIEW → APPROVED
//   Branching: REVIEW → REJECTED → DRAFT (bổ sung so với bản vẽ gốc mục 8)
//   Other possible: REVIEW → REVISION → SUBMITTED (loop)
// Schema column status dùng workflow_status enum (đã có REJECTED). Thêm:
//   - rejected_reason (text) để lưu lý do reject
//   - rejected_by (user_id) để track người reject
//   - reverted_to_draft_at (timestamp) để audit transition REJECTED → DRAFT
export const shopDrawings = pgTable('shop_drawings', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  zoneId: integer('zone_id').notNull().references(() => zones.id),
  sourceSheet: text('source_sheet'),
  drawingCode: varchar('drawing_code', { length: 100 }).notNull(),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  progressPct: real('progress_pct'),
  status: workflowStatusEnum('status').default('DRAFT'),
  plannedSubmitDate: date('planned_submit_date'),
  actualSubmitDate: date('actual_submit_date'),
  bqlL1Response: varchar('bql_l1_response', { length: 5 }),
  bqlL1Date: date('bql_l1_date'),
  bqlL1Comment: text('bql_l1_comment'),
  bqlL2Response: varchar('bql_l2_response', { length: 5 }),
  bqlL2Date: date('bql_l2_date'),
  bqlL2Comment: text('bql_l2_comment'),
  bqlL3Response: varchar('bql_l3_response', { length: 5 }),
  bqlL3Date: date('bql_l3_date'),
  bqlL3Comment: text('bql_l3_comment'),
  bqlL4Response: varchar('bql_l4_response', { length: 5 }),
  bqlL4Date: date('bql_l4_date'),
  bqlL4Comment: text('bql_l4_comment'),
  bqlL5Response: varchar('bql_l5_response', { length: 5 }),
  bqlL5Date: date('bql_l5_date'),
  bqlL5Comment: text('bql_l5_comment'),
  rs1PlannedDate: date('rs1_planned_date'),
  rs1ActualDate: date('rs1_actual_date'),
  rs2PlannedDate: date('rs2_planned_date'),
  rs2ActualDate: date('rs2_actual_date'),
  approvalDate: date('approval_date'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — REJECTED state fields
  rejectedReason: text('rejected_reason'),
  rejectedBy: integer('rejected_by').references(() => users.id),
  rejectedAt: timestamp('rejected_at'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — Track transition REJECTED → DRAFT
  revertedToDraftAt: timestamp('reverted_to_draft_at'),
  revertedToDraftBy: integer('reverted_to_draft_by').references(() => users.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('shop_project_code_idx').on(t.projectId, t.drawingCode),
  byProjectZone: index('shop_project_zone_idx').on(t.projectId, t.zoneId),
  byStatus: index('shop_status_idx').on(t.status),
}));

// ===== Construction Schedule =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.9) — planned quantity cần version theo thời gian
//   quantity hiện tại trong construction_schedule_items trở thành 1 version
//   schedule_baselines lưu lịch sử baseline (version, effective_date, created_by)
//   Khi baseline thay đổi → tạo version mới, KHÔNG sửa trực tiếp
// Thêm cột baseline_version (FK schedule_baselines.id, nullable) để liên kết
export const constructionScheduleItems = pgTable('construction_schedule_items', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  zoneId: integer('zone_id').notNull().references(() => zones.id),
  sourceSheet: text('source_sheet'),
  levelRoman: varchar('level_roman', { length: 10 }),
  levelArabic: integer('level_arabic'),
  sublevel: integer('sublevel'),
  ordinal: integer('ordinal'),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  progressPct: real('progress_pct'),
  status: varchar('status', { length: 50 }),
  planStartDate: date('plan_start_date'),
  actualStartDate: date('actual_start_date'),
  planEndDate: date('plan_end_date'),
  actualEndDate: date('actual_end_date'),
  planDurationDays: integer('plan_duration_days'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.9)
  baselineVersion: integer('baseline_version').default(1),
  baselineId: integer('baseline_id'),  // FK schedule_baselines (forward ref, defined below)
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProjectZone: index('cs_project_zone_idx').on(t.projectId, t.zoneId),
  byBaseline: index('cs_baseline_idx').on(t.baselineId),
}));

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.9) — Planned quantity baseline versioning
// Mỗi lần baseline thay đổi → tạo row mới với version tăng dần.
// Khi quantity thay đổi → KHÔNG update construction_schedule_items, tạo baseline mới + liên kết.
export const scheduleBaselines = pgTable('schedule_baselines', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  version: integer('version').notNull(),  // tăng dần: 1, 2, 3, ...
  effectiveDate: date('effective_date').notNull(),
  createdBy: integer('created_by').references(() => users.id),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProject: index('sb_project_idx').on(t.projectId),
  uniqueVersion: uniqueIndex('sb_project_version_idx').on(t.projectId, t.version),
}));

// ===== Materials =====
export const materials = pgTable('materials', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  zoneId: integer('zone_id').notNull().references(() => zones.id),
  sourceSheet: text('source_sheet'),
  materialCode: varchar('material_code', { length: 100 }),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  progressPct: real('progress_pct'),
  requestDate1: date('request_date_1'),
  deliveryDate1: date('delivery_date_1'),
  requestDate2: date('request_date_2'),
  deliveryDate2: date('delivery_date_2'),
  requestDate3: date('request_date_3'),
  deliveryDate3: date('delivery_date_3'),
  requestDate4: date('request_date_4'),
  deliveryDate4: date('delivery_date_4'),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProjectZone: index('mat_project_zone_idx').on(t.projectId, t.zoneId),
}));

// ===== Material Submittal (mục 43.4) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — Material Submittal workflow đầy đủ
// Fields bổ sung:
//   - sla_deadline: thời hạn review (date) — track SLA quá hạn
//   - sla_days: số ngày SLA (integer, default 7)
//   - revision_number: số vòng revision (integer, default 0)
//   - rejection_reason: lý do reject (text, bắt buộc khi status=REJECTED)
//   - approved_by: user_id của người approve
//   - submitted_by: user_id của người submit
export const materialSubmittals = pgTable('material_submittals', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  materialId: integer('material_id').references(() => materials.id),
  submittalCode: varchar('submittal_code', { length: 100 }),
  status: workflowStatusEnum('status').default('DRAFT'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — SLA fields
  slaDays: integer('sla_days').default(7),
  slaDeadline: date('sla_deadline'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — revision tracking
  revisionNumber: integer('revision_number').default(0),
  parentSubmittalId: integer('parent_submittal_id'),  // FK self, để chain revision history
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — rejection & audit
  rejectionReason: text('rejection_reason'),
  submittedBy: integer('submitted_by').references(() => users.id),
  approvedBy: integer('approved_by').references(() => users.id),
  submittedDate: date('submitted_date'),
  approvedDate: date('approved_date'),
  rejectedAt: timestamp('rejected_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProject: index('ms_project_idx').on(t.projectId),
  byMaterial: index('ms_material_idx').on(t.materialId),
  byStatus: index('ms_status_idx').on(t.status),
  byDeadline: index('ms_deadline_idx').on(t.slaDeadline),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — chain revision history
  parentRef: foreignKey({ columns: [t.parentSubmittalId], foreignColumns: [t.id], name: 'ms_parent_fk' }),
}));

// ===== RFA Log =====
export const rfaLog = pgTable('rfa_log', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  sourceSheet: text('source_sheet'),
  ordinal: integer('ordinal'),
  rfaCode: varchar('rfa_code', { length: 100 }).notNull(),
  descriptionVi: text('description_vi'),
  dateMa: date('date_ma'),
  dateSp: date('date_sp'),
  datePm: date('date_pm'),
  dateTp: date('date_tp'),
  dateSh: date('date_sh'),
  approvalDate: date('approval_date'),
  status: workflowStatusEnum('status').default('DRAFT'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueCode: uniqueIndex('rfa_project_code_idx').on(t.projectId, t.rfaCode),
}));

// ===== Subcontractors & Suppliers (tenant-level) =====
export const subcontractors = pgTable('subcontractors', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  name: text('name').notNull(),
  capabilitySummary: text('capability_summary'),
  status: masterStatusEnum('status').default('ACTIVE'),
  isInternalTeam: boolean('is_internal_team').default(false),
  sourceSheet: text('source_sheet'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const suppliers = pgTable('suppliers', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  name: text('name').notNull(),
  system: varchar('system', { length: 100 }),
  category: varchar('category', { length: 100 }),
  contact: text('contact'),
  status: masterStatusEnum('status').default('ACTIVE'),
  sourceSheet: text('source_sheet'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ===== Notifications (mục 43.6) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — Chỉ xử lý channel='in_app'
//   Các channel khác (email/zalo_oa/telegram/push) lưu record với status='not_implemented'
//   Không build logic gửi thật cho các kênh khác
// Fields bổ sung:
//   - channel: enum in_app | email | zalo_oa | telegram | push
//   - delivery_status: enum pending | sent | delivered | failed | not_implemented
//   - sent_at: thời điểm gửi
//   - delivered_at: thời điểm confirmed delivered (nếu có webhook callback)
export const notifications = pgTable('notifications', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  userId: integer('user_id').references(() => users.id),
  projectId: integer('project_id').references(() => projects.id),
  issueId: integer('issue_id'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — channel + delivery status
  channel: notificationChannelEnum('channel').default('in_app'),
  deliveryStatus: notificationStatusEnum('delivery_status').default('pending'),
  sentAt: timestamp('sent_at'),
  deliveredAt: timestamp('delivered_at'),
  severity: varchar('severity', { length: 20 }).default('info'),
  title: text('title'),
  body: text('body'),
  resourceType: varchar('resource_type', { length: 50 }),
  resourceId: integer('resource_id'),
  readAt: timestamp('read_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byUser: index('notif_user_idx').on(t.userId, t.readAt),
  byProject: index('notif_project_idx').on(t.projectId),
  byChannel: index('notif_channel_idx').on(t.channel, t.deliveryStatus),
}));

// ===== Audit Log =====
export const auditLog = pgTable('audit_log', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  userId: integer('user_id').references(() => users.id),
  action: varchar('action', { length: 50 }).notNull(),  // 'create' | 'update' | 'delete' | 'approve' | 'reject'
  resourceType: varchar('resource_type', { length: 50 }),
  resourceId: integer('resource_id'),
  before: jsonb('before'),
  after: jsonb('after'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byResource: index('audit_resource_idx').on(t.resourceType, t.resourceId),
  byUser: index('audit_user_idx').on(t.userId, t.createdAt),
}));

// ===== File Uploads =====
export const fileUploads = pgTable('file_uploads', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  projectId: integer('project_id').references(() => projects.id),
  originalFilename: text('original_filename').notNull(),
  storageKey: text('storage_key'),
  fileSize: bigint('file_size', { mode: 'number' }),
  fileHash: varchar('file_hash', { length: 64 }),
  mimeType: varchar('mime_type', { length: 100 }),
  expectedDocType: varchar('expected_doc_type', { length: 50 }),
  status: varchar('status', { length: 20 }).default('PROCESSING'),
  totalRows: integer('total_rows').default(0),
  okRows: integer('ok_rows').default(0),
  errorRows: integer('error_rows').default(0),
  reportJson: jsonb('report_json'),
  errorMessage: text('error_message'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  uniqueHash: uniqueIndex('uploads_tenant_hash_idx').on(t.tenantId, t.fileHash),
}));

// ===== Generic catch-all (cho các doc types chưa có schema riêng) =====
export const genericSheets = pgTable('generic_sheets', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').references(() => projects.id),
  docType: varchar('doc_type', { length: 50 }),
  sourceSheet: text('source_sheet'),
  zoneId: integer('zone_id').references(() => zones.id),
  ordinal: integer('ordinal'),
  col1: text('col_1'),
  col2: text('col_2'),
  col3: text('col_3'),
  col4: text('col_4'),
  col5: text('col_5'),
  col6: text('col_6'),
  col7: text('col_7'),
  col8: text('col_8'),
  col9: text('col_9'),
  col10: text('col_10'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ===== Master Data: Vendors, Teams, Workers, Cost Codes, Resources =====
export const vendors = pgTable('vendors', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }),
  name: text('name').notNull(),
  taxId: varchar('tax_id', { length: 50 }),
  contact: text('contact'),
  category: varchar('category', { length: 100 }),
  status: masterStatusEnum('status').default('ACTIVE'),
  legacyCode: varchar('legacy_code', { length: 100 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const teams = pgTable('teams', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }),
  name: text('name').notNull(),
  leadWorkerId: integer('lead_worker_id'),
  status: masterStatusEnum('status').default('ACTIVE'),
  legacyCode: varchar('legacy_code', { length: 100 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const workers = pgTable('workers', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }),
  fullName: text('full_name').notNull(),
  teamId: integer('team_id').references(() => teams.id),
  phone: varchar('phone', { length: 20 }),
  role: varchar('role', { length: 50 }),
  status: masterStatusEnum('status').default('ACTIVE'),
  legacyCode: varchar('legacy_code', { length: 100 }),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const costCodes = pgTable('cost_codes', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }),
  name: text('name').notNull(),
  category: varchar('category', { length: 100 }),
  unit: varchar('unit', { length: 20 }),
  unitPrice: decimal('unit_price', { precision: 18, scale: 2 }),
  status: masterStatusEnum('status').default('ACTIVE'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

export const resources = pgTable('resources', {
  id: serial('id').primaryKey(),
  tenantId: integer('tenant_id').notNull().references(() => tenants.id),
  code: varchar('code', { length: 50 }),
  name: text('name').notNull(),
  type: varchar('type', { length: 50 }),  // 'equipment' | 'tool' | 'vehicle'
  status: masterStatusEnum('status').default('ACTIVE'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ===== Work Items (Master Data, mục 43.9 — chưa chốt planned quantity) =====
export const workItems = pgTable('work_items', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  wbsId: integer('wbs_id').references(() => wbs.id),
  code: varchar('code', { length: 100 }),
  nameVi: text('name_vi'),
  nameEn: text('name_en'),
  unit: varchar('unit', { length: 20 }),
  plannedQty: decimal('planned_qty', { precision: 18, scale: 4 }),  // TODO: mục 43.9
  actualQty: decimal('actual_qty', { precision: 18, scale: 4 }),
  unitPrice: decimal('unit_price', { precision: 18, scale: 2 }),
  baselineVersion: integer('baseline_version').default(1),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// ===== Payment transaction model (mục 43.5) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — Đầy đủ: contract → invoice → payment_request → paid
// Cấu trúc:
//   contracts (master) → invoices (theo contract) → payment_requests (theo invoice) → payments (thanh toán thật)
//   payment có retention_amount, vat_amount, due_date
// Schema đã có vendors (master) + payments, bổ sung:
//   - contracts (id, project_id, vendor_id, contract_no, signed_date, value, status)
//   - invoices (id, contract_id, invoice_no, invoice_date, amount, vat_amount, status)
//   - payment_requests (id, invoice_id, request_no, request_date, retention_amount, due_date, status, amount)
//   - payments giữ nguyên (FK từ payment_requests.id thay vì project_id/vendor_id trực tiếp)

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — contracts master
export const contracts = pgTable('contracts', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  vendorId: integer('vendor_id').references(() => vendors.id),
  contractNo: varchar('contract_no', { length: 100 }).notNull(),
  contractName: text('contract_name'),
  signedDate: date('signed_date'),
  totalValue: decimal('total_value', { precision: 18, scale: 2 }),
  status: masterStatusEnum('status').default('ACTIVE'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProject: index('contract_project_idx').on(t.projectId),
  byVendor: index('contract_vendor_idx').on(t.vendorId),
  uniqueContractNo: uniqueIndex('contract_project_no_idx').on(t.projectId, t.contractNo),
}));

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — invoices
export const invoices = pgTable('invoices', {
  id: serial('id').primaryKey(),
  contractId: integer('contract_id').notNull().references(() => contracts.id),
  invoiceNo: varchar('invoice_no', { length: 100 }).notNull(),
  invoiceDate: date('invoice_date'),
  amount: decimal('amount', { precision: 18, scale: 2 }),
  vatAmount: decimal('vat_amount', { precision: 18, scale: 2 }),
  status: workflowStatusEnum('status').default('DRAFT'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byContract: index('invoice_contract_idx').on(t.contractId),
  uniqueInvoiceNo: uniqueIndex('invoice_contract_no_idx').on(t.contractId, t.invoiceNo),
}));

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — payment_requests
export const paymentRequests = pgTable('payment_requests', {
  id: serial('id').primaryKey(),
  invoiceId: integer('invoice_id').notNull().references(() => invoices.id),
  requestNo: varchar('request_no', { length: 100 }).notNull(),
  requestDate: date('request_date'),
  amount: decimal('amount', { precision: 18, scale: 2 }),
  retentionAmount: decimal('retention_amount', { precision: 18, scale: 2 }).default('0'),
  dueDate: date('due_date'),
  status: workflowStatusEnum('status').default('DRAFT'),
  approvedBy: integer('approved_by').references(() => users.id),
  approvedDate: date('approved_date'),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byInvoice: index('preq_invoice_idx').on(t.invoiceId),
  byStatus: index('preq_status_idx').on(t.status),
  byDueDate: index('preq_due_idx').on(t.dueDate),
  uniqueRequestNo: uniqueIndex('preq_invoice_no_idx').on(t.invoiceId, t.requestNo),
}));

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — payments table mở rộng
// Liên kết với payment_requests thay vì vendor/project trực tiếp
// Thêm: paid_at, paid_method, retention_held, vat_paid
export const payments = pgTable('payments', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — liên kết với payment_request
  paymentRequestId: integer('payment_request_id').references(() => paymentRequests.id),
  vendorId: integer('vendor_id').references(() => vendors.id),  // giữ để backward-compat
  contractNo: varchar('contract_no', { length: 100 }),
  invoiceNo: varchar('invoice_no', { length: 100 }),
  amount: decimal('amount', { precision: 18, scale: 2 }),
  paidAmount: decimal('paid_amount', { precision: 18, scale: 2 }),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — retention & VAT
  retentionAmount: decimal('retention_amount', { precision: 18, scale: 2 }),
  retentionHeld: decimal('retention_held', { precision: 18, scale: 2 }).default('0'),
  vatAmount: decimal('vat_amount', { precision: 18, scale: 2 }),
  vatPaid: decimal('vat_paid', { precision: 18, scale: 2 }).default('0'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — due_date + paid tracking
  dueDate: date('due_date'),
  paidAt: timestamp('paid_at'),
  paidMethod: varchar('paid_method', { length: 50 }),
  status: workflowStatusEnum('status').default('DRAFT'),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProject: index('pay_project_idx').on(t.projectId),
  byRequest: index('pay_request_idx').on(t.paymentRequestId),
  byDueDate: index('pay_due_idx').on(t.dueDate),
  byStatus: index('pay_status_idx').on(t.status),
}));

// ===== KPI targets (mục 43.10) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10) — KPI governance đầy đủ
// Fields bổ sung:
//   - period_lock (boolean): khoá không cho sửa KPI của kỳ đã đóng
//   - approved_by (user_id): người approve version hiện tại
//   - approved_at: thời điểm approve
//   - notes: ghi chú
//   - version: tăng dần mỗi lần thay đổi (existing field)
//   - effective_from: ngày bắt đầu áp dụng (existing field)
export const kpiTargets = pgTable('kpi_targets', {
  id: serial('id').primaryKey(),
  projectId: integer('project_id').notNull().references(() => projects.id),
  kpiCode: varchar('kpi_code', { length: 100 }),
  nameVi: text('name_vi'),
  targetValue: decimal('target_value', { precision: 18, scale: 4 }),
  actualValue: decimal('actual_value', { precision: 18, scale: 4 }),
  unit: varchar('unit', { length: 20 }),
  periodStart: date('period_start'),
  periodEnd: date('period_end'),
  version: integer('version').default(1),
  effectiveFrom: date('effective_from'),
  effectiveTo: date('effective_to'),  // ngày kết thúc áp dụng (NULL = current)
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10) — approver
  approvedBy: integer('approved_by').references(() => users.id),
  approvedAt: timestamp('approved_at'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10) — period lock
  periodLock: boolean('period_lock').default(false),
  notes: text('notes'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byProject: index('kpi_project_idx').on(t.projectId),
  byCode: index('kpi_code_idx').on(t.kpiCode),
  byPeriod: index('kpi_period_idx').on(t.periodStart, t.periodEnd),
}));

// ===== Offline Sync queue (mục 43.7) =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — Last-write-wins theo timestamp
// Khi 2 record cùng key conflict:
//   - Giữ bản có client_created_at/server timestamp mới hơn (theo clientTimestamp)
//   - Log bản bị ghi đè vào audit_log (không xoá mất hoàn toàn, để trace)
// Fields bổ sung:
//   - client_id: id phía client để detect conflict
//   - conflict_resolution: enum NONE | CLIENT_NEWER | SERVER_NEWER | EQUAL
//   - server_record_id: id record server bị overwrite (nếu có)
//   - superseded_at: thời điểm bị ghi đè
export const offlineSyncQueue = pgTable('offline_sync_queue', {
  id: serial('id').primaryKey(),
  userId: integer('user_id').notNull().references(() => users.id),
  deviceId: varchar('device_id', { length: 100 }),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — client_id để detect conflict
  clientId: varchar('client_id', { length: 200 }),
  resourceType: varchar('resource_type', { length: 50 }),
  resourceJson: jsonb('resource_json'),
  clientTimestamp: timestamp('client_timestamp').notNull(),
  clientCreatedAt: timestamp('client_created_at'),
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — conflict tracking
  conflictResolution: syncConflictEnum('conflict_resolution').default('NONE'),
  serverRecordId: integer('server_record_id'),
  supersededAt: timestamp('superseded_at'),
  status: varchar('status', { length: 20 }).default('PENDING'),
  errorMessage: text('error_message'),
  syncedAt: timestamp('synced_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
}, (t) => ({
  byUser: index('sync_user_idx').on(t.userId, t.status),
  byClientId: index('sync_client_idx').on(t.clientId, t.resourceType),
  byResource: index('sync_resource_idx').on(t.resourceType, t.serverRecordId),
}));
