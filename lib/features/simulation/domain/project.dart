import 'package:flutter/foundation.dart';

import 'simulation_input.dart';

/// One property studied: its simulation and the main parameters the user
/// typed, oldest first, which decide the next ones to compute.
@immutable
class Project {
  const Project(this.input, [this.typed = const []]);

  /// A simulation received as a whole (shared link): every parameter not
  /// computed counts as typed.
  Project.received(this.input)
    : typed = [
        for (final f in MainField.values)
          if (!input.computed.contains(f)) f,
      ];

  final SimulationInput input;
  final List<MainField> typed;

  /// Tab label: the address without its postcode, or `Projet <number>`.
  String name(int number) =>
      input.address?.label.replaceFirst(RegExp(r' \d{5} '), ', ') ??
      'Projet $number';
}
