import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/communes.dart';
import '../domain/simulation_input.dart';

/// Commune search: picking a commune sets the zone from the official ABC
/// zoning list, loaded on first use.
class CommuneField extends StatefulWidget {
  const CommuneField({super.key, required this.zone, required this.onZone});

  final PtzZone zone;
  final ValueChanged<PtzZone> onZone;

  @override
  State<CommuneField> createState() => _CommuneFieldState();
}

class _CommuneFieldState extends State<CommuneField> {
  Future<List<Commune>>? _communes;
  Commune? _picked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Hidden once the zone is changed by hand.
    final picked = _picked?.zone == widget.zone ? _picked : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Commune du bien', style: text.bodyMedium),
          const SizedBox(height: 6),
          Autocomplete<Commune>(
            displayStringForOption: (c) => c.label,
            optionsBuilder: (value) async {
              if (value.text.trim().length < 2) return const [];
              final communes = await (_communes ??= loadCommunes());
              return searchCommunes(communes, value.text);
            },
            onSelected: (commune) {
              setState(() => _picked = commune);
              widget.onZone(commune.zone);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Nom de la commune',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.control),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 280,
                    maxWidth: 360,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final commune in options)
                        ListTile(
                          dense: true,
                          title: Text(commune.label),
                          trailing: Text(
                            'Zone ${commune.zoneName}',
                            style: text.labelMedium,
                          ),
                          onTap: () => onSelected(commune),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (picked != null) ...[
            const SizedBox(height: 6),
            Text(
              'Zone ${picked.zoneName} (zonage ABC officiel)',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
