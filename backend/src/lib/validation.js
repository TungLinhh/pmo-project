// Validation logic & state machine cho các mục 43
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.x) — mọi hàm dưới đây là quyết định TẠM

// ===== 43.3 - Shopdrawing state machine =====
export const SHOP_DRAWING_STATE_MACHINE = {
  DRAFT: ['SUBMITTED', 'REJECTED'],
  SUBMITTED: ['REVIEW', 'DRAFT', 'REJECTED'],
  REVIEW: ['APPROVED', 'REJECTED', 'REVISION'],
  APPROVED: [],  // terminal
  REJECTED: ['DRAFT'],  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — bổ sung so với bản vẽ gốc
  REVISION: ['SUBMITTED', 'DRAFT'],
  PENDING: ['SUBMITTED', 'DRAFT'],
  OVERDUE: ['REJECTED', 'REVISION'],
  CLOSED: [],  // terminal
};
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — nếu transition REJECTED → DRAFT xảy ra:
//   - set reverted_to_draft_at = now()
//   - set reverted_to_draft_by = user_id
//   - ghi audit_log action=DIRECTIVE
//   - field rejected_reason vẫn giữ để trace lý do ban đầu

export function validateShopDrawingTransition(currentState, newState) {
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3)
  const allowed = SHOP_DRAWING_STATE_MACHINE[currentState] || [];
  if (!allowed.includes(newState)) {
    return { valid: false, error: `Cannot transition from ${currentState} to ${newState}. Allowed: ${allowed.join(', ')}` };
  }
  return { valid: true };
}

// ===== 43.4 - Material Submittal validation =====
export const MAT_SUBMITTAL_STATE_MACHINE = {
  DRAFT: ['PENDING', 'SUBMITTED'],
  PENDING: ['REVIEW', 'REJECTED', 'REVISION'],
  SUBMITTED: ['REVIEW', 'REJECTED', 'REVISION'],
  REVIEW: ['APPROVED', 'REJECTED', 'REVISION'],
  APPROVED: [],  // terminal
  REJECTED: ['DRAFT', 'REVISION'],  // re-do hoặc revise
  REVISION: ['SUBMITTED', 'DRAFT'],
  OVERDUE: ['REJECTED', 'REVISION'],
  CLOSED: [],
};
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — bắt buộc:
//   - khi status=REJECTED, rejection_reason NOT NULL
//   - sla_deadline được tính = submitted_date + sla_days
//   - mỗi revision tạo row mới (parent_submittal_id liên kết chain)

export function validateMaterialSubmittalTransition(currentState, newState) {
  const allowed = MAT_SUBMITTAL_STATE_MACHINE[currentState] || [];
  if (!allowed.includes(newState)) {
    return { valid: false, error: `Cannot transition from ${currentState} to ${newState}. Allowed: ${allowed.join(', ')}` };
  }
  return { valid: true };
}

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — compute SLA deadline từ submitted_date + sla_days
export function computeSlaDeadline(submittedDate, slaDays = 7) {
  if (!submittedDate) return null;
  const d = new Date(submittedDate);
  d.setDate(d.getDate() + slaDays);
  return d.toISOString().slice(0, 10);
}

// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — check overdue
export function isSlaOverdue(deadline, status) {
  if (!deadline || status === 'APPROVED' || status === 'CLOSED') return false;
  return new Date(deadline) < new Date();
}

// ===== 43.5 - Payment state machine =====
export const PAYMENT_STATE_MACHINE = {
  DRAFT: ['PENDING', 'SUBMITTED'],
  PENDING: ['REVIEW', 'REJECTED'],
  SUBMITTED: ['REVIEW', 'APPROVED', 'REJECTED'],
  REVIEW: ['APPROVED', 'REJECTED'],
  APPROVED: ['PAID', 'OVERDUE'],
  PAID: [],  // terminal
  REJECTED: ['DRAFT'],
  OVERDUE: ['PAID', 'REJECTED'],
  CLOSED: [],
};
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.5) — flow:
//   contracts (sign) → invoices (vendor xuất) → payment_requests (PM yêu cầu) → APPROVED → PAID
//   retention_amount: giữ lại 5-10% tuỳ hợp đồng
//   vat_amount: tính theo % quy định

export function validatePaymentTransition(currentState, newState) {
  const allowed = PAYMENT_STATE_MACHINE[currentState] || [];
  if (!allowed.includes(newState)) {
    return { valid: false, error: `Cannot transition from ${currentState} to ${newState}. Allowed: ${allowed.join(', ')}` };
  }
  return { valid: true };
}

// ===== 43.7 - Last-write-wins conflict resolution =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7)
export function resolveConflict(clientTs, serverTs) {
  const c = new Date(clientTs).getTime();
  const s = new Date(serverTs).getTime();
  if (c > s) return { winner: 'CLIENT', clientNewer: true, serverNewer: false };
  if (s > c) return { winner: 'SERVER', clientNewer: false, serverNewer: true };
  return { winner: 'EQUAL', clientNewer: false, serverNewer: false };
}

// ===== 43.10 - KPI period lock check =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10)
export function isPeriodLocked(kpi) {
  // Period locked = period_lock=true OR period_end < today
  if (kpi.period_lock) return true;
  if (kpi.period_end && new Date(kpi.period_end) < new Date()) return true;
  return false;
}

export function canEditKpi(kpi) {
  return !isPeriodLocked(kpi);
}

// ===== 43.6 - Notification channel logic =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — chỉ xử lý in_app
export function getNotificationDeliveryStatus(channel) {
  if (channel === 'in_app') return 'pending';  // sẽ xử lý ngay
  return 'not_implemented';  // email/zalo_oa/telegram/push
}

// ===== 43.2 - 6 role permission helper =====
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) — 6 role cố định
// Mapping: CEO (is_ceo flag), PM (pm), PMO (pmo), Site (site), Procurement (procurement), Accounting (accounting)
const PERMISSIONS = {
  // module: ['read', 'write']
  CEO: { shop: ['read', 'write'], payment: ['read', 'write'], material: ['read'], schedule: ['read', 'write'], master_data: ['read'], approval: ['read', 'write'] },
  PM: { shop: ['read', 'write'], payment: ['read'], material: ['read', 'write'], schedule: ['read', 'write'], master_data: ['read'], approval: ['read'] },
  PMO: { shop: ['read', 'write'], payment: ['read', 'write'], material: ['read', 'write'], schedule: ['read', 'write'], master_data: ['read', 'write'], approval: ['read', 'write'] },
  SITE: { shop: ['read'], payment: [], material: ['read'], schedule: ['read', 'write'], master_data: [], approval: [] },
  PROCUREMENT: { shop: ['read'], payment: ['read', 'write'], material: ['read', 'write'], schedule: [], master_data: ['read', 'write'], approval: [] },
  ACCOUNTING: { shop: [], payment: ['read', 'write'], material: [], schedule: [], master_data: ['read'], approval: ['read', 'write'] },
};
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) — admin tương đương PMO; editor xem tất cả
const ROLE_MAP = { admin: 'PMO', editor: 'PMO' };

export function getUserRole(user) {
  if (!user) return null;
  if (user.is_ceo) return 'CEO';
  return ROLE_MAP[user.role] || user.role?.toUpperCase() || null;
}

export function hasPermission(user, module, action = 'read') {
  const role = getUserRole(user);
  if (!role) return false;
  const perms = PERMISSIONS[role]?.[module] || [];
  return perms.includes(action);
}
