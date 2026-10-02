import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';
import 'package:simmo/features/simulation/data/communes.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('search ignores case, accents and "saint"', () {
    expect(searchKey('Saint-Étienne'), 'st etienne');
    expect(searchKey('L’Haÿ-les-Roses'), 'l hay les roses');
  });

  test('official list gives the zone of a commune', () async {
    final communes = await loadCommunes();
    expect(communes.length, greaterThan(34000));
    final paris = searchCommunes(communes, 'paris').first;
    expect(paris.label, 'Paris (75)');
    expect(paris.zoneName, 'A bis');
    expect(paris.zone, PtzZone.a);
    expect(searchCommunes(communes, 'lyon').first.zone, PtzZone.a);
    final stEtienne = searchCommunes(communes, 'st etienne').first;
    expect(stEtienne.label, 'Saint-Étienne (42)');
    expect(stEtienne.zone, PtzZone.b2);
  });

  test('an INSEE code gives the commune, arrondissements their city', () async {
    final communes = await loadCommunes();
    expect(communeByCode(communes, '69266')?.name, 'Villeurbanne');
    expect(communeByCode(communes, '69386')?.name, 'Lyon');
    expect(communeByCode(communes, '75115')?.zoneName, 'A bis');
    expect(communeByCode(communes, '13208')?.name, 'Marseille');
    expect(communeByCode(communes, '00000'), isNull);
  });

  testWidgets('picking a commune sets the zone', (tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SimmoApp());
    await tester.tap(find.text('Paramètres avancés'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de la commune'),
        'Saint-Etienne',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saint-Étienne (42)'));
    await tester.pumpAndSettle();

    expect(find.text('Zone B2 (zonage ABC officiel)'), findsOneWidget);
  });
}
