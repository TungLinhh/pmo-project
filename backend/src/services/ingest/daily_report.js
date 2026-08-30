// Ingestion: Daily Report (LAWRENCE STING C20 style)
// File: Báo cáo công việc C20 ngày 23.5.2021.xlsx
// Each sheet = 1 day
import { getDb } from '../../db/index.js';
import { readSheet, toDate, toInt, toFloat, toText, renumber, splitBilingual, normalizeCell } from '../../lib/excel.js';

const MANPOWER_ROLES = [
  'Quản lý dự án (Project Manager)',
  'Chỉ Huy trưởng/Phó CHT (Site Manager)',
  'KS điện (Electrical Engineer)',
  'KS cấp thoát nước (Water supply & drainage engineer)',
  'KS điều hòa (HVAC engineer)',
  'Kỹ sư QS',
  'Ks khác',
  'Thư ký dự án (nếu có)',
  'Giám sát ATLĐ (Safety Officer)',
  'Đốc công (Foreman)',
  'Thợ nước (Plumber)',
  'Thợ hàn (Welder)',
  'Thợ điện (Electrician)',
  'Thợ phụ (Help)',
  'Công nhân trực tiếp khác (Other)',
  'Thủ kho và lái xe',
  'Công nhật',
  'Nhân công của các đội thuê khoán',
];

// Parse sheet name "23.5.2021" -> "2021-05-23"
function parseSheetDate(sheetName) {
  const m = sheetName.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
  if (!m) return null;
  const [, d, mo, y] = m;
  return `${y}-${mo.padStart(2, '0')}-${d.padStart(2, '0')}`;
}

export async function ingestDailyReport(filePath, projectId, options = {}) {
  const db = getDb();
  const XLSX = (await import('xlsx')).default;
  const wb = XLSX.readFile(filePath, { cellDates: true });
  const report = { doc_type: 'daily_report', sheets: [], total: { ok: 0, errors: 0 } };

  for (const sheetName of wb.SheetNames) {
    const reportDate = parseSheetDate(sheetName);
    if (!reportDate) {
      report.sheets.push({ sheet: sheetName, status: 'SKIPPED', reason: 'Sheet name not a date' });
      continue;
    }

    try {
      const rows = readSheet(filePath, sheetName);
      const result = await ingestOneSheet(db, projectId, sheetName, reportDate, rows);
      report.sheets.push({ sheet: sheetName, status: 'OK', ...result });
      report.total.ok += result.ok;
      report.total.errors += result.errors;
    } catch (e) {
      report.sheets.push({ sheet: sheetName, status: 'FAILED', error: e.message });
      report.total.errors++;
    }
  }

  return report;
}

