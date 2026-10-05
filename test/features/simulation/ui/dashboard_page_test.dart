import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/app.dart';
import 'package:simmo/core/format.dart';
import 'package:simmo/features/simulation/data/saved_projects.dart';
import 'package:simmo/features/simulation/data/share_link.dart';
import 'package:simmo/features/simulation/domain/project.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

const _address = PropertyAddress(
  label: '69 Rue Louis Becker 69100 Villeurbanne',
  lat: 45.765293,
  lon: 4.871044,
  citycode: '69266',
);

/// Projects kept on the device, the first one shown.
Future<SavedProjects> _saved(List<SimulationInput> inputs) async {
  SharedPreferences.setMockInitialValues({});
  final saved = SavedProjects(await SharedPreferences.getInstance());
  await saved.save([for (final i in inputs) Project(i)], 0);
  return saved;
}

/// The text field on the line of [label].
Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
  matching: find.byType(TextField),
);

void _largeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('typing the loan makes price and payment computed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The input panel comes first, so `.first` is its label.
    Finder block(String label) => find
        .ancestor(of: find.text(label).first, matching: find.byType(Column))
        .first;
    bool computed(String label) => find
        .descendant(
          of: find
              .ancestor(of: find.text(label).first, matching: find.byType(Row))
              .first,
          matching: find.text('Calculé'),
        )
        .evaluate()
        .isNotEmpty;

    await tester.pumpWidget(const SimmoApp());
    expect(computed('Prix du bien'), isTrue);
    expect(computed('Montant emprunté'), isTrue);
    expect(computed('Mensualité'), isFalse);

    await tester.enterText(
      find.descendant(
        of: block('Montant emprunté'),
        matching: find.byType(TextField),
      ),
      '200000',
    );
    await tester.pump();

    expect(computed('Montant emprunté'), isFalse);
    expect(computed('Prix du bien'), isTrue);
    expect(computed('Mensualité'), isTrue);
  });

  testWidgets('switching to the all-in effort keeps the effort', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SimmoApp());
    // 35% of 4,000 €.
    expect(
      find.text(
        'Soit ${euros(1400, cents: true)} par mois, assurance comprise',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Tout compris'));
    await tester.pump();

    expect(find.text(groupDigits('1400')), findsOneWidget);
    expect(find.textContaining('à saisir dans'), findsOneWidget);
  });

  testWidgets('charges and an offer show in the budget and negotiation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Finder field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
      matching: find.byType(TextField),
    );

    await tester.pumpWidget(const SimmoApp());
    expect(find.text('Budget mensuel'), findsOneWidget);
    expect(find.text('Votre offre'), findsNothing);

    await tester.tap(find.text('Budget et négociation'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Charges de copropriété (par mois)'), '245');
    await tester.enterText(field('Votre offre'), '279000');
    await tester.pump();

    expect(find.text(euros(245)), findsOneWidget);
    expect(find.text(euros(279000)), findsOneWidget);
  });

  testWidgets('a new project keeps the buyer, not the property', (
    tester,
  ) async {
    _largeView(tester);
    final saved = await _saved([
      const SimulationInput(
        netMonthlyIncome: 5100,
        firstTimeBuyer: false,
        rate: 0.031,
        address: _address,
        condoFees: 245,
      ),
    ]);

    await tester.pumpWidget(SimmoApp(saved: saved));
    expect(find.text('69 Rue Louis Becker, Villeurbanne'), findsOneWidget);

    await tester.tap(find.text('Nouveau projet'));
    await tester.pump();

    expect(find.text('Projet 2'), findsOneWidget);
    expect(find.textContaining('${euros(5100)} nets par mois'), findsOneWidget);
    expect(saved.active, 1);
    final added = saved.projects[1].input;
    expect(added.netMonthlyIncome, 5100);
    expect(added.firstTimeBuyer, isFalse);
    // The rate of the project shown, its own from now on.
    expect(added.rate, 0.031);
    expect(added.address, isNull);
    expect(added.condoFees, 0);
  });

  testWidgets('the buyer is the same in every project', (tester) async {
    _largeView(tester);
    final saved = await _saved([
      const SimulationInput(address: _address, condoFees: 245, rate: 0.031),
      const SimulationInput(rate: 0.036),
    ]);

    await tester.pumpWidget(SimmoApp(saved: saved));
    expect(find.textContaining('Commune à tous vos projets'), findsOneWidget);
    // Folded once projects are kept.
    expect(find.text('Revenus nets mensuels'), findsNothing);
    await tester.tap(find.text('Votre situation'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Revenus nets mensuels'), '5200');
    await tester.pump();
    await tester.tap(find.text('Projet 2'));
    await tester.pump();

    expect(find.text(groupDigits('5200')), findsOneWidget);
    final [first, second] = saved.projects;
    expect(first.input.netMonthlyIncome, 5200);
    expect(second.input.netMonthlyIncome, 5200);
    // The property and the rate stay their own.
    expect(first.input.condoFees, 245);
    expect(second.input.address, isNull);
    expect(first.input.rate, 0.031);
    expect(second.input.rate, 0.036);
  });

  testWidgets('deleting a project asks first; one always remains', (
    tester,
  ) async {
    _largeView(tester);
    final saved = await _saved([
      const SimulationInput(address: _address),
      const SimulationInput(netMonthlyIncome: 5100),
    ]);

    await tester.pumpWidget(SimmoApp(saved: saved));
    await tester.tap(find.byTooltip('Supprimer le projet'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce projet ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(saved.projects, hasLength(2));

    await tester.tap(find.byTooltip('Supprimer le projet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('69 Rue Louis Becker, Villeurbanne'), findsNothing);
    expect(saved.projects.single.input.netMonthlyIncome, 5100);

    // The last project gives way to a new one, for the same buyer.
    await tester.tap(find.byTooltip('Supprimer le projet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Projet 1'), findsOneWidget);
    expect(saved.projects.single.input.netMonthlyIncome, 5100);
  });

  testWidgets('a shared simulation is shown apart, never kept', (tester) async {
    _largeView(tester);
    final saved = await _saved([const SimulationInput(netMonthlyIncome: 5100)]);

    await tester.pumpWidget(
      SimmoApp(
        saved: saved,
        sharedFragment: encodeInput(
          const SimulationInput(netMonthlyIncome: 3000),
        ),
      ),
    );
    expect(find.text('Lien partagé'), findsOneWidget);
    expect(find.textContaining('Celle du lien partagé'), findsOneWidget);
    await tester.tap(find.text('Votre situation'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Revenus nets mensuels'), '3300');
    await tester.pump();
    expect(saved.projects.single.input.netMonthlyIncome, 5100);

    await tester.tap(find.text('Projet 1'));
    await tester.pump();
    expect(find.text(groupDigits('5100')), findsOneWidget);

    await tester.tap(find.text('Lien partagé'));
    await tester.pump();
    expect(find.text(groupDigits('3300')), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pump();
    expect(find.text('Lien partagé'), findsNothing);
  });
}
