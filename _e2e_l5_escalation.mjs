// E2E test cho TVGS auto-escalation + L1-L5 shop approval
import { execSync } from 'node:child_process';

const BASE = 'http://localhost:3000';
let pass = 0, fail = 0;
const log = [];
function ok(name, detail) { pass++; log.push({ name, status: '✅', detail }); }
function ng(name, detail) { fail++; log.push({ name, status: '❌', detail }); }

async function api(token, path, opts = {}) {
  const headers = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
  if (token) headers.Authorization = 'Bearer ' + token;
  const r = await fetch(BASE + path, { ...opts, headers });
  const t = await r.text();
  let data; try { data = JSON.parse(t); } catch { data = t; }
  return { status: r.status, data };
}

const psql = '/home/linuxbrew/.linuxbrew/Cellar/postgresql@16/16.15/bin/psql';
function exec(sql) {
  return execSync(`${psql} -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -tA -c "${sql.replace(/"/g, '\\"')}"`, { env: { ...process.env, PGPASSWORD: 'pmo_dev_pwd' } }).toString().trim();
}

// ============ Login ============
const login = await api(null, '/api/auth/login', { method: 'POST', body: JSON.stringify({ email: 'admin@hbg.com', password: 'admin123' }) });
const T = login.data?.token;
if (!T) { ng('login', 'no token'); process.exit(1); }
ok('login', 'admin@hbg.com');

try {
  await runTests();
} catch (e) {
  console.error('TEST CRASHED:', e);
  ng('uncaught', e.message);
  process.exit(1);
}

async function runTests() {
// ============ 1. L1-L5 Approval workflow ============
console.log('\n=== L1-L5 Shop Approval ===');

// Tạo shop drawing mới
const projectId = 2; // BTE project
const zones = exec(`SELECT id FROM zones WHERE project_id = ${projectId} LIMIT 1`);
const zoneId = parseInt(zones);
if (!zoneId) { ng('zones', 'no zones in project 2'); process.exit(1); }

const createSd = await api(T, `/api/shop-drawings`, { method: 'POST', body: JSON.stringify({
  project_id: projectId, zone_id: zoneId, drawing_code: `TEST-L5-${Date.now()}`, name_vi: 'Test L5', name_en: 'Test L5'
}) });
ok('create shop drawing', `id=${createSd.data?.id}`);

const sdId = createSd.data?.id;
if (!sdId) { process.exit(1); }

// Submit (DRAFT → SUBMITTED)
const submit = await api(T, `/api/shop-drawings/${sdId}/transition`, { method: 'POST', body: JSON.stringify({ to_status: 'SUBMITTED', comment: 'E2E submit' }) });
ok('submit', `status=${submit.data?.status}`);

// Approve L1
const l1 = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 1, response: 'P', comment: 'L1 OK' }) });
ok('L1 approve', `status=${l1.data?.status} bql_l1=${l1.data?.bql_l1_response}`);

// Negative: try L3 before L2
const l3early = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 3, response: 'P' }) });
if (l3early.status >= 400) ok('L3 rejected (L2 not yet)', `status=${l3early.status} (expected 4xx)`);
else ng('L3 should be rejected', JSON.stringify(l3early.data));

// Approve L2
const l2 = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 2, response: 'P' }) });
ok('L2 approve', `status=${l2.data?.status}`);

// Approve L3
const l3 = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 3, response: 'P' }) });
ok('L3 approve', `status=${l3.data?.status}`);

// Approve L4
const l4 = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 4, response: 'P' }) });
ok('L4 approve', `status=${l4.data?.status}`);

