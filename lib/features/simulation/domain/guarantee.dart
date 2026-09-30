import 'dart:math';

/// Crédit Logement "Classic" guarantee for one loan, as returned by its
/// official simulator (creditlogement.fr, September 2026): FMG participation
/// 230 € + 0.89%, plus a commission of 0.5% (150 € to 650 €) below 260 000 €,
/// 0.25% (up to 850 €) from 260 000 €. Homes rated A or B (DPE) get 25% off
/// the commission below 260 000 €, 10% above.
double creditLogementFee(double amount, {bool efficientHome = false}) {
  if (amount <= 0) return 0;
  final fmg = 230 + 0.0089 * amount;
  final lowTier = amount < 260000;
  var commission = lowTier
      ? (0.005 * amount).clamp(150.0, 650.0)
      : min(0.0025 * amount, 850.0);
  if (efficientHome) commission *= lowTier ? 0.75 : 0.90;
  return fmg + commission;
}
