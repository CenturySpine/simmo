import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../shared/external_link.dart';
import '../../../shared/section_card.dart';
import '../data/nearby_sales.dart';
import '../domain/market.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';

/// Recorded sales around the property, fetched again when its address or
/// kind changes.
class NearbySalesCard extends StatefulWidget {
  const NearbySalesCard({super.key, required this.input, required this.result});

  /// Has an address.
  final SimulationInput input;
  final SimulationResult result;

  @override
  State<NearbySalesCard> createState() => _NearbySalesCardState();
}

class _NearbySalesCardState extends State<NearbySalesCard> {
  /// Sales listed before "see all".
  static const _shown = 8;

  late Future<NearbySales> _sales;
  late Object _query;
  var _all = false;

  Object _queryOf(SimulationInput i) =>
      (i.address, i.dwellingType, i.propertyKind);

  void _load() {
    final i = widget.input;
    _query = _queryOf(i);
    _all = false;
    _sales = fetchNearbySales(
      i.address!,
      dwelling: i.dwellingType,
      kind: i.propertyKind,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(NearbySalesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_queryOf(widget.input) != _query) _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Ventes autour',
      child: FutureBuilder(
        future: _sales,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Ventes indisponibles pour le moment.',
                    style: text.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('Réessayer'),
                ),
              ],
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          return _content(context, data);
        },
      ),
    );
  }

  Widget _content(BuildContext context, NearbySales data) {
    final text = Theme.of(context).textTheme;
    if (data.sales.isEmpty) {
      return Text(
        'Aucune vente trouvée à moins de 500 m. Les données ne couvrent ni '
        'l’Alsace-Moselle ni Mayotte.',
        style: text.bodyMedium,
      );
    }
    final surface = widget.input.surface;
    final comparable = surface > 0
        ? comparableSales(data.sales, surface).toList()
        : data.sales;
    final listed = _all ? comparable : comparable.take(_shown);
    final until = data.until;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ColumnsRow.header(['Médiane']),
        _statsRow('Toutes surfaces', marketStats(data.sales)),
        if (surface > 0)
          _statsRow(
            'De ${(surface * (1 - comparableMargin)).round()} à '
            '${(surface * (1 + comparableMargin)).round()} m²',
            marketStats(comparable),
          ),
        if (surface > 0)
          ColumnsRow(
            'Votre prix',
            [perSqm(widget.result.price / surface)],
            note: euros(widget.result.price),
            strong: true,
          ),
        if (comparable.isNotEmpty) ...[
          const Divider(height: 24),
          const ColumnsRow.header([
            'Prix/m²',
          ], trailing: SizedBox(width: _SaleLinks.width)),
          for (final sale in listed)
            ColumnsRow(
              sale.address,
              [perSqm(sale.pricePerSqm)],
              note: [
                shortDate(sale.date),
                '${sale.surface.round()} m²',
                if (sale.rooms > 0) '${sale.rooms} p.',
                euros(sale.price),
                if (sale.outbuildings > 0)
                  '${sale.outbuildings} dépendance${sale.outbuildings > 1 ? 's' : ''}',
              ].join(' · '),
              trailing: _SaleLinks(sale),
            ),
          if (comparable.length > _shown)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _all = !_all),
                child: Text(
                  _all ? 'Voir moins' : 'Voir les ${comparable.length} ventes',
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Ventes réelles à moins de 500 m en ${data.years.join(' et ')} '
          '(DVF, impôts)${until == null ? '' : ', publiées jusqu’au '
                    '${shortDate(until)}'}. Les dépendances (cave, garage, '
          'parking : la source ne dit pas lesquelles) sont comprises dans le '
          'prix.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Widget _statsRow(String label, MarketStats? stats) => ColumnsRow(
    label,
    [stats == null ? '—' : perSqm(stats.median)],
    note: stats == null
        ? 'Aucune vente'
        : '${stats.count} vente${stats.count > 1 ? 's' : ''}, la moitié '
              'entre ${groupDigits(stats.low.round().toString())} et '
              '${perSqm(stats.high)}',
  );
}

/// Where to check a sale: its address on a map, its official record.
class _SaleLinks extends StatelessWidget {
  const _SaleLinks(this.sale);

  static const width = 32.0;

  final Sale sale;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: width,
    child: PopupMenuButton<Uri>(
      tooltip: 'Voir',
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      onSelected: (url) => openExternal(url.toString()),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: saleMapUrl(sale),
          child: const ListTile(
            leading: Icon(Icons.place_outlined),
            title: Text('Voir l’adresse (Google Maps)'),
          ),
        ),
        PopupMenuItem(
          value: saleSourceUrl(sale),
          child: const ListTile(
            leading: Icon(Icons.open_in_new),
            title: Text('Voir la vente (source DVF, data.gouv.fr)'),
          ),
        ),
      ],
    ),
  );
}
