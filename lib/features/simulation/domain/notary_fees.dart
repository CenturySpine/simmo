import 'dart:math';

import 'rules.dart';

/// Notary fees estimate ("frais de notaire"): transfer taxes, emoluments
/// with VAT, contribution de sécurité immobilière and [miscFees]
/// (formalities, disbursements). Not rounded (brokers round to the hundred),
/// so the price solved from a loan amount matches it exactly.
double notaryFees({
  required double price,
  required bool newBuild,
  required double departmentRate,
  double furniture = 0,
  double miscFees = 0,
}) {
  final base = max(0.0, price - furniture);
  if (base == 0) return 0;
  final transferTaxes = newBuild
      ? base / (1 + Rules.vat) * Rules.newBuildTransferRate
      : base *
            (departmentRate +
                Rules.municipalRate +
                departmentRate * Rules.collectionFeeRate);
  final emoluments = _emoluments(base) * (1 + Rules.vat);
  final csi = max(Rules.csiMin, base * Rules.csiRate);
  return transferTaxes + emoluments + csi + miscFees;
}

double _emoluments(double base) {
  var total = 0.0;
  var lower = 0.0;
  for (final (upper, rate) in Rules.notaryBrackets) {
    if (base <= lower) break;
    total += (min(base, upper) - lower) * rate;
    lower = upper;
  }
  return total;
}
