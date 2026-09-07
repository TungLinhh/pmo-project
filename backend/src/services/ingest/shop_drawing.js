// Ingestion: Shop Drawing (file: Shop BOH.xlsx, Shop BPV.xlsx, etc.)
// PG-only. Mô hình A wizard: parse() returns rows, commit() inserts them.
import { getDb } from '../../db/index.js';
import { recordFailure } from './failures.js';
import { readSheet, toText, toInt, toFloat, toDate, findDataStart } from '../../lib/excel.js';
import { findOrCreateZone } from './index.js';

const HEADER_KEYWORDS = ['mã hiệu', 'mã', 'tên', 'name', 'stt', 'tt', 'drawing code'];

function resolveZone(zoneCode) {
  if (!zoneCode) return { code: 'GEN-SHOP', name: 'Shop Drawing - General' };
  return { code: zoneCode, name: zoneCode };
}

function parseRow(row) {
  const drawingCode = toText(row[5]);
  const name = toText(row[6]);
  if (!drawingCode) return null;
  return {
    drawing_code: drawingCode,
    name_vi: name,
    name_en: null,
    progress_pct: toFloat(row[7]),
    planned_submit_date: toDate(row[8]),
    actual_submit_date: toDate(row[9]),
    bql_l1_response: toText(row[11]),
    bql_l1_date: toDate(row[12]),
    bql_l1_comment: toText(row[13]),
    bql_l2_response: toText(row[15]),
    bql_l2_date: toDate(row[16]),
    bql_l2_comment: toText(row[17]),
    bql_l3_response: toText(row[19]),
    bql_l3_date: toDate(row[20]),
    bql_l3_comment: toText(row[21]),
    bql_l4_response: toText(row[23]),
    bql_l4_date: toDate(row[24]),
    bql_l4_comment: toText(row[25]),
    bql_l5_response: toText(row[27]),
    bql_l5_date: toDate(row[28]),
    bql_l5_comment: toText(row[29]),
    rs1_planned_date: toDate(row[21]),
    rs1_actual_date: toDate(row[25]),
    rs2_planned_date: toDate(row[29]),
    rs2_actual_date: toDate(row[29]),
    approval_date: toDate(typeof row[32] === 'boolean' ? null : row[32]),
  };
}

export async function parse(filePath, projectId, zoneCode) {
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const { code, name } = resolveZone(zoneCode);
  const sheets = [];
  for (const sheetName of wb.SheetNames) {
    if (!sheetName.toUpperCase().startsWith('SHOP') && sheetName !== 'SHOP OTH') continue;
    const rows = readSheet(filePath, sheetName);
    const dataStart = findDataStart(rows, { codeCol: 5, nameCol: 6, headerKeywords: HEADER_KEYWORDS, maxScan: 40 });
    const sheetRows = [];
    for (let r = dataStart; r < rows.length; r++) {
      const row = rows[r] || [];
      const parsed = parseRow(row);
      if (parsed) sheetRows.push({ rowIndex: r + 1, ...parsed });
    }
    sheets.push({ sheet: sheetName, rows: sheetRows });
  }
  return { zone: { code, name }, sheets, totalRows: sheets.reduce((s, x) => s + x.rows.length, 0) };
}

export async function commit(parsed, projectId, zoneCode) {
  const db = getDb();
  const { code } = resolveZone(zoneCode);
  const zone = await findOrCreateZone(projectId, code, code);
  const zoneId = zone.id;

  const report = { doc_type: 'shop_drawing', zone: code, ok: 0, errors: 0, items: [] };
  for (const sheet of parsed.sheets) {
    for (const [idx, row] of sheet.rows.entries()) {
      try {
        await db.upsert('shop_drawings',
          { conflictCols: ['project_id', 'drawing_code'] },
          {
            project_id: projectId, zone_id: zoneId, source_sheet: sheet.sheet,
            drawing_code: row.drawing_code, name_vi: row.name_vi, name_en: row.name_en,
            progress_pct: row.progress_pct,
            planned_submit_date: row.planned_submit_date, actual_submit_date: row.actual_submit_date,
            bql_l1_response: row.bql_l1_response, bql_l1_date: row.bql_l1_date, bql_l1_comment: row.bql_l1_comment,
            bql_l2_response: row.bql_l2_response, bql_l2_date: row.bql_l2_date, bql_l2_comment: row.bql_l2_comment,
            bql_l3_response: row.bql_l3_response, bql_l3_date: row.bql_l3_date, bql_l3_comment: row.bql_l3_comment,
            bql_l4_response: row.bql_l4_response, bql_l4_date: row.bql_l4_date, bql_l4_comment: row.bql_l4_comment,
            bql_l5_response: row.bql_l5_response, bql_l5_date: row.bql_l5_date, bql_l5_comment: row.bql_l5_comment,
            rs1_planned_date: row.rs1_planned_date, rs1_actual_date: row.rs1_actual_date,
            rs2_planned_date: row.rs2_planned_date, rs2_actual_date: row.rs2_actual_date,
            approval_date: row.approval_date,
          }
        );
        report.ok++;
      } catch (e) {
        recordFailure(report, { sheet: sheet.sheet, row: row.rowIndex ?? idx + 1, ref: row.drawing_code, message: e.message, keep: { code: row.drawing_code } });
      }
    }
  }
  return report;
}

// Backward compat
export async function ingestShopDrawing(filePath, projectId, zoneCode) {
  const parsed = await parse(filePath, projectId, zoneCode);
  return await commit(parsed, projectId, zoneCode);
}
