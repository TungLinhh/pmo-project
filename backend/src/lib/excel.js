// Excel helpers - normalize cells
import XLSX from 'xlsx';

export function isError(v) {
  if (v === null || v === undefined) return false;
  if (typeof v !== 'object') return false;
  return v.error === true || typeof v.w === 'string';
}

export function normalizeCell(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'object' && v.error) return null; // #N/A, #REF!
  if (typeof v === 'string' && v.trim() === '') return null;
  if (typeof v === 'string' && v === '0' || v === 0) {
    return typeof v === 'number' ? 0 : '0';
  }
  return v;
}

export function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) {
    return v.toISOString().slice(0, 10);
  }
  if (typeof v === 'string') {
    // Try dd/mm/yyyy
    const m = v.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
    if (m) {
      const [, d, mo, y] = m;
      return `${y}-${mo.padStart(2, '0')}-${d.padStart(2, '0')}`;
    }
  }
  return null;
}

export function toFloat(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return v;
  if (typeof v === 'string') {
    const cleaned = v.replace(',', '.').trim();
    const n = parseFloat(cleaned);
    return isNaN(n) ? null : n;
  }
  return null;
}

export function toInt(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return Math.round(v);
  if (typeof v === 'string') {
    const n = parseInt(v.replace(/[^\d\-]/g, ''), 10);
    return isNaN(n) ? null : n;
  }
  return null;
}

export function toText(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'object' && v.error) return null;
  if (typeof v === 'string') return v.trim() || null;
  return String(v).trim() || null;
}

// Parse bilingual "Foo | Bar" or "Foo / Bar"
export function splitBilingual(v) {
  if (!v) return { vi: null, en: null };
  const text = String(v);
  // Try "|", "/", " - "
  const parts = text.split(/\s*[\|\/\-]\s*/);
  if (parts.length >= 2) {
    return { vi: parts[0].trim() || null, en: parts[1].trim() || null };
  }
  // No separator - try to detect Vietnamese (has diacritics)
  const hasViet = /[ăâđêôơưĂÂĐÊÔƠƯàáảãạằắẳẵặầấẩẫậèéẻẽẹềếểễệìíỉĩịòóỏõọồốổỗộờớởỡợùúủũụừứửữựỳýỷỹỵÀÁẢÃẠẰẮẲẴẶẦẤẨẪẬÈÉẺẼẸỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌỒỐỔỖỘỜỚỞỠỢÙÚỦŨỤỪỨỬỮỰỲÝỶỸỴ]/.test(text);
  if (hasViet) return { vi: text, en: null };
  return { vi: null, en: text };
}

// Renumber ordinals (1, 2, 3, ...) - for STT gaps
export function renumber(items, key = 'ordinal') {
  return items.map((item, idx) => ({ ...item, [key]: idx + 1 }));
}

export function readSheet(filePath, sheetName) {
  const wb = XLSX.readFile(filePath, { cellDates: true, cellNF: false, cellText: false });
  if (!wb.Sheets[sheetName]) {
    throw new Error(`Sheet "${sheetName}" not found in ${filePath}. Available: ${wb.SheetNames.join(', ')}`);
  }
  const ws = wb.Sheets[sheetName];
  return XLSX.utils.sheet_to_json(ws, { header: 1, defval: null, blankrows: false });
}

export function listSheets(filePath) {
  const wb = XLSX.readFile(filePath, { cellDates: true });
  return wb.SheetNames;
}

// Try to detect doc_type from filename
// Order matters: more specific patterns first
// Normalize whitespace and remove double-spaces before matching
export function detectDocType(filename) {
  const f = filename.toLowerCase().replace(/\s+/g, ' ').trim();

  // Payment progress FIRST (before generic "tiến độ" match)
  if (f.includes('thanh toán') || f.includes('thanh toan') || f.includes('payment') || f.includes('hstt')) return 'payment_progress';

  // Business process / subcontractor
  if (f.includes('quy trình thực hiện') || f.includes('quy trinh thuc hien')) return 'business_process';
  if (f.includes('thầu phụ') || f.includes('thau phu') || f.includes('tổ đội') || f.includes('to doi')) return 'subcontractor_directory';

  // Shop / material / construction
  if (f.includes('shop ') || f.includes('shop_') || f.startsWith('shop')) return 'shop_drawing';
  if (f.includes('vật tư') || f.includes('vat tu')) return 'material_supply';
  if (f.includes('tđ ') || f.includes('td ') || f.includes('tiến độ') || f.includes('tiendo')) return 'construction_schedule';

  // Daily report
  if (f.includes('báo cáo công việc') || f.includes('bao cao cong viec') || f.includes('daily')) return 'daily_report';

  // RFA / Material master
  if (f.includes('mcr-mm') || f.includes('rfa') || f.includes('rfa-submission')) return 'rfa_log';
  if (f.includes('mcr-mpm') || f.includes('mpm')) return 'manpower_master_plan';

  // Shop master / work management
  if (f.includes('bte-mshop') || f.includes('mshop')) return 'shop_master';
  if (f.includes('bte-wm') || f.includes('wm-01')) return 'work_management';

  // Other
  if (f.includes('sơ đồ') && f.includes('khu vực')) return 'zone_map';
  if (f.includes('sơ đồ cây') || f.includes('cây')) return 'work_breakdown';
  if (f.includes('file start')) return 'file_index';
  if (f.includes('nguồn lực') || f.includes('nguon luc') || f.includes('tài nguyên')) return 'resource_directory';
  if (f.includes('duyệt khác') || f.includes('duyet khac')) return 'other_approved';
  return 'unknown';
}
