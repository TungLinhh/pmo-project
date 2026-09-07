// P1-02: sync queue reads offline_sync_queue; resolve uses timestamp comparison + real columns.
// Run: DATABASE_URL=postgresql://pmo_user:pmo_dev_pwd@127.0.0.1:5433/pmo node tests/e2e/p1-02-sync.mjs
import { spawn, execSync } from 'node:child_process';

let failures = 0;
const ok = (cond, msg) => { console.log(`${cond ? 'PASS' : 'FAIL'} — ${msg}`); if (!cond) failures++; };
const DB = process.env.DATABASE_URL || 'postgresql://pmo_user:pmo_dev_pwd@127.0.0.1:5433/pmo';
const BASE = 'http://localhost:3202';
const PSQL = 'PGPASSWORD=pmo_dev_pwd /home/linuxbrew/.linuxbrew/bin/psql -h 127.0.0.1 -p 5433 -U pmo_user -d pmo -t -A';
const psql = (sql) => execSync(`${PSQL} -c "${sql.replace(/"/g, '\\"')}"`, { encoding: 'utf8' }).trim();

const srv = spawn('node', ['backend/src/index.js'], { env: { ...process.env, DATABASE_URL: DB, PORT: '3202' }, stdio: 'ignore' });
await new Promise(r => setTimeout(r, 3500));
try {
  const login = await fetch(BASE + '/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'admin@hbg.com', password: 'admin123' }) });
  const { token, user } = await login.json();
  const H = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` };

  // seed a pending item with old client_timestamp (server receipt = created_at → SERVER newer)
  const qid = psql(`INSERT INTO offline_sync_queue (user_id, resource_type, resource_json, client_timestamp, server_record_id, status) VALUES (${user.id}, 'daily_report', '{"a":1}', now() - INTERVAL '2 hours', NULL, 'PENDING') RETURNING id;`).split('\n')[0];
  const q = await fetch(BASE + '/api/sync/queue', { headers: H }).then(r => r.json());
  ok(Array.isArray(q) && q.some(x => String(x.id) === String(qid)), `queue lists seeded item (got ${q.length} rows)`);

  const res = await fetch(BASE + '/api/sync/resolve', { method: 'POST', headers: H, body: JSON.stringify({ queue_id: Number(qid), winner: 'CLIENT' }) }).then(r => r.json());
  ok(res.ok && res.winner === 'CLIENT', `resolve ok with winner (got ${JSON.stringify(res).slice(0, 120)})`);
  ok(res.comparison && res.comparison.winner === 'SERVER', `timestamp comparison meaningful, not EQUAL-by-NaN (got ${res.comparison?.winner})`);
  const st = psql(`SELECT status || '/' || conflict_resolution FROM offline_sync_queue WHERE id=${qid};`);
  ok(st === 'RESOLVED/CLIENT_NEWER', `row records explicit winner (got ${st})`);

  // validation + 404 paths
  const bad = await fetch(BASE + '/api/sync/resolve', { method: 'POST', headers: H, body: JSON.stringify({}) });
  ok(bad.status === 400, `missing args → 400 (got ${bad.status})`);
  const nf = await fetch(BASE + '/api/sync/resolve', { method: 'POST', headers: H, body: JSON.stringify({ queue_id: 999999999, winner: 'SERVER' }) });
  ok(nf.status === 404, `unknown id → 404 (got ${nf.status})`);
  psql(`DELETE FROM offline_sync_queue WHERE id=${qid};`);
} finally {
  srv.kill('SIGTERM');
  await new Promise(r => setTimeout(r, 1000));
}
console.log(failures ? `\n${failures} FAILURE(S)` : '\nALL PASS');
process.exit(failures ? 1 : 0);
