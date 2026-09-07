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
  // Filenames from site reports can lack an extension — default to .bin.
  const parts = String(originalFilename || 'upload.bin').split('.');
  const ext = parts.length > 1 ? parts.pop() : 'bin';
  const key = `${hash.substring(0, 16)}_${Date.now()}.${ext}`;
  const fullPath = join(UPLOADS_DIR, key);
  writeFileSync(fullPath, buffer);
  const size = statSync(fullPath).size;
  // Canonical shape: { key, fullPath, hash, size }.
  // DB rows store `key` (portable); resolve disk path via getFilePath(key).
  return { key, fullPath, hash, size };
}

export function getFilePath(key) {
  return join(UPLOADS_DIR, key);
}

export function fileExists(key) {
  return existsSync(getFilePath(key));
}
