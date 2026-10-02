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

  test(
    'budget, negotiation, surface and address are saved, then cleared',
    () async {
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
          surface: 69.61,
          address: () => const PropertyAddress(
            label: '69 Rue Louis Becker 69100 Villeurbanne',
            lat: 45.765293,
            lon: 4.871044,
            citycode: '69266',
          ),
        ),
      );

      final restored = saved.restore(const SimulationInput());
      expect(restored.surface, 69.61);
      expect(restored.address?.citycode, '69266');
      expect(restored.condoFees, 245.6);
      expect(restored.propertyTax, 1128);
      expect(restored.condoWorks, 9000);
      expect(restored.condoWorksYears, 8);
      expect(restored.offerPrice, 279000);

      saved.clear();
      expect(saved.restore(const SimulationInput()).condoFees, 0);
      expect(saved.restore(const SimulationInput()).address, isNull);
    },
  );

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

  testWidgets('a saved address gives its zone back', (tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'address':
          '{"label":"69 Rue Louis Becker 69100 Villeurbanne",'
          '"lat":45.765293,"lon":4.871044,"citycode":"69266"}',
    });
    final saved = SavedInputs(await SharedPreferences.getInstance());

    await tester.pumpWidget(SimmoApp(saved: saved));
    // Let the zoning list load.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.tap(find.text('Paramètres avancés'));
    await tester.pumpAndSettle();

    final zone = tester.widget<SegmentedButton<PtzZone>>(
      find.byType(SegmentedButton<PtzZone>),
    );
    expect(zone.selected, {PtzZone.a});
  });
}
