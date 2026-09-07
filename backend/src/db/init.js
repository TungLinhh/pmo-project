// Database initialization — PG only.
// Applies drizzle migrations from drizzle/0000_*.sql (skips if already applied).
// Seeds default tenant + admin user + demo projects + zones.
// Also creates unique indexes required by upsert().
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { getDb, closeDb } from './index.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const db = getDb();

console.log('Initializing PostgreSQL database...');

// Apply migrations
const drizzleDir = join(__dirname, '..', '..', 'drizzle');
const alreadyApplied = await db.prepare(`SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tenants')`).getAsync();
if (!alreadyApplied?.exists) {
  const files = readdirSync(drizzleDir).filter(f => f.endsWith('.sql')).sort();
  for (const f of files) {
    const sql = readFileSync(join(drizzleDir, f), 'utf8');
    console.log(`  Applying ${f}...`);
    try {
      await db.exec(sql);
    } catch (e) {
      console.error(`❌ Migration ${f} FAILED — aborting init: ${e.message}`);
      await closeDb();
      process.exit(1);
    }
  }
  console.log(`✓ Applied ${files.length} migration(s)`);
} else {
  console.log(`✓ Schema already applied`);
}

// Patch tables that were added after initial drizzle migrations
// (issues, directives — required by routes but missing from drizzle schema)
// FATAL on failure: a half-migrated schema is worse than a loud abort.
// Patches themselves must be additive/idempotent (IF NOT EXISTS) — never DROP.
const patches = readdirSync(drizzleDir).filter(f => f.match(/^9\d{3}_/)).sort();
for (const p of patches) {
  const sql = readFileSync(join(drizzleDir, p), 'utf8');
  try {
    await db.exec(sql);
  } catch (e) {
    console.error(`❌ Patch ${p} FAILED — aborting init (schema may be partial): ${e.message}`);
    await closeDb();
    process.exit(1);
  }
  console.log(`✓ Applied patch ${p}`);
}

// Create unique indexes required by db.upsert() in ingestors
const requiredIndexes = [
  { name: 'business_process_steps_process_ord_uq', table: 'business_process_steps', cols: ['process_id', 'ordinal'] },
  { name: 'construction_schedule_items_uq', table: 'construction_schedule_items', cols: ['project_id', 'zone_id', 'source_sheet', 'ordinal'] },
  { name: 'subcontractors_tenant_name_uq', table: 'subcontractors', cols: ['tenant_id', 'name'] },
  { name: 'suppliers_tenant_name_uq', table: 'suppliers', cols: ['tenant_id', 'name'] },
  { name: 'materials_project_zone_code_uq', table: 'materials', cols: ['project_id', 'zone_id', 'material_code'] },
  { name: 'generic_sheets_uq', table: 'generic_sheets', cols: ['project_id', 'doc_type', 'source_sheet', 'ordinal'] },
  { name: 'daily_reports_project_date_uq', table: 'daily_reports', cols: ['project_id', 'report_date'] },
];
for (const idx of requiredIndexes) {
  await db.exec(`CREATE UNIQUE INDEX IF NOT EXISTS ${idx.name} ON ${idx.table} (${idx.cols.join(', ')})`);
}
console.log(`✓ Ensured ${requiredIndexes.length} unique indexes for upsert()`);

// Seed default tenant + project for demo
const tenantExists = await db.prepare('SELECT id FROM tenants WHERE code = ?').getAsync('hbg');
let tenantId;
if (!tenantExists) {
  const result = await db.prepare('INSERT INTO tenants (code, name) VALUES (?, ?)').runAsync('hbg', 'HBG Construction');
  tenantId = Number(result.lastInsertRowid);
  console.log(`✓ Created tenant 'hbg' (id=${tenantId})`);
} else {
  tenantId = tenantExists.id;
  console.log(`✓ Tenant 'hbg' exists (id=${tenantId})`);
}

// Seed admin user
const userExists = await db.prepare('SELECT id FROM users WHERE tenant_id = ? AND email = ?').getAsync(tenantId, 'admin@hbg.com');
if (!userExists) {
  await db.prepare('INSERT INTO users (tenant_id, email, name, role) VALUES (?, ?, ?, ?)').runAsync(tenantId, 'admin@hbg.com', 'Admin HBG', 'admin');
  console.log('✓ Created admin user admin@hbg.com');
}

// Seed demo projects
const projects = [
  { code: 'BTE-WP4-HBC', name_vi: 'Khu du lịch sinh thái Bãi Tràm', name_en: 'Bãi Tràm Estates', package: 'MEP', rev_prefix: 'BTE-HBG' },
  { code: 'LAWRENCE-STING-2', name_vi: 'Trường Lawrence Sting 2', name_en: 'LAWRENCE STING SCHOOL 2', package: 'MEP', rev_prefix: 'HBG-LS' },
];
for (const p of projects) {
  const exists = await db.prepare('SELECT id FROM projects WHERE tenant_id = ? AND code = ?').getAsync(tenantId, p.code);
  if (!exists) {
    await db.prepare('INSERT INTO projects (tenant_id, code, name_vi, name_en, package, rev_prefix) VALUES (?, ?, ?, ?, ?, ?)').runAsync(tenantId, p.code, p.name_vi, p.name_en, p.package, p.rev_prefix);
    console.log(`✓ Created project ${p.code}`);
  }
}

// Seed zones for BTE project
const bteProject = await db.prepare('SELECT id FROM projects WHERE tenant_id = ? AND code = ?').getAsync(tenantId, 'BTE-WP4-HBC');
if (bteProject) {
  const zones = [
    { code: 'BOH', name_en: 'Back of House' },
    { code: 'BPV', name_en: 'Beach Pool Villa' },
    { code: 'BPV-1BR', name_en: 'Beach Pool Villa 1BR' },
    { code: 'BPV-2BR', name_en: 'Beach Pool Villa 2BR' },
    { code: 'BSN', name_en: 'Business' },
    { code: 'BUT', name_en: 'Butler' },
    { code: 'BZONE', name_en: 'Zone B' },
    { code: 'CLU', name_en: 'Cluster Villa' },
    { code: 'GEN', name_en: 'General' },
    { code: 'HPV', name_en: 'HPV' },
    { code: 'HPV-1BR', name_en: 'HPV 1BR' },
    { code: 'HPV-2BR', name_en: 'HPV 2BR' },
    { code: 'INF', name_en: 'Infrastructure' },
    { code: 'KID', name_en: 'Kid Club' },
    { code: 'LOB-SPA', name_en: 'Lobby & Spa' },
    { code: 'RES', name_en: 'Resort' },
    { code: 'RES-3BR', name_en: 'Resort 3BR' },
    { code: 'RES-4BR', name_en: 'Resort 4BR' },
    { code: 'VNR', name_en: 'Vietnam Residences' },
  ];
  for (const z of zones) {
    const exists = await db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').getAsync(bteProject.id, z.code);
    if (!exists) {
      await db.prepare('INSERT INTO zones (project_id, code, name_en) VALUES (?, ?, ?)').runAsync(bteProject.id, z.code, z.name_en);
    }
  }
  console.log(`✓ Seeded ${zones.length} zones for BTE project`);
}

await closeDb();
console.log(`\n✅ Database ready`);
