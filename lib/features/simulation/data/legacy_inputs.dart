import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/project.dart';
import '../domain/simulation_input.dart';
import 'communes.dart';
import 'saved_projects.dart';

/// Values kept by the single-simulation version of Simmo, one key each.
/// Stored as text: whole numbers lose their double type in JSON on the web.
final _values = <String, SimulationInput Function(SimulationInput, double)>{
  'price': (i, v) => i.copyWith(price: v),
  'netMonthlyIncome': (i, v) => i.copyWith(netMonthlyIncome: v),
  'referenceTaxIncome': (i, v) => i.copyWith(referenceTaxIncome: v),
  'rate': (i, v) => i.copyWith(rate: v),
  'borrowerAge': (i, v) => i.copyWith(borrowerAge: v.round()),
  'withholdingRate': (i, v) => i.copyWith(withholdingRate: () => v),
  'condoFees': (i, v) => i.copyWith(condoFees: v),
  'propertyTax': (i, v) => i.copyWith(propertyTax: v),
  'utilities': (i, v) => i.copyWith(utilities: v),
  'currentUtilities': (i, v) => i.copyWith(currentUtilities: v),
  'condoCalls': (i, v) => i.copyWith(condoCalls: v),
  'condoWorks': (i, v) => i.copyWith(condoWorks: v),
  'condoWorksYears': (i, v) => i.copyWith(condoWorksYears: v.round()),
  'askingPrice': (i, v) => i.copyWith(askingPrice: v),
  'offerPrice': (i, v) => i.copyWith(offerPrice: v),
  'maxPrice': (i, v) => i.copyWith(maxPrice: v),
  'surface': (i, v) => i.copyWith(surface: v),
};

const _address = 'address';

/// Moves the values kept by the single-simulation version into a first
/// project, so returning users find them, then forgets the old keys.
Future<void> migrateLegacyInputs(SharedPreferences prefs) async {
  final keys = [..._values.keys, _address].where(prefs.containsKey).toList();
  if (keys.isEmpty) return;
  var input = const SimulationInput();
  for (final MapEntry(:key, value: set) in _values.entries) {
    final value = double.tryParse(prefs.getString(key) ?? '');
    if (value != null) input = set(input, value);
  }
  final address = _readAddress(prefs.getString(_address));
  if (address != null) {
    // The zone was not kept: the address gives it back.
    final zone = communeByCode(await loadCommunes(), address.citycode)?.zone;
    input = input.copyWith(address: () => address, zone: zone);
  }
  // Only a typed price was kept: it stays an input.
  const typed = [MainField.price];
  final project = prefs.containsKey('price')
      ? Project(input.copyWith(computed: pickComputed(typed)), typed)
      : Project(input);
  final saved = SavedProjects(prefs);
  if (saved.projects.isEmpty) await saved.save([project], 0);
  for (final key in keys) {
    await prefs.remove(key);
  }
}

PropertyAddress? _readAddress(String? text) {
  if (text == null) return null;
  try {
    final json = jsonDecode(text) as Map<String, dynamic>;
    return PropertyAddress(
      label: json['label'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      citycode: json['citycode'] as String,
    );
  } on Object {
    return null;
  }
}
