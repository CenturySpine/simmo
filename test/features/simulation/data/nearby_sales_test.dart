import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simmo/features/simulation/data/geocoding.dart';
import 'package:simmo/features/simulation/data/nearby_sales.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

const _address = PropertyAddress(
  label: '69 Rue Louis Becker 69100 Villeurbanne',
  lat: 45.765293,
  lon: 4.871044,
  citycode: '69266',
);

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('addresses come from the IGN geocoding', () async {
    Uri? asked;
    final client = MockClient((request) async {
      asked = request.url;
      return _json({
        'features': [
          {
            'geometry': {
              'coordinates': [4.871044, 45.765293],
            },
            'properties': {
              'label': '69 Rue Louis Becker 69100 Villeurbanne',
              'citycode': '69266',
            },
          },
        ],
      });
    });

    final found = await searchAddresses('69 rue louis becker', client: client);
    expect(asked!.host, 'data.geopf.fr');
    expect(asked!.queryParameters['q'], '69 rue louis becker');
    expect(found, [_address]);
  });

  test('a failing geocoding gives no address', () async {
    final client = MockClient((_) async => http.Response('', 503));
    expect(await searchAddresses('rue', client: client), isEmpty);
  });

  test('nearby sales of the same kind as the project', () async {
    Uri? asked;
    final client = MockClient((request) async {
      asked = request.url;
      return _json({
        'years': [2025, 2024],
        'until': '2025-12-31',
        'sales': [
          {
            'date': '2025-11-14',
            'address': '69 rue Louis Becker',
            'commune': 'Villeurbanne',
            'surface': 71,
            'rooms': 3,
            'price': 272790,
            'outbuildings': 2,
            'distance': 23,
            'parcel': '69266000BN0052',
            'lat': 45.765465,
            'lon': 4.871204,
          },
        ],
      });
    });

    final nearby = await fetchNearbySales(
      _address,
      dwelling: DwellingType.house,
      kind: PropertyKind.newBuild,
      client: client,
    );
    expect(asked!.path, '/api/sales');
    expect(asked!.queryParameters, {
      'lat': '45.76529',
      'lon': '4.87104',
      'type': 'Maison',
      'neuf': '1',
    });
    expect(nearby.years, [2025, 2024]);
    expect(nearby.until, DateTime(2025, 12, 31));
    final sale = nearby.sales.single;
    expect(sale.pricePerSqm, closeTo(3842, 1));
    expect(sale.outbuildings, 2);

    // Where to check it: the official record, the building on a map.
    expect(
      saleSourceUrl(sale).toString(),
      'https://explore.data.gouv.fr/fr/immobilier?onglet=carte&filtre=tous'
      '&lat=45.765465&lng=4.871204&zoom=18&level=parcelle'
      '&code=69266000BN0052',
    );
    expect(
      saleMapUrl(sale).toString(),
      'https://www.google.com/maps/search/?api=1&query=45.765465%2C4.871204',
    );
  });

  test('a failing sales function is reported', () async {
    final client = MockClient((_) async => http.Response('', 502));
    expect(
      fetchNearbySales(
        _address,
        dwelling: DwellingType.apartment,
        kind: PropertyKind.existing,
        client: client,
      ),
      throwsA(isA<http.ClientException>()),
    );
  });
}
