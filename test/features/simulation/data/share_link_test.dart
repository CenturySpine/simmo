import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/app.dart';
import 'package:simmo/features/simulation/data/share_link.dart';
import 'package:simmo/features/simulation/domain/simulation_input.dart';
import 'package:simmo/features/simulation/domain/simulator.dart';

/// Every parameter away from its default, optional ones set.
final _custom = const SimulationInput().copyWith(
  computed: {MainField.downPayment, MainField.payment},
  price: 287500,
  downPayment: 41000.5,
  loanAmount: 255000,
  durationMonths: 262,
  effortMode: EffortMode.payment,
  debtRatio: 0.31,
  monthlyPayment: 1480.75,
  netMonthlyIncome: 5123.4,
  referenceTaxIncome: 52000,
  rate: 0.0325,
  propertyKind: PropertyKind.newBuild,
  dwellingType: DwellingType.house,
  zone: PtzZone.b2,
  firstTimeBuyer: false,
  raisedTransferTax: false,
  works: 12000,
  agencyFees: 8000,
  furniture: 4000,
  notaryMiscFees: 1500,
  bankFees: 800,
  brokerFees: 0,
  guaranteeFees: () => 2100,
  efficientHome: true,
  borrowerAge: 41,
  bankInsurance: false,
  insuranceRate: () => 0.0018,
  insuranceCoverage: 2,
  couple: true,
  children: 2,
  otherLoans: 150,
  currentRent: 950,
  rentalIncome: 600,
  withholdingRate: () => 0.087,
  ptzEnabled: true,
  actionLogement: 20000,
  smoothing: false,
  condoFees: 245.6,
  propertyTax: 1128,
  utilities: 70,
  currentUtilities: 90,
  condoCalls: 210,
  condoWorks: 9000,
  condoWorksYears: 8,
  askingPrice: 299000,
  offerPrice: 279000,
  maxPrice: 285000,
);

void main() {
  test('the link points to the site and keeps every parameter', () {
    final link = shareLink(_custom);
    expect(link, startsWith('https://simmo.centuryspine.org/#'));
    // A short opaque code, not a list of parameters.
    expect(link.length, lessThan(180));
    expect(link, isNot(contains('&')));

    final decoded = decodeInput(Uri.parse(link).fragment)!;
    expect(encodeInput(decoded), encodeInput(_custom));
    expect(decoded.computed, {MainField.downPayment, MainField.payment});
    expect(decoded.withholdingRate, 0.087);
    expect(decoded.zone, PtzZone.b2);
    expect(decoded.condoFees, 245.6);
    expect(decoded.condoWorksYears, 8);
    expect(decoded.maxPrice, 285000);
  });

  test('links shared before the housing budget still open', () {
    // Version 1 code, from before the housing budget was added.
    final decoded = decodeInput(
      'ARSWJLDh2g3Sn_oBwOf7CsCpB4C1GICS9AEAAACA4gmgjQbQ2REAmOYFAADgz9UBsK4VgK3'
      'iBNCMAawCIwI',
    )!;
    expect(decoded.price, 287500);
    expect(decoded.currentRent, 950);
    expect(decoded.insuranceRate, 0.0018);
    expect(decoded.children, 2);
    expect(decoded.condoFees, 0);
    expect(decoded.condoWorksYears, 10);
    expect(simulate(decoded).monthlyPayment, closeTo(1185.93, 0.01));
  });

  test('the shared simulation gives the same results', () {
    final shared = decodeInput(encodeInput(_custom))!;
    final a = simulate(_custom);
    final b = simulate(shared);
    expect(b.downPayment, a.downPayment);
    expect(b.monthlyPayment, a.monthlyPayment);
    expect(b.creditCost, a.creditCost);
  });

  test('optional values left out stay computed by the app', () {
    final decoded = decodeInput(encodeInput(const SimulationInput()))!;
    expect(decoded.guaranteeFees, isNull);
    expect(decoded.insuranceRate, isNull);
    expect(decoded.withholdingRate, isNull);
  });

  test('a fragment without a simulation is ignored', () {
    expect(decodeInput(''), isNull);
    expect(decodeInput('section=2'), isNull);
  });

  testWidgets('opening a link restores it, Partager copies it', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await tester.pumpWidget(SimmoApp(sharedFragment: encodeInput(_custom)));
    // The price typed in the shared simulation.
    expect(find.text('287 500'), findsOneWidget);

    await tester.tap(find.text('Partager'));
    await tester.pump();
    expect(copied, shareLink(_custom));
    expect(find.text('Lien de la simulation copié'), findsOneWidget);
  });

  testWidgets('the link is shown when the clipboard is refused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.setData'
          ? throw PlatformException(code: 'copy_fail')
          : null,
    );

    await tester.pumpWidget(SimmoApp(sharedFragment: encodeInput(_custom)));
    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();

    expect(find.text('Lien de la simulation'), findsOneWidget);
    expect(find.text(shareLink(_custom)), findsOneWidget);
  });
}
