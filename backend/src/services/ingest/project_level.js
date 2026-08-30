// Ingest a "tổng thể" file by reading each sheet as a separate zone
// Strategy: each sheet has a name like "TĐ BPV-1BR" or "TĐ KID CLUB" → extract zone from sheet name
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';
import { findZoneByName } from '../../lib/zone_matcher.js';

export async function ingestProjectLevel(filePath, projectId, options = {}) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: options.docType, ok: 0, errors: 0, items: [], zone_splits: {} };

  const zones = db.prepare('SELECT id, code FROM zones WHERE project_id = ?').all(projectId);

  for (const sheetName of wb.SheetNames) {
    // Skip non-data sheets (e.g. "SƠ đồ tông thể thi công", "Index")
    if (sheetName.toLowerCase().includes('sơ đồ') || sheetName.toLowerCase().includes('index')) continue;

    // Try to extract zone from sheet name
    // Patterns: "TĐ BPV-1BR", "TĐ KID CLUB", "Shop BOH", "Vật tư BOH"
    const m = sheetName.match(/(?:TĐ|Shop|Vật tư)\s+(.+)/i);
    if (!m) continue;
    const zoneName = m[1].trim();
    const zoneId = findZoneByName(zoneName, zones);
    if (!zoneId) {
      report.errors++;
      report.items.push({ sheet: sheetName, error: `Zone '${zoneName}' not found` });
      continue;
    }

    const rows = readSheet(filePath, sheetName);
    // Find data start
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      if (toInt(rows[i][3]) || toInt(rows[i][0])) { dataStart = i; break; }
    }

    if (options.docType === 'shop_drawing') {
      db.prepare('DELETE FROM shop_drawings WHERE project_id = ? AND zone_id = ? AND source_sheet = ?').run(projectId, zoneId, sheetName);
      const insert = db.prepare(`
        INSERT INTO shop_drawings (project_id, zone_id, source_sheet, drawing_code, name_vi, progress_pct)
        VALUES (?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const code = toText(row[5]) || toText(row[1]);
        const name = toText(row[6]) || toText(row[2]);
        if (!code && !name) continue;
        try {
          insert.run(projectId, zoneId, sheetName, code, name, toFloat(row[7]) || toFloat(row[3]));
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) { report.errors++; }
      }
    } else if (options.docType === 'material_supply') {
      db.prepare('DELETE FROM materials WHERE project_id = ? AND zone_id = ? AND source_sheet = ?').run(projectId, zoneId, sheetName);
      const insert = db.prepare(`
        INSERT INTO materials (project_id, zone_id, source_sheet, material_code, name_vi, progress_pct, request_date_1)
        VALUES (?,?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const code = toText(row[5]) || toText(row[1]);
        const name = toText(row[6]) || toText(row[2]);
        if (!code && !name) continue;
        try {
          insert.run(projectId, zoneId, sheetName, code, name, toFloat(row[7]) || toFloat(row[3]), toDate(row[8]) || toDate(row[4]));
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) { report.errors++; }
      }
    } else if (options.docType === 'construction_schedule') {
      db.prepare('DELETE FROM construction_schedule_items WHERE project_id = ? AND zone_id = ? AND source_sheet = ?').run(projectId, zoneId, sheetName);
      const insert = db.prepare(`
        INSERT INTO construction_schedule_items (project_id, zone_id, source_sheet, name_vi, progress_pct, plan_start_date, plan_end_date)
        VALUES (?,?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const stt = toText(row[3]) || toText(row[0]);
        const name = toText(row[4]) || toText(row[1]);
        if (!name) continue;
        try {
          insert.run(projectId, zoneId, sheetName, name, toFloat(row[5]) || toFloat(row[2]), toDate(row[7]) || toDate(row[3]), toDate(row[9]) || toDate(row[5]));
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) { report.errors++; }
      }
    } else {
      // Generic
      const insert = db.prepare(`
        INSERT OR REPLACE INTO generic_sheets (project_id, doc_type, source_sheet, zone_id, ordinal, col_1, col_2, col_3, col_4, col_5)
        VALUES (?,?,?,?,?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const ordinal = toInt(row[0]);
        if (!ordinal) continue;
        try {
          insert.run(projectId, options.docType, sheetName, zoneId, ordinal,
            toText(row[1]), toText(row[2]), toText(row[3]), toText(row[4]), toText(row[5]));
          report.ok++;
        } catch (e) { report.errors++; }
      }
    }
  }

  return report;
}
