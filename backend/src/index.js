// Express server
import express from 'express';
import cors from 'cors';
import multer from 'multer';
import { saveFile, getFilePath, fileExists } from './lib/storage.js';
import { detectDocType, listSheets } from './lib/excel.js';
import { getDb, closeDb } from './db/index.js';
import { ingest, findOrCreateProject } from './services/ingest/index.js';

const app = express();
const PORT = process.env.PORT || 3000;
const TENANT_ID = 1;  // hardcoded for MVP

app.use(cors());
app.use(express.json());
import { authMiddleware } from './lib/auth.js';
app.use(authMiddleware);

// Multer config: preserve UTF-8 filenames
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 },
});

app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file' });

    // Multer may mangle UTF-8 filenames as Latin-1. Try to detect and fix.
    let originalName = req.file.originalname;

    // Try to detect Vietnamese chars in the original
    const hasVietChars = /[áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ]/.test(originalName);

    if (!hasVietChars) {
      // Try to re-decode as UTF-8 from Latin-1 mangled form
      const decoded = Buffer.from(originalName, 'latin1').toString('utf8');
      if (/[áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ]/.test(decoded)) {
        originalName = decoded;
      }
    }

    const { key, fullPath, hash, size } = saveFile(req.file.buffer, originalName);
    let expectedDocType = req.body.doc_type || detectDocType(originalName.toLowerCase());

    // If still unknown, try with mojibake-decoded version
    if (expectedDocType === 'unknown') {
      const redecoded = Buffer.from(originalName, 'latin1').toString('utf8');
      const altType = detectDocType(redecoded.toLowerCase());
      if (altType !== 'unknown') {
        expectedDocType = altType;
        originalName = redecoded;
      }
    }
    const projectCode = req.body.project_code || null;

    const db = getDb();

    // Idempotency: same content_hash + same tenant = skip re-processing
    const existing = db.prepare(`
      SELECT id, status, report_json FROM file_uploads
      WHERE tenant_id = ? AND content_hash = ?
    `).get(TENANT_ID, hash);

    if (existing) {
      return res.json({
        upload_id: existing.id,
        status: existing.status,
        report: JSON.parse(existing.report_json || '{}'),
        message: 'File already processed (idempotent)',
        content_hash: hash,
      });
    }

    // Save upload record
    const insertUpload = db.prepare(`
      INSERT INTO file_uploads (tenant_id, original_filename, storage_key, content_hash, file_size, expected_doc_type, status)
      VALUES (?, ?, ?, ?, ?, ?, 'PROCESSING')
    `);
    const insertResult = insertUpload.run(TENANT_ID, req.file.originalname, key, hash, size, expectedDocType);
    const uploadId = Number(insertResult.lastInsertRowid);

    // Find/create project
    let project = null;
    if (projectCode) {
      project = findOrCreateProject(TENANT_ID, projectCode);
    } else {
      // Try to detect from filename (e.g. "Shop BOH" -> project BTE-WP4-HBC, zone BOH)
      // For MVP, default to BTE-WP4-HBC
      project = findOrCreateProject(TENANT_ID, 'BTE-WP4-HBC');
    }

    // Run ingestion
    let ingestResult;
    try {
      const ingestOpts = {
        tenantId: TENANT_ID,
        projectId: project.id,
        projectCode,
      };

      // Extract zone from filename for shop/construction/material
      if (['shop_drawing', 'construction_schedule', 'material_supply'].includes(expectedDocType)) {
        // Use originalName (already mojibake-fixed) for regex
        // Match: "Shop TST-A", "TĐ TST-B", "Vật tư TST-C"
        const m = originalName.match(/(?:Shop|TĐ|Vật tư|Vat tu|VT|MEP)\s+(.+?)\.xlsx?$/i);
        if (m) {
          let zone = m[1].toUpperCase().trim()
            .replace(/\s*&\s*/g, '-')
            .replace(/^BOH$/, 'BOH')
            .replace(/^BPV-1\s*BR$/, 'BPV-1BR')
            .replace(/^BPV-2\s*BR$/, 'BPV-2BR')
            .replace(/^HPV-1\s*BR$/, 'HPV-1BR')
            .replace(/^HPV-2\s*BR$/, 'HPV-2BR')
            .replace(/^RES-3\s*BR$/, 'RES-3BR')
            .replace(/^RES-4\s*BR$/, 'RES-4BR')
            .replace(/^BULTER$/, 'BUT')
            .replace(/^BSC$/, 'BSN')
            .replace(/^LOB.*SPA$/, 'LOB-SPA')
            .replace(/^HẠ TẦNG$/, 'INF');
          ingestOpts.zoneCode = zone;
        }
      }

      console.log('DEBUG upload: expectedDocType=', expectedDocType, 'projectId=', project.id, 'ingestOpts=', ingestOpts);
      ingestResult = await ingest(fullPath, expectedDocType, ingestOpts);
      console.log('DEBUG upload: ingestResult=', JSON.stringify(ingestResult).slice(0, 200));
    } catch (e) {
      console.error('DEBUG upload: ingest FAILED:', e.message, e.stack);
      db.prepare(`UPDATE file_uploads SET status = 'FAILED', report_json = ? WHERE id = ?`).run(JSON.stringify({ error: e.message }), uploadId);
      return res.status(500).json({ upload_id: uploadId, status: 'FAILED', error: e.message });
    }

    const totalOk = ingestResult.total?.ok || ingestResult.ok || 0;
    const totalErrors = ingestResult.total?.errors || ingestResult.errors || 0;
    const status = totalErrors === 0 ? 'SUCCESS' : (totalOk > 0 ? 'PARTIAL' : 'FAILED');

    db.prepare(`
      UPDATE file_uploads
      SET status = ?, total_rows = ?, ok_rows = ?, error_rows = ?, report_json = ?
      WHERE id = ?
    `).run(status, totalOk + totalErrors, totalOk, totalErrors, JSON.stringify(ingestResult), uploadId);

    res.json({
      upload_id: uploadId,
      status,
      content_hash: hash,
      project_id: project.id,
      project_code: projectCode || 'BTE-WP4-HBC',
      ...ingestResult,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message, stack: e.stack });
  }
});

