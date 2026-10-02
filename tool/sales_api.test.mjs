// Tests of api/sales.mjs (Vercel function): node --test tool/sales_api.test.mjs
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { metres, nearbySales, parseCsv, streetAddress } from '../api/sales.mjs';

const header =
  'id_mutation,date_mutation,nature_mutation,valeur_fonciere,adresse_numero,' +
  'adresse_suffixe,adresse_nom_voie,nom_commune,id_parcelle,lot1_numero,' +
  'type_local,surface_reelle_bati,nombre_pieces_principales,longitude,latitude';
const here = { lat: 45.765293, lon: 4.871044 };
const csv = [
  header,
  // A flat with a cellar and a garage: kept.
  'm1,2025-11-14,Vente,272790,69,,RUE LOUIS BECKER,Villeurbanne,P1,24,Appartement,71,3,4.871,45.7653',
  'm1,2025-11-14,Vente,272790,69,,RUE LOUIS BECKER,Villeurbanne,P1,48,Dépendance,,,4.871,45.7653',
  'm1,2025-11-14,Vente,272790,69,,RUE LOUIS BECKER,Villeurbanne,P1,61,Dépendance,,,4.871,45.7653',
  // Two flats sold together: one price for both, dropped.
  'm2,2025-06-01,Vente,400000,1,,RUE A,Villeurbanne,P2,1,Appartement,50,2,4.871,45.7653',
  'm2,2025-06-01,Vente,400000,1,,RUE A,Villeurbanne,P2,2,Appartement,40,2,4.871,45.7653',
  // New build, a different market: dropped from "Vente".
  "m3,2025-05-01,Vente en l'état futur d'achèvement,300000,2,,RUE B,Villeurbanne,P3,1,Appartement,60,3,4.871,45.7653",
  // Too far (about 1.1 km north).
  'm4,2025-04-01,Vente,250000,3,B,RUE DU 8 MAI,Villeurbanne,P4,1,Appartement,65,3,4.871,45.775',
  // Flat with a shop in the same sale: dropped.
  'm5,2025-03-01,Vente,500000,4,,RUE C,Villeurbanne,P5,1,Appartement,70,3,4.871,45.7653',
  'm5,2025-03-01,Vente,500000,4,,RUE C,Villeurbanne,P5,2,Local industriel. commercial ou assimilé,30,,4.871,45.7653',
  // Older sale, without outbuilding, about 110 m away.
  'm6,2024-02-01,Vente,200000,5,,RUE DE LA PAIX,Villeurbanne,P6,1,Appartement,50,2,4.872,45.766',
  // Same building as m1, older: after it.
  'm7,2023-05-02,Vente,180000,69,,RUE LOUIS BECKER,Villeurbanne,P1,30,Appartement,48,2,4.871,45.7653',
].join('\n');

test('only single-dwelling sales nearby are kept, closest first', () => {
  const sales = nearbySales(parseCsv(csv), {
    ...here,
    type: 'Appartement',
    nature: 'Vente',
  });
  assert.deepEqual(
    sales.map((s) => s.date),
    ['2025-11-14', '2023-05-02', '2024-02-01'],
  );
  assert.deepEqual(sales[0], {
    date: '2025-11-14',
    address: '69 rue Louis Becker',
    commune: 'Villeurbanne',
    surface: 71,
    rooms: 3,
    price: 272790,
    outbuildings: 2,
    distance: 4,
    parcel: 'P1',
    lat: 45.7653,
    lon: 4.871,
  });
  assert.equal(sales[2].outbuildings, 0);
});

test('new builds are searched separately', () => {
  const sales = nearbySales(parseCsv(csv), {
    ...here,
    type: 'Appartement',
    nature: "Vente en l'état futur d'achèvement",
  });
  assert.deepEqual(
    sales.map((s) => s.price),
    [300000],
  );
});

test('quoted cells may hold commas', () => {
  const [row] = parseCsv('a,b,c\n1,"x, y",3');
  assert.deepEqual(row, { a: '1', b: 'x, y', c: '3' });
});

test('street names read naturally', () => {
  assert.equal(
    streetAddress({ adresse_numero: '3', adresse_suffixe: 'B', adresse_nom_voie: 'RUE DE LA PAIX' }),
    '3b rue de la Paix',
  );
  assert.equal(
    streetAddress({ adresse_numero: '35', adresse_suffixe: '', adresse_nom_voie: 'RUE ST-ANTOINE' }),
    '35 rue St-Antoine',
  );
});

test('distances in metres', () => {
  // 0.001° of latitude is about 111 m.
  assert.equal(Math.round(metres(45, 4, 45.001, 4)), 111);
});
