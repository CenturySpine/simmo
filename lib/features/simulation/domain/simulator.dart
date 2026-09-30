import 'dart:math';

import 'income_tax.dart';
import 'notary_fees.dart';
import 'ptz.dart';
import 'rules.dart';
import 'simulation_input.dart';
import 'simulation_result.dart';

/// Runs the simulation: computes the two [SimulationInput.computed] main
/// parameters from the three others, then the full financing plan.
SimulationResult simulate(SimulationInput input) {
  final computed = input.computed;
  assert(isSolvable(computed));
  final target = targetMonthly(input);
  final months = input.durationMonths;
  double monthly(double price, double down, int n) =>
      _plan(input, price, down, n).maxMonthly;

  if (computed.contains(MainField.loan)) {
    final price = input.price;
    final down = input.downPayment;
    if (computed.contains(MainField.payment)) {
      return _result(input, _plan(input, price, down, months));
    }
    if (computed.contains(MainField.duration)) {
      return _shortestDuration(input, price, down, target);
    }
    if (computed.contains(MainField.price)) {
      if (target < 0 || monthly(0, down, months) > target) {
        return _result(input, _plan(input, 0, down, months), feasible: false);
      }
      final best = _bisect(0, 20e6, (p) => monthly(p, down, months) <= target);
      return _result(input, _plan(input, best.floorToDouble(), down, months));
    }
    // Down payment.
    if (monthly(price, 0, months) <= target) {
      return _result(input, _plan(input, price, 0, months));
    }
    final all = _fixedCosts(input, price);
    if (target < 0) {
      return _result(input, _plan(input, price, all, months), feasible: false);
    }
    final least = _bisect(all, 0, (d) => monthly(price, d, months) <= target);
    return _result(input, _plan(input, price, least.ceilToDouble(), months));
  }

  // The loan is an input: the financing plan gives the price or the down
  // payment, then the repayment side gives the duration or the payment.
  final loan = max(0.0, input.loanAmount);
  var price = input.price;
  var down = input.downPayment;
  var feasible = true;
  if (computed.contains(MainField.price)) {
    feasible = _borrowed(input, 0, down) <= loan;
    price = feasible
        ? _bisect(0, 20e6, (p) => _borrowed(input, p, down) <= loan)
        : 0;
  } else {
    down = _fixedCosts(input, price) + _guarantee(input, loan) - loan;
    feasible = down >= 0;
    down = max(0, down);
  }
  if (computed.contains(MainField.payment)) {
    return _result(
      input,
      _plan(input, price, down, months),
      feasible: feasible,
    );
  }
  final result = _shortestDuration(input, price, down, target);
  return feasible
      ? result
      : _result(
          input,
          _plan(input, price, down, result.durationMonths),
          feasible: false,
        );
}

/// Value closest to [to] for which [ok] holds, assuming it holds at [from].
double _bisect(double from, double to, bool Function(double) ok) {
  var good = from;
  var bad = to;
  for (var i = 0; i < 60; i++) {
    final mid = (good + bad) / 2;
    ok(mid) ? good = mid : bad = mid;
  }
  return good;
}

SimulationResult _shortestDuration(
  SimulationInput input,
  double price,
  double down,
  double target,
) {
  for (var months = 12; months <= 360; months++) {
    final plan = _plan(input, price, down, months);
    if (plan.maxMonthly <= target) return _result(input, plan);
  }
  return _result(input, _plan(input, price, down, 360), feasible: false);
}

/// Price, notary fees, works, agency, bank and broker fees: everything to
/// finance except the guarantee.
double _fixedCosts(SimulationInput input, double price) =>
    price +
    _notary(input, price) +
    input.works +
    input.agencyFees +
    input.bankFees +
    input.brokerFees;

double _notary(SimulationInput input, double price) => notaryFees(
  price: price,
  newBuild: input.propertyKind == PropertyKind.newBuild,
  departmentRate: input.firstTimeBuyer || !input.raisedTransferTax
      ? Rules.departmentRateStandard
      : Rules.departmentRateRaised,
  furniture: input.furniture,
  miscFees: input.notaryMiscFees,
);

double _guarantee(SimulationInput input, double borrowed) =>
    borrowed > 0 ? input.guaranteeRate * borrowed + input.guaranteeFixed : 0;

/// Total borrowed: the guarantee is financed too, so
/// borrowed = need + rate × borrowed + fixed.
double _borrowed(SimulationInput input, double price, double down) {
  final need = _fixedCosts(input, price) - down;
  return need > 0
      ? (need + input.guaranteeFixed) / (1 - input.guaranteeRate)
      : 0;
}

