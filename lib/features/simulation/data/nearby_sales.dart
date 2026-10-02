import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/market.dart';
import '../domain/simulation_input.dart';

/// The sales function (`api/sales.mjs`), on the site itself unless the build
/// says otherwise (`--dart-define=SALES_API=...`, to test locally).
const _salesApi = String.fromEnvironment(
  'SALES_API',
  defaultValue: '/api/sales',
);

/// Recorded sales around [address], of the same kind as the project.
Future<NearbySales> fetchNearbySales(
  PropertyAddress address, {
  required DwellingType dwelling,
  required PropertyKind kind,
  http.Client? client,
}) async {
  final uri = Uri.base
      .resolve(_salesApi)
      .replace(
        queryParameters: {
          // About 1 m: the same property always gets the same cached answer.
          'lat': address.lat.toStringAsFixed(5),
          'lon': address.lon.toStringAsFixed(5),
          if (dwelling == DwellingType.house) 'type': 'Maison',
          if (kind == PropertyKind.newBuild) 'neuf': '1',
        },
      );
  final response = await (client?.get(uri) ?? http.get(uri));
  if (response.statusCode != 200) {
    throw http.ClientException('${response.statusCode}', uri);
  }
  return parseNearbySales(utf8.decode(response.bodyBytes));
}

NearbySales parseNearbySales(String json) {
  final body = jsonDecode(json) as Map<String, dynamic>;
  final until = body['until'] as String?;
  return NearbySales(
    years: [for (final year in body['years'] as List) year as int],
    until: until == null ? null : DateTime.parse(until),
    sales: [
      for (final sale in body['sales'] as List)
        Sale(
          date: DateTime.parse(sale['date'] as String),
          address: sale['address'] as String,
          commune: sale['commune'] as String,
          surface: (sale['surface'] as num).toDouble(),
          rooms: sale['rooms'] as int,
          price: (sale['price'] as num).toDouble(),
          outbuildings: sale['outbuildings'] as int,
          distance: sale['distance'] as int,
          parcel: sale['parcel'] as String,
          lat: (sale['lat'] as num).toDouble(),
          lon: (sale['lon'] as num).toDouble(),
        ),
    ],
  );
}

/// The sale on the official DVF explorer (data.gouv.fr), on its parcel.
Uri saleSourceUrl(Sale sale) =>
    Uri.https('explore.data.gouv.fr', '/fr/immobilier', {
      'onglet': 'carte',
      'filtre': 'tous',
      'lat': '${sale.lat}',
      'lng': '${sale.lon}',
      'zoom': '18',
      'level': 'parcelle',
      'code': sale.parcel,
    });

/// The sale's building on Google Maps.
Uri saleMapUrl(Sale sale) => Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': '${sale.lat},${sale.lon}',
});
