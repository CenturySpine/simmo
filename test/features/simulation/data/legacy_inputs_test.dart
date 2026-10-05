import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/features/simulation/data/legacy_inputs.dart';
import 'package:simmo/features/simulation/data/saved_projects.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  // The zoning list is an asset.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('values kept before projects become the first project', () async {
    SharedPreferences.setMockInitialValues({
      'price': '300000.0',
      'netMonthlyIncome': '3210.5',
      'referenceTaxIncome': '36000.0',
      'rate': '0.034',
      'borrowerAge': '42.0',
      'withholdingRate': '0.12',
      'condoFees': '245.6',
      'condoWorksYears': '8.0',
      'offerPrice': '279000.0',
      'surface': '69.61',
      'address':
          '{"label":"69 Rue Louis Becker 69100 Villeurbanne",'
          '"lat":45.765293,"lon":4.871044,"citycode":"69266"}',
    });
    final prefs = await SharedPreferences.getInstance();

    await migrateLegacyInputs(prefs);

    final projects = SavedProjects(prefs).projects;
    expect(projects, hasLength(1));
    final input = projects.single.input;
    expect(input.price, 300000);
    expect(input.netMonthlyIncome, 3210.5);
    expect(input.referenceTaxIncome, 36000);
    expect(input.rate, 0.034);
    expect(input.borrowerAge, 42);
    expect(input.withholdingRate, 0.12);
    expect(input.condoFees, 245.6);
    expect(input.condoWorksYears, 8);
    expect(input.offerPrice, 279000);
    expect(input.surface, 69.61);
    expect(input.address?.citycode, '69266');
    // The zone was not kept: Villeurbanne is in zone A.
    expect(input.zone, PtzZone.a);
    // The typed price stays an input.
    expect(projects.single.typed, [MainField.price]);
    expect(input.computed, isNot(contains(MainField.price)));
    // The old keys are gone.
    expect(prefs.getKeys(), {'projects', 'activeProject'});
  });

  test('a computed price was not kept: it stays computed', () async {
    SharedPreferences.setMockInitialValues({'netMonthlyIncome': '3210.5'});
    final prefs = await SharedPreferences.getInstance();

    await migrateLegacyInputs(prefs);

    final project = SavedProjects(prefs).projects.single;
    expect(project.input.netMonthlyIncome, 3210.5);
    expect(project.typed, isEmpty);
    expect(project.input.computed, contains(MainField.price));
  });

  test('nothing kept, nothing to move', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await migrateLegacyInputs(prefs);

    expect(prefs.getKeys(), isEmpty);
  });
}
