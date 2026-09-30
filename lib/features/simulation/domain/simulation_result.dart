import 'ptz.dart';

enum LoanKind { main, ptz, actionLogement }

class LoanResult {
  const LoanResult({
    required this.kind,
    required this.amount,
    required this.rate,
    required this.months,
    required this.deferralMonths,
    required this.firstPayment,
    required this.insuranceMonthly,
    required this.interest,
    required this.insuranceTotal,
    required this.tiers,
  });

  final LoanKind kind;
  final double amount;
  final double rate;

  /// Total duration, deferral included.
  final int months;
  final int deferralMonths;

  /// Credit part of the first monthly payment (0 during a deferral).
  final double firstPayment;
  final double insuranceMonthly;
  final double interest;
  final double insuranceTotal;

  /// Credit part of the payment by period (several when smoothed).
  final List<PaymentTier> tiers;
}

/// Months [from] to [to] (1-based, inclusive) pay [amount] in total.
class PaymentTier {
  const PaymentTier(this.from, this.to, this.amount);

  final int from;
  final int to;
  final double amount;
}

class SimulationResult {
  const SimulationResult({
    required this.feasible,
    required this.price,
    required this.downPayment,
    required this.durationMonths,
    required this.notaryFees,
    required this.guaranteeFees,
    required this.bankFees,
    required this.brokerFees,
    required this.works,
    required this.agencyFees,
    required this.totalCost,
    required this.loans,
    required this.tiers,
    required this.monthlyPayment,
    required this.debtRatioBefore,
    required this.debtRatioAfter,
    required this.incomeTax,
    required this.residualBefore,
    required this.residualAfter,
    required this.paymentJump,
    required this.totalInterest,
    required this.totalInsurance,
    required this.creditCost,
    required this.taeg,
    required this.ptz,
  });

  /// False when no value of the solved parameter meets the target effort.
  final bool feasible;
  final double price;
  final double downPayment;
  final int durationMonths;
  final double notaryFees;
  final double guaranteeFees;
  final double bankFees;
  final double brokerFees;
  final double works;
  final double agencyFees;

  /// Everything to finance: price, notary, fees, guarantee, works, agency.
  final double totalCost;
  final List<LoanResult> loans;
  final List<PaymentTier> tiers;

  /// Highest total monthly payment (all loans, insurance included).
  final double monthlyPayment;
  final double debtRatioBefore;
  final double debtRatioAfter;
  final double incomeTax;

  /// Income left after tax, rent or loans, before and after the project.
  final double residualBefore;
  final double residualAfter;

  /// New monthly payment minus current rent (0 without rent).
  final double paymentJump;
  final double totalInterest;
  final double totalInsurance;

  /// Interest + insurance + bank, broker and guarantee fees.
  final double creditCost;

  /// Main loan APR (fees and insurance included), null without a loan.
  final double? taeg;
  final PtzOutcome ptz;

  double get borrowed => loans.fold(0, (sum, loan) => sum + loan.amount);
  double get downPaymentShare => totalCost > 0 ? downPayment / totalCost : 0;
  LoanResult? get mainLoan =>
      loans.where((loan) => loan.kind == LoanKind.main).firstOrNull;
}
