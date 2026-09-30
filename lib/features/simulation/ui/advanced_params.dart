import 'package:flutter/material.dart';

import '../../../shared/number_field.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';

/// Everything banks and brokers look at, preset to usual values and folded
/// away by default.
class AdvancedParams extends StatelessWidget {
  const AdvancedParams({
    super.key,
    required this.input,
    required this.result,
    required this.onChanged,
  });

  final SimulationInput input;
  final SimulationResult result;
  final ValueChanged<SimulationInput> onChanged;

  void _set(SimulationInput Function(SimulationInput) change) =>
      onChanged(change(input));

  @override
  Widget build(BuildContext context) {
    final existing = input.propertyKind == PropertyKind.existing;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'Paramètres avancés',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Préréglés aux valeurs usuelles',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Group('Bien'),
          _Choice<PropertyKind>(
            'Type',
            const {
              PropertyKind.existing: 'Ancien',
              PropertyKind.newBuild: 'Neuf',
            },
            input.propertyKind,
            (v) => _set((i) => i.copyWith(propertyKind: v)),
          ),
          _Choice<DwellingType>(
            'Logement',
            const {
              DwellingType.apartment: 'Appartement',
              DwellingType.house: 'Maison',
            },
            input.dwellingType,
            (v) => _set((i) => i.copyWith(dwellingType: v)),
          ),
          _Choice<PtzZone>(
            'Zone',
            const {
              PtzZone.a: 'A',
              PtzZone.b1: 'B1',
              PtzZone.b2: 'B2',
              PtzZone.c: 'C',
            },
            input.zone,
            (v) => _set((i) => i.copyWith(zone: v)),
          ),
          _Toggle(
            'Primo-accédant',
            input.firstTimeBuyer,
            (v) => _set((i) => i.copyWith(firstTimeBuyer: v)),
          ),
          if (existing && !input.firstTimeBuyer)
            _Toggle(
              'Droits de mutation à 5 %',
              input.raisedTransferTax,
              (v) => _set((i) => i.copyWith(raisedTransferTax: v)),
            ),
          _Amount(
            'Travaux',
            input.works,
            (v) => _set((i) => i.copyWith(works: v)),
          ),
          _Amount(
            'Frais d’agence (acquéreur)',
            input.agencyFees,
            (v) => _set((i) => i.copyWith(agencyFees: v)),
          ),
          _Amount(
            'Dont mobilier',
            input.furniture,
            (v) => _set((i) => i.copyWith(furniture: v)),
          ),

          const _Group('Frais'),
          _Amount(
            'Frais de dossier',
            input.bankFees,
            (v) => _set((i) => i.copyWith(bankFees: v)),
          ),
          _Amount(
            'Honoraires de courtage',
            input.brokerFees,
            (v) => _set((i) => i.copyWith(brokerFees: v)),
          ),
          _Amount(
            'Notaire : formalités et débours',
            input.notaryMiscFees,
            (v) => _set((i) => i.copyWith(notaryMiscFees: v)),
          ),
          _Rate(
            'Garantie : part proportionnelle',
            input.guaranteeRate,
            (v) => _set((i) => i.copyWith(guaranteeRate: v)),
            decimals: 3,
          ),
          _Amount(
            'Garantie : part fixe',
            input.guaranteeFixed,
            (v) => _set((i) => i.copyWith(guaranteeFixed: v)),
          ),

          const _Group('Assurance emprunteur'),
          _Rate(
            'Taux (sur capital initial)',
            input.insuranceRate,
            (v) => _set((i) => i.copyWith(insuranceRate: v)),
            decimals: 3,
          ),
          _Rate(
            'Quotité assurée (totale)',
            input.insuranceCoverage,
            (v) => _set((i) => i.copyWith(insuranceCoverage: v)),
            decimals: 0,
          ),

          const _Group('Foyer'),
          _Toggle(
            'En couple',
            input.couple,
            (v) => _set((i) => i.copyWith(couple: v)),
          ),
          _Field(
            'Enfants à charge',
            NumberField(
              value: input.children.toDouble(),
              suffix: '',
              dense: true,
              onChanged: (v) =>
                  _set((i) => i.copyWith(children: v.round().clamp(0, 10))),
            ),
          ),
          _Amount(
            'Autres crédits (par mois)',
            input.otherLoans,
            (v) => _set((i) => i.copyWith(otherLoans: v)),
          ),
          _Amount(
            'Loyer actuel',
            input.currentRent,
            (v) => _set((i) => i.copyWith(currentRent: v)),
          ),
          _Amount(
            'Revenus locatifs (retenus à 70 %)',
            input.rentalIncome,
            (v) => _set((i) => i.copyWith(rentalIncome: v)),
          ),
          _Field(
            'Impôt sur le revenu (par mois)',
            NumberField(
              value: input.monthlyIncomeTax ?? result.incomeTax.roundToDouble(),
              decimals: 2,
              dense: true,
              onChanged: (v) =>
                  _set((i) => i.copyWith(monthlyIncomeTax: () => v)),
            ),
            trailing: input.monthlyIncomeTax == null
                ? null
                : IconButton(
                    tooltip: 'Estimer depuis le revenu fiscal',
                    icon: const Icon(Icons.restart_alt, size: 20),
                    onPressed: () =>
                        _set((i) => i.copyWith(monthlyIncomeTax: () => null)),
                  ),
          ),

          const _Group('Aides'),
          _Toggle(
            'Prêt à taux zéro si éligible',
            input.ptzEnabled,
            (v) => _set((i) => i.copyWith(ptzEnabled: v)),
          ),
          _Amount(
            'Prêt Action Logement (1 %)',
            input.actionLogement,
            (v) => _set((i) => i.copyWith(actionLogement: v)),
          ),
          _Toggle(
            'Lisser les mensualités',
            input.smoothing,
            (v) => _set((i) => i.copyWith(smoothing: v)),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.child, {this.trailing});

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          ?trailing,
          const SizedBox(width: 8),
          SizedBox(width: 140, child: child),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.value, this.onChanged);

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => _Field(
    label,
    NumberField(value: value, dense: true, onChanged: onChanged),
  );
}

class _Rate extends StatelessWidget {
  const _Rate(this.label, this.value, this.onChanged, {this.decimals = 2});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final int decimals;

  @override
  Widget build(BuildContext context) => _Field(
    label,
    NumberField(
      value: value,
      scale: 100,
      decimals: decimals,
      suffix: '%',
      dense: true,
      onChanged: onChanged,
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice(this.label, this.options, this.selected, this.onChanged);

  final String label;
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          SegmentedButton<T>(
            segments: [
              for (final entry in options.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {selected},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
