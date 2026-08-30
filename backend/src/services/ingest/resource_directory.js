// Ingestion: Resource Directory (file: Danh sách nguồn lực công ty.xlsx)
// Uses legacy schema: subcontractors (tenant-level) + suppliers (tenant-level)
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt } from '../../lib/excel.js';

export async function ingestResourceDirectory(filePath, tenantId) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'resource_directory', ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    const isSupplier = sheetName.toLowerCase().includes('cung cấp') || sheetName.toLowerCase().includes('ncc');

    let dataStart = 1;
    if (toInt(rows[0]?.[0]) && toText(rows[0]?.[1])) dataStart = 0;

    if (isSupplier) {
      const insert = db.prepare(`
        INSERT OR REPLACE INTO suppliers (tenant_id, name, system, category, past_projects, location, price_rating, quality_rating, warranty_rating)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const ordinal = toInt(row[0]);
        const name = toText(row[1]);
        if (!name) continue;
        try {
          insert.run(tenantId, name, toText(row[2]), toText(row[3]), toText(row[4]), toText(row[5]),
            toText(row[6]), toText(row[7]), toText(row[8]));
          report.ok++;
        } catch (e) {
          report.errors++;
          report.items.push({ sheet: sheetName, row: r + 1, name, error: e.message });
        }
      }
    } else {
      // Subcontractors / teams
      const insert = db.prepare(`
        INSERT OR REPLACE INTO subcontractors (tenant_id, name, capability_summary, status, is_internal_team)
        VALUES (?, ?, ?, ?, ?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const ordinal = toInt(row[0]);
        const name = toText(row[1]);
        if (!name) continue;
        try {
          insert.run(tenantId, name, toText(row[2]), 'ACTIVE', 0);
          report.ok++;
        } catch (e) {
          report.errors++;
          report.items.push({ sheet: sheetName, row: r + 1, name, error: e.message });
        }
      }
    }
  }

  return report;
}
