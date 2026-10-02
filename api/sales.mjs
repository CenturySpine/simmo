// Recent sales around a point, from the geolocated DVF files (DGFiP, published
// by Etalab on data.gouv.fr, Licence Ouverte). Those files refuse cross-origin
// reads, hence this function: GET /api/sales?lat=..&lon=..[&type=Maison][&neuf=1]

const filesUrl = 'https://files.data.gouv.fr/geo-dvf/latest/csv';
const communesUrl = 'https://geo.api.gouv.fr/communes';

/** Search radius, in metres. */
export const radius = 500;

/** Number of most recent published years searched. */
const yearCount = 2;

/** Paris, Lyon and Marseille: DVF files are per arrondissement. */
const cities = new Set(['75056', '69123', '13055']);

export async function GET(request) {
  const params = new URL(request.url).searchParams;
  const lat = Number(params.get('lat'));
  const lon = Number(params.get('lon'));
  if (!params.get('lat') || !params.get('lon') || !Number.isFinite(lat + lon)) {
    return reply({ error: 'lat and lon required' }, 400);
  }
  const type = params.get('type') === 'Maison' ? 'Maison' : 'Appartement';
  const nature =
    params.get('neuf') === '1' ? "Vente en l'état futur d'achèvement" : 'Vente';
  try {
    const codes = await communesAround(lat, lon);
    if (codes.length === 0) return reply({ years: [], until: null, sales: [] });
    const years = await publishedYears(codes[0]);
    const tables = await Promise.all(
      codes.flatMap((code) => years.map((year) => readFile(code, year))),
    );
    const rows = tables.flat();
    const until = rows.reduce(
      (latest, row) => (row.date_mutation > latest ? row.date_mutation : latest),
      '',
    );
    return reply({
      years,
      until: until || null,
      sales: nearbySales(rows, { lat, lon, type, nature }),
    });
  } catch (error) {
    console.error(error);
    return reply({ error: 'DVF unavailable' }, 502);
  }
}

function reply(body, status = 200) {
  return Response.json(body, {
    status,
    headers: {
      'Access-Control-Allow-Origin': '*',
      // DVF terms of use: no indexing by search engines.
      'X-Robots-Tag': 'noindex',
      // New sales are published twice a year.
      ...(status === 200 && { 'Cache-Control': 'public, s-maxage=86400' }),
    },
  });
}

/** Communes (arrondissements in Paris, Lyon, Marseille) within [radius]. */
async function communesAround(lat, lon) {
  const dLat = radius / 111320;
  const dLon = radius / (111320 * Math.cos((lat * Math.PI) / 180));
  const points = [
    [lat, lon],
    [lat + dLat, lon],
    [lat - dLat, lon],
    [lat, lon + dLon],
    [lat, lon - dLon],
  ];
  const codes = await Promise.all(points.map(([la, lo]) => communeAt(la, lo)));
  return [...new Set(codes.filter(Boolean))];
}

