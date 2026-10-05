import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/project.dart';
import '../domain/simulation_input.dart';
import 'share_link.dart';

/// The projects kept on the device (browser local storage) and the one shown
/// last, restored at the next visit. Each simulation is kept as its share
/// code (share_link.dart): every value, in a format that stays readable
/// across versions.
class SavedProjects {
  SavedProjects(this._prefs);

  final SharedPreferences _prefs;

  static const _projects = 'projects';
  static const _active = 'activeProject';

  /// The kept projects; none on a first visit.
  List<Project> get projects {
    final text = _prefs.getString(_projects);
    if (text == null) return const [];
    try {
      return [
        for (final entry in jsonDecode(text) as List)
          if (entry case {
            'code': final String code,
            'typed': final List<dynamic> typed,
          })
            if (decodeInput(code) case final input?)
              Project(input, [
                for (final i in typed) MainField.values[i as int],
              ]),
      ];
    } on Object {
      return const [];
    }
  }

  /// Index of the project shown last.
  int get active => _prefs.getInt(_active) ?? 0;

  Future<void> save(List<Project> projects, int active) => Future.wait([
    _prefs.setString(
      _projects,
      jsonEncode([
        for (final p in projects)
          {
            'code': encodeInput(p.input),
            'typed': [for (final f in p.typed) f.index],
          },
      ]),
    ),
    _prefs.setInt(_active, active),
  ]);

  /// Forgets every project.
  Future<void> clear() =>
      Future.wait([_prefs.remove(_projects), _prefs.remove(_active)]);
}
