import 'package:flutter/foundation.dart';

/// A recorded sale near the property (DVF: deeds registered by the tax
/// office).
@immutable
class Sale {
  const Sale({
    required this.date,
    required this.address,
    required this.commune,
    required this.surface,
    required this.rooms,
    required this.price,
    required this.outbuildings,
    required this.distance,
    required this.parcel,
    required this.lat,
    required this.lon,
  });

  final DateTime date;
  final String address;
  final String commune;
  final double surface;
  final int rooms;
  final double price;

  /// Cellars, garages or parkings sold with it, within the price (DVF does
  /// not tell which).
  final int outbuildings;

  /// In metres.
  final int distance;

  /// Cadastral parcel id (`69266000BN0052`).
  final String parcel;
  final double lat;
  final double lon;

  double get pricePerSqm => price / surface;
}

class NearbySales {
  const NearbySales({
    required this.years,
    required this.until,
    required this.sales,
  });

  /// Years searched, most recent first.
  final List<int> years;

  /// Latest sale published.
  final DateTime? until;

  /// Closest first.
  final List<Sale> sales;
}

/// Median and quartiles of the price per m².
class MarketStats {
  const MarketStats(this.count, this.low, this.median, this.high);

  final int count;
  final double low;
  final double median;
  final double high;
}

MarketStats? marketStats(Iterable<Sale> sales) {
  final values = [for (final sale in sales) sale.pricePerSqm]..sort();
  if (values.isEmpty) return null;
  double at(double share) {
    final position = share * (values.length - 1);
    final below = position.floor();
    final above = position.ceil();
    return values[below] + (values[above] - values[below]) * (position - below);
  }

  return MarketStats(values.length, at(0.25), at(0.5), at(0.75));
}

/// Share of the surface around the property's within which a sale counts
/// as comparable.
const comparableMargin = 0.2;

Iterable<Sale> comparableSales(List<Sale> sales, double surface) => sales.where(
  (sale) => (sale.surface - surface).abs() <= surface * comparableMargin,
);