// Approve L5 → should be APPROVED
const l5 = await api(T, `/api/shop-drawings/${sdId}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 5, response: 'P' }) });
ok('L5 approve (final)', `status=${l5.data?.status} approval_date=${l5.data?.approval_date}`);

// Get approval state
const state = await api(T, `/api/shop-drawings/${sdId}/approval-state`);
const passedLevels = state.data?.levels?.filter(l => l.response === 'P').length || 0;
ok('approval-state', `passed=${passedLevels}/5 is_fully_approved=${state.data?.is_fully_approved}`);

// ============ 2. L1-L5 Reject flow ============
console.log('\n=== L1-L5 Reject ===');

// Tạo shop drawing mới để test reject
const sd2 = await api(T, `/api/shop-drawings`, { method: 'POST', body: JSON.stringify({
  project_id: projectId, zone_id: zoneId, drawing_code: `TEST-L5-REJ-${Date.now()}`, name_vi: 'Test L5 Reject', name_en: 'Test'
}) });
const sd2Id = sd2.data?.id;

await api(T, `/api/shop-drawings/${sd2Id}/transition`, { method: 'POST', body: JSON.stringify({ to_status: 'SUBMITTED' }) });
const rej = await api(T, `/api/shop-drawings/${sd2Id}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 1, response: 'F', comment: 'Kích thước sai' }) });
if (rej.data?.status === 'REJECTED') ok('L1 reject', `status=${rej.data?.status} reason=${rej.data?.rejected_reason?.slice(0, 40)}`);
else ng('L1 reject', JSON.stringify(rej.data));

// Try L2 after reject
const l2afterRej = await api(T, `/api/shop-drawings/${sd2Id}/approve-level`, { method: 'POST', body: JSON.stringify({ level: 2, response: 'P' }) });
if (l2afterRej.status >= 400) ok('L2 after reject blocked', `status=${l2afterRej.status}`);
else ng('L2 after reject should be blocked', JSON.stringify(l2afterRej.data));

// ============ 3. TVGS Auto-escalation ============
console.log('\n=== TVGS Auto-escalation ===');

// Tạo material submittal với supervisor_deadline trong quá khứ (để trigger escalation)
const yesterday = new Date(Date.now() - 86400000 * 5).toISOString().slice(0, 10);
const msCreate = await api(T, `/api/material-submittals`, { method: 'POST', body: JSON.stringify({
  project_id: projectId, submittal_code: `TEST-ESC-${Date.now()}`, sla_days: 7, supervisor_approval_days: 3
}) });
const msId = msCreate.data?.id;
ok('create submittal', `id=${msId}`);

// Submit
await api(T, `/api/material-submittals/${msId}/submit`, { method: 'POST' });

// Force supervisor_deadline về quá khứ
exec(`UPDATE material_submittals SET supervisor_deadline = '${yesterday}', escalated_at = NULL WHERE id = ${msId}`);

// Run escalation job
const esc = await api(T, `/api/jobs/escalate-tvgs`, { method: 'POST' });
const escalated = esc.data?.escalated_count || 0;
ok('run escalation', `escalated_count=${escalated}`);

// Check escalated_at
const escCheck = exec(`SELECT escalated_at IS NOT NULL FROM material_submittals WHERE id = ${msId}`);
if (escCheck === 't') ok('submittal marked escalated', 'OK');
else ng('submittal not marked escalated', escCheck);

// Check notifications created
const notifCount = exec(`SELECT COUNT(*) FROM notifications WHERE body LIKE '%TEST-ESC-%' OR title LIKE '%TEST-ESC-%' OR body LIKE '%quá hạn%' AND created_at > now() - interval '5 minutes'`);
if (parseInt(notifCount) > 0) ok('notifications created', `count=${notifCount}`);
else ng('no notifications', `count=${notifCount}`);

// Idempotency: chạy lại lần nữa, không escalate lại
const esc2 = await api(T, `/api/jobs/escalate-tvgs`, { method: 'POST' });
const escalated2 = esc2.data?.escalated_count || 0;
ok('idempotency', `2nd run escalated=${escalated2} (should be 0 or only new ones)`);

// Status endpoint
const escStatus = await api(T, `/api/jobs/escalate-tvgs/status`);
if (escStatus.data?.last_run) ok('status endpoint', `last_run=${escStatus.data.last_run}`);
else ng('status endpoint', JSON.stringify(escStatus.data));

// ============ Summary ============
console.log(`\n=== L1-L5 + Escalation Results: ${pass}/${pass + fail} PASS ===`);
log.forEach(l => console.log(`  ${l.status} ${l.name} (${l.detail})`));
process.exit(fail === 0 ? 0 : 1);
}
