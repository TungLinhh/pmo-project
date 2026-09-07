// Master data — generic CRUD cho vendors, subcontractors, suppliers, workers, teams, cost_codes
// Cú pháp: GET /api/master-data/:resource trả về list, POST để tạo mới

import { Router } from 'express';
import { requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { withAudit } from '../lib/with-audit.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

const TABLES = {
  vendors: 'vendors',
  subcontractors: 'subcontractors',
  suppliers: 'suppliers',
  workers: 'workers',
  teams: 'teams',
  cost_codes: 'cost_codes',
  resources: 'resources',
  business_processes: 'business_processes',
  'business-processes': 'business_processes',
};

router.get('/:resource', async (req, res) => {
  const table = TABLES[req.params.resource];
  if (!table) return res.status(404).json({ error: `Unknown resource: ${req.params.resource}` });
  const db = getDb();
  res.json(await db.prepare(`SELECT * FROM ${table} ORDER BY id LIMIT 500`).allAsync());
});

router.post('/:resource', async (req, res) => {
  const table = TABLES[req.params.resource];
  if (!table) return res.status(404).json({ error: `Unknown resource` });
  const db = getDb();
  const data = req.body || {};
  const cols = Object.keys(data);
  if (!cols.length) return res.status(400).json({ error: 'Empty body' });
  // Whitelist common columns
  const safe = cols.filter(c => /^[a-z_]+$/i.test(c));
  if (!safe.length) return res.status(400).json({ error: 'No valid columns' });
  const placeholders = safe.map((_, i) => `$${i + 1}`).join(', ');
  try {
    const r = await withAudit(req, {
      action: 'CREATE', resourceType: table, resourceId: 0,
      context: {},
      after: data,
      note: `Tạo ${table}`,
    }, async (client) => {
      const ins = await client.query(
        `INSERT INTO ${table} (${safe.join(', ')}) VALUES (${placeholders}) RETURNING *`,
        safe.map(c => data[c])
      );
      return ins.rows[0];
    });
    res.json(r);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
