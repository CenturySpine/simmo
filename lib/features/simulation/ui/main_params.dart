import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/number_field.dart';
import '../../../shared/section_card.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';
import '../domain/simulator.dart';
import 'debt_ratio_color.dart';

/// Range of the debt ratio slider (no cap: the colour is the guard-rail).
const minDebtRatio = 0.05;
const maxDebtRatio = 0.50;

/// The five main parameters, all editable; the two computed ones show the
/// result and adapt to the others.
class MainParams extends StatelessWidget {
  const MainParams({
    super.key,
    required this.input,
    required this.result,
    required this.onEdit,
    required this.onChanged,
    required this.onEffortMode,
  });

  final SimulationInput input;
  final SimulationResult result;

  /// A main parameter was typed: it becomes an input.
  final void Function(MainField field, SimulationInput input) onEdit;

  /// Any other parameter changed.
  final ValueChanged<SimulationInput> onChanged;
  final ValueChanged<EffortMode> onEffortMode;

  bool _computed(MainField field) => input.computed.contains(field);

  @override
  Widget build(BuildContext context) {
    Widget money(
      MainField field,
      String label,
      double inputValue,
      double computedValue,
      SimulationInput Function(double) apply, {
      String? note,
    }) => _ParamBlock(
      label: label,
      computed: _computed(field),
      note: note,
      editor: NumberField(
        value: _computed(field) ? computedValue : inputValue,
        highlight: _computed(field),
        onChanged: (v) => onEdit(field, apply(v)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Projet',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Les deux valeurs « calculées » s’ajustent à vos saisies.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              money(
                MainField.price,
                'Prix du bien',
                input.price,
                result.price,
                (v) => input.copyWith(price: v),
              ),
              money(
                MainField.downPayment,
                'Apport',
                input.downPayment,
                result.downPayment,
                (v) => input.copyWith(downPayment: v),
                note:
                    '${(result.downPaymentShare * 100).round()} % du coût total',
              ),
              money(
                MainField.loan,
                'Montant emprunté',
                input.loanAmount,
                result.borrowed,
                (v) => input.copyWith(loanAmount: v),
              ),
              _ParamBlock(
                label: 'Durée',
                computed: _computed(MainField.duration),
                editor: _DurationSlider(
                  months: _computed(MainField.duration)
                      ? result.durationMonths
                      : input.durationMonths,
                  onChanged: (months) => onEdit(
                    MainField.duration,
                    input.copyWith(durationMonths: months),
                  ),
                ),
              ),
              _ParamBlock(
                label: 'Mensualité',
                computed: _computed(MainField.payment),
                editor: _EffortEditor(
                  input: input,
                  result: _computed(MainField.payment) ? result : null,
                  onEdit: (i) => onEdit(MainField.payment, i),
                  onEffortMode: onEffortMode,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Revenus et taux',
          child: Column(
            children: [
              _InlineField(
                'Revenus nets mensuels',
                NumberField(
                  value: input.netMonthlyIncome,
                  decimals: 2,
                  onChanged: (v) =>
                      onChanged(input.copyWith(netMonthlyIncome: v)),
                ),
              ),
              _InlineField(
                'Revenu fiscal de référence N-2',
                NumberField(
                  value: input.referenceTaxIncome,
                  onChanged: (v) =>
                      onChanged(input.copyWith(referenceTaxIncome: v)),
                ),
              ),
              _InlineField(
                'Taux du prêt',
                NumberField(
                  value: input.rate,
                  scale: 100,
                  decimals: 2,
                  suffix: '%',
                  onChanged: (v) => onChanged(input.copyWith(rate: v)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParamBlock extends StatelessWidget {
  const _ParamBlock({
    required this.label,
    required this.computed,
    required this.editor,
    this.note,
  });

  final String label;
  final bool computed;
  final Widget editor;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Expanded(child: Text(label, style: text.titleSmall)),
                if (computed) const _ComputedPill(),
              ],
            ),
          ),
          const SizedBox(height: 6),
          editor,
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ComputedPill extends StatelessWidget {
  const _ComputedPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calculate,
              size: 16,
              color: AppColors.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              'Calculé',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppColors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.months, required this.onChanged});

  final int months;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final years = (months / 12).round().clamp(1, 30);
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: years.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            label: durationLabel(years * 12),
            onChanged: (v) => onChanged(v.round() * 12),
          ),
        ),
        SizedBox(
          width: 110,
          child: Text(
            durationLabel(months),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

/// Monthly effort as a debt ratio, the loan payment or the whole housing
/// cost. Shows [result] when the payment is computed.
class _EffortEditor extends StatelessWidget {
  const _EffortEditor({
    required this.input,
    required this.result,
    required this.onEdit,
    required this.onEffortMode,
  });

  final SimulationInput input;
  final SimulationResult? result;
  final ValueChanged<SimulationInput> onEdit;
  final ValueChanged<EffortMode> onEffortMode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mode = input.effortMode;
    final income = retainedIncome(input);
    final r = result;
    // Computed, or what the effort allows.
    final payment = r?.monthlyPayment ?? targetMonthly(input);
    final ratio =
        r?.debtRatioAfter ??
        (mode == EffortMode.debtRatio
            ? input.debtRatio
            : income > 0
            ? (payment + input.otherLoans) / income
            : 0.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<EffortMode>(
          segments: [
            for (final (value, label) in const [
              (EffortMode.debtRatio, 'Endettement'),
              (EffortMode.payment, 'Montant'),
              (EffortMode.allIn, 'Tout compris'),
            ])
              ButtonSegment(
                value: value,
                // Three labels on a phone: shrink rather than wrap.
                label: FittedBox(child: Text(label, maxLines: 1)),
              ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onEffortMode(s.first),
        ),
        const SizedBox(height: 12),
        switch (mode) {
          EffortMode.debtRatio => Row(
            children: [
              Expanded(
                child: Slider(
                  value: ratio.clamp(minDebtRatio, maxDebtRatio),
                  min: minDebtRatio,
                  max: maxDebtRatio,
                  divisions: 90,
                  label: percent(ratio, decimals: 1),
                  onChanged: (v) => onEdit(input.copyWith(debtRatio: v)),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  percent(ratio, decimals: 1),
                  textAlign: TextAlign.end,
                  style: text.titleMedium?.copyWith(
                    color: debtRatioColor(ratio),
                  ),
                ),
              ),
            ],
          ),
          EffortMode.payment => NumberField(
            value: payment,
            decimals: 2,
            suffix: '€/mois',
            highlight: r != null,
            onChanged: (v) => onEdit(input.copyWith(monthlyPayment: v)),
          ),
          EffortMode.allIn => NumberField(
            value: payment + input.runningCosts,
            decimals: 2,
            suffix: '€/mois',
            highlight: r != null,
            onChanged: (v) => onEdit(input.copyWith(housingBudget: v)),
          ),
        },
        const SizedBox(height: 6),
        Text(
          switch (mode) {
            EffortMode.debtRatio =>
              'Soit ${euros(payment, cents: true)} par mois, assurance comprise',
            EffortMode.payment => 'Soit ${percent(ratio)} d’endettement',
            EffortMode.allIn =>
              'Dont ${euros(payment, cents: true)} de mensualité, soit '
                  '${percent(ratio)} d’endettement',
          },
          style: text.bodySmall?.copyWith(
            color: mode == EffortMode.debtRatio ? null : debtRatioColor(ratio),
          ),
        ),
        if (mode == EffortMode.allIn && input.runningCosts == 0) ...[
          const SizedBox(height: 4),
          Text(
            'Charges, taxe foncière, énergie : à saisir dans « Bien, budget '
            'et négociation ».',
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Label on the left, compact field on the right.
class _InlineField extends StatelessWidget {
  const _InlineField(this.label, this.field);

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 170, child: field),
        ],
      ),
    );
  }
}
