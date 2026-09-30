/// Regulatory and market figures used by the simulator, as of September 2026.
/// Each block names its source; update it when the rule changes.
abstract final class Rules {
  // --- Debt ratio highlight, the only guard-rail (PO) ------------------------
  /// Strictly above: red (HCSF limit, unchanged in 2026).
  static const debtRatioLimit = 0.35;

  /// Strictly above: orange. Otherwise green.
  static const debtRatioWarning = 0.33;

  /// Banks count 70% of rental income.
  static const rentalIncomeWeight = 0.70;

  // --- Action Logement home-ownership loan (2026) -------------------------
  static const actionLogementMax = 30000.0;
  static const actionLogementRate = 0.01;
  static const actionLogementMaxMonths = 300;

  // --- Notary fees (tarif des notaires, unchanged since 2020) --------------
  /// Proportional emoluments on a sale: (bracket upper bound, rate).
  static const notaryBrackets = [
    (6500.0, 0.03870),
    (17000.0, 0.01596),
    (60000.0, 0.01064),
    (double.infinity, 0.00799),
  ];
  static const vat = 0.20;

  /// Contribution de sécurité immobilière: 0.10%, 15 € minimum.
  static const csiRate = 0.001;
  static const csiMin = 15.0;

  /// Transfer taxes on existing homes: departmental rate + 1.20% municipal
  /// tax + 2.37% collection fee on the departmental part. Departments may
  /// charge 5.00% since April 2025 (88 do); first-time buyers of a main
  /// residence stay at 4.50%.
  static const departmentRateStandard = 0.045;
  static const departmentRateRaised = 0.05;
  static const municipalRate = 0.012;
  static const collectionFeeRate = 0.0237;

  /// New homes (VEFA): taxe de publicité foncière 0.715% on the price
  /// excluding VAT.
  static const newBuildTransferRate = 0.0071498;

  // --- Income tax, barème 2026 on 2025 income -----------------------------
  /// (bracket upper bound per part, rate).
  static const taxBrackets = [
    (11600.0, 0.0),
    (29579.0, 0.11),
    (84577.0, 0.30),
    (181917.0, 0.41),
    (double.infinity, 0.45),
  ];
  static const quotientCapPerHalfPart = 1807.0;
  static const quotientCapSingleParentFirstChild = 4262.0;
  static const decoteSingle = 897.0;
  static const decoteCouple = 1483.0;
  static const decoteRate = 0.4525;
}
