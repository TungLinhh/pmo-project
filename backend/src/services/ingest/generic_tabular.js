// Generic ingestor for tabular files that don't fit other types
// Schema: project_id, source_sheet, ordinal, code, name_vi, + many text fields
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

export async function ingestGenericTabular(filePath, projectId, options = {}) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: options.docType || 'generic', ok: 0, errors: 0, items: [] };

  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    if (rows.length < 3) continue;

    // Find data start: row with int in col 0 and text in col 1+
    let dataStart = 0;
    for (let i = 0; i < Math.min(40, rows.length); i++) {
      if (toInt(rows[i][0]) && toText(rows[i][1])) { dataStart = i; break; }
    }

    const insert = db.prepare(`
      INSERT OR REPLACE INTO generic_sheets (project_id, doc_type, source_sheet, ordinal, col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10, col_11, col_12)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    `);

    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const ordinal = toInt(row[0]);
      if (!ordinal) continue;
      try {
        insert.run(
          projectId, options.docType || 'generic', sheetName, ordinal,
          toText(row[1]), toText(row[2]), toText(row[3]), toText(row[4]),
          toText(row[5]), toText(row[6]), toText(row[7]), toText(row[8]),
          toText(row[9]), toText(row[10]), toText(row[11]), toText(row[12])
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, error: e.message });
      }
    }
  }
  return report;
}
