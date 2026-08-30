// PostgreSQL connection via Drizzle
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from './schema-pg.js';

const connectionString = process.env.DATABASE_URL || 'postgresql://pmo_user:pmo_dev_pwd@localhost:5432/pmo';

let _pool = null;
let _db = null;

export function getPool() {
  if (!_pool) {
    _pool = new Pool({ connectionString, max: 10 });
  }
  return _pool;
}

export function getPgDb() {
  if (!_db) {
    _db = drizzle(getPool(), { schema });
  }
  return _db;
}

export async function closePgDb() {
  if (_pool) {
    await _pool.end();
    _pool = null;
    _db = null;
  }
}

// Run raw SQL via pool
export async function pgQuery(sql, params) {
  return getPool().query(sql, params);
}

export { schema };
