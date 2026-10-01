import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/features/simulation/domain/budget.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';
import 'package:simmo/features/simulation/domain/simulator.dart';

/// A fixed price and down payment: loan and payment are computed.
const _base = SimulationInput(
  computed: {MainField.loan, MainField.payment},
  price: 285000,
  downPayment: 30000,
  durationMonths: 240,
  rate: 0.0365,
  insuranceRate: 0,
  netMonthlyIncome: 4000,
  withholdingRate: 0.05,
  currentRent: 900,
);

void main() {
  test('the budget adds charges, tax, utilities and works saving', () {
    final input = _base.copyWith(
      condoFees: 245,
      propertyTax: 1128,
      utilities: 60,
      currentUtilities: 80,
      condoWorks: 9000,
      condoWorksYears: 10,
    );
    final result = simulate(input);
    final b = housingBudget(input, result);

    expect(b.propertyTax, 94);
    expect(b.worksSaving, 75);
    expect(b.totalBefore, 980);
    expect(b.totalAfter, result.monthlyPayment + 245 + 94 + 60 + 75);
    // Income tax withheld: 5% of 4,000 €.
    expect(b.incomeTax, 200);
    expect(b.residualAfter, 4000 - 200 - b.totalAfter);
    expect(b.residualBefore, closeTo(result.residualBefore - 80, 1e-9));
    expect(
      b.residualAfter,
      closeTo(result.residualAfter - (245 + 94 + 60 + 75), 1e-9),
    );
  });

  test('the bank view ignores the budget', () {
    final plain = simulate(_base);
    final withBudget = simulate(
      _base.copyWith(condoFees: 245, propertyTax: 1128, condoWorks: 9000),
    );
    expect(withBudget.monthlyPayment, plain.monthlyPayment);
    expect(withBudget.debtRatioAfter, plain.debtRatioAfter);
  });

  test('co-ownership calls are financed with the project', () {
    final plain = simulate(_base);
    final calls = simulate(_base.copyWith(condoCalls: 5000));
    expect(calls.condoCalls, 5000);
    expect(calls.totalCost, greaterThan(plain.totalCost + 5000));
    expect(calls.borrowed, greaterThan(plain.borrowed + 5000));

    // With the price computed, they lower the price within reach.
    const byPayment = SimulationInput(
      effortMode: EffortMode.payment,
      monthlyPayment: 1500,
    );
    final capacity = simulate(byPayment);
    final reduced = simulate(byPayment.copyWith(condoCalls: 5000));
    expect(reduced.price, lessThan(capacity.price - 4000));
  });

  test('another price keeps the down payment and the duration', () {
    final result = simulate(_base);
    final offer = atPrice(_base, result, 279000);
    expect(offer.downPayment, result.downPayment);
    expect(offer.durationMonths, result.durationMonths);
    expect(offer.monthlyPayment, lessThan(result.monthlyPayment));
  });

  test('1,000 € more costs the financed share over the loan', () {
    // 1,000 € plus notary fees and guarantee, at 3.65% over 20 years.
    expect(costPerThousand(_base, simulate(_base)), closeTo(6.3, 0.15));
  });
}
