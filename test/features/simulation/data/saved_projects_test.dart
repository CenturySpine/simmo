import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simmo/features/simulation/data/saved_projects.dart';
import 'package:simmo/features/simulation/data/share_link.dart';
import 'package:simmo/features/simulation/domain/project.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  test('every value of every project is kept, then cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = SavedProjects(await SharedPreferences.getInstance());
    final custom = const SimulationInput().copyWith(
      computed: {MainField.downPayment, MainField.payment},
      downPayment: 41000.5,
      durationMonths: 240,
      zone: PtzZone.b2,
      couple: true,
      surface: 69.61,
      address: () => const PropertyAddress(
        label: '69 Rue Louis Becker 69100 Villeurbanne',
        lat: 45.765293,
        lon: 4.871044,
        citycode: '69266',
      ),
    );

    await saved.save([
      const Project(SimulationInput()),
      Project(custom, const [MainField.price, MainField.loan]),
    ], 1);

    final projects = saved.projects;
    expect(projects, hasLength(2));
    expect(saved.active, 1);
    expect(projects[0].typed, isEmpty);
    expect(projects[1].typed, [MainField.price, MainField.loan]);
    expect(encodeInput(projects[1].input), encodeInput(custom));

    await saved.clear();
    expect(saved.projects, isEmpty);
    expect(saved.active, 0);
  });
}
