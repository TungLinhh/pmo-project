// Database initialization script
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { getDb, closeDb } from './index.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const schemaPath = join(__dirname, 'schema.sql');
const schema = readFileSync(schemaPath, 'utf8');

const db = getDb();

console.log('Initializing database...');
db.exec(schema);
console.log('✓ Schema created');

// Seed default tenant + project for demo
const tenantExists = db.prepare('SELECT id FROM tenants WHERE code = ?').get('hbg');
let tenantId;
if (!tenantExists) {
  const result = db.prepare('INSERT INTO tenants (code, name) VALUES (?, ?)').run('hbg', 'HBG Construction');
  tenantId = result.lastInsertRowid;
  console.log(`✓ Created tenant 'hbg' (id=${tenantId})`);
} else {
  tenantId = tenantExists.id;
  console.log(`✓ Tenant 'hbg' exists (id=${tenantId})`);
}

// Seed admin user
const userExists = db.prepare('SELECT id FROM users WHERE tenant_id = ? AND email = ?').get(tenantId, 'admin@hbg.com');
if (!userExists) {
  db.prepare('INSERT INTO users (tenant_id, email, name, role) VALUES (?, ?, ?, ?)').run(tenantId, 'admin@hbg.com', 'Admin HBG', 'admin');
  console.log('✓ Created admin user admin@hbg.com');
}

// Seed demo projects
const projects = [
  { code: 'BTE-WP4-HBC', name_vi: 'Khu du lịch sinh thái Bãi Tràm', name_en: 'Bãi Tràm Estates', package: 'MEP', rev_prefix: 'BTE-HBG' },
  { code: 'LAWRENCE-STING-2', name_vi: 'Trường Lawrence Sting 2', name_en: 'LAWRENCE STING SCHOOL 2', package: 'MEP', rev_prefix: 'HBG-LS' },
];
for (const p of projects) {
  const exists = db.prepare('SELECT id FROM projects WHERE tenant_id = ? AND code = ?').get(tenantId, p.code);
  if (!exists) {
    db.prepare('INSERT INTO projects (tenant_id, code, name_vi, name_en, package, rev_prefix) VALUES (?, ?, ?, ?, ?, ?)').run(tenantId, p.code, p.name_vi, p.name_en, p.package, p.rev_prefix);
    console.log(`✓ Created project ${p.code}`);
  }
}

// Seed zones for BTE project
const bteProject = db.prepare('SELECT id FROM projects WHERE tenant_id = ? AND code = ?').get(tenantId, 'BTE-WP4-HBC');
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
    const exists = db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').get(bteProject.id, z.code);
    if (!exists) {
      db.prepare('INSERT INTO zones (project_id, code, name_en) VALUES (?, ?, ?)').run(bteProject.id, z.code, z.name_en);
    }
  }
  console.log(`✓ Seeded ${zones.length} zones for BTE project`);
}

closeDb();
console.log('\n✅ Database ready at backend/data/pmo.db');
