import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/app.dart';
import 'package:simmo/features/simulation/data/saved_inputs.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  test('income, tax income and rate are saved when they change', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = SavedInputs(await SharedPreferences.getInstance());
    const before = SimulationInput();
    saved.save(
      before,
      before.copyWith(
        netMonthlyIncome: 3210.5,
        referenceTaxIncome: 48000,
        rate: 0.034,
        price: 300000,
      ),
    );

    final restored = saved.restore(const SimulationInput());
    expect(restored.netMonthlyIncome, 3210.5);
    expect(restored.referenceTaxIncome, 48000);
    expect(restored.rate, 0.034);
    // A computed price is not saved.
    expect(saved.hasPrice, isFalse);
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
