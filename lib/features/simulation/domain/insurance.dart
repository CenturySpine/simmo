/// Usual borrower insurance rate on the initial capital (non-smoker,
/// standard cover), by age and contract, 2026 market averages:
/// - delegation: Magnolia comparator, January 2026 (200 000 € over 20 years);
/// - bank group contract: 0.26% before 30 and 0.62% after 60 (Réassurez-moi,
///   2025-2026), 0.34% to 0.36% in the thirties (Magnolia, APRIL barometer
///   March 2026); 40s and 50s interpolated.
double usualInsuranceRate({required int age, required bool bankContract}) {
  final bracket = age < 30
      ? 0
      : age < 40
      ? 1
      : age < 50
      ? 2
      : age < 60
      ? 3
      : 4;
  return (bankContract ? _bank : _delegation)[bracket];
}

const _bank = [0.0026, 0.0034, 0.0044, 0.0053, 0.0062];
const _delegation = [0.0009, 0.0015, 0.0024, 0.0032, 0.0055];