/// Monthly payment allowed by the effort parameter (all loans, insurance
/// included).
double targetMonthly(SimulationInput input) =>
    input.effortMode == EffortMode.payment
    ? input.monthlyPayment
    : input.debtRatio * retainedIncome(input) - input.otherLoans;

double retainedIncome(SimulationInput input) =>
    input.netMonthlyIncome + input.rentalIncome * Rules.rentalIncomeWeight;

class _Loan {
  _Loan(
    this.kind,
    this.amount,
    this.rate,
    this.deferral,
    this.payments,
    this.insurance,
  );

  final LoanKind kind;
  final double amount;
  final double rate;
  final int deferral;

  /// Credit part of each monthly payment.
  final List<double> payments;
  final double insurance;

  int get months => payments.length;
  double get interest => payments.fold(0.0, (a, b) => a + b) - amount;
}

class _Plan {
  _Plan({
    required this.price,
    required this.downPayment,
    required this.months,
    required this.notary,
    required this.guarantee,
    required this.totalCost,
    required this.ptz,
    required this.loans,
    required this.totals,
  });

  final double price;
  final double downPayment;
  final int months;
  final double notary;
  final double guarantee;
  final double totalCost;
  final PtzOutcome ptz;
  final List<_Loan> loans;

  /// Total monthly payment (insurance included), month by month.
  final List<double> totals;

  double get maxMonthly => totals.fold(0.0, max);
}

_Plan _plan(SimulationInput input, double price, double down, int months) {
  final notary = _notary(input, price);
  final operationCost = price + input.works + input.agencyFees;
  final ptz = ptzOutcome(input, operationCost);
  final borrowed = _borrowed(input, price, down);
  final guarantee = _guarantee(input, borrowed);
  final ratio = ptz.otherLoansRatio;
  final ptzAmount = min(ptz.maxAmount, borrowed * ratio / (1 + ratio));
  final alAmount = max(
    0.0,
    min(
      min(input.actionLogement, Rules.actionLogementMax),
      borrowed - ptzAmount,
    ),
  );
  final mainAmount = borrowed - ptzAmount - alAmount;

  double insurance(double amount) =>
      amount * input.insuranceRate * input.insuranceCoverage / 12;

  final aids = <_Loan>[];
  if (ptzAmount > 0) {
    final deferral = min(ptz.deferralMonths, months);
    final repayment = ptzAmount / ptz.repaymentMonths;
    aids.add(
      _Loan(LoanKind.ptz, ptzAmount, 0, deferral, [
        for (var t = 0; t < deferral; t++) 0,
        for (var t = 0; t < ptz.repaymentMonths; t++) repayment,
      ], insurance(ptzAmount)),
    );
  }
  if (alAmount > 0) {
    final alMonths = min(months, Rules.actionLogementMaxMonths);
    final payment = _annuity(alAmount, Rules.actionLogementRate / 12, alMonths);
    aids.add(
      _Loan(
        LoanKind.actionLogement,
        alAmount,
        Rules.actionLogementRate,
        0,
        List.filled(alMonths, payment),
        insurance(alAmount),
      ),
    );
  }

  final monthlyRate = input.rate / 12;
  List<double> mainPayments;
  if (input.smoothing && aids.isNotEmpty) {
    // Insurance included, so the total (not just the credit part) is flat.
    final others = List.generate(
      months,
      (t) => aids.fold(
        0.0,
        (sum, loan) =>
            sum + (t < loan.months ? loan.payments[t] + loan.insurance : 0),
      ),
    );
    mainPayments = _smoothed(mainAmount, monthlyRate, others);
  } else {
    mainPayments = List.filled(
      months,
      _annuity(mainAmount, monthlyRate, months),
    );
  }
  final loans = [
    if (mainAmount > 0)
      _Loan(
        LoanKind.main,
        mainAmount,
        input.rate,
        0,
        mainPayments,
        insurance(mainAmount),
      ),
    ...aids,
  ];

  final horizon = loans.fold(0, (m, loan) => max(m, loan.months));
  final totals = List.generate(
    horizon,
    (t) => loans.fold(
      0.0,
      (sum, loan) =>
          sum + (t < loan.months ? loan.payments[t] + loan.insurance : 0),
    ),
  );

  return _Plan(
    price: price,
    downPayment: down,
    months: months,
    notary: notary,
    guarantee: guarantee,
    totalCost:
        operationCost + notary + input.bankFees + input.brokerFees + guarantee,
    ptz: ptz,
    loans: loans,
    totals: totals,
  );
}

double _annuity(double principal, double monthlyRate, int months) {
  if (months <= 0 || principal <= 0) return 0;
  if (monthlyRate == 0) return principal / months;
  return principal * monthlyRate / (1 - pow(1 + monthlyRate, -months));
}

