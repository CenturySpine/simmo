import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';

void main() {
  testWidgets('home page shows the app name and promise', (tester) async {
    await tester.pumpWidget(const SimmoApp());

    expect(find.text('Simmo'), findsOneWidget);
    expect(
      find.text('Simulez votre prêt immobilier comme un courtier.'),
      findsOneWidget,
    );
  });
}
