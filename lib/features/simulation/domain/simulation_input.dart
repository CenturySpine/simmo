import 'dart:math';

import 'package:flutter/foundation.dart';

/// The five main parameters: two are computed from the three others.
enum MainField { price, downPayment, loan, duration, payment }

const _financing = {MainField.price, MainField.downPayment, MainField.loan};
const _repayment = {MainField.loan, MainField.duration, MainField.payment};

/// Two computed fields are consistent when one sits on the financing side
/// (price, down payment, loan) and one on the repayment side (loan,
/// duration, payment).
bool isSolvable(Set<MainField> computed) =>
    computed.length == 2 &&
    computed.any(_financing.contains) &&
    computed.any(_repayment.contains);

/// Which untouched parameters adapt first: the purchase capacity.
const _computePreference = [
  MainField.price,
  MainField.loan,
  MainField.payment,
  MainField.duration,
  MainField.downPayment,
];

/// The two parameters to compute, given those the user typed (newest last):
/// untouched ones first, then the least recently typed, so the latest entries
/// always stay as typed.
Set<MainField> pickComputed(List<MainField> typed) {
  final order = [
    ..._computePreference.where((f) => !typed.contains(f)),
    ...typed,
  ];
  for (var j = 1; j < order.length; j++) {
    for (var i = 0; i < j; i++) {
      final pair = {order[i], order[j]};
      if (isSolvable(pair)) return pair;
    }
  }
  return const {MainField.price, MainField.loan};
}

/// How the borrower's monthly effort is expressed: a debt ratio, the loan
/// payment, or the whole monthly housing cost ([SimulationInput.runningCosts]
/// on top of the payment).
enum EffortMode { debtRatio, payment, allIn }

enum PropertyKind { existing, newBuild }

enum DwellingType { apartment, house }

/// PTZ zoning (A includes A bis).
enum PtzZone { a, b1, b2, c }

/// A geocoded address: where the property is.
@immutable
class PropertyAddress {
  const PropertyAddress({
    required this.label,
    required this.lat,
    required this.lon,
    required this.citycode,
  });

  final String label;
  final double lat;
  final double lon;

  /// INSEE code; the arrondissement in Paris, Lyon and Marseille.
  final String citycode;

  @override
  bool operator ==(Object other) =>
      other is PropertyAddress &&
      other.label == label &&
      other.lat == lat &&
      other.lon == lon &&
      other.citycode == citycode;

  @override
  int get hashCode => Object.hash(label, lat, lon, citycode);
}

/// Everything the user can set. Rates are fractions (0.035 = 3.5%), amounts
/// in euros, durations in months.
@immutable
class SimulationInput {
  const SimulationInput({
    this.computed = const {MainField.price, MainField.loan},
    this.price = 250000,
    this.downPayment = 30000,
    this.loanAmount = 230000,
    this.durationMonths = 300,
    this.effortMode = EffortMode.debtRatio,
    this.debtRatio = 0.35,
    this.monthlyPayment = 1200,
    this.housingBudget = 1500,
    this.netMonthlyIncome = 4000,
    this.referenceTaxIncome = 40000,
    this.rate = 0.035,
    this.propertyKind = PropertyKind.existing,
    this.dwellingType = DwellingType.apartment,
    this.zone = PtzZone.b1,
    this.firstTimeBuyer = true,
    this.raisedTransferTax = true,
    this.works = 0,
    this.agencyFees = 0,
    this.furniture = 0,
    this.notaryMiscFees = 1600,
    this.bankFees = 1000,
    this.brokerFees = 2900,
    this.guaranteeFees,
    this.efficientHome = false,
    this.borrowerAge = 35,
    this.bankInsurance = true,
    this.insuranceRate,
    this.insuranceCoverage = 1,
    this.couple = false,
    this.children = 0,
    this.otherLoans = 0,
    this.currentRent = 0,
    this.rentalIncome = 0,
    this.withholdingRate,
    this.ptzEnabled = false,
    this.actionLogement = 0,
    this.smoothing = true,
    this.condoFees = 0,
    this.propertyTax = 0,
    this.utilities = 0,
    this.currentUtilities = 0,
    this.condoCalls = 0,
    this.condoWorks = 0,
    this.condoWorksYears = 10,
    this.askingPrice = 0,
    this.offerPrice = 0,
    this.maxPrice = 0,
    this.address,
    this.surface = 0,
  });

  // --- Main parameters -----------------------------------------------------
  final Set<MainField> computed;
  final double price;
  final double downPayment;

  /// Total borrowed, all loans included.
  final double loanAmount;
  final int durationMonths;
  final EffortMode effortMode;