async function communeAt(lat, lon) {
  const query = (type) =>
    fetchJson(`${communesUrl}?lat=${lat}&lon=${lon}&type=${type}&fields=code`);
  const [commune] = await query('commune-actuelle');
  if (!commune || !cities.has(commune.code)) return commune?.code;
  const [district] = await query('arrondissement-municipal');
  return district?.code;
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status} ${url}`);
  return response.json();
}

function fileUrl(code, year) {
  const department = code.startsWith('97') ? code.slice(0, 3) : code.slice(0, 2);
  return `${filesUrl}/${year}/communes/${department}/${code}.csv`;
}

/** The [yearCount] most recent years published for the commune [code]. */
async function publishedYears(code) {
  for (let year = new Date().getFullYear(); year > 2018; year--) {
    const response = await fetch(fileUrl(code, year), { method: 'HEAD' });
    if (response.ok) {
      return Array.from({ length: yearCount }, (_, i) => year - i);
    }
  }
  return [];
}

/** Parsed files, kept while the function instance stays warm. */
const cache = new Map();

function readFile(code, year) {
  const url = fileUrl(code, year);
  if (!cache.has(url)) {
    if (cache.size > 40) cache.clear();
    const rows = fetch(url).then(async (response) => {
      // No file: no sale in that commune that year.
      if (response.status === 404) return [];
      if (!response.ok) throw new Error(`${response.status} ${url}`);
      return parseCsv(await response.text());
    });
    rows.catch(() => cache.delete(url));
    cache.set(url, rows);
  }
  return cache.get(url);
}

/** Rows of a DVF CSV file as objects keyed by the header. */
export function parseCsv(text) {
  const [header, ...lines] = text.trim().split('\n').map(splitLine);
  return lines.map((cells) =>
    Object.fromEntries(header.map((key, i) => [key, cells[i] ?? ''])),
  );
}

function splitLine(line) {
  const cells = [];
  let cell = '';
  let quoted = false;
  for (const char of line.replace(/\r$/, '')) {
    if (char === '"') quoted = !quoted;
    else if (char === ',' && !quoted) {
      cells.push(cell);
      cell = '';
    } else cell += char;
  }
  cells.push(cell);
  return cells;
}

/**
 * Sales of exactly one dwelling of [type] (with or without outbuildings) by
 * [nature], within [radius] of the point, closest first (the most recent
 * first at the same distance).
 */
export function nearbySales(rows, { lat, lon, type, nature }) {
  const mutations = new Map();
  for (const row of rows) {
    if (row.nature_mutation !== nature) continue;
    const list = mutations.get(row.id_mutation) ?? [];
    list.push(row);
    mutations.set(row.id_mutation, list);
  }
  const sales = [];
  for (const list of mutations.values()) {
    const dwellings = list.filter((row) => row.type_local === type);
    const others = list.filter(
      (row) => row.type_local && !['Dépendance', type].includes(row.type_local),
    );
    const distinct = new Set(
      dwellings.map((row) =>
        [row.id_parcelle, row.lot1_numero, row.surface_reelle_bati].join('|'),
      ),
    );
    if (distinct.size !== 1 || others.length > 0) continue;
    const dwelling = dwellings[0];
    const price = Number(dwelling.valeur_fonciere);
    const surface = Number(dwelling.surface_reelle_bati);
    const at = [Number(dwelling.latitude), Number(dwelling.longitude)];
    if (!(price > 0 && surface > 0 && dwelling.latitude && dwelling.longitude)) {
      continue;
    }
    const distance = metres(lat, lon, ...at);
    if (distance > radius) continue;
    // DVF only says "Dépendance" (cellar, garage, parking...): count the lots.
    const outbuildings = new Set(
      list
        .filter((row) => row.type_local === 'Dépendance')
        .map((row, i) => (row.lot1_numero ? `${row.id_parcelle}|${row.lot1_numero}` : i)),
    ).size;
    sales.push({
      date: dwelling.date_mutation,
      address: streetAddress(dwelling),
      commune: dwelling.nom_commune,
      surface,
      rooms: Number(dwelling.nombre_pieces_principales) || 0,
      price,
      outbuildings,
      distance: Math.round(distance),
      parcel: dwelling.id_parcelle,
      lat: at[0],
      lon: at[1],
    });
  }
  return sales.sort((a, b) => a.distance - b.distance || b.date.localeCompare(a.date));
}

/** Great-circle distance, in metres. */
export function metres(lat1, lon1, lat2, lon2) {
  const rad = (degrees) => (degrees * Math.PI) / 180;
  const a =
    Math.sin(rad(lat2 - lat1) / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(rad(lon2 - lon1) / 2) ** 2;
  return 6371000 * 2 * Math.asin(Math.sqrt(a));
}

const smallWords = new Set(['de', 'du', 'des', 'la', 'le', 'les', 'et', 'aux', 'en', 'sur']);

/** "69 RUE LOUIS BECKER" as "69 rue Louis Becker", "ST-ANTOINE" as "St-Antoine". */
export function streetAddress(row) {
  const words = row.adresse_nom_voie.toLowerCase().split(' ');
  const street = words
    .map((word, i) =>
      i === 0 || smallWords.has(word)
        ? word
        : word.replace(/(^|-)(\p{L})/gu, (_, dash, letter) => dash + letter.toUpperCase()),
    )
    .join(' ');
  const number = [row.adresse_numero, row.adresse_suffixe].join('').toLowerCase();
  return [number, street].filter(Boolean).join(' ');
}
