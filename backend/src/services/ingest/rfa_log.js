// Ingestion: RFA Log (file: HBG-MCR-MM-01.xlsx, etc.)
// Log of Request for Approval / Material Approval submissions
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

export async function ingestRFALog(filePath, projectId) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'rfa_log', ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    if (rows.length < 5) continue;

    // Find data start: first row where col[0] is number and col[1] or col[2] has text
    let dataStart = 0;
    for (let i = 0; i < Math.min(40, rows.length); i++) {
      if (toInt(rows[i][0]) && (toText(rows[i][1]) || toText(rows[i][2]))) {
        dataStart = i;
        break;
      }
    }

    db.prepare('DELETE FROM rfa_log WHERE project_id = ? AND source_sheet = ?').run(projectId, sheetName);

    const insert = db.prepare(`
      INSERT INTO rfa_log (project_id, source_sheet, ordinal, rfa_code, description_vi, discipline, area,
        submitted_date, reviewer, reviewer_status, reviewer_comment, response_date, final_status, notes)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    `);

    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const ordinal = toInt(row[0]);
      const rfaCode = toText(row[1]) || toText(row[2]);
      if (!ordinal || !rfaCode) continue;

      try {
        insert.run(
          projectId, sheetName, ordinal, rfaCode, toText(row[3]), toText(row[4]), toText(row[5]),
          toDate(row[6]), toText(row[7]), toText(row[8]), toText(row[9]),
          toDate(row[10]), toText(row[11]), toText(row[12])
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, code: rfaCode, error: e.message });
      }
    }
  }

  return report;
}
