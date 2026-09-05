// Permission middleware - block based on role + module + action
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2) - permission matrix
import { getDb } from '../db/index.js';
import { getPermissions, FULL_ACCESS_ROLES, canAccess } from './permissions.js';

// Map route patterns to module names
const ROUTE_MODULE_MAP = [
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/construction-schedule/, module: 'schedule', action: 'read' },
  { method: 'POST|PUT', pattern: /^\/api\/projects\/\d+\/construction-schedule/, module: 'schedule', action: 'write' },
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/shop-drawings/, module: 'shop', action: 'read' },
  { method: 'POST', pattern: /^\/api\/projects\/\d+\/shop-drawings/, module: 'shop', action: 'write' },
  { method: 'PUT', pattern: /^\/api\/shop-drawings\/\d+\/transition/, module: 'shop', action: 'approve' },
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/materials/, module: 'material', action: 'read' },
  { method: 'POST', pattern: /^\/api\/projects\/\d+\/materials/, module: 'material', action: 'write' },
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/daily-reports/, module: 'daily_report', action: 'read' },
  { method: 'POST', pattern: /^\/api\/projects\/\d+\/daily-reports/, module: 'daily_report', action: 'write' },
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/issues/, module: 'issue', action: 'read' },
  { method: 'POST', pattern: /^\/api\/projects\/\d+\/issues/, module: 'issue', action: 'write' },
  { method: 'GET', pattern: /^\/api\/master-data\//, module: 'master_data', action: 'read' },
  { method: 'POST', pattern: /^\/api\/master-data\//, module: 'master_data', action: 'write' },
  { method: 'GET', pattern: /^\/api\/kpi/, module: 'kpi', action: 'read' },
  { method: 'POST|PUT', pattern: /^\/api\/kpi/, module: 'kpi', action: 'write' },
  { method: 'GET', pattern: /^\/api\/directives/, module: 'directive', action: 'read' },
  { method: 'POST', pattern: /^\/api\/directives/, module: 'directive', action: 'write' },
  { method: 'GET', pattern: /^\/api\/approval/, module: 'approval', action: 'read' },
  { method: 'POST', pattern: /^\/api\/approval/, module: 'approval', action: 'approve' },
  { method: 'GET', pattern: /^\/api\/audit/, module: 'audit', action: 'read' },
  { method: 'POST', pattern: /^\/api\/upload/, module: 'file_upload', action: 'write' },
  { method: 'GET', pattern: /^\/api\/upload/, module: 'file_upload', action: 'read' },
  { method: 'GET', pattern: /^\/api\/projects\/\d+\/contracts/, module: 'contract', action: 'read' },
  { method: 'POST', pattern: /^\/api\/projects\/\d+\/contracts/, module: 'contract', action: 'write' },
  { method: 'GET', pattern: /^\/api\/invoices/, module: 'invoice', action: 'read' },
  { method: 'POST', pattern: /^\/api\/invoices/, module: 'invoice', action: 'write' },
  { method: 'GET', pattern: /^\/api\/payment-requests/, module: 'payment', action: 'read' },
  { method: 'POST', pattern: /^\/api\/payment-requests/, module: 'payment', action: 'write' },
  { method: 'PUT', pattern: /^\/api\/payment-requests/, module: 'payment', action: 'write' },
];

export async function permissionMiddleware(req, res, next) {
  // Skip non-API and read-only health checks
  if (!req.path.startsWith('/api/')) return next();
  if (req.path === '/api/auth/login' || req.path === '/api/health' || req.path.startsWith('/api/me/permissions')) return next();

  // Skip GET /api/projects (list) - everyone can see
  if (req.method === 'GET' && req.path === '/api/projects') return next();

  if (!req.session || !req.session.user_id) return next();  // requireAuth should have caught

  // Get user role from DB to bypass ROLE_MAP (admin stays ADMIN)
  const db = getDb();
  const u = await db.prepare('SELECT role FROM users WHERE id = ?').getAsync(req.session.user_id);
  const role = u?.role === 'admin' ? 'ADMIN' : (req.session.role || 'PMO').toUpperCase();
  if (FULL_ACCESS_ROLES.includes(role)) return next();

  // Find matching route
  for (const m of ROUTE_MODULE_MAP) {
    if (req.method.match(new RegExp(`^(${m.method})$`)) && m.pattern.test(req.path)) {
      // Extract project_id from path
      const projectMatch = req.path.match(/\/api\/projects\/(\d+)/);
      const projectId = projectMatch ? Number(projectMatch[1]) : null;
      const allowed = canAccess(role, m.module, m.action, projectId, req.session.user_id);
      if (!allowed) {
        return res.status(403).json({
          error: `Forbidden: role '${role}' cannot ${m.action} ${m.module}${projectId ? ` in project ${projectId}` : ''}`,
        });
      }
      return next();
    }
  }
  // If no rule matched but it's a /api/ request, allow (default: don't break unmapped endpoints)
  next();
}