/// Main loan payments K − others(t), K constant, so that the total stays
/// flat; months where the other loans alone exceed K pay nothing.
List<double> _smoothed(
  double principal,
  double monthlyRate,
  List<double> others,
) {
  final n = others.length;
  final discount = List.generate(
    n,
    (t) => pow(1 + monthlyRate, -(t + 1)).toDouble(),
  );
  final active = List.filled(n, true);
  var k = 0.0;
  for (var iteration = 0; iteration < 20; iteration++) {
    var weights = 0.0;
    var value = principal;
    for (var t = 0; t < n; t++) {
      if (!active[t]) continue;
      weights += discount[t];
      value += others[t] * discount[t];
    }
    k = weights > 0 ? value / weights : 0;
    var changed = false;
    for (var t = 0; t < n; t++) {
      final isActive = others[t] < k;
      if (isActive != active[t]) {
        active[t] = isActive;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return [for (var t = 0; t < n; t++) active[t] ? k - others[t] : 0];
}

SimulationResult _result(
  SimulationInput input,
  _Plan plan, {
  bool feasible = true,
}) {
  final income = retainedIncome(input);
  final tax =
      input.monthlyIncomeTax ??
      annualIncomeTax(
            taxableIncome: input.referenceTaxIncome,
            couple: input.couple,
            children: input.children,
          ) /
          12;
  final monthly = plan.maxMonthly;
  final main = plan.loans
      .where((loan) => loan.kind == LoanKind.main)
      .firstOrNull;
  final fees = input.bankFees + input.brokerFees + plan.guarantee;
  final totalInterest = plan.loans.fold(
    0.0,
    (sum, loan) => sum + loan.interest,
  );
  final totalInsurance = plan.loans.fold(
    0.0,
    (sum, loan) => sum + loan.insurance * loan.months,
  );

  return SimulationResult(
    feasible: feasible,
    price: plan.price,
    downPayment: plan.downPayment,
    durationMonths: plan.months,
    notaryFees: plan.notary,
    guaranteeFees: plan.guarantee,
    bankFees: input.bankFees,
    brokerFees: input.brokerFees,
    works: input.works,
    agencyFees: input.agencyFees,
    totalCost: plan.totalCost,
    loans: [
      for (final loan in plan.loans)
        LoanResult(
          kind: loan.kind,
          amount: loan.amount,
          rate: loan.rate,
          months: loan.months,
          deferralMonths: loan.deferral,
          firstPayment: loan.payments.first,
          insuranceMonthly: loan.insurance,
          interest: loan.interest,
          insuranceTotal: loan.insurance * loan.months,
          tiers: _tiers(loan.payments),
        ),
    ],
    tiers: _tiers(plan.totals),
    monthlyPayment: monthly,
    debtRatioBefore: income > 0
        ? (input.currentRent + input.otherLoans) / income
        : 0,
    debtRatioAfter: income > 0 ? (monthly + input.otherLoans) / income : 0,
    incomeTax: tax,
    residualBefore: income - tax - input.currentRent - input.otherLoans,
    residualAfter: income - tax - monthly - input.otherLoans,
    paymentJump: input.currentRent > 0 ? monthly - input.currentRent : 0,
    totalInterest: totalInterest,
    totalInsurance: totalInsurance,
    creditCost: totalInterest + totalInsurance + fees,
    taeg: main == null
        ? null
        : _apr(main.amount - fees, [
            for (final p in main.payments) p + main.insurance,
          ]),
    ptz: plan.ptz,
  );
}

/// Actuarial annual rate at which [flows] (one per month) are worth [net].
double? _apr(double net, List<double> flows) {
  if (net <= 0) return null;
  double value(double rate) {
    final monthly = pow(1 + rate, 1 / 12) - 1;
    var v = 0.0;
    var factor = 1.0;
    for (final flow in flows) {
      factor /= 1 + monthly;
      v += flow * factor;
    }
    return v;
  }

  var lo = 0.0;
  var hi = 1.0;
  if (value(lo) < net) return 0;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    value(mid) > net ? lo = mid : hi = mid;
  }
  return lo;
}

List<PaymentTier> _tiers(List<double> totals) {
  final tiers = <PaymentTier>[];
  for (var t = 0; t < totals.length; t++) {
    final amount = (totals[t] * 100).round() / 100;
    if (tiers.isNotEmpty && tiers.last.amount == amount) {
      tiers[tiers.length - 1] = PaymentTier(tiers.last.from, t + 1, amount);
    } else {
      tiers.add(PaymentTier(t + 1, t + 1, amount));
    }
  }
  return tiers;
}
