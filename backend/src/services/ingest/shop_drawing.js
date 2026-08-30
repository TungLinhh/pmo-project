// Ingestion: Shop Drawing (file: Shop BOH.xlsx, Shop BPV.xlsx, etc.)
// Per user Q10: only ingest C1-C33 (skip Gantt template C34+)
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

export async function ingestShopDrawing(filePath, projectId, zoneCode) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });

  const report = { doc_type: 'shop_drawing', zone: zoneCode, ok: 0, errors: 0, items: [] };

  // Get zone
  const zone = db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').get(projectId, zoneCode);
  if (!zone) {
    report.errors++;
    report.items.push({ error: `Zone '${zoneCode}' not found in project ${projectId}` });
    return report;
  }
  const zoneId = zone.id;

  // Idempotency: delete old rows for this zone in this project
  db.prepare('DELETE FROM shop_drawings WHERE project_id = ? AND zone_id = ?').run(projectId, zoneId);

  for (const sheetName of wb.SheetNames) {
    if (!sheetName.toUpperCase().startsWith('SHOP') && sheetName !== 'SHOP OTH') continue;

    const rows = readSheet(filePath, sheetName);

    // Data starts at R27 (0-indexed 26), header at R23-R25
    for (let r = 26; r < rows.length; r++) {
      const row = rows[r] || [];
      const drawingCode = toText(row[5]);
      const name = toText(row[6]);
      if (!drawingCode) continue;

      const exists = db.prepare(`
        SELECT 1 FROM shop_drawings
        WHERE project_id = ? AND zone_id = ? AND drawing_code = ?
      `).get(projectId, zoneId, drawingCode);
      if (exists) {
        db.prepare('DELETE FROM shop_drawings WHERE project_id = ? AND zone_id = ? AND drawing_code = ?')
          .run(projectId, zoneId, drawingCode);
      }

      try {
        // SQL has 28 columns; we pass 28 params
        // Note: resubmit_actual_date_2 is duplicated from row[29] since HBG file uses same col
        const result = db.prepare(`
          INSERT INTO shop_drawings (
            project_id, zone_id, drawing_code, name_vi, name_en, progress_pct,
            planned_submit_date, actual_submit_date,
            bql_l1_response, bql_l1_date, bql_l1_comment,
            bql_l2_response, bql_l2_date, bql_l2_comment,
            bql_l3_response, bql_l3_date, bql_l3_comment,
            bql_l4_response, bql_l4_date, bql_l4_comment,
            bql_l5_response, bql_l5_date, bql_l5_comment,
            resubmit_planned_date_1, resubmit_actual_date_1,
            resubmit_planned_date_2, resubmit_actual_date_2,
            approval_date
          ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        `).run(
          projectId, zoneId, drawingCode, name, null, toFloat(row[7]),
          toDate(row[8]), toDate(row[9]),
          toText(row[11]), toDate(row[12]), toText(row[13]),
          toText(row[15]), toDate(row[16]), toText(row[17]),
          toText(row[19]), toDate(row[20]), toText(row[21]),
          toText(row[23]), toDate(row[24]), toText(row[25]),
          toText(row[27]), toDate(row[28]), toText(row[29]),
          toDate(row[21]), toDate(row[25]),  // resubmit_planned_1, resubmit_actual_1
          toDate(row[29]),                  // resubmit_planned_2
          toDate(row[29]),                  // resubmit_actual_2 (duplicated to fill 28 params)
          toDate(typeof row[32] === 'boolean' ? null : row[32])
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, code: drawingCode, error: e.message });
      }
    }
  }

  return report;
}