// ============ Data endpoints ============
app.get('/api/projects', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM projects WHERE tenant_id = ? ORDER BY id').all(TENANT_ID);
  res.json(rows);
});

app.get('/api/projects/:id/zones', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM zones WHERE project_id = ? ORDER BY code').all(req.params.id);
  res.json(rows);
});

app.get('/api/master-data/:resource', (req, res) => {
  const db = getDb();
  const allowed = {
    subcontractors: 'SELECT id, name, capability_summary, status, is_internal_team FROM subcontractors',
    suppliers: 'SELECT id, name, system, category, past_projects, location FROM suppliers',
    'business-processes': 'SELECT id, process_code, name_vi, name_en, ordinal FROM business_process_steps ORDER BY ordinal',
    workers: 'SELECT id, full_name, role, 1 as is_active FROM (SELECT 1 as id, "Demo Worker" as full_name, "worker" as role LIMIT 1)',
  };
  const sql = allowed[req.params.resource];
  if (!sql) return res.json([]);  // empty for resources not yet wired
  const rows = db.prepare(sql).all();
  res.json(rows);
});

// ============ Health Dashboard (mục 4-6) ============
app.get('/api/dashboard/portfolio-kpi', (req, res) => {
  const db = getDb();
  const projects = db.prepare('SELECT id, code, name_vi FROM projects').all();
  const result = projects.map(p => {
    const total = db.prepare('SELECT COUNT(*) as c FROM construction_schedule_items WHERE project_id = ?').get(p.id).c;
    const done = db.prepare('SELECT COUNT(*) as c FROM construction_schedule_items WHERE project_id = ? AND progress_pct >= 1').get(p.id).c;
    const overdue = db.prepare('SELECT COUNT(*) as c FROM construction_schedule_items WHERE project_id = ? AND progress_pct < 1 AND plan_end_date < date(\'now\')').get(p.id).c;
    const shopTotal = db.prepare('SELECT COUNT(*) as c FROM shop_drawings WHERE project_id = ?').get(p.id).c;
    const shopApproved = db.prepare('SELECT COUNT(*) as c FROM shop_drawings WHERE project_id = ? AND approval_date IS NOT NULL').get(p.id).c;
    const pct = total > 0 ? done / total : 0;
    let health = 'ON_TRACK';
    if (pct < 0.5) health = 'CRITICAL';
    else if (pct < 0.7) health = 'BEHIND';
    else if (pct < 0.9 || overdue > 0) health = 'WATCH';
    return { ...p, progress_pct: pct, total, done, overdue, shopTotal, shopApproved, health };
  });
  res.json(result);
});

app.get('/api/projects/:id/daily-reports', (req, res) => {
  const db = getDb();
  const rows = db.prepare(`
    SELECT dr.*,
      (SELECT COUNT(*) FROM daily_work_items WHERE daily_report_id = dr.id) AS work_items_count,
      (SELECT COUNT(*) FROM daily_manpower WHERE daily_report_id = dr.id) AS manpower_count
    FROM daily_reports dr
    WHERE project_id = ?
    ORDER BY report_date DESC
  `).all(req.params.id);
  res.json(rows);
});

app.get('/api/daily-reports/:id/full', (req, res) => {
  const db = getDb();
  const report = db.prepare('SELECT * FROM daily_reports WHERE id = ?').get(req.params.id);
  if (!report) return res.status(404).json({ error: 'Not found' });
  res.json({
    ...report,
    work_items: db.prepare('SELECT * FROM daily_work_items WHERE daily_report_id = ? ORDER BY id').all(req.params.id),
    materials: db.prepare('SELECT * FROM daily_materials WHERE daily_report_id = ? ORDER BY id').all(req.params.id),
    manpower: db.prepare('SELECT * FROM daily_manpower WHERE daily_report_id = ? ORDER BY id').all(req.params.id),
    acceptance: db.prepare('SELECT * FROM daily_acceptance WHERE daily_report_id = ? ORDER BY id').all(req.params.id),
  });
});

