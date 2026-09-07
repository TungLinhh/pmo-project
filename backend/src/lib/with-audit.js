// Audit-friendly transaction wrapper
// Gộp business action + audit log trong 1 transaction.
//   const result = await withAudit(req, { action, resourceType, resourceId, ... },
//     async (client) => { /* business using `client` */ return updatedRow; });
//
// Nếu audit log fail → business cũng rollback (và ngược lại)
// Nếu không truyền businessFn → chỉ ghi audit (cho read-only events)

import { tx } from './tx.js';
import { currentUser } from './auth.js';
import { getDb } from '../db/index.js';

export async function withAudit(req, auditMeta, businessFn) {
  // Nếu businessFn = null/undefined: chỉ ghi audit, không transaction
  if (typeof businessFn !== 'function') {
    const db = getDb();
    const u = currentUser(req);
    if (!u) throw new Error('Unauthorized: no session user');
    await db.auditLog?.({
      userId: u.id, userName: u.name, userRole: u.role,
      ...auditMeta,
    });
    return null;
  }

  return await tx(async (client) => {
    // Business action với client
    const result = await businessFn(client);
    // Audit log cùng transaction
    const u = currentUser(req);
    if (!u) throw new Error('Unauthorized: no session user');
    await client.query(
      `INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, context, before, after, field_changes, actor_role, note)
       VALUES (1, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
      [
        u.id,
        u.name,
        auditMeta.action || 'UNKNOWN',
        auditMeta.resourceType || null,
        auditMeta.resourceId || null,
        auditMeta.context ? JSON.stringify(auditMeta.context) : null,
        auditMeta.before ? JSON.stringify(auditMeta.before) : null,
        auditMeta.after ? JSON.stringify(auditMeta.after) : null,
        auditMeta.fieldChanges ? JSON.stringify(auditMeta.fieldChanges) : null,
        u.role,
        auditMeta.note || null,
      ]
    );
    return result;
  });
}
