// Transaction wrapper — đảm bảo business action + audit log cùng COMMIT hoặc cùng ROLLBACK
// Trước đây: auditLog() chạy riêng, có thể fail → mất log
// Bây giờ: wrap trong transaction
//
// Usage:
//   await tx(async (client) => {
//     const r = await client.query('UPDATE ...', [...]);
//     await client.query('INSERT INTO audit_log ...');
//     return r;
//   });

import pg from 'pg';
const { Pool } = pg;

let _pool = null;
export function getPool() {
  if (!_pool) {
    const url = process.env.DATABASE_URL || 'postgresql://pmo_user:pmo_dev_pwd@127.0.0.1:5433/pmo';
    _pool = new Pool({ connectionString: url, max: 10 });
  }
  return _pool;
}

export async function tx(fn) {
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch {}
    throw err;
  } finally {
    client.release();
  }
}

// Audit-friendly tx: gọi auditLog như bình thường nhưng đảm bảo cùng transaction
//   const auditAndBusiness = await txAudit(req, {
//     action: 'STATUS_CHANGE', resourceType: 'shop_drawing', resourceId: id,
//     before: old, after: updated, fieldChanges: [...], note: '...',
//   }, async (client) => {
//     // do business updates with `client` (not db.prepare)
//     return updatedRow;
//   });
//   return res.json(auditAndBusiness);
//
// Implementation: dùng chung _pool ở db/index.js
