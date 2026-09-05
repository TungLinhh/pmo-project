// Auth middleware
// Sử dụng:
//   router.get('/api/foo', requireAuth, handler)        — bắt buộc đăng nhập
//   router.get('/api/foo', requireAuth, requireRole('admin', 'ceo'), handler)  — yêu cầu role
//
// req.session được set bởi /api/auth/login (in-memory, key: sessionId → user)
// Phase 2: chuyển sang JWT + PG session

const SESSIONS = new Map(); // sessionId → user
let _sessionId = 0;

export function createSession(user) {
  const id = `s_${++_sessionId}_${Date.now()}`;
  SESSIONS.set(id, user);
  return id;
}

export function destroySession(id) {
  return SESSIONS.delete(id);
}

export function getSessionUser(id) {
  return SESSIONS.get(id) || null;
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
  return SESSIONS.get(token) || null;
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
export function currentUser(req) {
  if (req.user) {
    return {
      id: req.user.id,
      name: req.user.name || req.user.full_name || 'System',
      role: req.user.role || 'admin',
    };
  }
  // Fallback khi không có auth (edge case, chỉ dùng trong test/internal)
  return {
    id: req.session?.user_id || 1,
    name: req.session?.user_name || 'System',
    role: req.session?.role || 'admin',
  };
}