app.get('/api/projects/:id/construction-schedule', (req, res) => {
  const db = getDb();
  const { zone, search, status } = req.query;
  let sql = `
    SELECT csi.*, z.code AS zone_code
    FROM construction_schedule_items csi
    JOIN zones z ON z.id = csi.zone_id
    WHERE csi.project_id = ?
  `;
  const params = [req.params.id];
  if (zone) {
    sql += ' AND z.code = ?';
    params.push(zone);
  }
  if (status) {
    sql += ' AND csi.status = ?';
    params.push(status);
  }
  if (search) {
    sql += ' AND (csi.name_vi LIKE ? OR csi.name_en LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }
  sql += ' ORDER BY z.code, csi.level_arabic, csi.level_roman, csi.ordinal LIMIT 500';
  const rows = db.prepare(sql).all(...params);
  res.json(rows);
});

app.get('/api/projects/:id/shop-drawings', (req, res) => {
  const db = getDb();
  const { zone, search, min_progress, status } = req.query;
  let sql = `
    SELECT sd.*, z.code AS zone_code
    FROM shop_drawings sd
    LEFT JOIN zones z ON z.id = sd.zone_id
    WHERE sd.project_id = ?
  `;
  const params = [req.params.id];
  if (zone) {
    sql += ' AND z.code = ?';
    params.push(zone);
  }
  if (status) {
    sql += ' AND sd.status = ?';
    params.push(status);
  }
  if (min_progress) {
    sql += ' AND sd.progress_pct >= ?';
    params.push(Number(min_progress));
  }
  if (search) {
    sql += ' AND (sd.drawing_code LIKE ? OR sd.name_vi LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }
  sql += ' ORDER BY z.code, sd.drawing_code LIMIT 500';
  const rows = db.prepare(sql).all(...params);
  res.json(rows);
});

app.get('/api/projects/:id/zones/:code/items', (req, res) => {
  const db = getDb();
  // Generic: get all items for a specific zone across all data types
  const projectId = Number(req.params.id);
  const zoneCode = req.params.code;
  const zone = db.prepare('SELECT id FROM zones WHERE project_id = ? AND code = ?').get(projectId, zoneCode);
  if (!zone) return res.status(404).json({ error: 'Zone not found' });

  const result = {
    zone: { code: zoneCode, id: zone.id },
    shop_drawings: db.prepare('SELECT * FROM shop_drawings WHERE project_id = ? AND zone_id = ?').all(projectId, zone.id),
    construction_items: db.prepare('SELECT * FROM construction_schedule_items WHERE project_id = ? AND zone_id = ?').all(projectId, zone.id),
    materials: db.prepare('SELECT * FROM materials WHERE project_id = ? AND zone_id = ?').all(projectId, zone.id),
  };
  res.json(result);
});

app.get('/api/business-process/:code', (req, res) => {
  const db = getDb();
  const rows = db.prepare(`
    SELECT * FROM business_process_steps
    WHERE tenant_id = ? AND process_code = ?
    ORDER BY ordinal
  `).all(TENANT_ID, req.params.code);
  res.json(rows);
});

app.get('/api/uploads', (req, res) => {
  const db = getDb();
  const rows = db.prepare(`
    SELECT id, original_filename, expected_doc_type, status, total_rows, ok_rows, error_rows, created_at
    FROM file_uploads
    WHERE tenant_id = ?
    ORDER BY id DESC
    LIMIT 50
  `).all(TENANT_ID);
  res.json(rows);
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    authenticated: !!req.session,
    user: req.session ? { id: req.session.user_id, role: req.session.role } : null
  });
});

import { login as loginFn, logout as logoutFn, listUsers } from './lib/auth.js';

app.post('/api/auth/login', (req, res) => {
  if (!req.body.email) {
    return res.json({
      message: 'Send POST {email, password}',
      default: { email: 'admin@hbg.com', password: 'admin123' },
      users: listUsers().map(u => ({ email: u.email, role: u.role }))
    });
  }
  const result = loginFn(req.body.email, req.body.password);
  if (!result) return res.status(401).json({ error: 'Invalid credentials' });
  res.json(result);
});

app.post('/api/auth/logout', (req, res) => {
  const auth = req.headers.authorization;
  if (auth?.startsWith('Bearer ')) logoutFn(auth.slice(7));
  res.json({ message: 'Logged out' });
});

app.get('/api/auth/me', (req, res) => {
  if (!req.session) return res.status(401).json({ error: 'Not authenticated' });
  res.json(req.session);
});

// ============ Export endpoints ============
import { exportDailyReport, exportConstructionSchedule, exportShopDrawings } from './services/export.js';

app.get('/api/export/daily-report/:id.xlsx', async (req, res) => {
  try {
    const buf = await exportDailyReport(Number(req.params.id));
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="daily-report-${req.params.id}.xlsx"`);
    res.send(buf);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/export/construction-schedule/:projectId.xlsx', async (req, res) => {
  try {
    const buf = await exportConstructionSchedule(Number(req.params.projectId));
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="construction-schedule-${req.params.projectId}.xlsx"`);
    res.send(buf);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/export/shop-drawings/:projectId.xlsx', async (req, res) => {
  try {
    const buf = await exportShopDrawings(Number(req.params.projectId));
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="shop-drawings-${req.params.projectId}.xlsx"`);
    res.send(buf);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ============ Issues (Mục 4-5, 6.5) ============
app.get('/api/projects/:id/issues', (req, res) => {
  const db = getDb();
  const { severity, status, category } = req.query;
  let sql = 'SELECT * FROM issues WHERE project_id = ?';
  const params = [req.params.id];
  if (severity) { sql += ' AND severity = ?'; params.push(severity); }
  if (status) { sql += ' AND status = ?'; params.push(status); }
  if (category) { sql += ' AND category = ?'; params.push(category); }
  sql += ' ORDER BY CASE severity WHEN \'CRITICAL\' THEN 1 WHEN \'HIGH\' THEN 2 WHEN \'MEDIUM\' THEN 3 ELSE 4 END, created_at DESC';
  res.json(db.prepare(sql).all(...params));
});

app.get('/api/issues/:id', (req, res) => {
  const db = getDb();
  const issue = db.prepare('SELECT * FROM issues WHERE id = ?').get(req.params.id);
  if (!issue) return res.status(404).json({ error: 'Issue not found' });
  // Attach directives
  const directives = db.prepare('SELECT * FROM directives WHERE issue_id = ? ORDER BY created_at DESC').all(req.params.id);
  // Attach audit log for this issue
  const audit = db.prepare("SELECT * FROM audit_log WHERE resource_type = 'issue' AND resource_id = ? ORDER BY created_at DESC LIMIT 20").all(req.params.id);
  res.json({ ...issue, directives, audit });
});

app.post('/api/projects/:id/issues', (req, res) => {
  // Alias for POST /api/issues - inject project_id from URL
  req.body.project_id = Number(req.params.id);
  const db = getDb();
  const { project_id, title, body, category, severity, source_resource, source_id, zone_id } = req.body;
  if (!project_id || !title) return res.status(400).json({ error: 'project_id and title required' });
  const info = db.prepare(`INSERT INTO issues (tenant_id, project_id, zone_id, source_resource, source_id, title, body, category, severity, status) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, 'OPEN')`)
    .run(project_id, zone_id || null, source_resource || null, source_id || null, title, body || null, category || null, severity || 'MEDIUM');
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'CREATE', 'issue', ?, ?)`)
    .run(req.session?.user_id || 1, req.session?.full_name || 'System', info.lastInsertRowid, `Issue created: ${title}`);
  const r = db.prepare('SELECT * FROM issues WHERE id = ?').get(info.lastInsertRowid);
  res.json(r);
});

