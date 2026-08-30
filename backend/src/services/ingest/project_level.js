// Ingest a "tổng thể" file by reading each sheet as a separate zone
// Strategy: each sheet has a name like "TĐ BPV-1BR" or "TĐ KID CLUB" → extract zone from sheet name
// File structure (per sheet):
//   Row 12 (0-idx): header
//   Row 18+: parent rows (row[3]="I." or "II."), child rows (row[3]=1,2,3...)
//   Cols: 3=Stt, 4=% hạng mục, 5=Hạng mục, 6=Khu vực, 7=% chi tiết, 8=% thi công, 9=% hoàn thành
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
    // Find data start: first row where Stt col[3] is non-empty
    let dataStart = 0;
    for (let i = 0; i < Math.min(30, rows.length); i++) {
      const stt = toText(rows[i]?.[3]) || toText(rows[i]?.[0]);
      if (stt && stt.trim()) { dataStart = i; break; }
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
        // Skip if code looks like a number (likely progress %)
        if (code && /^[0-9.]+$/.test(code)) continue;
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
        if (code && /^[0-9.]+$/.test(code)) continue;
        try {
          insert.run(projectId, zoneId, sheetName, code, name, toFloat(row[7]) || toFloat(row[3]), toDate(row[8]) || toDate(row[4]));
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) { report.errors++; }
      }
    } else if (options.docType === 'construction_schedule') {
      // File structure: Stt(3), %(4), Hạng mục(5), Khu vực(6), % chi tiết(7), % thi công(8), % hoàn thành(9)
      // Parent rows: Stt = "I.", "II.", "III." (roman)
      // Child rows: Stt = 1, 2, 3 (number)
      db.prepare('DELETE FROM construction_schedule_items WHERE project_id = ? AND zone_id = ? AND source_sheet = ?').run(projectId, zoneId, sheetName);
      const insert = db.prepare(`
        INSERT INTO construction_schedule_items (project_id, zone_id, source_sheet, name_vi, progress_pct, plan_start_date, plan_end_date, ordinal)
        VALUES (?,?,?,?,?,?,?,?)
      `);
      for (let r = dataStart; r < rows.length; r++) {
        const row = rows[r] || [];
        const stt = toText(row[3]) || toText(row[0]);
        const name = toText(row[5]) || toText(row[4]);
        // Skip empty rows
        if (!stt && !name) continue;
        // Skip if name is a number (likely %)
        if (name && /^[0-9.]+$/.test(name)) continue;
        // Skip if Stt is header text
        if (stt && /^(Stt|Hạng|%)\b/i.test(stt)) continue;
        // Detect ordinal: "I." → 1, "II." → 2, "1" → 1, etc.
        let ordinal = null;
        const romanMatch = stt.match(/^([IVX]+)\.?$/);
        if (romanMatch) {
          const roman = romanMatch[1];
          const romanMap = { I: 1, II: 2, III: 3, IV: 4, V: 5, VI: 6, VII: 7, VIII: 8, IX: 9, X: 10 };
          ordinal = romanMap[roman] || null;
        } else {
          ordinal = toInt(stt);
        }
        try {
          insert.run(projectId, zoneId, sheetName, name || stt, toFloat(row[9]) || toFloat(row[8]) || toFloat(row[7]) || toFloat(row[2]),
            toDate(row[6]) || toDate(row[3]), toDate(row[10]) || toDate(row[7]), ordinal);
          report.ok++;
          report.zone_splits[zoneName] = (report.zone_splits[zoneName] || 0) + 1;
        } catch (e) {
          report.errors++;
          report.items.push({ sheet: sheetName, row: r, error: e.message });
        }
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
