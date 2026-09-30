import 'dart:math';

import 'rules.dart';

/// Annual income tax estimate from the revenu fiscal de référence, with the
/// family quotient (capped) and the décote. Ignores tax credits.
double annualIncomeTax({
  required double taxableIncome,
  required bool couple,
  required int children,
}) {
  if (taxableIncome <= 0) return 0;
  final baseParts = couple ? 2.0 : 1.0;
  final singleParent = !couple && children > 0;
  final childParts = min(children, 2) * 0.5 + max(children - 2, 0) * 1.0;
  final parts = baseParts + childParts + (singleParent ? 0.5 : 0);

  final withoutChildren = _scale(taxableIncome / baseParts) * baseParts;
  final withChildren = _scale(taxableIncome / parts) * parts;
  final extraHalfParts = ((parts - baseParts) * 2).round();
  final cap = singleParent
      ? Rules.quotientCapSingleParentFirstChild +
            Rules.quotientCapPerHalfPart * (extraHalfParts - 2)
      : Rules.quotientCapPerHalfPart * extraHalfParts;
  var tax = max(withChildren, withoutChildren - cap);

  final decote = couple ? Rules.decoteCouple : Rules.decoteSingle;
  if (tax < decote / Rules.decoteRate) {
    tax -= decote - Rules.decoteRate * tax;
  }
  return max(0, tax);
}

double _scale(double incomePerPart) {
  var tax = 0.0;
  var lower = 0.0;
  for (final (upper, rate) in Rules.taxBrackets) {
    if (incomePerPart <= lower) break;
    tax += (min(incomePerPart, upper) - lower) * rate;
    lower = upper;
  }
  return tax;
}
