// Ingestion: Business Process (file: quy trình thực hiện dự án.xlsx)
import { getDb } from '../../db/index.js';
import { readSheet, toText, toInt } from '../../lib/excel.js';

export async function ingestBusinessProcess(filePath, tenantId, processCode = 'project_execution') {
  const db = getDb();
  const rows = readSheet(filePath, 'Quy trình thực hiện dự án');
  const report = { doc_type: 'business_process', ok: 0, errors: 0, items: [] };

  // Idempotency: delete old
  db.prepare('DELETE FROM business_process_steps WHERE tenant_id = ? AND process_code = ?').run(tenantId, processCode);

  const insert = db.prepare(`
    INSERT INTO business_process_steps (tenant_id, process_code, ordinal, name_vi, name_en, content_vi, responsibility_vi, verification_vi)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `);

  for (const row of rows) {
    // Header at R8 (0-idx 1): C1=STT, C2=Tiến trình, C3=Nội dung, C4=Thực hiện, C5=Kiểm tra
    // Data starts at R10 (0-idx 3+). Some rows have null in C1 (continuation).
    const ordinal = toInt(row[0]) || (report.items.length > 0 ? report.items[report.items.length - 1].ordinal : null);
    const name = toText(row[1]);
    const content = toText(row[2]);
    const responsibility = toText(row[3]);
    const verification = toText(row[4]);

    if (!ordinal || !name) continue;

    try {
      insert.run(tenantId, processCode, ordinal, name, null, content, responsibility, verification);
      report.ok++;
      report.items.push({ ordinal, name });
    } catch (e) {
      report.errors++;
      report.items.push({ ordinal, name, error: e.message });
    }
  }

  return report;
}
