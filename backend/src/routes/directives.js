// Directives routes — chỉ thị từ CEO/PMO

import { Router } from 'express';
import { requireAuth, requireRole } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { withAudit } from '../lib/with-audit.js';
import { notifyMany } from '../services/notify.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

router.get('/', async (req, res) => {
  const db = getDb();
  const { project_id, limit = 50 } = req.query;
  const where = ['1=1'];
  const params = [];
  let i = 1;
  if (project_id) { where.push(`project_id = $${i++}`); params.push(project_id); }
  const lim = Math.min(parseInt(limit) || 50, 200);
  params.push(lim);
  res.json(await db.prepare(
    `SELECT * FROM directives WHERE ${where.join(' AND ')} ORDER BY created_at DESC LIMIT $${i}`
  ).allAsync(...params));
});

router.post('/', requireRole('ceo', 'admin', 'pmo'), async (req, res) => {
  const db = getDb();
  const { project_id, body, issue_id, notify_to_user_ids } = req.body || {};
  if (!project_id || !body) return res.status(400).json({ error: 'project_id and body required' });
  const created = await withAudit(req, {
    action: 'DIRECTIVE', resourceType: 'directive', resourceId: 0,
    context: { project_id },
    after: { project_id, body, issue_id: issue_id || null },
    note: `Directive: ${body.slice(0, 80)}`,
  }, async (client) => {
    const ins = await client.query(
      `INSERT INTO directives (tenant_id, project_id, issue_id, from_user_id, from_user_name, body, notify_to_user_ids) VALUES (1, $1, $2, $3, $4, $5, $6) RETURNING *`,
      [project_id, issue_id || null, req.user.id, req.user.name || 'Admin', body, Array.isArray(notify_to_user_ids) ? notify_to_user_ids.join(',') : null]
    );
    return ins.rows[0];
  });
  // Send notifications (async, don't block response)
  if (notify_to_user_ids?.length) {
    notifyMany(req, notify_to_user_ids, {
      title: `Chỉ thị mới: ${project_id}`,
      body: body.slice(0, 200),
      link: `/hq/projects/${project_id}`,
      severity: 'INFO',
    }).catch(e => console.error('[notify] directive failed:', e.message));
  }
  res.json(created);
});

export default router;
