import 'dart:math';

import 'simulation_input.dart';

/// Why a PTZ is granted or not.
enum PtzReason {
  eligible,
  disabled,
  notFirstTimeBuyer,

  /// Existing homes qualify only in zones B2 and C.
  existingZone,

  /// Existing homes need works worth 25% of the operation cost.
  existingWorks,
  income,
}

/// PTZ rights for a household (offers issued from April 2025 to end 2027,
/// unchanged by the 2026 finance law; décret 2025-299, CCH D.31-10).
class PtzOutcome {
  const PtzOutcome(
    this.reason, {
    this.tranche = 0,
    this.maxAmount = 0,
    this.deferralMonths = 0,
    this.repaymentMonths = 0,
    this.otherLoansRatio = 1,
  });

  final PtzReason reason;
  final int tranche;

  /// Quotité × capped operation cost, before the "other loans" limit.
  final double maxAmount;
  final int deferralMonths;
  final int repaymentMonths;

  /// The PTZ may not exceed this multiple of the other loans (1.25 when the
  /// quotité is 50%).
  final double otherLoansRatio;

  bool get eligible => reason == PtzReason.eligible;
}

/// [operationCost]: price + works + agency fees (notary fees excluded).
PtzOutcome ptzOutcome(SimulationInput input, double operationCost) {
  if (!input.ptzEnabled) return const PtzOutcome(PtzReason.disabled);
  if (!input.firstTimeBuyer) {
    return const PtzOutcome(PtzReason.notFirstTimeBuyer);
  }
  final newBuild = input.propertyKind == PropertyKind.newBuild;
  if (!newBuild) {
    if (input.zone != PtzZone.b2 && input.zone != PtzZone.c) {
      return const PtzOutcome(PtzReason.existingZone);
    }
    if (input.works < 0.25 * operationCost) {
      return const PtzOutcome(PtzReason.existingWorks);
    }
  }

  final persons = input.persons.clamp(1, 8);
  final zone = input.zone.index;
  final income = max(input.referenceTaxIncome, operationCost / 9);
  if (income > _incomeCeilings[persons - 1][zone]) {
    return const PtzOutcome(PtzReason.income);
  }
  final perUnit = income / _familyCoefficients[min(persons, 5) - 1];
  var tranche = 4;
  for (var t = 0; t < 3; t++) {
    if (perUnit <= _trancheLimits[t][zone]) {
      tranche = t + 1;
      break;
    }
  }
  final quotas = newBuild && input.dwellingType == DwellingType.house
      ? _houseQuotas
      : _collectiveQuotas;
  final quota = quotas[tranche - 1];
  final cost = min(operationCost, _costCeilings[min(persons, 5) - 1][zone]);
  final (deferral, repayment) = _repayment[tranche - 1];
  return PtzOutcome(
    PtzReason.eligible,
    tranche: tranche,
    maxAmount: quota * cost,
    deferralMonths: deferral,
    repaymentMonths: repayment,
    otherLoansRatio: quota == 0.5 ? 1.25 : 1,
  );
}

// Tables indexed [persons - 1][zone A, B1, B2, C].
const _incomeCeilings = [
  [49000.0, 34500.0, 31500.0, 28500.0],
  [73500.0, 51750.0, 47250.0, 42750.0],
  [88200.0, 62100.0, 56700.0, 51300.0],
  [102900.0, 72450.0, 66150.0, 59850.0],
  [117600.0, 82800.0, 75600.0, 68400.0],
  [132300.0, 93150.0, 85050.0, 76950.0],
  [147000.0, 103500.0, 94500.0, 85500.0],
  [161700.0, 113850.0, 103950.0, 94050.0],
];

/// 1 to 5+ persons.
const _costCeilings = [
  [150000.0, 135000.0, 110000.0, 100000.0],
  [225000.0, 202500.0, 165000.0, 150000.0],
  [270000.0, 243000.0, 198000.0, 180000.0],
  [315000.0, 283500.0, 231000.0, 210000.0],
  [360000.0, 324000.0, 264000.0, 240000.0],
];

/// 1 to 5+ persons.
const _familyCoefficients = [1.0, 1.5, 1.8, 2.1, 2.4];

/// Upper bounds of tranches 1 to 3 (tranche 4 up to the income ceiling).
const _trancheLimits = [
  [25000.0, 21500.0, 18000.0, 15000.0],
  [31000.0, 26000.0, 22500.0, 19500.0],
  [37000.0, 30000.0, 27000.0, 24000.0],
];

const _collectiveQuotas = [0.5, 0.4, 0.4, 0.2];
const _houseQuotas = [0.3, 0.2, 0.2, 0.1];

/// (deferral months, repayment months) per tranche.
const _repayment = [(120, 180), (96, 144), (24, 156), (0, 120)];