async function ingestOneSheet(db, projectId, sheetName, reportDate, rows) {
  // Extract metadata
  const preparedBy = toText(rows[1]?.[24]);  // R2 C25 = 0-indexed [1][24]
  const approverRole = toText(rows[83]?.[20]) || 'Đại diện ban chấp hành/chủ tịch';

  // Upsert daily_reports
  const insertReport = db.prepare(`
    INSERT INTO daily_reports (project_id, report_date, prepared_by, approver_role, source_sheet_name)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(project_id, report_date) DO UPDATE SET
      prepared_by = excluded.prepared_by,
      approver_role = excluded.approver_role,
      source_sheet_name = excluded.source_sheet_name
    RETURNING id
  `);
  const insertReportResult = insertReport.get(projectId, reportDate, preparedBy, approverRole, sheetName);
  const dailyReportId = insertReportResult?.id !== undefined ? insertReportResult.id : insertReportResult?.lastInsertRowid;

  // Delete old child rows for idempotency
  db.prepare('DELETE FROM daily_work_items WHERE daily_report_id = ?').run(dailyReportId);
  db.prepare('DELETE FROM daily_materials WHERE daily_report_id = ?').run(dailyReportId);
  db.prepare('DELETE FROM daily_manpower WHERE daily_report_id = ?').run(dailyReportId);
  db.prepare('DELETE FROM daily_acceptance WHERE daily_report_id = ?').run(dailyReportId);
  db.prepare('DELETE FROM daily_safety_observations WHERE daily_report_id = ?').run(dailyReportId);
  db.prepare('DELETE FROM daily_recommendations WHERE daily_report_id = ?').run(dailyReportId);

  let ok = 0, errors = 0;

  // ========= Section I: Work items (rows 29-37) =========
  // Cols: C1=TT, C2=system, C3=blocker, C8=sub-TT, C9=sub-name, C11=rate, C12=start, C15=progress
  const workItems = [];
  let currentParent = null;
  for (let r = 28; r <= 37; r++) {  // 0-indexed
    const row = rows[r] || [];
    const tt = toInt(row[0]);
    const name = toText(row[1]);
    const blocker = toText(row[2]);
    if (tt && name) {
      // Parent item (level 1)
      currentParent = { parent_id: null, ordinal: tt, name_vi: name, blocker_notes: blocker, system_type: null, manpower_rate: null, start_date: null, finish_date: null, lost_days: null, progress_pct: null };
      workItems.push(currentParent);
    }
    const subTT = toInt(row[7]);
    const subName = toText(row[8]);
    if (subName) {
      workItems.push({
        parent_id: currentParent ? workItems.indexOf(currentParent) + 1 : null, // 1-indexed
        ordinal: subTT,
        name_vi: subName,
        blocker_notes: null,
        system_type: name && /MECHANICAL/i.test(name) ? 'MECHANICAL' : (name && /ELECTRICAL/i.test(name) ? 'ELECTRICAL' : null),
        manpower_rate: toFloat(row[10]),
        start_date: toDate(row[11]),
        finish_date: toDate(row[12]),
        lost_days: toInt(row[13]),
        progress_pct: toFloat(row[14]),
      });
    }
  }
  // Insert work items
  const insertWork = db.prepare(`
    INSERT INTO daily_work_items (daily_report_id, parent_id, ordinal, name_vi, blocker_notes, system_type, manpower_rate, start_date, finish_date, lost_days, progress_pct)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const insertedIds = [];
  for (const item of workItems) {
    try {
      const result = insertWork.run(
        dailyReportId, null, item.ordinal, item.name_vi, item.blocker_notes, item.system_type,
        item.manpower_rate, item.start_date, item.finish_date, item.lost_days, item.progress_pct
      );
      insertedIds.push(Number(result.lastInsertRowid));
      ok++;
    } catch (e) {
      errors++;
    }
  }
  // Update parent_id for children (two-pass: first insert all, then update parent_id)
  for (let i = 0; i < workItems.length; i++) {
    if (workItems[i].parent_id) {
      const parentIdx = workItems[i].parent_id - 1;
      if (parentIdx >= 0 && parentIdx < insertedIds.length) {
        db.prepare('UPDATE daily_work_items SET parent_id = ? WHERE id = ?').run(insertedIds[parentIdx], insertedIds[i]);
      }
    }
  }

  // ========= Section II: Materials (rows 42-57) =========
  // Cols: C1=TT, C8=sub-TT, C9=material name, C12=start, C13=finish, C14=lost, C15=progress
  const insertMaterial = db.prepare(`
    INSERT INTO daily_materials (daily_report_id, ordinal, name_vi, start_date, finish_date, lost_days, progress_pct)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  for (let r = 42; r <= 57; r++) {
    const row = rows[r] || [];
    const subTT = toInt(row[7]);
    const name = toText(row[8]);
    if (name) {
      try {
        insertMaterial.run(dailyReportId, subTT, name, toDate(row[11]), toDate(row[12]), toInt(row[13]), toFloat(row[14]));
        ok++;
      } catch (e) { errors++; }
    }
  }

  // ========= Section III: Manpower (rows 63-82) =========
  // Cols: C11=role, C20=cumulative, C26=today, C32=consumed
  const insertManpower = db.prepare(`
    INSERT INTO daily_manpower (daily_report_id, role_name, cumulative_qty, today_qty, consumed_qty)
    VALUES (?, ?, ?, ?, ?)
  `);
  for (let r = 63; r <= 82; r++) {
    const row = rows[r] || [];
    const role = toText(row[10]);
    if (role) {
      try {
        insertManpower.run(dailyReportId, role, toInt(row[19]), toInt(row[25]), toInt(row[31]));
        ok++;
      } catch (e) { errors++; }
    }
  }

  // ========= Section III: Acceptance (rows 63-77) =========
  // Cols: C1=TT, C2=material_name, C3=status (0/1)
  const insertAcceptance = db.prepare(`
    INSERT INTO daily_acceptance (daily_report_id, ordinal, acceptance_type, status)
    VALUES (?, ?, ?, ?)
  `);
  for (let r = 63; r <= 77; r++) {
    const row = rows[r] || [];
    const tt = toInt(row[0]);
    if (tt) {
      try {
        // status 0 = chưa cập nhật (NULL per user), 1 = OK
        const raw = toInt(row[2]);
        const status = raw === 0 ? null : raw;
        insertAcceptance.run(dailyReportId, tt, 'material', status);
        ok++;
      } catch (e) { errors++; }
    }
  }

  return { daily_report_id: dailyReportId, ok, errors };
}

export async function ingestAllDailyReports(filePath, projectId) {
  return await ingestDailyReport(filePath, projectId);
}
