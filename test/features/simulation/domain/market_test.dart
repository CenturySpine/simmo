import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/features/simulation/domain/market.dart';

Sale _sale(double surface, double price) => Sale(
  date: DateTime(2025, 11, 14),
  address: '69 rue Louis Becker',
  commune: 'Villeurbanne',
  surface: surface,
  rooms: 3,
  price: price,
  outbuildings: 1,
  distance: 20,
  parcel: '69266000BN0052',
  lat: 45.765465,
  lon: 4.871204,
);

void main() {
  test('median and quartiles of the price per m²', () {
    final stats = marketStats([
      _sale(50, 150000), // 3 000
      _sale(50, 175000), // 3 500
      _sale(50, 200000), // 4 000
      _sale(50, 225000), // 4 500
      _sale(50, 250000), // 5 000
    ])!;
    expect(stats.count, 5);
    expect(stats.low, 3500);
    expect(stats.median, 4000);
    expect(stats.high, 4500);
    // An even count interpolates between the two middle values.
    expect(marketStats([_sale(50, 150000), _sale(50, 200000)])!.median, 3500);
    expect(marketStats([]), isNull);
  });

  test('comparable sales are within 20% of the surface', () {
    final sales = [_sale(55, 1), _sale(56, 1), _sale(84, 1), _sale(85, 1)];
    expect(comparableSales(sales, 70).map((s) => s.surface), [56, 84]);
  });
}