app.post('/api/issues', (req, res) => {
  const db = getDb();
  const { project_id, title, body, category, severity, source_resource, source_id, zone_id } = req.body;
  if (!project_id || !title) return res.status(400).json({ error: 'project_id and title required' });
  const info = db.prepare(`INSERT INTO issues (tenant_id, project_id, zone_id, source_resource, source_id, title, body, category, severity, status) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, 'OPEN')`)
    .run(project_id, zone_id || null, source_resource || null, source_id || null, title, body || null, category || null, severity || 'MEDIUM');
  // Audit
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'CREATE', 'issue', ?, ?)`)
    .run(req.session?.user_id || 1, req.session?.full_name || 'System', info.lastInsertRowid, `Issue created: ${title}`);
  res.json({ id: info.lastInsertRowid });
});

// ============ Directives (CEO/PMO qualitative notes) ============
app.post('/api/directives', (req, res) => {
  const db = getDb();
  const { project_id, issue_id, body, notify_to_user_ids } = req.body;
  if (!project_id || !body) return res.status(400).json({ error: 'project_id and body required' });
  const userId = req.session?.user_id || 1;
  const userName = req.session?.full_name || 'Admin HBG (CEO)';
  // Insert directive
  const info = db.prepare(`INSERT INTO directives (tenant_id, project_id, issue_id, from_user_id, from_user_name, body, notify_to_user_ids) VALUES (1, ?, ?, ?, ?, ?, ?)`)
    .run(project_id, issue_id || null, userId, userName, body, JSON.stringify(notify_to_user_ids || []));
  // Trigger notification (resource_type=directive)
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — channel='in_app' là mặc định, các kênh khác để TODO
  db.prepare(`INSERT INTO notifications (tenant_id, user_id, project_id, issue_id, channel, delivery_status, severity, title, body, resource_type, resource_id) VALUES (1, NULL, ?, ?, 'in_app', 'sent', 'warning', ?, ?, 'directive', ?)`)
    .run(project_id, issue_id, `Chỉ thị mới từ ${userName}`, body.slice(0, 200), info.lastInsertRowid);
  // Audit (important change per spec mục 42 #8)
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'DIRECTIVE', ?, ?, ?)`)
    .run(userId, userName, issue_id ? 'issue' : 'project', issue_id || project_id, body.slice(0, 200));
  res.json({ id: info.lastInsertRowid });
});

app.get('/api/directives', (req, res) => {
  const db = getDb();
  const { project_id, issue_id } = req.query;
  let sql = 'SELECT * FROM directives WHERE 1=1';
  const params = [];
  if (project_id) { sql += ' AND project_id = ?'; params.push(project_id); }
  if (issue_id) { sql += ' AND issue_id = ?'; params.push(issue_id); }
  sql += ' ORDER BY created_at DESC';
  res.json(db.prepare(sql).all(...params));
});

// ============ Notifications ============
app.get('/api/notifications', (req, res) => {
  const db = getDb();
  const unreadOnly = req.query.unread === '1';
  let sql = 'SELECT * FROM notifications WHERE 1=1';
  const params = [];
  if (unreadOnly) { sql += ' AND read_at IS NULL'; }
  sql += ' ORDER BY CASE severity WHEN \'critical\' THEN 1 WHEN \'warning\' THEN 2 ELSE 3 END, created_at DESC LIMIT 50';
  const rows = db.prepare(sql).all(...params);
  // Count
  const counts = {
    total: db.prepare('SELECT COUNT(*) as c FROM notifications').get().c,
    unread: db.prepare('SELECT COUNT(*) as c FROM notifications WHERE read_at IS NULL').get().c,
    critical: db.prepare("SELECT COUNT(*) as c FROM notifications WHERE severity = 'critical' AND read_at IS NULL").get().c,
    warning: db.prepare("SELECT COUNT(*) as c FROM notifications WHERE severity = 'warning' AND read_at IS NULL").get().c,
  };
  res.json({ items: rows, counts });
});

app.post('/api/notifications/:id/read', (req, res) => {
  const db = getDb();
  db.prepare("UPDATE notifications SET read_at = datetime('now') WHERE id = ?").run(req.params.id);
  res.json({ ok: true });
});

app.post('/api/notifications/mark-all-read', (req, res) => {
  const db = getDb();
  const info = db.prepare("UPDATE notifications SET is_read = 1, read_at = datetime('now') WHERE is_read = 0").run();
  res.json({ updated: info.changes });
});

