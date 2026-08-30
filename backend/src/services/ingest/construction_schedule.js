// Ingestion: Construction Schedule (file: TĐ BOH.xlsx, etc.)
// Per user Q6: split level_roman + level_arabic
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate } from '../../lib/excel.js';

// Parse "A", "I", "II", "1", "1.1", "2.3" -> {roman, arabic, sublevel}
function parseLevel(stt) {
  if (!stt) return { roman: null, arabic: null, sublevel: null };
  const s = String(stt).trim();
  if (/^[IVX]+$/.test(s)) return { roman: s, arabic: null, sublevel: null };
  if (/^\d+$/.test(s)) return { roman: null, arabic: parseInt(s, 10), sublevel: null };
  if (/^\d+\.\d+$/.test(s)) {
    const [a, b] = s.split('.').map(n => parseInt(n, 10));
    return { roman: null, arabic: a, sublevel: b };
  }
  return { roman: s, arabic: null, sublevel: null };  // fallback: store as roman
}

function mapStatus(v) {
  if (v === 'YES' || v === 'yes' || v === 'Y') return 'DONE';
  if (v === 'NO' || v === 'no' || v === 'N') return 'PENDING';
  return null;
}

export async function ingestConstructionSchedule(filePath, projectId, zoneCode) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'construction_schedule', zone: zoneCode, ok: 0, errors: 0, items: [] };

  const zone = db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').get(projectId, zoneCode);
  if (!zone) {
    return { ...report, errors: 1, items: [{ error: `Zone '${zoneCode}' not found` }] };
  }
  const zoneId = zone.id;

  for (const sheetName of wb.SheetNames) {
    if (!sheetName.toUpperCase().includes('TĐ') && !sheetName.toUpperCase().includes('TD')) continue;
    const rows = readSheet(filePath, sheetName);

    // Header at R14 (0-indexed 13), data starts R17 (0-indexed 16)
    // Cols: 3=Stt, 4=Name, 5=Progress, 6=Status, 7=PlanStart, 8=ActualStart,
    //        9=PlanEnd, 10=ActualEnd, 11=PlanDays
    db.prepare('DELETE FROM construction_schedule_items WHERE project_id = ? AND zone_id = ?').run(projectId, zoneId);

    const insert = db.prepare(`
      INSERT INTO construction_schedule_items (
        project_id, zone_id, level_roman, level_arabic, sublevel, ordinal,
        name_vi, name_en, progress_pct, status,
        plan_start_date, actual_start_date, plan_end_date, actual_end_date, plan_duration_days
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (let r = 16; r < rows.length; r++) {
      const row = rows[r] || [];
      const stt = toText(row[3]);
      const name = toText(row[4]);
      if (!name) continue;

      const { roman, arabic, sublevel } = parseLevel(stt);

      try {
        // Coerce nulls - SQLite Node can be picky about undefined vs null
        const params = [
          projectId, zoneId, roman ?? null, arabic ?? null, sublevel ?? null, toInt(stt) || null,
          name, null, toFloat(row[5]), mapStatus(row[6]),
          toDate(row[7]), toDate(row[8]), toDate(row[9]), toDate(row[10]), toInt(row[11])
        ];
        // Sanity check
        for (let i = 0; i < params.length; i++) {
          if (params[i] === undefined) {
            throw new Error(`param ${i + 1} is undefined (stt=${stt}, name=${name})`);
          }
        }
        insert.run(...params);
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheetName, row: r + 1, stt, name, error: e.message });
      }
    }
  }

  return report;
}
