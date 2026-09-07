// Auth middleware
// Sử dụng:
//   router.get('/api/foo', requireAuth, handler)        — bắt buộc đăng nhập
//   router.get('/api/foo', requireAuth, requireRole('admin', 'ceo'), handler)  — yêu cầu role
//
// req.session được set bởi /api/auth/login (in-memory, key: sessionId → user)
// Phase 2 (inevitable, not yet): JWT + PG session so login survives restart
// and works across replicas. Until then: in-memory WITH expiry (no immortal
// sessions) and fail-closed reads (no admin fallback).
import { randomBytes } from 'node:crypto';

function sessionTtlMs() {
  const v = Number(process.env.SESSION_TTL_MS);
  return Number.isFinite(v) && v > 0 ? v : 24 * 3600 * 1000; // default 24h
}

// sessionId → { user, expiresAt }
const SESSIONS = new Map();

function isExpired(entry) {
  return !entry || entry.expiresAt <= Date.now();
}

// Opportunistic sweep so expired sessions don't accumulate.
let _lastSweep = 0;
function sweepExpired() {
  const now = Date.now();
  if (now - _lastSweep < 60_000) return;
  _lastSweep = now;
  for (const [k, v] of SESSIONS) {
    if (isExpired(v)) SESSIONS.delete(k);
  }
}

export function createSession(user) {
  sweepExpired();
  const id = `s_${randomBytes(16).toString('hex')}_${Date.now()}`;
  SESSIONS.set(id, { user, expiresAt: Date.now() + sessionTtlMs() });
  return id;
}

export function destroySession(id) {
  return SESSIONS.delete(id);
}

export function getSessionUser(id) {
  const entry = SESSIONS.get(id);
  if (!entry) return null;
  if (isExpired(entry)) {
    SESSIONS.delete(id);
    return null;
  }
  return entry.user;
}

export function listSessions() {
  return SESSIONS.size;
}

// Read user from Authorization: Bearer <token>
export function readTokenUser(req) {
  const auth = req.headers?.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return null;
  const token = auth.slice(7);
  // Token = sessionId (simple) or JWT (future)
  return getSessionUser(token);
}

// requireAuth: 401 nếu chưa đăng nhập
export function requireAuth(req, res, next) {
  const user = readTokenUser(req);
  if (!user) {
    return res.status(401).json({ error: 'Unauthorized. Đăng nhập để tiếp tục.' });
  }
  req.user = user;
  // Backward-compat: set req.session.* (deprecated, dùng req.user.* thay)
  req.session = req.session || {};
  req.session.user_id = user.id;
  req.session.user_name = user.name;
  req.session.role = user.role;
  next();
}

// requireRole(...roles): 403 nếu không đúng role
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    if (roles.length && !roles.includes(req.user.role)) {
      return res.status(403).json({ error: `Forbidden. Cần role: ${roles.join('|')}` });
    }
    next();
  };
}

// Helper: lấy user hiện tại (dùng trong route, optional)
// Fail-closed: trả về null khi không có auth — caller phải xử lý 401.
// (Trước đây fallback về admin id=1, cho phép leo thang đặc quyền nếu route quên requireAuth.)
export function currentUser(req) {
  if (req.user) {
    return {
      id: req.user.id,
      name: req.user.name || req.user.full_name || 'System',
      role: req.user.role || 'admin',
    };
  }
  return null;
}