// ============ Audit Log ============
app.get('/api/audit', (req, res) => {
  const db = getDb();
  const { resource_type, resource_id, limit = 50 } = req.query;
  let sql = 'SELECT * FROM audit_log WHERE 1=1';
  const params = [];
  if (resource_type) { sql += ' AND resource_type = ?'; params.push(resource_type); }
  if (resource_id) { sql += ' AND resource_id = ?'; params.push(resource_id); }
  sql += ' ORDER BY created_at DESC LIMIT ?';
  params.push(Number(limit));
  res.json(db.prepare(sql).all(...params));
});

// ============ Material breakdown (for pie tooltip mục 2) ============
app.get('/api/projects/:id/material-breakdown', (req, res) => {
  const db = getDb();
  // materials table has no category column - group by name_vi prefix
  const rows = db.prepare(`
    SELECT
      SUBSTR(COALESCE(name_vi, material_code, 'Other'), 1, 16) AS category,
      COUNT(*) as count
    FROM materials
    WHERE project_id = ?
    GROUP BY category
    ORDER BY count DESC
    LIMIT 8
  `).all(req.params.id);
  res.json(rows);
});

// ============ Materials list + create (for Material pillar) ============
app.get('/api/projects/:id/materials', (req, res) => {
  const db = getDb();
  const limit = Number(req.query.limit) || 200;
  const rows = db.prepare('SELECT * FROM materials WHERE project_id = ? ORDER BY id DESC LIMIT ?').all(req.params.id, limit);
  res.json(rows);
});
app.post('/api/projects/:id/materials', (req, res) => {
  const db = getDb();
  const { material_code, name_vi, name_en, zone_id, progress_pct } = req.body;
  if (!material_code) return res.status(422).json({ error: 'material_code bắt buộc' });
  // Get zone_id from zones table - use first available zone for this project
  let zoneId = zone_id;
  if (!zoneId) {
    const z = db.prepare('SELECT id FROM zones WHERE project_id = ? LIMIT 1').get(req.params.id);
    zoneId = z?.id || null;
  }
  if (!zoneId) return res.status(422).json({ error: 'Project này chưa có zone nào - cần upload file "BTE_ZONE" trước' });
  // Idempotent: nếu đã có material_code thì update thay vì tạo mới
  const existing = db.prepare('SELECT * FROM materials WHERE project_id = ? AND material_code = ?').get(req.params.id, material_code);
  if (existing) {
    db.prepare('UPDATE materials SET name_vi = ?, name_en = ?, progress_pct = ? WHERE id = ?').run(name_vi || existing.name_vi, name_en || existing.name_en, progress_pct != null ? progress_pct : existing.progress_pct, existing.id);
    return res.json({ ...existing, name_vi: name_vi || existing.name_vi, name_en: name_en || existing.name_en, progress_pct: progress_pct != null ? progress_pct : existing.progress_pct, _updated: true });
  }
  try {
    const info = db.prepare(`INSERT INTO materials (project_id, zone_id, material_code, name_vi, name_en, progress_pct, created_at) VALUES (?, ?, ?, ?, ?, ?, datetime('now'))`)
      .run(req.params.id, zoneId, material_code, name_vi || null, name_en || null, progress_pct || 0);
    const r = db.prepare('SELECT * FROM materials WHERE id = ?').get(info.lastInsertRowid);
    db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'CREATE', 'material', ?, ?)`).run(req.session?.user_id || 1, req.session?.full_name || 'Admin HBG', r.id, 'Created material ' + material_code);
    return res.json(r);
  } catch (e) {
    if (String(e.message).includes('UNIQUE constraint')) {
      return res.status(409).json({ error: 'material_code đã tồn tại trong project này' });
    }
    if (String(e.message).includes('NOT NULL constraint')) {
      return res.status(422).json({ error: 'Project này thiếu zone - cần upload file BTE_ZONE trước' });
    }
    return res.status(500).json({ error: e.message });
  }
});

// ============ Payment milestones (for Payment pillar) ============
app.get('/api/projects/:id/payments', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM payment_milestones WHERE project_id = ? ORDER BY id DESC').all(req.params.id);
  res.json(rows);
});

// ============ Shopdrawing state transition (43.3) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — REJECTED → DRAFT transition
import {
  validateShopDrawingTransition, validateMaterialSubmittalTransition,
  computeSlaDeadline, isSlaOverdue, resolveConflict,
  hasPermission, getUserRole, isPeriodLocked
} from './lib/validation.js';

app.post('/api/shop-drawings/:id/transition', (req, res) => {
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — state machine
  const db = getDb();
  const { new_status, reason } = req.body;
  const sd = db.prepare('SELECT * FROM shop_drawings WHERE id = ?').get(req.params.id);
  if (!sd) return res.status(404).json({ error: 'Not found' });

  const v = validateShopDrawingTransition(sd.status, new_status);
  if (!v.valid) return res.status(400).json({ error: v.error });

  const userId = req.session?.user_id || 1;
  const updates = ['status = ?'];
  const params = [new_status];

  if (new_status === 'REJECTED') {
    if (!reason) return res.status(400).json({ error: 'reason required when REJECTED' });
    updates.push('rejected_reason = ?', 'rejected_by = ?', 'rejected_at = datetime(\'now\')');
    params.push(reason, userId);
  }
  if (sd.status === 'REJECTED' && new_status === 'DRAFT') {
    // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.3) — track REJECTED → DRAFT
    updates.push('reverted_to_draft_at = datetime(\'now\')', 'reverted_to_draft_by = ?');
    params.push(userId);
  }

  params.push(req.params.id);
  db.prepare(`UPDATE shop_drawings SET ${updates.join(', ')} WHERE id = ?`).run(...params);

  // Audit
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, field_name, old_value, new_value, note) VALUES (1, ?, ?, 'STATUS_CHANGE', 'shop_drawing', ?, 'status', ?, ?, ?)`)
    .run(userId, req.session?.full_name || 'System', req.params.id, sd.status, new_status, reason || (sd.status === 'REJECTED' && new_status === 'DRAFT' ? 'Reverted to DRAFT' : null));

  res.json({ id: req.params.id, old_status: sd.status, new_status });
});

