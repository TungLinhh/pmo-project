// Ingestion: Subcontractor Directory (file: Quy trình thuê thầu phụ, tổ đội.xlsx)
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

export async function ingestSubcontractorDirectory(filePath, projectId) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'subcontractor_directory', ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);

    // Try to detect the data schema
    let dataStart = 1;
    if (toInt(rows[0]?.[0]) && toText(rows[0]?.[1])) dataStart = 0;

    // Use legacy schema: tenant-level, name + capability_summary
    const tenantId = 1;
    db.prepare('DELETE FROM subcontractors WHERE tenant_id = ? AND name IN (SELECT name FROM subcontractors WHERE 1=0)').run(tenantId);
    // (Use unique-by-name pattern)

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
        insert.run(
          tenantId, name, toText(row[2]),
          toText(row[8]) || 'ACTIVE',
          0
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, name, error: e.message });
      }
    }
  }

  return report;
}
