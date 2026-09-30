import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';

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
}