// ============ Material Submittal SLA + revision (43.4) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4)
app.get('/api/projects/:id/material-submittals/overdue', (req, res) => {
  const db = getDb();
  const rows = db.prepare(`
    SELECT * FROM material_submittals
    WHERE project_id = ?
      AND status NOT IN ('APPROVED', 'CLOSED')
      AND sla_deadline < date('now')
  `).all(req.params.id);
  res.json(rows);
});

app.post('/api/material-submittals', (req, res) => {
  const db = getDb();
  const { project_id, material_id, submittal_code, sla_days, parent_submittal_id } = req.body;
  if (!project_id) return res.status(400).json({ error: 'project_id required' });
  const slaDays = sla_days || 7;
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — auto-compute sla_deadline khi submitted
  const revisionNumber = parent_submittal_id
    ? (db.prepare('SELECT revision_number FROM material_submittals WHERE id = ?').get(parent_submittal_id)?.revision_number || 0) + 1
    : 0;
  const info = db.prepare(`INSERT INTO material_submittals (project_id, material_id, submittal_code, status, sla_days, revision_number, parent_submittal_id, submitted_by) VALUES (?, ?, ?, 'DRAFT', ?, ?, ?, ?)`)
    .run(project_id, material_id, submittal_code, slaDays, revisionNumber, parent_submittal_id, req.session?.user_id || 1);
  res.json({ id: info.lastInsertRowid, revision_number: revisionNumber });
});

app.post('/api/material-submittals/:id/submit', (req, res) => {
  const db = getDb();
  const ms = db.prepare('SELECT * FROM material_submittals WHERE id = ?').get(req.params.id);
  if (!ms) return res.status(404).json({ error: 'Not found' });
  const v = validateMaterialSubmittalTransition(ms.status, 'SUBMITTED');
  if (!v.valid) return res.status(400).json({ error: v.error });
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — auto-compute sla_deadline
  const deadline = computeSlaDeadline(new Date().toISOString().slice(0, 10), ms.sla_days || 7);
  db.prepare(`UPDATE material_submittals SET status = 'SUBMITTED', submitted_date = date('now'), sla_deadline = ? WHERE id = ?`)
    .run(deadline, req.params.id);
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, field_name, old_value, new_value) VALUES (1, ?, ?, 'STATUS_CHANGE', 'material_submittal', ?, 'status', ?, 'SUBMITTED')`)
    .run(req.session?.user_id || 1, req.session?.full_name || 'System', req.params.id, ms.status);
  res.json({ id: req.params.id, sla_deadline: deadline });
});

app.post('/api/material-submittals/:id/reject', (req, res) => {
  const db = getDb();
  const { reason } = req.body;
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.4) — bắt buộc reason
  if (!reason) return res.status(400).json({ error: 'rejection reason required (43.4)' });
  const ms = db.prepare('SELECT * FROM material_submittals WHERE id = ?').get(req.params.id);
  if (!ms) return res.status(404).json({ error: 'Not found' });
  const v = validateMaterialSubmittalTransition(ms.status, 'REJECTED');
  if (!v.valid) return res.status(400).json({ error: v.error });
  db.prepare(`UPDATE material_submittals SET status = 'REJECTED', rejection_reason = ?, rejected_at = datetime('now') WHERE id = ?`)
    .run(reason, req.params.id);
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, field_name, old_value, new_value, note) VALUES (1, ?, ?, 'REJECT', 'material_submittal', ?, 'status', ?, 'REJECTED', ?)`)
    .run(req.session?.user_id || 1, req.session?.full_name || 'System', req.params.id, ms.status, reason);
  res.json({ id: req.params.id, rejected: true });
});

// ============ Schedule baseline (43.9) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.9) — versioning
app.post('/api/projects/:id/schedule-baselines', (req, res) => {
  const db = getDb();
  const { effective_date, notes } = req.body;
  const last = db.prepare('SELECT MAX(version) as v FROM schedule_baselines WHERE project_id = ?').get(req.params.id);
  const version = (last?.v || 0) + 1;
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.9) — KHÔNG sửa trực tiếp items
  //   Tạo row mới trong schedule_baselines, các item sẽ liên kết qua baseline_id
  const info = db.prepare(`INSERT INTO schedule_baselines (project_id, version, effective_date, created_by, notes) VALUES (?, ?, ?, ?, ?)`)
    .run(req.params.id, version, effective_date || new Date().toISOString().slice(0, 10), req.session?.user_id || 1, notes);
  res.json({ id: info.lastInsertRowid, version });
});

app.get('/api/projects/:id/schedule-baselines', (req, res) => {
  const db = getDb();
  res.json(db.prepare('SELECT * FROM schedule_baselines WHERE project_id = ? ORDER BY version DESC').all(req.params.id));
});

