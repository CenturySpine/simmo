import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/app.dart';
import 'package:simmo/features/simulation/data/saved_inputs.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  test('income, tax income, rate, age and withholding are saved', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = SavedInputs(await SharedPreferences.getInstance());
    const before = SimulationInput();
    saved.save(
      before,
      before.copyWith(
        netMonthlyIncome: 3210.5,
        referenceTaxIncome: 36000,
        rate: 0.034,
        price: 300000,
        borrowerAge: 42,
        withholdingRate: () => 0.12,
      ),
    );

    final restored = saved.restore(const SimulationInput());
    expect(restored.netMonthlyIncome, 3210.5);
    expect(restored.referenceTaxIncome, 36000);
    expect(restored.rate, 0.034);
    expect(restored.borrowerAge, 42);
    expect(restored.withholdingRate, 0.12);
    // A computed price is not saved.
    expect(saved.hasPrice, isFalse);
  });

  test('housing budget and negotiation are saved, then cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = SavedInputs(await SharedPreferences.getInstance());
    const before = SimulationInput();
    saved.save(
      before,
      before.copyWith(
        condoFees: 245.6,
        propertyTax: 1128,
        condoWorks: 9000,
        condoWorksYears: 8,
        offerPrice: 279000,
      ),
    );

    final restored = saved.restore(const SimulationInput());
    expect(restored.condoFees, 245.6);
    expect(restored.propertyTax, 1128);
    expect(restored.condoWorks, 9000);
    expect(restored.condoWorksYears, 8);
    expect(restored.offerPrice, 279000);

    saved.clear();
    expect(saved.restore(const SimulationInput()).condoFees, 0);
  });

  test('resetting the withholding rate forgets it', () async {
    SharedPreferences.setMockInitialValues({'withholdingRate': '0.12'});
    final saved = SavedInputs(await SharedPreferences.getInstance());
    final typed = saved.restore(const SimulationInput());
    saved.save(typed, typed.copyWith(withholdingRate: () => null));
    expect(saved.restore(const SimulationInput()).withholdingRate, isNull);
  });

  testWidgets('a saved price is restored as an input', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'price': '300000.0'});
    final saved = SavedInputs(await SharedPreferences.getInstance());

    await tester.pumpWidget(SimmoApp(saved: saved));

    // Grouped with a non-breaking space, as shown in the price field.
    expect(find.text('300 000'), findsOneWidget);
    expect(saved.hasPrice, isTrue);
  });
}
