// Upload + upload list (inherited from old wizard)

import { Router } from 'express';
import multer from 'multer';
import { requireAuth } from '../lib/auth.js';
import { getDb } from '../db/index.js';
import { saveFile } from '../lib/storage.js';
import { detectDocType } from '../lib/excel.js';
import { findOrCreateProject, findOrCreateZone, ingestProjectLevelFile } from '../services/ingest/index.js';

const router = Router({ mergeParams: true });
router.use(requireAuth);

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

router.post('/', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file' });
  const { project_code, zone_code } = req.body || {};
  if (!project_code) return res.status(400).json({ error: 'project_code required' });
  const db = getDb();
  try {
    const project = await findOrCreateProject(req.body);
    const zone = zone_code ? await findOrCreateZone(project.id, zone_code) : null;
    const saved = saveFile(req.file.buffer, req.file.originalname, req.file.mimetype);
    const docType = detectDocType(req.file.originalname, req.file.mimetype);
    const result = await ingestProjectLevelFile({
      project_id: project.id,
      zone_id: zone?.id,
      file_path: saved.path,
      file_name: saved.filename,
      doc_type: docType,
      user_id: req.user.id,
    });
    res.json({ ok: true, project: { id: project.id, code: project.code }, zone, file: saved, result });
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
