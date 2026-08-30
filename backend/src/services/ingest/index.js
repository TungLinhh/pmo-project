// Ingestion router - dispatches by doc_type
import { ingestDailyReport } from './daily_report.js';
import { ingestBusinessProcess } from './business_process.js';
import { ingestShopDrawing } from './shop_drawing.js';
import { ingestConstructionSchedule } from './construction_schedule.js';
import { ingestMaterialSupply } from './material_supply.js';
import { ingestSubcontractorDirectory } from './subcontractor_directory.js';
import { ingestResourceDirectory } from './resource_directory.js';
import { ingestRFALog } from './rfa_log.js';
import { ingestGenericTabular } from './generic_tabular.js';
import { ingestProjectLevel } from './project_level.js';
import { getDb } from '../../db/index.js';

const GENERIC_TYPES = new Set(['manpower_master_plan', 'shop_master', 'work_management', 'other_approved', 'file_index', 'zone_map']);
const PROJECT_LEVEL_TYPES = new Set(['construction_schedule', 'shop_drawing', 'material_supply']);

export async function ingest(filePath, docType, opts) {
  switch (docType) {
    case 'daily_report':
      return await ingestDailyReport(filePath, opts.projectId);
    case 'business_process':
      return await ingestBusinessProcess(filePath, opts.tenantId, opts.processCode || 'project_execution');
    case 'shop_drawing':
      return await ingestShopDrawing(filePath, opts.projectId, opts.zoneCode);
    case 'construction_schedule':
      return await ingestConstructionSchedule(filePath, opts.projectId, opts.zoneCode);
    case 'material_supply':
      return await ingestMaterialSupply(filePath, opts.projectId, opts.zoneCode);
    case 'subcontractor_directory':
      return await ingestSubcontractorDirectory(filePath, opts.projectId);
    case 'resource_directory':
      return await ingestResourceDirectory(filePath, opts.tenantId);
    case 'rfa_log':
      return await ingestRFALog(filePath, opts.projectId);
    case 'payment_progress':
      return await ingestGenericTabular(filePath, opts.projectId, { docType: 'payment_progress' });
    default:
      if (GENERIC_TYPES.has(docType)) {
        return await ingestGenericTabular(filePath, opts.projectId, { docType });
      }
      throw new Error(`Doc type '${docType}' not yet supported. Add an ingestor.`);
  }
}

// Special entrypoint for project-level (multi-zone summary) files
export async function ingestProjectLevelFile(filePath, projectId, docType) {
  if (!PROJECT_LEVEL_TYPES.has(docType)) {
    throw new Error(`Doc type '${docType}' not supported for project-level ingestion`);
  }
  return await ingestProjectLevel(filePath, projectId, { docType });
}

export function findOrCreateProject(tenantId, projectCode) {
  const db = getDb();
  let project = db.prepare('SELECT id FROM projects WHERE tenant_id = ? AND code = ?').get(tenantId, projectCode);
  if (!project) {
    const result = db.prepare('INSERT INTO projects (tenant_id, code, name_vi) VALUES (?, ?, ?)').run(tenantId, projectCode, projectCode);
    project = { id: Number(result.lastInsertRowid) };
  }
  return project;
}
