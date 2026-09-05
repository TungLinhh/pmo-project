// Auth routes — login, logout, me
// Sử dụng: requireAuth, createSession, destroySession

import { Router } from 'express';
import { createSession, destroySession, getSessionUser, requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';

const router = Router({ mergeParams: true });

router.post('/login', async (req, res) => {
  const db = getDb();
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'email + password required' });
  // Schema thật: users có email + name + role, KHÔNG có password column (PMO MVP dev only)
  // TODO Phase 2: thêm password_hash + bcrypt
  const user = await db.prepare('SELECT * FROM users WHERE email = ?').getAsync(email);
  if (!user) return res.status(401).json({ error: 'Sai email hoặc mật khẩu' });
  // Dev only: chấp nhận password = "admin123" cho mọi user (TODO: real password check)
  if (password !== 'admin123') return res.status(401).json({ error: 'Sai email hoặc mật khẩu' });
  const sessionId = createSession(user);
  res.json({ token: sessionId, user: { id: user.id, email: user.email, full_name: user.name, role: user.role } });
});

router.post('/logout', requireAuth, async (req, res) => {
  const auth = req.headers.authorization || '';
  const token = auth.replace(/^Bearer\s+/, '');
  destroySession(token);
  res.json({ ok: true });
});

router.get('/me', requireAuth, async (req, res) => {
  res.json({ user: req.user });
});

export default router;
