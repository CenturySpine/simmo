import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/simulation_input.dart';

/// IGN geocoding (Géoplateforme, formerly API Adresse): free, no key, open
/// to browsers.
const _search = 'https://data.geopf.fr/geocodage/search';

/// Addresses matching [query], best first; none when the service fails.
Future<List<PropertyAddress>> searchAddresses(
  String query, {
  http.Client? client,
}) async {
  final uri = Uri.parse(
    _search,
  ).replace(queryParameters: {'q': query, 'limit': '5', 'autocomplete': '1'});
  try {
    final response = await (client?.get(uri) ?? http.get(uri));
    if (response.statusCode != 200) return const [];
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    return [
      for (final feature in body['features'] as List)
        if (feature case {
          'geometry': {'coordinates': [final num lon, final num lat]},
          'properties': {
            'label': final String label,
            'citycode': final String citycode,
          },
        })
          PropertyAddress(
            label: label,
            lat: lat.toDouble(),
            lon: lon.toDouble(),
            citycode: citycode,
          ),
    ];
  } on Exception {
    return const [];
  }
}
