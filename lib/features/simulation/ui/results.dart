import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/section_card.dart';
import '../domain/ptz.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';
import 'debt_ratio_color.dart';

/// Headline figure, key metrics and alerts.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.input, required this.result});

  final SimulationInput input;
  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = result;
    // Computed values first, in the order of the input panel.
    final figures = {
      MainField.price: ('Prix du bien', euros(r.price)),
      MainField.downPayment: ('Apport', euros(r.downPayment)),
      MainField.loan: ('Montant emprunté', euros(r.borrowed)),
      MainField.duration: ('Durée', durationLabel(r.durationMonths)),
      MainField.payment: (
        'Mensualité totale',
        euros(r.monthlyPayment, cents: true),
      ),
    };
    final heroes = [
      for (final e in figures.entries)
        if (input.computed.contains(e.key)) e.value,
    ];
    final taeg = r.taeg;
    final ratioColor = debtRatioColor(r.debtRatioAfter);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 40,
            runSpacing: 12,
            children: [
              for (final (label, value) in heroes)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: text.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: text.headlineLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              for (final e in figures.entries)
                if (!input.computed.contains(e.key))
                  _Metric(e.value.$1, e.value.$2),
              _Metric('Coût du crédit', euros(r.creditCost)),
              _Metric('TAEG', taeg == null ? '—' : percent(taeg)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Taux d’endettement', style: text.titleSmall),
              ),
              Text(
                percent(r.debtRatioAfter),
                style: text.titleLarge?.copyWith(color: ratioColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              // 35% sits at 70% of the bar.
              value: (r.debtRatioAfter / 0.5).clamp(0, 1),
              minHeight: 8,
              color: ratioColor,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          if (!r.feasible) ...[
            const SizedBox(height: 12),
            const _Alert('Aucune valeur ne tient avec ces paramètres'),
          ],
        ],
      ),
    );
  }
}

/// Financing plan, loans, tiers and key figures.
class ResultDetails extends StatelessWidget {
  const ResultDetails({super.key, required this.result});

  final SimulationResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FinancingPlan(r),
        const SizedBox(height: 16),
        _Loans(r),
        if (r.tiers.length > 1) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Paliers',
            child: Column(
              children: [
                for (final tier in r.tiers)
                  ValueRow(
                    'Mois ${tier.from} à ${tier.to}',
                    euros(tier.amount, cents: true),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          title: 'Chiffres clés',
          child: Column(
            children: [
              ValueRow('Endettement avant projet', percent(r.debtRatioBefore)),
              ValueRow(
                'Endettement après projet',
                percent(r.debtRatioAfter),
                color: debtRatioColor(r.debtRatioAfter),
              ),
              ValueRow(
                'Reste à vivre avant projet',
                euros(r.residualBefore, cents: true),
              ),
              ValueRow(
                'Reste à vivre après projet',
                euros(r.residualAfter, cents: true),
              ),
              if (r.paymentJump != 0)
                ValueRow('Saut de charge', euros(r.paymentJump, cents: true)),
              ValueRow(
                'Impôt sur le revenu retenu',
                '${euros(r.incomeTax, cents: true)} / mois',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancingPlan extends StatelessWidget {
  const _FinancingPlan(this.r);

  final SimulationResult r;

  @override
  Widget build(BuildContext context) {
    double amountOf(LoanKind kind) => r.loans
        .where((loan) => loan.kind == kind)
        .fold(0, (sum, loan) => sum + loan.amount);
    final ptz = amountOf(LoanKind.ptz);
    final actionLogement = amountOf(LoanKind.actionLogement);
    return SectionCard(
      title: 'Plan de financement',
      child: Column(
        children: [
          ValueRow('Prix du bien', euros(r.price)),
          ValueRow('Frais de notaire', euros(r.notaryFees)),
          if (r.works > 0) ValueRow('Travaux', euros(r.works)),
          if (r.agencyFees > 0) ValueRow('Frais d’agence', euros(r.agencyFees)),
          ValueRow('Frais de dossier', euros(r.bankFees)),
          if (r.brokerFees > 0)
            ValueRow('Honoraires de courtage', euros(r.brokerFees)),
          ValueRow('Frais de garantie', euros(r.guaranteeFees, cents: true)),
          ValueRow('Coût total', euros(r.totalCost, cents: true), strong: true),
          const Divider(height: 24),
          ValueRow(
            'Apport (${(r.downPaymentShare * 100).round()} %)',
            euros(r.downPayment),
          ),
          if (ptz > 0)
            ValueRow('Prêt à taux zéro (tranche ${r.ptz.tranche})', euros(ptz)),
          if (actionLogement > 0)
            ValueRow('Prêt Action Logement', euros(actionLogement)),
          ValueRow(
            'Prêt principal',
            euros(amountOf(LoanKind.main), cents: true),
            strong: true,
          ),
          if (!r.ptz.eligible && r.ptz.reason != PtzReason.disabled)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'PTZ non éligible : ${_ptzReason(r.ptz.reason)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

String _ptzReason(PtzReason reason) => switch (reason) {
  PtzReason.notFirstTimeBuyer => 'réservé aux primo-accédants',
  PtzReason.existingZone => 'ancien hors zones B2 et C',
  PtzReason.existingWorks => 'travaux inférieurs à 25 % du coût',
  PtzReason.income => 'revenus au-dessus du plafond',
  PtzReason.eligible || PtzReason.disabled => '',
};

class _Loans extends StatelessWidget {
  const _Loans(this.r);

  final SimulationResult r;

  static String _name(LoanKind kind) => switch (kind) {
    LoanKind.main => 'Prêt principal',
    LoanKind.ptz => 'Prêt à taux zéro',
    LoanKind.actionLogement => 'Prêt Action Logement',
  };

  @override
  Widget build(BuildContext context) {
    final taeg = r.taeg;
    return SectionCard(
      title: 'Crédit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final loan in r.loans) ...[
            if (r.loans.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  _name(loan.kind),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ValueRow('Montant', euros(loan.amount, cents: true)),
            ValueRow('Taux', percent(loan.rate)),
            ValueRow(
              'Durée',
              loan.deferralMonths > 0
                  ? '${durationLabel(loan.months)} dont ${durationLabel(loan.deferralMonths)} de différé'
                  : durationLabel(loan.months),
            ),
            if (loan.deferralMonths == 0 && loan.tiers.length > 1)
              for (final tier in loan.tiers)
                ValueRow(
                  'Mois ${tier.from} à ${tier.to}, hors assurance',
                  euros(tier.amount, cents: true),
                )
            else
              ValueRow(
                loan.deferralMonths > 0
                    ? 'Mensualité après différé'
                    : 'Mensualité hors assurance',
                euros(
                  loan.deferralMonths > 0
                      ? loan.amount / (loan.months - loan.deferralMonths)
                      : loan.firstPayment,
                  cents: true,
                ),
              ),
            ValueRow('Assurance', euros(loan.insuranceMonthly, cents: true)),
            const Divider(height: 24),
          ],
          ValueRow('TAEG', taeg == null ? '—' : percent(taeg)),
          ValueRow('Total des intérêts', euros(r.totalInterest, cents: true)),
          ValueRow('Total assurance', euros(r.totalInsurance, cents: true)),
          ValueRow(
            'Coût total (frais inclus)',
            euros(r.creditCost, cents: true),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: text.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: text.titleMedium),
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerContainer,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.onDangerContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.onDangerContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