// ============ Contracts / Invoices / Payment Requests (43.5) ============
app.get('/api/projects/:id/contracts', (req, res) => {
  const db = getDb();
  res.json(db.prepare('SELECT * FROM contracts WHERE project_id = ? ORDER BY created_at DESC').all(req.params.id));
});
app.get('/api/contracts/:id/invoices', (req, res) => {
  const db = getDb();
  res.json(db.prepare('SELECT * FROM invoices WHERE contract_id = ? ORDER BY invoice_date DESC').all(req.params.id));
});
app.post('/api/invoices/:id/payment-requests', (req, res) => {
  const db = getDb();
  const { request_no, request_date, amount, retention_amount, due_date, notes } = req.body;
  if (!request_no || !amount) return res.status(422).json({ error: 'request_no and amount required' });
  const info = db.prepare(`INSERT INTO payment_requests (invoice_id, request_no, request_date, amount, retention_amount, due_date, status, notes, created_at) VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?, datetime('now'))`)
    .run(req.params.id, request_no, request_date || null, amount, retention_amount || 0, due_date || null, notes || null);
  const r = db.prepare('SELECT * FROM payment_requests WHERE id = ?').get(info.lastInsertRowid);
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'CREATE', 'payment_request', ?, ?)`)
    .run(req.session?.user_id || 1, req.session?.full_name || 'Admin HBG', r.id, 'Created payment request ' + request_no);
  res.json(r);
});

app.get('/api/invoices/:id/payment-requests', (req, res) => {
  const db = getDb();
  res.json(db.prepare('SELECT * FROM payment_requests WHERE invoice_id = ? ORDER BY due_date ASC').all(req.params.id));
});

// ============ Shop drawing detail ============
app.get('/api/shop-drawings/:id', (req, res) => {
  const db = getDb();
  const r = db.prepare('SELECT sd.*, z.code AS zone_code FROM shop_drawings sd LEFT JOIN zones z ON z.id = sd.zone_id WHERE sd.id = ?').get(req.params.id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  res.json(r);
});

// ============ Material Submittal list + detail (43.4) ============
app.get('/api/projects/:id/material-submittals', (req, res) => {
  const db = getDb();
  const { status } = req.query;
  let sql = 'SELECT * FROM material_submittals WHERE project_id = ?';
  const params = [req.params.id];
  if (status) { sql += ' AND status = ?'; params.push(status); }
  sql += ' ORDER BY created_at DESC LIMIT 100';
  res.json(db.prepare(sql).all(...params));
});
app.get('/api/material-submittals/:id', (req, res) => {
  const db = getDb();
  const r = db.prepare('SELECT * FROM material_submittals WHERE id = ?').get(req.params.id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  res.json(r);
});
app.post('/api/material-submittals/:id/approve', (req, res) => {
  const db = getDb();
  const r = db.prepare('SELECT * FROM material_submittals WHERE id = ?').get(req.params.id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  if (r.status !== 'SUBMITTED') return res.status(422).json({ error: 'Chỉ approve được status SUBMITTED, hiện tại: ' + r.status });
  const userId = req.session?.user_id || 1;
  const userName = req.session?.full_name || 'Admin HBG';
  db.prepare(`UPDATE material_submittals SET status = 'APPROVED', approved_by = ?, approved_date = datetime('now') WHERE id = ?`).run(userId, req.params.id);
  db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'APPROVE', 'material_submittal', ?, ?)`).run(userId, userName, req.params.id, 'Approved material submittal');
  res.json({ ok: true, id: req.params.id, status: 'APPROVED' });
});

