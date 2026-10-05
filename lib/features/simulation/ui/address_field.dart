import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/communes.dart';
import '../data/geocoding.dart';
import '../domain/simulation_input.dart';

/// Address search (IGN geocoding). Picking an address also gives the zone,
/// from the official ABC zoning list.
class AddressField extends StatefulWidget {
  const AddressField({
    super.key,
    required this.address,
    required this.onChanged,
  });

  final PropertyAddress? address;

  /// The picked address and its zone (null when the commune is not listed);
  /// a null address when cleared.
  final void Function(PropertyAddress? address, PtzZone? zone) onChanged;

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  Future<List<Commune>>? _communes;

  Future<void> _pick(PropertyAddress address) async {
    final communes = await (_communes ??= loadCommunes());
    widget.onChanged(address, communeByCode(communes, address.citycode)?.zone);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Adresse', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Autocomplete<PropertyAddress>(
            // A new key resets the text when the address changes elsewhere
            // (shared link, cleared).
            key: ValueKey(widget.address),
            initialValue: TextEditingValue(text: widget.address?.label ?? ''),
            displayStringForOption: (a) => a.label,
            optionsBuilder: (value) async => value.text.trim().length < 3
                ? const []
                : await searchAddresses(value.text),
            onSelected: _pick,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSubmitted(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'N°, rue, commune',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: widget.address == null
                        ? null
                        : IconButton(
                            tooltip: 'Effacer l’adresse',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => widget.onChanged(null, null),
                          ),
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
                    maxWidth: 400,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      for (final address in options)
                        ListTile(
                          dense: true,
                          title: Text(address.label),
                          onTap: () => onSelected(address),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
