// Storage helper - saves files to local filesystem (MinIO-compatible interface)
import { createHash } from 'node:crypto';
import { writeFileSync, statSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { mkdirSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const UPLOADS_DIR = join(__dirname, '..', '..', 'uploads');

mkdirSync(UPLOADS_DIR, { recursive: true });

export function saveFile(buffer, originalFilename) {
  const hash = createHash('sha256').update(buffer).digest('hex');
  const ext = originalFilename.split('.').pop();
  const key = `${hash.substring(0, 16)}_${Date.now()}.${ext}`;
  const fullPath = join(UPLOADS_DIR, key);
  writeFileSync(fullPath, buffer);
  const size = statSync(fullPath).size;
  return { key, fullPath, hash, size };
}

export function getFilePath(key) {
  return join(UPLOADS_DIR, key);
}

export function fileExists(key) {
  return existsSync(getFilePath(key));
}
