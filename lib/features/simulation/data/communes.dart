import 'package:flutter/services.dart';

import '../domain/simulation_input.dart';

/// A commune of the official ABC zoning list.
class Commune {
  Commune(this.code, this.name, this.department, this.zoneLabel);

  /// INSEE code.
  final String code;
  final String name;
  final String department;

  /// As published: `Abis`, `A`, `B1`, `B2` or `C`.
  final String zoneLabel;

  /// [name] as compared with the search text, computed once.
  late final String key = searchKey(name);

  /// A bis counts as A for the PTZ.
  PtzZone get zone => switch (zoneLabel) {
    'Abis' || 'A' => PtzZone.a,
    'B1' => PtzZone.b1,
    'B2' => PtzZone.b2,
    _ => PtzZone.c,
  };

  String get zoneName => zoneLabel == 'Abis' ? 'A bis' : zoneLabel;
  String get label => '$name ($department)';
}

const communesAsset = 'assets/data/zonage_abc.csv';

/// Parses the official CSV: `CODGEO;DEP;LIBGEO;zone`, one header line.
List<Commune> parseCommunes(String csv) => [
  for (final line in csv.split('\n').skip(1))
    if (line.trim().split(';') case [
      final code,
      final dep,
      final name,
      final zone,
    ])
      Commune(code, name, dep, zone),
];

Future<List<Commune>> loadCommunes([AssetBundle? bundle]) async =>
    parseCommunes(await (bundle ?? rootBundle).loadString(communesAsset));

/// The commune of INSEE [code]; an arrondissement of Paris, Lyon or
/// Marseille gives its city, the only one listed.
Commune? communeByCode(List<Commune> communes, String code) {
  final city = switch (code) {
    _ when code.startsWith('751') => '75056',
    _ when code.startsWith('6938') => '69123',
    _ when code.startsWith('132') => '13055',
    _ => code,
  };
  return communes.where((commune) => commune.code == city).firstOrNull;
}

/// Communes matching [query], ignoring case, accents and punctuation
/// ("st etienne" finds Saint-Étienne): exact names first, then names
/// starting with the query, then the others, shorter names first.
List<Commune> searchCommunes(
  List<Commune> communes,
  String query, {
  int limit = 8,
}) {
  final q = searchKey(query);
  if (q.isEmpty) return const [];
  final matches = <(int, Commune)>[];
  for (final commune in communes) {
    final key = commune.key;
    if (!key.contains(q)) continue;
    matches.add((key == q ? 0 : (key.startsWith(q) ? 1 : 2), commune));
  }
  matches.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.name.length - b.$2.name.length;
  });
  return [for (final (_, commune) in matches.take(limit)) commune];
}

/// Lower case, no accents, words separated by single spaces, "saint(e)"
/// shortened to "st(e)".
String searchKey(String text) {
  final words = <String>[];
  final word = StringBuffer();
  void endWord() {
    if (word.isEmpty) return;
    final w = word.toString();
    words.add(w == 'saint' ? 'st' : (w == 'sainte' ? 'ste' : w));
    word.clear();
  }

  for (final char in text.toLowerCase().split('')) {
    final folded = _folded[char] ?? char;
    final code = folded.codeUnitAt(0);
    final alphanumeric =
        (code >= 0x61 && code <= 0x7a) || (code >= 0x30 && code <= 0x39);
    alphanumeric ? word.write(folded) : endWord();
  }
  endWord();
  return words.join(' ');
}

const _folded = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'ô': 'o',
  'ö': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ÿ': 'y',
  'ç': 'c',
  'œ': 'oe',
  'æ': 'ae',
};
