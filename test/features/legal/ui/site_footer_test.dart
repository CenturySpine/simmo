import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/app.dart';
import 'package:simmo/core/format.dart';
import 'package:simmo/features/simulation/data/saved_projects.dart';
import 'package:simmo/features/simulation/domain/project.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  testWidgets('footer: warning, legal notice, privacy, copyright', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final saved = SavedProjects(await SharedPreferences.getInstance());
    await saved.save([
      const Project(SimulationInput(netMonthlyIncome: 3210.5)),
    ], 0);

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
    expect(saved.projects, isEmpty);
    // The page starts afresh too.
    expect(find.textContaining('${euros(4000)} nets par mois'), findsOneWidget);
  });
}
