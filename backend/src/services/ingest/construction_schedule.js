// Ingestion: Construction Schedule (file: TĐ BOH.xlsx, etc.)
// PG-only. Mô hình A wizard: parse() returns rows, commit() inserts them.
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt, toFloat, toDate, findDataStart } from '../../lib/excel.js';
import { findOrCreateZone } from './index.js';

const HEADER_KEYWORDS = ['stt', 'tt', 'hạng mục', 'nội dung', 'tiến độ'];

function resolveZone(zoneCode) {
  if (!zoneCode) return { code: 'GEN-TD', name: 'Construction Schedule - General' };
  return { code: zoneCode, name: zoneCode };
}

function parseLevel(stt) {
  if (!stt) return { roman: null, arabic: null, sublevel: null };
  const s = String(stt).trim();
  if (/^[IVX]+$/.test(s)) return { roman: s, arabic: null, sublevel: null };
  if (/^\d+$/.test(s)) return { roman: null, arabic: parseInt(s, 10), sublevel: null };
  if (/^\d+\.\d+$/.test(s)) {
    const [a, b] = s.split('.').map(n => parseInt(n, 10));
    return { roman: null, arabic: a, sublevel: b };
  }
  return { roman: s, arabic: null, sublevel: null };
}

function parseRow(row) {
  const stt = toText(row[3]);
  const name = toText(row[4]);
  if (!name) return null;
  const { roman, arabic, sublevel } = parseLevel(stt);
  return {
    level_roman: roman, level_arabic: arabic, sublevel, ordinal: toInt(stt) || null,
    name_vi: name, name_en: null,
    progress_pct: toFloat(row[5]),
    status: row[6] === 'YES' || row[6] === 'yes' || row[6] === 'Y' ? 'DONE' : (row[6] === 'NO' || row[6] === 'no' || row[6] === 'N' ? 'PENDING' : null),
    plan_start_date: toDate(row[7]),
    actual_start_date: toDate(row[8]),
    plan_end_date: toDate(row[9]),
    actual_end_date: toDate(row[10]),
    plan_duration_days: toInt(row[11]),
  };
}

export async function parse(filePath, projectId, zoneCode) {
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const { code, name } = resolveZone(zoneCode);
  const sheets = [];
  for (const sheetName of wb.SheetNames) {
    if (!sheetName.toUpperCase().includes('TĐ') && !sheetName.toUpperCase().includes('TD')) continue;
    const rows = readSheet(filePath, sheetName);
    const dataStart = findDataStart(rows, { codeCol: 3, nameCol: 4, headerKeywords: HEADER_KEYWORDS, maxScan: 30 });
    const sheetRows = [];
    for (let r = dataStart; r < rows.length; r++) {
      const parsed = parseRow(rows[r] || []);
      if (parsed) sheetRows.push({ rowIndex: r + 1, ...parsed });
    }
    if (sheetRows.length > 0) sheets.push({ sheet: sheetName, rows: sheetRows });
  }
  return { zone: { code, name }, sheets, totalRows: sheets.reduce((s, x) => s + x.rows.length, 0) };
}

export async function commit(parsed, projectId, zoneCode) {
  const db = getDb();
  const { code } = resolveZone(zoneCode);
  const zone = await findOrCreateZone(projectId, code, code);
  const zoneId = zone.id;

  const report = { doc_type: 'construction_schedule', zone: code, ok: 0, errors: 0, items: [] };
  for (const sheet of parsed.sheets) {
    for (const row of sheet.rows) {
      try {
        await db.upsert('construction_schedule_items',
          { conflictCols: ['project_id', 'zone_id', 'source_sheet', 'ordinal'] },
          {
            project_id: projectId, zone_id: zoneId, source_sheet: sheet.sheet,
            level_roman: row.level_roman, level_arabic: row.level_arabic, sublevel: row.sublevel, ordinal: row.ordinal,
            name_vi: row.name_vi, name_en: row.name_en, progress_pct: row.progress_pct, status: row.status,
            plan_start_date: row.plan_start_date, actual_start_date: row.actual_start_date,
            plan_end_date: row.plan_end_date, actual_end_date: row.actual_end_date, plan_duration_days: row.plan_duration_days,
          }
        );
        report.ok++;
      } catch (e) {
        report.errors++;
        report.items.push({ sheet: sheet.sheet, name: row.name_vi, error: e.message });
      }
    }
  }
  return report;
}

export async function ingestConstructionSchedule(filePath, projectId, zoneCode) {
  const parsed = await parse(filePath, projectId, zoneCode);
  return await commit(parsed, projectId, zoneCode);
}
