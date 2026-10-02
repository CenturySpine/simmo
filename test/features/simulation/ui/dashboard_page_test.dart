import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';
import 'package:simmo/core/format.dart';

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

    await tester.tap(find.text('Bien, budget et négociation'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Charges de copropriété (par mois)'), '245');
    await tester.enterText(field('Votre offre'), '279000');
    await tester.pump();

    expect(find.text(euros(245)), findsOneWidget);
    expect(find.text(euros(279000)), findsOneWidget);
  });
}
