// Notifications routes

import { Router } from 'express';
import { requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { notify, notifyMany } from '../services/notify.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

router.get('/', async (req, res) => {
  const db = getDb();
  const { limit = 50, unread_only } = req.query;
  const lim = Math.min(parseInt(limit) || 50, 200);
  const where = ['user_id = ?'];
  const params = [req.user.id];
  if (unread_only === '1') where.push("read_at IS NULL");
  params.push(lim);
  res.json(await db.prepare(
    `SELECT * FROM notifications WHERE ${where.join(' AND ')} ORDER BY created_at DESC LIMIT ?`
  ).allAsync(...params));
});

router.post('/:id/read', async (req, res) => {
  const db = getDb();
  await db.prepare('UPDATE notifications SET read_at = now() WHERE id = ? AND user_id = ? AND read_at IS NULL').runAsync(req.params.id, req.user.id);
  res.json({ ok: true });
});

router.post('/mark-all-read', async (req, res) => {
  const db = getDb();
  await db.prepare('UPDATE notifications SET read_at = now() WHERE user_id = ? AND read_at IS NULL').runAsync(req.user.id);
  res.json({ ok: true });
});

router.post('/', async (req, res) => {
  // Manual create notification (admin only)
  const { user_ids, title, body, link, channel, severity } = req.body || {};
  if (!title || !user_ids?.length) return res.status(400).json({ error: 'title and user_ids[] required' });
  await notifyMany(req, user_ids, { title, body, link, channel: channel || 'in_app', severity: severity || 'INFO' });
  res.json({ ok: true, count: user_ids.length });
});

export default router;