// ============ Payment requests list + detail + update (43.5) ============
app.get('/api/projects/:id/payment-requests', (req, res) => {
  const db = getDb();
  const { status } = req.query;
  let sql = `SELECT pr.*, i.invoice_no, i.contract_id
             FROM payment_requests pr
             JOIN invoices i ON i.id = pr.invoice_id
             JOIN contracts c ON c.id = i.contract_id
             WHERE c.project_id = ?`;
  const params = [req.params.id];
  if (status) { sql += ' AND pr.status = ?'; params.push(status); }
  sql += ' ORDER BY pr.due_date ASC LIMIT 100';
  res.json(db.prepare(sql).all(...params));
});
app.get('/api/payment-requests/:id', (req, res) => {
  const db = getDb();
  const r = db.prepare(`SELECT pr.*, i.invoice_no, i.contract_id FROM payment_requests pr JOIN invoices i ON i.id = pr.invoice_id WHERE pr.id = ?`).get(req.params.id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  res.json(r);
});
app.put('/api/payment-requests/:id', (req, res) => {
  const db = getDb();
  const r = db.prepare('SELECT * FROM payment_requests WHERE id = ?').get(req.params.id);
  if (!r) return res.status(404).json({ error: 'Not found' });
  const { status, notes } = req.body;
  if (status === 'APPROVED') {
    const userId = req.session?.user_id || 1;
    db.prepare(`UPDATE payment_requests SET status = ?, approved_by = ?, approved_date = datetime('now'), notes = COALESCE(?, notes) WHERE id = ?`)
      .run(status, userId, notes, req.params.id);
    db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, note) VALUES (1, ?, ?, 'APPROVE', 'payment_request', ?, ?)`)
      .run(userId, req.session?.full_name || 'Admin HBG', req.params.id, 'Approved payment request ' + (notes || ''));
  } else {
    db.prepare(`UPDATE payment_requests SET status = ?, notes = COALESCE(?, notes) WHERE id = ?`).run(status, notes, req.params.id);
  }
  res.json({ ok: true, id: req.params.id, status });
});

// ============ KPI period lock PUT (43.10) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10) — period lock
app.get('/api/projects/:id/kpi-targets', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM kpi_targets WHERE project_id = ? ORDER BY period_start DESC, version DESC').all(req.params.id);
  res.json(rows);
});
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10)
app.put('/api/kpi-targets/:id', (req, res) => {
  const db = getDb();
  const kpi = db.prepare('SELECT * FROM kpi_targets WHERE id = ?').get(req.params.id);
  if (!kpi) return res.status(404).json({ error: 'Not found' });
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.10) — check period lock
  if (isPeriodLocked(kpi)) {
    return res.status(423).json({ error: 'Period locked. KPI không thể sửa (43.10)', period_lock: true, period_end: kpi.period_end });
  }
  // Allow update
  const { target_value, actual_value, notes } = req.body;
  db.prepare('UPDATE kpi_targets SET target_value = ?, actual_value = ?, notes = ? WHERE id = ?')
    .run(target_value, actual_value, notes, kpi.id);
  res.json({ updated: true });
});

// ============ Offline sync conflict resolution (43.7) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — last-write-wins
app.get('/api/sync/queue', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM offline_sync_queue ORDER BY created_at DESC LIMIT 20').all();
  res.json(rows);
});
app.post('/api/sync/resolve', (req, res) => {
  const db = getDb();
  const { resource_type, client_id, client_data, client_timestamp, server_record_id, server_timestamp } = req.body;
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — last-write-wins theo timestamp
  const resolution = resolveConflict(client_timestamp, server_timestamp || new Date().toISOString());

  // Log conflict to offline_sync_queue
  const qInfo = db.prepare(`INSERT INTO offline_sync_queue (user_id, client_id, resource_type, resource_json, client_timestamp, client_created_at, conflict_resolution, server_record_id, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`)
    .run(req.session?.user_id || 1, client_id, resource_type, JSON.stringify(client_data), client_timestamp, client_timestamp, resolution.winner, server_record_id, 'SYNCED');

  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.7) — nếu SERVER thắng, log server record vào audit_log
  if (resolution.winner === 'SERVER' && server_record_id) {
    db.prepare(`INSERT INTO audit_log (tenant_id, user_id, user_name, action, resource_type, resource_id, field_name, old_value, new_value, note) VALUES (1, ?, ?, 'UPDATE', ?, ?, 'conflict', 'CLIENT', 'SERVER', ?)`)
      .run(req.session?.user_id || 1, req.session?.full_name || 'System', resource_type, server_record_id, `Client ${client_id} bị override bởi server`);
  }
  res.json({ resolution: resolution.winner, sync_id: qInfo.lastInsertRowid });
});

// ============ Area hierarchy (43.8) ============
app.get('/api/projects/:id/area-hierarchy', (req, res) => {
  const db = getDb();
  const rows = db.prepare('SELECT * FROM area_hierarchy WHERE project_id = ? ORDER BY level, sort_order, id').all(req.params.id);
  res.json(rows);
});

// ============ Permission helper endpoint (43.2) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.2)
app.get('/api/me/permissions', (req, res) => {
  const session = req.session;
  if (!session) return res.status(401).json({ error: 'Not authenticated' });
  // Load is_ceo từ DB mỗi lần (cheap query) để đảm bảo luôn đúng
  const db = getDb();
  const u = db.prepare('SELECT role, is_ceo FROM users WHERE id = ?').get(session.user_id);
  if (!u) return res.status(401).json({ error: 'User not found' });
  const user = {
    id: session.user_id, role: u.role,
    full_name: session.full_name, is_ceo: u.is_ceo === 1
  };
  const userRole = getUserRole(user);
  const modules = ['shop', 'payment', 'material', 'schedule', 'master_data', 'approval'];
  const perms = {};
  for (const m of modules) perms[m] = { read: hasPermission(user, m, 'read'), write: hasPermission(user, m, 'write') };
  res.json({ role: userRole, is_ceo: user.is_ceo, permissions: perms });
});

// ============ Notification channel logic (43.6) ============
// TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — chỉ in_app
app.post('/api/notifications', (req, res) => {
  const db = getDb();
  const { project_id, issue_id, severity, title, body, resource_type, resource_id, channel = 'in_app' } = req.body;
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6)
  const deliveryStatus = channel === 'in_app' ? 'pending' : 'not_implemented';
  const info = db.prepare(`INSERT INTO notifications (tenant_id, user_id, project_id, issue_id, channel, delivery_status, severity, title, body, resource_type, resource_id) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
    .run(req.session?.user_id || 1, project_id, issue_id, channel, deliveryStatus, severity || 'info', title, body, resource_type, resource_id);
  // TODO: tạm thời, chờ sếp tổng xác nhận (mục 43.6) — chỉ xử lý kênh in_app
  if (channel === 'in_app') {
    db.prepare(`UPDATE notifications SET delivery_status = 'sent', sent_at = datetime('now') WHERE id = ?`).run(info.lastInsertRowid);
  }
  // Các kênh khác: giữ status='not_implemented', không build logic gửi
  res.json({ id: info.lastInsertRowid, channel, delivery_status: deliveryStatus });
});

// ============ Serve frontend (Vite build) ============
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const __dirname = dirname(fileURLToPath(import.meta.url));
const frontendDist = join(__dirname, '..', '..', 'frontend', 'dist');
if (existsSync(frontendDist)) {
  app.use(express.static(frontendDist));
  app.get('*', (req, res) => res.sendFile(join(frontendDist, 'index.html')));
}

const server = app.listen(PORT, () => {
  console.log(`🚀 PMO Backend running on http://localhost:${PORT}`);
  console.log(`   API: http://localhost:${PORT}/api/health`);
});

process.on('SIGINT', () => { closeDb(); server.close(); process.exit(0); });
process.on('SIGTERM', () => { closeDb(); server.close(); process.exit(0); });
