// Ingestion: Material Supply (file: Vật tư BOH.xlsx, etc.)
// PG-only. Mô hình A wizard: parse() returns rows, commit() inserts them.
import { getDb } from '../../db/index.js';
import { recordFailure } from './failures.js';
import { readSheet, toText, toInt, toFloat, toDate, findDataStart } from '../../lib/excel.js';
import { findOrCreateZone } from './index.js';

const HEADER_KEYWORDS = ['mã hiệu', 'mã', 'tên', 'stt', 'tt', 'code', 'reference'];

function resolveZone(zoneCode) {
  if (!zoneCode) return { code: 'GEN-MAT', name: 'Material Supply - General' };
  return { code: zoneCode, name: zoneCode };
}

function parseRow(row, rIdx) {
  const code = toText(row[5]);
  const name = toText(row[6]);
  if (!code && !name) return null;
  return {
    material_code: code || `AUTO-${rIdx}`,
    name_vi: name,
    name_en: null,
    progress_pct: toFloat(row[7]),
    request_date_1: toDate(row[8]),
    request_date_2: toDate(row[9]),
    request_date_3: toDate(row[10]),
    request_date_4: toDate(row[11]),
  };
}

export async function parse(filePath, projectId, zoneCode) {
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const { code, name } = resolveZone(zoneCode);
  const sheets = [];
  for (const sheetName of wb.SheetNames) {
    const rows = readSheet(filePath, sheetName);
    if (rows.length < 5) continue;
    const dataStart = findDataStart(rows, { codeCol: 5, nameCol: 6, headerKeywords: HEADER_KEYWORDS, maxScan: 30 });
    const sheetRows = [];
    for (let r = dataStart; r < rows.length; r++) {
      const parsed = parseRow(rows[r] || [], r);
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

  const report = { doc_type: 'material_supply', zone: code, ok: 0, errors: 0, items: [] };
  for (const sheet of parsed.sheets) {
    for (const [idx, row] of sheet.rows.entries()) {
      try {
        await db.upsert('materials',
          { conflictCols: ['project_id', 'zone_id', 'material_code'] },
          {
            project_id: projectId, zone_id: zoneId, source_sheet: sheet.sheet,
            material_code: row.material_code, name_vi: row.name_vi, name_en: row.name_en,
            progress_pct: row.progress_pct,
            request_date_1: row.request_date_1, request_date_2: row.request_date_2,
            request_date_3: row.request_date_3, request_date_4: row.request_date_4,
          }
        );
        report.ok++;
      } catch (e) {
        recordFailure(report, { sheet: sheet.sheet, row: row.rowIndex ?? idx + 1, ref: row.material_code, message: e.message, keep: { code: row.material_code } });
      }
    }
  }
  return report;
}

export async function ingestMaterialSupply(filePath, projectId, zoneCode) {
  const parsed = await parse(filePath, projectId, zoneCode);
  return await commit(parsed, projectId, zoneCode);
}
