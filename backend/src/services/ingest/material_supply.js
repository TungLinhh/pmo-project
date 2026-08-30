// Ingestion: Material Supply (file: Vật tư BOH.xlsx, etc.)
// Uses legacy schema: materials (project_id, zone_id, material_code, name_vi, name_en, progress_pct, 4 request dates)
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

export async function ingestMaterialSupply(filePath, projectId, zoneCode) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'material_supply', zone: zoneCode, ok: 0, errors: 0, items: [] };

  const zone = db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').get(projectId, zoneCode);
  if (!zone) {
    report.errors++;
    report.items.push({ error: `Zone '${zoneCode}' not found` });
    return report;
  }
  const zoneId = zone.id;

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    if (rows.length < 5) continue;

    // Heuristic: find data start
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      if (toInt(rows[i][0]) && toText(rows[i][5])) { dataStart = i; break; }
    }

    db.prepare('DELETE FROM materials WHERE project_id = ? AND zone_id = ? AND material_code IN (SELECT material_code FROM materials WHERE 1=0)').run(projectId, zoneId);

    const insert = db.prepare(`
      INSERT OR REPLACE INTO materials (project_id, zone_id, material_code, name_vi, name_en, progress_pct,
        request_date_1, request_date_2, request_date_3, request_date_4)
      VALUES (?,?,?,?,?,?,?,?,?,?)
    `);

    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const code = toText(row[5]);
      const name = toText(row[6]);
      if (!code && !name) continue;

      try {
        insert.run(
          projectId, zoneId, code || `AUTO-${r}`, name, null, toFloat(row[7]),
          toDate(row[8]), toDate(row[9]), toDate(row[10]), toDate(row[11])
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, code, error: e.message });
      }
    }
  }

  return report;
}
