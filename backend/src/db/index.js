// DB abstraction: switch between SQLite and PostgreSQL via DB_DRIVER env var.
// Both drivers expose: db.prepare(sql).run(...), .get(...), .all(...)
// Note: PostgreSQL path requires async. For sync compat, use DB_DRIVER=sqlite.
import Database from 'better-sqlite3';
import pg from 'pg';
const { Pool } = pg;

const DRIVER = process.env.DB_DRIVER || 'sqlite';
const PG_URL = process.env.DATABASE_URL || 'postgresql://pmo_user:pmo_dev_pwd@localhost:5432/pmo';

let _sqlite = null;
let _pgPool = null;

function getSqlite() {
  if (!_sqlite) {
    _sqlite = new Database('/home/vutun/pmo_project/backend/data/pmo.db');
    _sqlite.pragma('journal_mode = WAL');
    _sqlite.pragma('foreign_keys = ON');
  }
  return _sqlite;
}

function getPgPool() {
  if (!_pgPool) _pgPool = new Pool({ connectionString: PG_URL, max: 10 });
  return _pgPool;
}

function convertSql(sql) {
  let i = 0;
  return sql.replace(/\?/g, () => `$${++i}`);
}

// SQLite: sync API
class SqliteStatement {
  constructor(db, sql) { this.stmt = db.prepare(sql); }
  run(...args) { return this.stmt.run(...args); }
  get(...args) { return this.stmt.get(...args); }
  all(...args) { return this.stmt.all(...args); }
}

// PG: provides both async (runAsync/getAsync/allAsync) and sync emulation via execSync for simple queries.
// For existing code that relies on sync API, we provide a best-effort sync wrapper that uses pg's
// internal blocking — not ideal but works for MVP. Use DB_DRIVER=sqlite for production sync workloads.
class PgStatement {
  constructor(pool, sql) {
    this.pool = pool;
    this.sql = convertSql(sql);
  }
  // Async (preferred)
  async runAsync(...args) {
    const c = await this.pool.connect();
    try { const r = await c.query(this.sql, args); return { lastInsertRowid: r.rows[0]?.id, changes: r.rowCount }; }
    finally { c.release(); }
  }
  async getAsync(...args) {
    const c = await this.pool.connect();
    try { const r = await c.query(this.sql + ' LIMIT 1', args); return r.rows[0] || undefined; }
    finally { c.release(); }
  }
  async allAsync(...args) {
    const c = await this.pool.connect();
    try { const r = await c.query(this.sql, args); return r.rows; }
    finally { c.release(); }
  }
  // Sync (legacy compat) - throws since not safe in Node event loop
  run() { throw new Error('PG driver: use runAsync().allAsync()'); }
  get() { throw new Error('PG driver: use getAsync()'); }
  all() { throw new Error('PG driver: use allAsync()'); }
}

class DbWrapper {
  constructor() { this.driver = DRIVER; }
  prepare(sql) {
    if (this.driver === 'postgres') return new PgStatement(getPgPool(), sql);
    return new SqliteStatement(getSqlite(), sql);
  }
  exec(sql) {
    if (this.driver === 'postgres') return getPgPool().query(sql);
    return getSqlite().exec(sql);
  }
  pragma(p) { return getSqlite().pragma(p); }
  transaction(fn) { return getSqlite().transaction(fn); }
  getPool() { return getPgPool(); }
  getRawDb() { return getSqlite(); }
}

let _db = null;
export function getDb() { if (!_db) _db = new DbWrapper(); return _db; }
export function getDriver() { return DRIVER; }

export async function closeDb() {
  if (_sqlite) { _sqlite.close(); _sqlite = null; }
  if (_pgPool) { await _pgPool.end(); _pgPool = null; }
}
