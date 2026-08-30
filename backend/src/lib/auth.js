// Simple auth MVP - uses minimal users table from schema
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) — hard-coded passwords cho demo
//   Khi có password_hash column sẽ migrate sang bcrypt.
import { getDb } from '../db/index.js';
import { createHash, randomBytes } from 'node:crypto';

// Passwords cho 7 demo accounts (mục 43.2 — 6 role cố định + admin)
const PASSWORDS = new Map([
  ['admin@hbg.com', 'admin123'],
  ['ceo@hbg.com', 'ceo123'],
  ['pm@hbg.com', 'pm123'],
  ['pmo@hbg.com', 'pmo123'],
  ['site@hbg.com', 'site123'],
  ['procurement@hbg.com', 'proc123'],
  ['accounting@hbg.com', 'acc123'],
]);

const SESSIONS = new Map();

function loadUser(email) {
  const db = getDb();
  const u = db.prepare('SELECT id, tenant_id, email, name, role, is_ceo FROM users WHERE email = ?').get(email);
  if (!u) return null;
  return {
    id: u.id, email: u.email,
    full_name: u.name, role: u.role, is_ceo: u.is_ceo,
    tenant_id: u.tenant_id,
  };
}

export function listUsers() {
  const db = getDb();
  return db.prepare('SELECT id, email, name as full_name, role, is_ceo, tenant_id FROM users').all();
}

export function login(email, password) {
  const expected = PASSWORDS.get(email);
  if (!expected || expected !== password) return null;
  const user = loadUser(email);
  if (!user) return null;
  const token = randomBytes(16).toString('hex');
  const session = { token, user_id: user.id, ...user };
  SESSIONS.set(token, session);
  return { token, user };
}

export function getSession(token) {
  return token ? SESSIONS.get(token) : null;
}

export function logout(token) {
  SESSIONS.delete(token);
}

export function requireAuth(req, res, next) {
  // Skip auth for login + health + static (frontend) paths
  const p = req.path;
  if (p === '/api/auth/login' || p === '/api/health' || !p.startsWith('/api/')) return next();
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  const session = getSession(token);
  if (!session) return res.status(401).json({ error: 'Unauthorized' });
  req.session = session;
  next();
}

export const authMiddleware = requireAuth;
