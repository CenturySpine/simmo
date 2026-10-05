import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/features/simulation/domain/project.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';

void main() {
  test('a project is named after its address', () {
    const address = PropertyAddress(
      label: '69 Rue Louis Becker 69100 Villeurbanne',
      lat: 45.765293,
      lon: 4.871044,
      citycode: '69266',
    );
    expect(const Project(SimulationInput()).name(2), 'Projet 2');
    expect(
      const Project(SimulationInput(address: address)).name(2),
      '69 Rue Louis Becker, Villeurbanne',
    );
  });

  test('a shared simulation counts its inputs as typed', () {
    final project = Project.received(
      const SimulationInput(computed: {MainField.price, MainField.payment}),
    );
    expect(project.typed, [
      MainField.downPayment,
      MainField.loan,
      MainField.duration,
    ]);
  });
}
