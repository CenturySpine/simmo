import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/features/simulation/domain/guarantee.dart';
import 'package:simmo/features/simulation/domain/income_tax.dart';
import 'package:simmo/features/simulation/domain/insurance.dart';
import 'package:simmo/features/simulation/domain/notary_fees.dart';
import 'package:simmo/features/simulation/domain/ptz.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';
import 'package:simmo/features/simulation/domain/simulation_result.dart';
import 'package:simmo/features/simulation/domain/simulator.dart';

const _loanAndPayment = {MainField.loan, MainField.payment};
const _income = 4600.0;
const _rent = 700.0;
const _withholding = 0.14;
const _tax = _income * _withholding;

/// Two broker proposals (existing home, main residence, 3.40%, bank
/// insurance 0.50%, Crédit Logement guarantee) used as reference. Brokers
/// round notary fees to the hundred, the simulator does not: about ±27 € on
/// the loan, ±0.15 € on the monthly payment. Income, rent and tax are
/// fictive (public repository): the expected ratios apply the proposals'
/// formulas to the proposals' monthly payments.
SimulationInput brokerCase({required double price, required int years}) =>
    SimulationInput(
      computed: _loanAndPayment,
      price: price,
      downPayment: 35000,
      durationMonths: years * 12,
      rate: 0.034,
      netMonthlyIncome: _income,
      currentRent: _rent,
      insuranceRate: 0.005,
      withholdingRate: _withholding,
    );

