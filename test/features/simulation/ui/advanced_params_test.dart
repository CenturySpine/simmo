import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';

void main() {
  testWidgets('age can be typed digit by digit', (tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SimmoApp());
    await tester.tap(find.text('Paramètres avancés'));
    await tester.pumpAndSettle();

    final ageField = find.descendant(
      of: find
          .ancestor(
            of: find.text('Âge de l’emprunteur'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(TextField),
    );
    String text() => tester.widget<TextField>(ageField).controller!.text;

    await tester.enterText(ageField, '4');
    await tester.pump();
    expect(text(), '4');

    await tester.enterText(ageField, '42');
    await tester.pump();
    expect(text(), '42');
    // Bank contract in the forties.
    expect(find.text('0,44'), findsOneWidget);
  });
}
