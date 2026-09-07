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
    SELECT * FROM offline_sync_queue
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
  const item = await db.prepare('SELECT * FROM offline_sync_queue WHERE id = ?').getAsync(queue_id);
  if (!item) return res.status(404).json({ error: 'Not found' });
  // Last-write-wins advisory: client_timestamp vs server receipt (synced_at || created_at).
  // Explicit `winner` decides and is recorded; timestamp comparison is returned for transparency.
  const comparison = resolveConflict(item.client_timestamp, item.synced_at || item.created_at);
  const conflictResolution = winner === 'CLIENT' ? 'CLIENT_NEWER' : 'SERVER_NEWER';
  if (winner === 'SERVER' && item.server_record_id) {
    try {
      await withAudit(req, {
        action: 'SYNC_RESOLVE', resourceType: item.resource_type, resourceId: item.server_record_id,
        context: { queue_id, winner, comparison: comparison.winner },
        before: item.resource_json,
        after: item.resource_json,
        note: `Resolve sync conflict (winner=SERVER) for queue #${queue_id}`,
      }, async (client) => {
        await client.query(`UPDATE offline_sync_queue SET status = 'RESOLVED', conflict_resolution = $1, superseded_at = now() WHERE id = $2`, [conflictResolution, queue_id]);
        return { ok: true };
      });
    } catch (e) {
      return res.status(500).json({ error: e.message });
    }
  } else {
    await db.prepare(`UPDATE offline_sync_queue SET status = 'RESOLVED', conflict_resolution = ?, superseded_at = now() WHERE id = ?`).runAsync(conflictResolution, queue_id);
  }
  res.json({ ok: true, winner, comparison, conflict_resolution: conflictResolution });
});

export default router;
