// API client + auth token management
const BASE = '/api';

let _token = localStorage.getItem('pmo_token');
let _user = (() => { try { return JSON.parse(localStorage.getItem('pmo_user')); } catch { return null; } })();

function authHeaders() {
  return _token ? { Authorization: `Bearer ${_token}` } : {};
}

async function req(path, opts = {}) {
  const r = await fetch(BASE + path, {
    ...opts,
    headers: { ...authHeaders(), ...(opts.headers || {}) },
  });
  if (!r.ok) {
    const t = await r.text();
    throw new Error(`${r.status}: ${t.slice(0, 200)}`);
  }
  return r.json();
}

export function setToken(t) {
  _token = t;
  if (t) localStorage.setItem('pmo_token', t);
  else localStorage.removeItem('pmo_token');
}

export function getToken() { return _token; }

export function getUser() {
  const u = localStorage.getItem('pmo_user');
  return u ? JSON.parse(u) : null;
}

export function setUser(u) {
  _user = u;
  if (u) localStorage.setItem('pmo_user', JSON.stringify(u));
  else localStorage.removeItem('pmo_user');
}

async function request(path, opts = {}) {
  const headers = { ...(opts.headers || {}) };
  if (_token) headers['Authorization'] = `Bearer ${_token}`;
  if (opts.body && !(opts.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(opts.body);
  }
  const r = await fetch(`${BASE}${path}`, { ...opts, headers });
  if (!r.ok) {
    const e = await r.json().catch(() => ({ error: r.statusText }));
    throw new Error(e.error || 'Request failed');
  }
  return r.status === 204 ? null : r.json();
}

// Auth
export const auth = {
  login: (email, password) => request('/auth/login', { method: 'POST', body: { email, password } }),
  logout: () => request('/auth/logout', { method: 'POST' }),
  me: () => request('/auth/me'),
};

// Issues (Mục 4-5, 6.5)
export const issues = {
  list: (projectId, params) => request(`/projects/${projectId}/issues${params ? '?' + new URLSearchParams(params) : ''}`),
  get: (id) => request(`/issues/${id}`),
  create: (data) => request('/issues', { method: 'POST', body: data }),
  addDirective: (id, body, notifyTo) => request(`/issues/${id}/directives`, { method: 'POST', body: { body, notify_to_user_ids: notifyTo } }),
};

// Directives (CEO/PMO qualitative notes)
export const directives = {
  list: (params) => request(`/directives${params ? '?' + new URLSearchParams(params) : ''}`),
  create: (data) => request('/directives', { method: 'POST', body: data }),
};

// Notifications (Bell dropdown)
export const notifications = {
  list: (unreadOnly = false) => request(`/notifications${unreadOnly ? '?unread=1' : ''}`),
  markRead: (id) => request(`/notifications/${id}/read`, { method: 'POST' }),
  markAllRead: () => request('/notifications/mark-all-read', { method: 'POST' }),
};

// Audit log
export const audit = {
  list: (params) => request(`/audit${params ? '?' + new URLSearchParams(params) : ''}`),
};

// Projects & related data
export const projects = {
  list: () => request('/projects'),
  get: (id) => request(`/projects/${id}`),
  areaHierarchy: (id) => request(`/projects/${id}/area-hierarchy`),
  scheduleBaselines: (id) => request(`/projects/${id}/schedule-baselines`),
  materialSubmittalsOverdue: (id) => request(`/projects/${id}/material-submittals/overdue`),
  payments: (id) => request(`/projects/${id}/payments`),
  contracts: (id) => request(`/projects/${id}/contracts`),
  invoices: (id) => request(`/contracts/${id}/invoices`),
  paymentRequests: (id) => request(`/invoices/${id}/payment-requests`),
  kpiTargets: (id) => request(`/projects/${id}/kpi-targets`),
};

// Shop drawings (state machine 43.3)
export const shopApi = {
  drawings: (projectId, params) => request(`/projects/${projectId}/shop-drawings${params ? '?' + new URLSearchParams(params) : ''}`),
  transition: (id, newStatus, reason) => request(`/shop-drawings/${id}/transition`, { method: 'POST', body: { new_status: newStatus, reason } }),
};
// Alias for backward compat
export const shop = shopApi;

// Material (submittal workflow 43.4)
export const materials = {
  list: (projectId, limit = 50) => request(`/projects/${projectId}/materials?limit=${limit}`),
  createSubmittal: (data) => request('/material-submittals', { method: 'POST', body: data }),
  submit: (id) => request(`/material-submittals/${id}/submit`, { method: 'POST' }),
  reject: (id, reason) => request(`/material-submittals/${id}/reject`, { method: 'POST', body: { reason } }),
  overdue: (projectId) => request(`/projects/${projectId}/material-submittals/overdue`),
};

// Material breakdown (pie tooltip)
export const materialBreakdown = {
  byProject: (projectId) => request(`/projects/${projectId}/material-breakdown`),
};

export const construction = {
  schedule: (projectId, params) => request(`/projects/${projectId}/construction-schedule${params ? '?' + new URLSearchParams(params) : ''}`),
  byZone: (projectId, code) => request(`/projects/${projectId}/zones/${code}/items`),
};

export const daily = {
  reports: (projectId) => request(`/projects/${projectId}/daily-reports`),
  get: (id) => request(`/daily-reports/${id}/full`),
};

export const businessProcess = {
  get: (code) => request(`/business-process/${code}`),
};

export const uploads = {
  list: () => request('/uploads'),
  upload: (file, projectCode) => {
    const fd = new FormData();
    fd.append('file', file);
    if (projectCode) fd.append('project_code', projectCode);
    return fetch(`${BASE}/upload`, { method: 'POST', body: fd, headers: _token ? { Authorization: `Bearer ${_token}` } : {} }).then(r => r.json());
  },
};

export const exportApi = {
  constructionSchedule: (projectId) => `${BASE}/export/construction-schedule/${projectId}.xlsx`,
  shopDrawings: (projectId) => `${BASE}/export/shop-drawings/${projectId}.xlsx`,
  dailyReport: (id) => `${BASE}/export/daily-report/${id}.xlsx`,
};

// Master data
export const masterData = {
  subcontractors: () => request('/master-data/subcontractors'),
  suppliers: () => request('/master-data/suppliers'),
  businessProcesses: () => request('/master-data/business-processes'),
};

// Sync queue (43.7)
export const sync = {
  queue: () => request('/sync/queue'),
  resolve: (data) => request('/sync/resolve', { method: 'POST', body: data }),
};

// KPI targets (43.10)
export const kpi = {
  list: (projectId) => request(`/projects/${projectId}/kpi-targets`),
  update: (id, data) => request(`/kpi-targets/${id}`, { method: 'PUT', body: data }),
};

// Permission check (43.2)
export const permissions = {
  me: () => request('/me/permissions'),
};

export const api = { issues, directives, notifications, audit, materialBreakdown, projects, shopApi, materials, masterData, sync, kpi, permissions };
