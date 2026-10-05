import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../shared/number_field.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';
import 'commune_field.dart';

/// The buyer's situation, the same in every project: income, household and
/// current housing. Open on a first visit, folded afterwards.
class BuyerParams extends StatelessWidget {
  const BuyerParams({
    super.key,
    required this.input,
    required this.result,
    required this.onChanged,
    required this.wide,
    required this.initiallyExpanded,
    this.shared = false,
  });

  final SimulationInput input;
  final SimulationResult result;
  final ValueChanged<SimulationInput> onChanged;

  /// Income and household side by side.
  final bool wide;
  final bool initiallyExpanded;

  /// The situation of a shared simulation, not the user's.
  final bool shared;

  void _set(SimulationInput Function(SimulationInput) change) =>
      onChanged(change(input));

  String get _summary {
    final children = input.children;
    final household = [
      '${euros(input.netMonthlyIncome)} nets par mois',
      if (input.couple) 'en couple',
      if (children > 0) '$children enfant${children > 1 ? 's' : ''}',
    ].join(', ');
    return '$household. '
        '${shared ? 'Celle du lien partagé.' : 'Commune à tous vos projets.'}';
  }

  @override
  Widget build(BuildContext context) {
    final income = [
      const _Group('Revenus'),
      _Field(
        'Revenus nets mensuels',
        NumberField(
          value: input.netMonthlyIncome,
          decimals: 2,
          dense: true,
          onChanged: (v) => _set((i) => i.copyWith(netMonthlyIncome: v)),
        ),
      ),
      _Amount(
        'Revenu fiscal de référence N-2',
        input.referenceTaxIncome,
        (v) => _set((i) => i.copyWith(referenceTaxIncome: v)),
      ),
      _Auto(
        'Taux de prélèvement à la source',
        typed: input.withholdingRate,
        computed: result.withholdingRate,
        scale: 100,
        decimals: 1,
        suffix: '%',
        onChanged: (v) => _set((i) => i.copyWith(withholdingRate: () => v)),
      ),
      _Amount(
        'Revenus locatifs (retenus à 70 %)',
        input.rentalIncome,
        (v) => _set((i) => i.copyWith(rentalIncome: v)),
      ),
      _Amount(
        'Autres crédits (par mois)',
        input.otherLoans,
        (v) => _set((i) => i.copyWith(otherLoans: v)),
      ),
    ];
    final household = [
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
          onChanged: (v) => _set((i) => i.copyWith(children: v.round())),
        ),
      ),
      _Field(
        'Âge de l’emprunteur',
        NumberField(
          value: input.borrowerAge.toDouble(),
          suffix: 'ans',
          dense: true,
          onChanged: (v) => _set((i) => i.copyWith(borrowerAge: v.round())),
        ),
      ),
      _Toggle(
        'Primo-accédant',
        input.firstTimeBuyer,
        (v) => _set((i) => i.copyWith(firstTimeBuyer: v)),
      ),
      const _Group('Logement actuel'),
      _Amount(
        'Loyer (par mois)',
        input.currentRent,
        (v) => _set((i) => i.copyWith(currentRent: v)),
      ),
      _Amount(
        'Charges, énergie et assurance (par mois)',
        input.currentUtilities,
        (v) => _set((i) => i.copyWith(currentUtilities: v)),
      ),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          'Votre situation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(_summary, style: Theme.of(context).textTheme.bodySmall),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: wide
            ? [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: income,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: household,
                      ),
                    ),
                  ],
                ),
              ]
            : [...income, ...household],
      ),
    );
  }
}

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
          CommuneField(
            zone: input.zone,
            onZone: (v) => _set((i) => i.copyWith(zone: v)),
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
          if (existing && !input.firstTimeBuyer)
            _Toggle(
              'Droits de mutation à 5 %',
              input.raisedTransferTax,
              (v) => _set((i) => i.copyWith(raisedTransferTax: v)),
            ),
          _Toggle(
            'DPE A ou B (garantie moins chère)',
            input.efficientHome,
            (v) => _set((i) => i.copyWith(efficientHome: v)),
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
          _Auto(
            'Garantie (barème Crédit Logement)',
            typed: input.guaranteeFees,
            computed: result.guaranteeFees,
            decimals: 2,
            onChanged: (v) => _set((i) => i.copyWith(guaranteeFees: () => v)),
          ),

          const _Group('Assurance emprunteur'),
          _Choice<bool>(
            'Contrat',
            const {true: 'Banque (groupe)', false: 'Délégation'},
            input.bankInsurance,
            (v) => _set((i) => i.copyWith(bankInsurance: v)),
          ),
          _Auto(
            'Taux (sur capital initial)',
            typed: input.insuranceRate,
            computed: result.insuranceRate,
            scale: 100,
            decimals: 3,
            suffix: '%',
            onChanged: (v) => _set((i) => i.copyWith(insuranceRate: () => v)),
          ),
          _Rate(
            'Quotité assurée (totale)',
            input.insuranceCoverage,
            (v) => _set((i) => i.copyWith(insuranceCoverage: v)),
            decimals: 0,
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

/// What the property costs day to day and the prices at stake in the
/// negotiation; all optional, folded away by default.
class BudgetParams extends StatelessWidget {
  const BudgetParams({super.key, required this.input, required this.onChanged});

  final SimulationInput input;
  final ValueChanged<SimulationInput> onChanged;

  void _set(SimulationInput Function(SimulationInput) change) =>
      onChanged(change(input));

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          'Budget et négociation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Charges, taxe foncière, travaux de copro, offre',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Group('Après l’achat'),
          _Amount(
            'Charges de copropriété (par mois)',
            input.condoFees,
            (v) => _set((i) => i.copyWith(condoFees: v)),
          ),
          _Amount(
            'Taxe foncière (par an)',
            input.propertyTax,
            (v) => _set((i) => i.copyWith(propertyTax: v)),
          ),
          _Amount(
            'Énergie et assurance habitation (par mois)',
            input.utilities,
            (v) => _set((i) => i.copyWith(utilities: v)),
          ),

          const _Group('Travaux de copropriété'),
          _Amount(
            'Appels de fonds à payer à l’achat',
            input.condoCalls,
            (v) => _set((i) => i.copyWith(condoCalls: v)),
          ),
          _Amount(
            'Votre part des travaux à venir',
            input.condoWorks,
            (v) => _set((i) => i.copyWith(condoWorks: v)),
          ),
          _Field(
            'Dans combien d’années',
            NumberField(
              value: input.condoWorksYears.toDouble(),
              suffix: 'ans',
              dense: true,
              onChanged: (v) =>
                  _set((i) => i.copyWith(condoWorksYears: v.round())),
            ),
          ),

          const _Group('Négociation'),
          _Amount(
            'Prix affiché',
            input.askingPrice,
            (v) => _set((i) => i.copyWith(askingPrice: v)),
          ),
          _Amount(
            'Votre offre',
            input.offerPrice,
            (v) => _set((i) => i.copyWith(offerPrice: v)),
          ),
          _Amount(
            'Votre plafond',
            input.maxPrice,
            (v) => _set((i) => i.copyWith(maxPrice: v)),
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

/// A value computed by the simulator unless the user types one; the reset
/// button brings the computed value back.
class _Auto extends StatelessWidget {
  const _Auto(
    this.label, {
    required this.typed,
    required this.computed,
    required this.onChanged,
    this.scale = 1,
    this.decimals = 0,
    this.suffix = '€',
  });

  final String label;
  final double? typed;
  final double computed;
  final ValueChanged<double?> onChanged;
  final double scale;
  final int decimals;
  final String suffix;

  @override
  Widget build(BuildContext context) => _Field(
    label,
    NumberField(
      value: typed ?? computed,
      scale: scale,
      decimals: decimals,
      suffix: suffix,
      dense: true,
      highlight: typed == null,
      onChanged: onChanged,
    ),
    trailing: typed == null
        ? null
        : IconButton(
            tooltip: 'Revenir à la valeur calculée',
            icon: const Icon(Icons.restart_alt, size: 20),
            onPressed: () => onChanged(null),
          ),
  );
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