void main() {
  group('broker proposal, 25 years', () {
    final r = simulate(brokerCase(price: 300000, years: 25));
    final loan = r.mainLoan!;

    test('financing plan', () {
      expect(r.notaryFees, closeTo(22700, 50));
      expect(r.guaranteeFees, closeTo(3595.23, 1));
      expect(loan.amount, closeTo(295195.23, 30));
      expect(r.totalCost, closeTo(330195.23, 30));
      expect((r.downPaymentShare * 100).round(), 11);
    });

    test('monthly payment and cost', () {
      expect(loan.firstPayment, closeTo(1462.03, 0.2));
      expect(loan.insuranceMonthly, closeTo(123.00, 0.02));
      expect(r.monthlyPayment, closeTo(1585.03, 0.2));
      expect(r.totalInterest, closeTo(143414.53, 20));
      expect(r.totalInsurance, closeTo(36899.40, 5));
      expect(r.creditCost, closeTo(187809.16, 25));
      expect(r.taeg!, closeTo(0.0450, 0.0001));
    });

    test('key figures', () {
      expect(r.debtRatioBefore, closeTo(_rent / _income, 1e-9));
      expect(r.debtRatioAfter, closeTo(1585.03 / _income, 0.0001));
      expect(r.residualBefore, closeTo(_income - _tax - _rent, 0.01));
      expect(r.residualAfter, closeTo(_income - _tax - 1585.03, 0.2));
      expect(r.tiers.single.amount, closeTo(1585.03, 0.2));
    });
  });

  group('broker proposal, 20 years', () {
    final r = simulate(brokerCase(price: 260000, years: 20));
    final loan = r.mainLoan!;

    test('financing plan', () {
      expect(r.notaryFees, closeTo(19900, 50));
      expect(r.guaranteeFees, closeTo(3122.11, 1));
      expect(loan.amount, closeTo(251922.11, 30));
      expect((r.downPaymentShare * 100).round(), 12);
    });

    test('monthly payment and cost', () {
      expect(loan.firstPayment, closeTo(1448.13, 0.2));
      expect(loan.insuranceMonthly, closeTo(104.97, 0.02));
      expect(r.monthlyPayment, closeTo(1553.10, 0.2));
      expect(r.totalInterest, closeTo(95630.22, 20));
      expect(r.totalInsurance, closeTo(25192.21, 5));
      expect(r.creditCost, closeTo(127844.55, 25));
      expect(r.taeg!, closeTo(0.0462, 0.0001));
    });

    test('key figures', () {
      expect(r.debtRatioAfter, closeTo(1553.10 / _income, 0.0001));
      expect(r.residualAfter, closeTo(_income - _tax - 1553.10, 0.2));
    });
  });

  group('broker loan typed with the down payment', () {
    // The broker's exact loan: the payment matches to the cent.
    final base = brokerCase(price: 0, years: 25).copyWith(
      computed: {MainField.price, MainField.payment},
      loanAmount: 295195.23,
    );

    test('price and payment', () {
      final r = simulate(base);
      expect(r.borrowed, closeTo(295195.23, 0.01));
      // Crédit Logement grid: the broker's guarantee to the cent.
      expect(r.guaranteeFees, closeTo(3595.23, 0.01));
      expect(r.price, closeTo(300000, 50));
      expect(r.monthlyPayment, closeTo(1585.03, 0.01));
      expect(r.taeg!, closeTo(0.0450, 0.0001));
    });

    test('price and duration', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.price, MainField.duration},
          effortMode: EffortMode.payment,
          monthlyPayment: 1585.04,
        ),
      );
      expect(r.durationMonths, 300);
    });

    test('down payment from price and loan', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.downPayment, MainField.payment},
          price: 300000,
        ),
      );
      expect(r.downPayment, closeTo(35000, 50));
      expect(r.borrowed, closeTo(295195.23, 0.01));
    });

    test('loan above the project cost is reported', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.downPayment, MainField.payment},
          price: 100000,
        ),
      );
      expect(r.feasible, isFalse);
    });
  });

  group('solving from the effort', () {
    final base = brokerCase(price: 300000, years: 25);
    final reference = simulate(base);

    test('price from the monthly payment', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.price, MainField.loan},
          effortMode: EffortMode.payment,
          monthlyPayment: reference.monthlyPayment,
        ),
      );
      expect(r.price, closeTo(300000, 1));
    });

    test('duration from the monthly payment', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.duration, MainField.loan},
          effortMode: EffortMode.payment,
          monthlyPayment: reference.monthlyPayment + 0.01,
        ),
      );
      expect(r.durationMonths, 300);
    });

    test('down payment from the debt ratio', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.downPayment, MainField.loan},
          debtRatio: 0.35,
        ),
      );
      expect(r.debtRatioAfter, lessThanOrEqualTo(0.35));
      expect(r.downPayment, lessThan(35000));
    });

    test('unreachable target is reported', () {
      final r = simulate(
        base.copyWith(
          computed: {MainField.duration, MainField.loan},
          effortMode: EffortMode.payment,
          monthlyPayment: 500,
        ),
      );
      expect(r.feasible, isFalse);
    });
  });

  test('computed pairs need one financing and one repayment field', () {
    expect(isSolvable({MainField.price, MainField.loan}), isTrue);
    expect(isSolvable({MainField.price, MainField.payment}), isTrue);
    expect(isSolvable({MainField.price, MainField.downPayment}), isFalse);
    expect(isSolvable({MainField.duration, MainField.payment}), isFalse);
  });

  group('PTZ', () {
    const newFlat = SimulationInput(
      computed: _loanAndPayment,
      ptzEnabled: true,
      propertyKind: PropertyKind.newBuild,
      zone: PtzZone.a,
      price: 200000,
      referenceTaxIncome: 24000,
    );

    test('tranche 1 new flat in zone A: 50% of the capped cost', () {
      final r = simulate(newFlat);
      expect(r.ptz.tranche, 1);
      final ptz = r.loans.firstWhere((l) => l.kind == LoanKind.ptz);
      expect(ptz.amount, 75000);
      expect(ptz.deferralMonths, 120);
      expect(ptz.months, 300);
    });

    test('income floor is the operation cost / 9', () {
      // 250 000 / 9 = 27 778 > 25 000: tranche 2 despite a 24 000 RFR.
      final r = simulate(newFlat.copyWith(price: 250000));
      expect(r.ptz.tranche, 2);
    });

    test('smoothing keeps the total monthly payment flat', () {
      // Tranche 2: the PTZ (8 + 12 years) ends before the 25-year loan.
      final r = simulate(newFlat.copyWith(price: 250000));
      expect(r.tiers.length, 1);
      final unsmoothed = simulate(
        newFlat.copyWith(price: 250000, smoothing: false),
      );
      expect(unsmoothed.tiers.length, 3);
    });

    test('existing home outside B2/C is not eligible', () {
      final r = simulate(newFlat.copyWith(propertyKind: PropertyKind.existing));
      expect(r.ptz.reason, PtzReason.existingZone);
    });

    test('off by default', () {
      final r = simulate(newFlat.copyWith(ptzEnabled: false));
      expect(r.ptz.reason, PtzReason.disabled);
      expect(const SimulationInput().ptzEnabled, isFalse);
    });

    test('income above the ceiling is not eligible', () {
      final r = simulate(newFlat.copyWith(referenceTaxIncome: 49001));
      expect(r.ptz.reason, PtzReason.income);
    });
  });

  test('Crédit Logement fees match its official simulator', () {
    // (loan, DPE A or B, fees shown by creditlogement.fr in September 2026)
    const cases = [
      (10000.0, false, 469),
      (40000.0, false, 786),
      (100000.0, false, 1620),
      (200000.0, false, 2660),
      (251922.0, false, 3122),
      (295195.0, false, 3595),
      (300000.0, false, 3650),
      (1500000.0, false, 14430),
      (20000.0, true, 521),
      (200000.0, true, 2498),
      (255000.0, true, 2987),
      (300000.0, true, 3575),
    ];
    for (final (amount, efficient, fees) in cases) {
      expect(
        creditLogementFee(amount, efficientHome: efficient),
        closeTo(fees, 0.51),
        reason: '$amount, DPE A/B: $efficient',
      );
    }
  });

  test('usual insurance rate by age and contract', () {
    expect(usualInsuranceRate(age: 35, bankContract: true), 0.0034);
    expect(usualInsuranceRate(age: 35, bankContract: false), 0.0015);
    expect(usualInsuranceRate(age: 62, bankContract: true), 0.0062);
  });

  test('withholding rate from the payslip sets the income tax', () {
    final r = simulate(
      brokerCase(
        price: 300000,
        years: 25,
      ).copyWith(withholdingRate: () => 0.12),
    );
    expect(r.incomeTax, closeTo(_income * 0.12, 0.001));
  });

  test('notary fees on a new home are around 2.5%', () {
    final fees = notaryFees(
      price: 250000,
      newBuild: true,
      departmentRate: 0.045,
      miscFees: 1600,
    );
    expect(fees / 250000, closeTo(0.025, 0.003));
  });

  test('income tax, single, 2026 scale', () {
    final tax = annualIncomeTax(
      taxableIncome: 50000,
      couple: false,
      children: 0,
    );
    // (29 579 − 11 600) × 11 % + (50 000 − 29 579) × 30 %
    expect(tax, closeTo(8103.99, 0.01));
  });
}
