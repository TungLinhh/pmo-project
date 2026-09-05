// Projects routes — list, detail, zones, close, revoke

import { Router } from 'express';
import { requireAuth, requireRole, currentUser } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { withAudit } from '../lib/with-audit.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

router.get('/', async (req, res) => {
  const db = getDb();
  const { include_closed = '0' } = req.query;
  let sql = 'SELECT * FROM projects WHERE tenant_id = 1';
  const params = [];
  if (include_closed !== '1') sql += " AND status != 'CLOSED'";
  sql += ' ORDER BY id';
  res.json(await db.prepare(sql).allAsync(...params));
});

router.post('/:id/close', requireRole('ceo', 'admin'), async (req, res) => {
  const db = getDb();
  const { reason } = req.body || {};
  const proj = await db.prepare('SELECT * FROM projects WHERE id = ?').getAsync(req.params.id);
  if (!proj) return res.status(404).json({ error: 'Not found' });
  if (proj.status === 'CLOSED') return res.status(409).json({ error: 'Đã CLOSED. Dùng /revoke-close.' });
  try {
    const updated = await withAudit(req, {
      action: 'CLOSE', resourceType: 'project', resourceId: Number(req.params.id),
      context: { project_id: Number(req.params.id) },
      before: proj,
      after: { ...proj, status: 'CLOSED', closed_at: new Date().toISOString(), closed_by: req.user.id, close_reason: reason || null },
      fieldChanges: [
        { field: 'status', from: proj.status, to: 'CLOSED' },
        { field: 'closed_at', from: null, to: new Date().toISOString() },
      ],
      note: `Close project: ${reason || 'no reason'}`,
    }, async (client) => {
      const r = await client.query(
        `UPDATE projects SET status = 'CLOSED', closed_at = now(), closed_by = $1, close_reason = $2 WHERE id = $3 RETURNING *`,
        [req.user.id, reason || null, req.params.id]
      );
      return r.rows[0];
    });
    res.json(updated);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/:id/revoke-close', requireRole('ceo', 'admin'), async (req, res) => {
  const db = getDb();
  const proj = await db.prepare('SELECT * FROM projects WHERE id = ?').getAsync(req.params.id);
  if (!proj) return res.status(404).json({ error: 'Not found' });
  if (proj.status !== 'CLOSED') return res.status(409).json({ error: 'Project chưa CLOSED' });
  try {
    const updated = await withAudit(req, {
      action: 'REVOKE_CLOSE', resourceType: 'project', resourceId: Number(req.params.id),
      context: { project_id: Number(req.params.id) },
      before: proj,
      after: { ...proj, status: 'ACTIVE', closed_at: null },
      fieldChanges: [
        { field: 'status', from: 'CLOSED', to: 'ACTIVE' },
        { field: 'closed_revoked_at', from: null, to: new Date().toISOString() },
      ],
      note: 'Revoke close project',
    }, async (client) => {
      const r = await client.query(
        `UPDATE projects SET status = 'ACTIVE', closed_at = NULL, closed_by = NULL, close_reason = NULL, closed_revoked_at = now(), closed_revoked_by = $1 WHERE id = $2 RETURNING *`,
        [req.user.id, req.params.id]
      );
      return r.rows[0];
    });
    res.json(updated);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Project-scoped resources (zones, materials, contracts, etc.)
router.get('/:id/zones', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM zones WHERE project_id = ? ORDER BY code').allAsync(req.params.id));
});

router.get('/:id/materials', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM materials WHERE project_id = ? ORDER BY id').allAsync(req.params.id));
});

router.get('/:id/contracts', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM contracts WHERE project_id = ? ORDER BY created_at DESC').allAsync(req.params.id));
});

router.get('/:id/payments', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM payments WHERE project_id = ? ORDER BY id DESC').allAsync(req.params.id));
});

router.get('/:id/daily-reports', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM daily_reports WHERE project_id = ? ORDER BY report_date DESC').allAsync(req.params.id));
});

router.get('/:id/issues', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM issues WHERE project_id = ? ORDER BY created_at DESC LIMIT 200').allAsync(req.params.id));
});

router.post('/:id/issues', async (req, res) => {
  const { createIssue } = await import('./issues.js');
  return createIssue(req, res);
});

router.get('/:id/construction-schedule', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM construction_schedule_items WHERE project_id = $1 ORDER BY plan_start_date').allAsync(req.params.id));
});

router.get('/:id/shop-drawings', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT * FROM shop_drawings WHERE project_id = ? ORDER BY id DESC').allAsync(req.params.id));
});

router.get('/:id/material-breakdown', async (req, res) => {
  const db = getDb();
  // materials schema không có category/quantity → breakdown theo zone_id
  res.json(await db.prepare(
    `SELECT zone_id, COUNT(*) as count FROM materials WHERE project_id = $1 GROUP BY zone_id ORDER BY count DESC`
  ).allAsync(req.params.id));
});

// Submittal overdue / pending
router.get('/:id/material-submittals/overdue', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare(`
    SELECT * FROM material_submittals
    WHERE project_id = ?
      AND status NOT IN ('APPROVED', 'CLOSED')
      AND (sla_deadline < CURRENT_DATE OR supervisor_deadline < CURRENT_DATE)
  `).allAsync(req.params.id));
});

router.get('/:id/material-submittals/pending-supervisor', async (req, res) => {
  const db = getDb();
  const within = Math.min(parseInt(req.query.within_days) || 3, 30);
  res.json(await db.prepare(`
    SELECT * FROM material_submittals
    WHERE project_id = ? AND status = 'SUBMITTED'
      AND supervisor_deadline <= (CURRENT_DATE + (? || ' days')::INTERVAL)
    ORDER BY supervisor_deadline ASC
  `).allAsync(req.params.id, String(within)));
});

// Schedule baseline
router.post('/:id/schedule-baselines', async (req, res) => {
  const db = getDb();
  const { notes, effective_date } = req.body || {};
  const lastV = await db.prepare('SELECT COALESCE(MAX(version), 0) as v FROM schedule_baselines WHERE project_id = $1').getAsync(req.params.id);
  const newV = (lastV?.v || 0) + 1;
  const effDate = effective_date || new Date().toISOString().slice(0, 10);
  const info = await db.prepare(
    `INSERT INTO schedule_baselines (project_id, version, effective_date, notes, created_by, created_at) VALUES ($1, $2, $3, $4, $5, now())`
  ).runAsync(req.params.id, newV, effDate, notes || null, req.user.id);
  res.json({ id: info.lastInsertRowid, version: newV });
});

router.get('/:id/schedule-baselines', async (req, res) => {
  const db = getDb();
  res.json(await db.prepare('SELECT id, project_id, version, notes, created_at, created_by FROM schedule_baselines WHERE project_id = ? ORDER BY version DESC').allAsync(req.params.id));
});

router.get('/:id/schedule-baselines/:version', async (req, res) => {
  const db = getDb();
  const r = await db.prepare('SELECT * FROM schedule_baselines WHERE project_id = ? AND version = ?').getAsync(req.params.id, req.params.version);
  if (!r) return res.status(404).json({ error: 'Not found' });
  res.json(r);
});

export default router;
