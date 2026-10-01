import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/app.dart';
import 'package:simmo/features/simulation/data/saved_inputs.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  testWidgets('footer: warning, legal notice, privacy, copyright', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'netMonthlyIncome': '3210.5'});
    final saved = SavedInputs(await SharedPreferences.getInstance());

    await tester.pumpWidget(SimmoApp(saved: saved));
    expect(find.text('© 2026 Simmo'), findsOneWidget);
    expect(find.textContaining('Un crédit vous engage'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);

    await tester.tap(find.text('Mentions légales'));
    await tester.pumpAndSettle();
    expect(find.text('Hébergeur'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confidentialité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Effacer les données de cet appareil'));
    await tester.pumpAndSettle();
    expect(find.text('Données de cet appareil effacées'), findsOneWidget);
    expect(saved.restore(const SimulationInput()).netMonthlyIncome, 4000);
  });
}