  /// Target debt ratio, used when [effortMode] is [EffortMode.debtRatio].
  final double debtRatio;

  /// Target monthly payment (all loans, insurance included), used when
  /// [effortMode] is [EffortMode.payment].
  final double monthlyPayment;

  /// Target monthly housing cost, all included (payment and
  /// [runningCosts]), used when [effortMode] is [EffortMode.allIn].
  final double housingBudget;
  final double netMonthlyIncome;

  /// Revenu fiscal de référence N-2 (PTZ eligibility, income tax estimate).
  final double referenceTaxIncome;

  /// Nominal rate of the main loan.
  final double rate;

  // --- Project ---------------------------------------------------------------
  final PropertyKind propertyKind;
  final DwellingType dwellingType;
  final PtzZone zone;

  /// No main-residence ownership in the last 2 years: PTZ, and the 4.50%
  /// transfer tax rate even where the department raised it.
  final bool firstTimeBuyer;

  /// The department charges 5.00% instead of 4.50% (88 departments in 2026).
  final bool raisedTransferTax;
  final double works;

  /// Agency fees paid by the buyer (not subject to transfer taxes).
  final double agencyFees;

  /// Furniture included in the price (not subject to transfer taxes).
  final double furniture;

  /// Notary formalities and disbursements.
  final double notaryMiscFees;

  // --- Fees --------------------------------------------------------------------
  final double bankFees;
  final double brokerFees;

  /// Guarantee cost typed by the user; `null` = Crédit Logement grid.
  final double? guaranteeFees;

  /// Home rated A or B (DPE): cheaper Crédit Logement commission.
  final bool efficientHome;

  // --- Borrower insurance (on the initial capital) ---------------------------
  final int borrowerAge;

  /// Bank group contract rather than a delegated one.
  final bool bankInsurance;

  /// Rate typed by the user; `null` = usual rate for the age and contract.
  final double? insuranceRate;

  /// 1 = 100%; two borrowers insured at 100% each = 2.
  final double insuranceCoverage;

  // --- Household ---------------------------------------------------------------
  final bool couple;
  final int children;

  /// Monthly payments of loans that continue after the project.
  final double otherLoans;

  /// Rent paid today, which stops with the purchase.
  final double currentRent;
  final double rentalIncome;

  /// Income tax withholding rate (prélèvement à la source, on the payslip),
  /// applied to [netMonthlyIncome]. `null` = estimated from
  /// [referenceTaxIncome].
  final double? withholdingRate;

  // --- Aids --------------------------------------------------------------------
  final bool ptzEnabled;
  final double actionLogement;

  /// Main loan in tiers so the total monthly payment stays constant while
  /// the PTZ or Action Logement loan runs.
  final bool smoothing;

  // --- Housing budget (buyer's view; banks ignore it) -----------------------
  /// Co-ownership charges per month.
  final double condoFees;

  /// Property tax per year.
  final double propertyTax;

  /// Energy, home insurance and other housing costs per month, after the
  /// purchase.
  final double utilities;

  /// Same costs paid today on top of [currentRent].
  final double currentUtilities;

  /// Co-ownership calls for funds left to the buyer at purchase: financed
  /// like the rest of the project.
  final double condoCalls;

  /// Buyer's estimated share of co-ownership works to come, saved monthly
  /// over [condoWorksYears].
  final double condoWorks;
  final int condoWorksYears;

  // --- Negotiation (0 = not typed) -------------------------------------------
  final double askingPrice;
  final double offerPrice;
  final double maxPrice;

  // --- Market ----------------------------------------------------------------
  /// Where the property is: nearby sales.
  final PropertyAddress? address;

  /// Living area in m², 0 = not typed.
  final double surface;

  double get monthlyPropertyTax => propertyTax / 12;

  /// Monthly saving for the co-ownership works to come.
  double get worksSaving => condoWorks / (max(1, condoWorksYears) * 12);

  /// Monthly housing costs besides the loan: charges, property tax,
  /// utilities, works saving.
  double get runningCosts =>
      condoFees + monthlyPropertyTax + utilities + worksSaving;

  int get adults => couple ? 2 : 1;
  int get persons => adults + children;

  /// This input with the buyer of [other]: income, age, household and
  /// current housing, the same in every project.
  SimulationInput withBuyerOf(SimulationInput other) => copyWith(
    netMonthlyIncome: other.netMonthlyIncome,
    referenceTaxIncome: other.referenceTaxIncome,
    borrowerAge: other.borrowerAge,
    firstTimeBuyer: other.firstTimeBuyer,
    couple: other.couple,
    children: other.children,
    otherLoans: other.otherLoans,
    currentRent: other.currentRent,
    currentUtilities: other.currentUtilities,
    rentalIncome: other.rentalIncome,
    withholdingRate: () => other.withholdingRate,
  );

