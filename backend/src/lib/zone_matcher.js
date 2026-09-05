// Match zone name from free text to known zone codes
// Zones: BOH, BPV, BSN, BUT, BZONE, CLU, GEN, HPV, INF, KID, LOB-SPA, RES, RES-3BR, RES-4BR, VNR
// Plus aliases: BPV-1BR, BPV-2BR, HPV-1BR, HPV-2BR

const ZONE_ALIASES = {
  'boh': 'BOH', 'back of house': 'BOH',
  'bpv': 'BPV', 'bpv-1br': 'BPV-1BR', 'bpv-2br': 'BPV-2BR', 'bpv 1br': 'BPV-1BR', 'bpv 2br': 'BPV-2BR', 'bpv 1 br': 'BPV-1BR', 'bpv 2 br': 'BPV-2BR',
  'bpv1br': 'BPV-1BR', 'bpv2br': 'BPV-2BR', 'beach pool villa': 'BPV',
  'bsn': 'BSN', 'bsc': 'BSN', 'business': 'BSN', 'business center': 'BSN',
  'but': 'BUT', 'bulter': 'BUT', 'butler': 'BUT',
  'bzone': 'BZONE', 'zone b': 'BZONE', 'beach zone': 'BZONE', 'beachzone': 'BZONE', 'beach': 'BZONE',
  'clu': 'CLU', 'cluster villa': 'CLU', 'clustervilla': 'CLU', 'cul': 'CLU',
  'gen': 'GEN', 'general': 'GEN', 'fitness': 'GEN', 'fitnes': 'GEN', 'gym': 'GEN', 'fitness club': 'GEN', 'fit': 'GEN',
  'hpv': 'HPV', 'hpv-2br': 'HPV-2BR', 'hpv 1br': 'HPV-1BR', 'hpv 2br': 'HPV-2BR', 'hpv 1 br': 'HPV-1BR', 'hpv 2 br': 'HPV-2BR',
  'hpv1br': 'HPV-1BR', 'hpv2br': 'HPV-2BR',
  'inf': 'INF', 'hạ tầng': 'INF', 'hạ-tầng': 'INF', 'hạtầng': 'INF', 'infrastructure': 'INF',
  'kid': 'KID', 'kid club': 'KID', 'kidclub': 'KID',
  'lob-spa': 'LOB-SPA', 'lob&spa': 'LOB-SPA', 'lob spa': 'LOB-SPA', 'lobby': 'LOB-SPA', 'spa': 'LOB-SPA', 'lob': 'LOB-SPA', 'loby': 'LOB-SPA', 'lobby spa': 'LOB-SPA', 'lobby-spa': 'LOB-SPA',
  'res': 'RES', 'res-3br': 'RES-3BR', 'res-4br': 'RES-4BR', 'res 3br': 'RES-3BR', 'res 4br': 'RES-4BR', 'res 3 br': 'RES-3BR', 'res 4 br': 'RES-4BR',
  'res3br': 'RES-3BR', 'res4br': 'RES-4BR', 'resort': 'RES', 'res villas': 'RES', 'resvillas': 'RES',
  'vnr': 'VNR', 'vn res': 'VNR', 'vnres': 'VNR', 'vietnam residences': 'VNR', 'vn residences': 'VNR',
};

export function findZoneByName(name, zones) {
  if (!name) return null;
  const rawLower = name.toLowerCase().trim();

  // 1. Try EXACT match (case-insensitive) first — preserves dashes like "TST-A", "BPV-1BR"
  const exact = zones.find(z => z.code.toLowerCase() === rawLower);
  if (exact) return exact.id;

  // 2. Normalize for alias matching
  const n = rawLower
    .replace(/\s*&\s*/g, '-')
    .replace(/\s+/g, ' ')
    .replace(/-/g, ' ');  // for alias lookup, spaces and dashes are equivalent

  // Try alias
  const alias = ZONE_ALIASES[n] || ZONE_ALIASES[n.replace(/\s+/g, '')];
  if (alias) {
    const z = zones.find(z => z.code === alias);
    if (z) return z.id;
  }

  // 3. Try direct match
  const direct = zones.find(z => z.code.toLowerCase() === name.toLowerCase().trim());
  if (direct) return direct.id;

  // 4. Try partial
  for (const z of zones) {
    const code = z.code.toLowerCase();
    if (n.includes(code) || code.includes(n)) return z.id;
  }

  return null;
}
