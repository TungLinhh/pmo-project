// Sync routes — offline queue resolve

import { Router } from 'express';
import { requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { withAudit } from '../lib/with-audit.js';
import { resolveConflict } from '../lib/validation.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

router.get('/queue', async (req, res) => {
  const db = getDb();
  const rows = await db.prepare(`
    SELECT * FROM sync_queue
    WHERE user_id = ? AND status = 'PENDING'
    ORDER BY created_at ASC LIMIT 100
  `).allAsync(req.user.id);
  res.json(rows);
});

router.post('/resolve', async (req, res) => {
  const db = getDb();
  const { queue_id, winner } = req.body || {};
  if (!queue_id || !['SERVER', 'CLIENT'].includes(winner)) {
    return res.status(400).json({ error: 'queue_id and winner=SERVER|CLIENT required' });
  }
  const item = await db.prepare('SELECT * FROM sync_queue WHERE id = ?').getAsync(queue_id);
  if (!item) return res.status(404).json({ error: 'Not found' });
  const resolution = resolveConflict({ client_payload: item.payload, server_record: item.server_record });
  if (winner === 'SERVER' && item.server_record_id) {
    try {
      await withAudit(req, {
        action: 'SYNC_RESOLVE', resourceType: item.resource_type, resourceId: item.server_record_id,
        context: { queue_id, winner },
        before: item.payload,
        after: item.server_record,
        note: `Resolve sync conflict (winner=SERVER) for queue #${queue_id}`,
      }, async (client) => {
        await client.query(`UPDATE sync_queue SET status = 'RESOLVED', resolution = 'SERVER', resolved_at = now(), resolved_by = $1 WHERE id = $2`, [req.user.id, queue_id]);
        return { ok: true };
      });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  } else {
    await db.prepare(`UPDATE sync_queue SET status = 'RESOLVED', resolution = 'CLIENT', resolved_at = now(), resolved_by = ? WHERE id = ?`).runAsync(req.user.id, queue_id);
  }
  res.json({ ok: true, resolution });
});

export default router;
