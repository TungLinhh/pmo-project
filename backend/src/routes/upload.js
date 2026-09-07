// Upload + upload list (inherited from old wizard)

import { Router } from 'express';
import multer from 'multer';
import { requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { saveFile } from '../lib/storage.js';
import { detectDocType } from '../lib/excel.js';
import { findOrCreateProject, findOrCreateZone } from '../services/ingest/index.js';
import { ingestProjectLevel } from '../services/ingest/project_level.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

router.post('/', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file' });
  const { project_code, zone_code } = req.body || {};
  if (!project_code) return res.status(400).json({ error: 'project_code required' });
  const db = getDb();
  try {
    const project = await findOrCreateProject(1, project_code, req.body || {});
    const zone = zone_code ? await findOrCreateZone(project.id, zone_code) : null;
    const saved = saveFile(req.file.buffer, req.file.originalname);
    const docType = detectDocType(req.file.originalname);
    // Staged record: lets the wizard configure/preview/commit flow work on the
    // same upload, and gives re-uploads (same sha256) a stable identity.
    const staged = await db.prepare(`
      INSERT INTO file_uploads (tenant_id, project_id, zone_id, original_filename, storage_key, file_size, file_hash, mime_type, expected_doc_type, status)
      VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, 'PROCESSING')
      ON CONFLICT (tenant_id, file_hash) DO UPDATE SET
        project_id = EXCLUDED.project_id, zone_id = EXCLUDED.zone_id,
        original_filename = EXCLUDED.original_filename, storage_key = EXCLUDED.storage_key,
        file_size = EXCLUDED.file_size, mime_type = EXCLUDED.mime_type,
        expected_doc_type = EXCLUDED.expected_doc_type, status = 'PROCESSING'
      RETURNING id
    `).getAsync(project.id, zone?.id || null, req.file.originalname, saved.key, saved.size, saved.hash, req.file.mimetype, docType);
    const result = await ingestProjectLevel(saved.fullPath, project.id, { docType });
    const totalRows = (result.ok || 0) + (result.errors || 0);
    const status = result.errors === 0 ? 'SUCCESS' : (result.ok > 0 ? 'PARTIAL' : 'FAILED');
    await db.prepare(
      `UPDATE file_uploads SET status = ?, total_rows = ?, ok_rows = ?, error_rows = ?, report_json = ? WHERE id = ?`
    ).runAsync(status, totalRows, result.ok || 0, result.errors || 0, JSON.stringify(result), staged.id);
    res.json({
      ok: true, upload_id: staged.id,
      project: { id: project.id, code: project.code }, zone,
      file: { key: saved.key, file_name: req.file.originalname, size: saved.size, hash: saved.hash },
      result, total_rows: totalRows, ok_rows: result.ok || 0, error_rows: result.errors || 0,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.get('/', async (req, res) => {
  const db = getDb();
  const rows = await db.prepare('SELECT * FROM file_uploads ORDER BY created_at DESC LIMIT 100').allAsync();
  res.json(rows);
});

export default router;