  SimulationInput copyWith({
    Set<MainField>? computed,
    double? price,
    double? downPayment,
    double? loanAmount,
    int? durationMonths,
    EffortMode? effortMode,
    double? debtRatio,
    double? monthlyPayment,
    double? housingBudget,
    double? netMonthlyIncome,
    double? referenceTaxIncome,
    double? rate,
    PropertyKind? propertyKind,
    DwellingType? dwellingType,
    PtzZone? zone,
    bool? firstTimeBuyer,
    bool? raisedTransferTax,
    double? works,
    double? agencyFees,
    double? furniture,
    double? notaryMiscFees,
    double? bankFees,
    double? brokerFees,
    ValueGetter<double?>? guaranteeFees,
    bool? efficientHome,
    int? borrowerAge,
    bool? bankInsurance,
    ValueGetter<double?>? insuranceRate,
    double? insuranceCoverage,
    bool? couple,
    int? children,
    double? otherLoans,
    double? currentRent,
    double? rentalIncome,
    ValueGetter<double?>? withholdingRate,
    bool? ptzEnabled,
    double? actionLogement,
    bool? smoothing,
    double? condoFees,
    double? propertyTax,
    double? utilities,
    double? currentUtilities,
    double? condoCalls,
    double? condoWorks,
    int? condoWorksYears,
    double? askingPrice,
    double? offerPrice,
    double? maxPrice,
    ValueGetter<PropertyAddress?>? address,
    double? surface,
  }) => SimulationInput(
    computed: computed ?? this.computed,
    price: price ?? this.price,
    downPayment: downPayment ?? this.downPayment,
    loanAmount: loanAmount ?? this.loanAmount,
    durationMonths: durationMonths ?? this.durationMonths,
    effortMode: effortMode ?? this.effortMode,
    debtRatio: debtRatio ?? this.debtRatio,
    monthlyPayment: monthlyPayment ?? this.monthlyPayment,
    housingBudget: housingBudget ?? this.housingBudget,
    netMonthlyIncome: netMonthlyIncome ?? this.netMonthlyIncome,
    referenceTaxIncome: referenceTaxIncome ?? this.referenceTaxIncome,
    rate: rate ?? this.rate,
    propertyKind: propertyKind ?? this.propertyKind,
    dwellingType: dwellingType ?? this.dwellingType,
    zone: zone ?? this.zone,
    firstTimeBuyer: firstTimeBuyer ?? this.firstTimeBuyer,
    raisedTransferTax: raisedTransferTax ?? this.raisedTransferTax,
    works: works ?? this.works,
    agencyFees: agencyFees ?? this.agencyFees,
    furniture: furniture ?? this.furniture,
    notaryMiscFees: notaryMiscFees ?? this.notaryMiscFees,
    bankFees: bankFees ?? this.bankFees,
    brokerFees: brokerFees ?? this.brokerFees,
    guaranteeFees: guaranteeFees != null ? guaranteeFees() : this.guaranteeFees,
    efficientHome: efficientHome ?? this.efficientHome,
    borrowerAge: borrowerAge ?? this.borrowerAge,
    bankInsurance: bankInsurance ?? this.bankInsurance,
    insuranceRate: insuranceRate != null ? insuranceRate() : this.insuranceRate,
    insuranceCoverage: insuranceCoverage ?? this.insuranceCoverage,
    couple: couple ?? this.couple,
    children: children ?? this.children,
    otherLoans: otherLoans ?? this.otherLoans,
    currentRent: currentRent ?? this.currentRent,
    rentalIncome: rentalIncome ?? this.rentalIncome,
    withholdingRate: withholdingRate != null
        ? withholdingRate()
        : this.withholdingRate,
    ptzEnabled: ptzEnabled ?? this.ptzEnabled,
    actionLogement: actionLogement ?? this.actionLogement,
    smoothing: smoothing ?? this.smoothing,
    condoFees: condoFees ?? this.condoFees,
    propertyTax: propertyTax ?? this.propertyTax,
    utilities: utilities ?? this.utilities,
    currentUtilities: currentUtilities ?? this.currentUtilities,
    condoCalls: condoCalls ?? this.condoCalls,
    condoWorks: condoWorks ?? this.condoWorks,
    condoWorksYears: condoWorksYears ?? this.condoWorksYears,
    askingPrice: askingPrice ?? this.askingPrice,
    offerPrice: offerPrice ?? this.offerPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    address: address != null ? address() : this.address,
    surface: surface ?? this.surface,
  );
}
