import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/number_field.dart';
import '../../../shared/section_card.dart';
import '../domain/project.dart';
import '../domain/rules.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';
import '../domain/simulator.dart';
import 'address_field.dart';
import 'advanced_params.dart';
import 'main_params.dart';
import 'results.dart';

/// One project: the property first, then inputs and results, recomputed on
/// every change.
class ProjectView extends StatelessWidget {
  const ProjectView({
    super.key,
    required this.project,
    required this.onChanged,
    required this.wide,
  });

  final Project project;
  final ValueChanged<Project> onChanged;

  /// Inputs and results side by side.
  final bool wide;

  SimulationInput get _input => project.input;

  void _set(SimulationInput input) => onChanged(Project(input, project.typed));

  void _edit(MainField field, SimulationInput edited) {
    final previous = simulate(_input);
    final typed = [...project.typed.where((f) => f != field), field];
    final computed = pickComputed(typed);
    // Parameters that stop being computed keep their last computed value,
    // so nothing jumps.
    var input = edited;
    for (final f in _input.computed.difference(computed)) {
      if (f != field) input = _keep(input, f, previous);
    }
    onChanged(Project(input.copyWith(computed: computed), typed));
  }

  SimulationInput _keep(
    SimulationInput i,
    MainField field,
    SimulationResult r,
  ) => switch (field) {
    MainField.price => i.copyWith(price: r.price),
    MainField.downPayment => i.copyWith(downPayment: r.downPayment),
    MainField.loan => i.copyWith(loanAmount: r.borrowed),
    MainField.duration => i.copyWith(durationMonths: r.durationMonths),
    MainField.payment => switch (i.effortMode) {
      EffortMode.payment => i.copyWith(monthlyPayment: r.monthlyPayment),
      EffortMode.allIn => i.copyWith(
        housingBudget: r.monthlyPayment + i.runningCosts,
      ),
      EffortMode.debtRatio => i.copyWith(debtRatio: r.debtRatioAfter),
    },
  };

  /// Converts the effort to the other unit without changing it.
  void _effortMode(EffortMode mode) {
    final i = _input.copyWith(effortMode: mode);
    final target = max(0.0, targetMonthly(_input));
    final income = retainedIncome(i);
    _set(switch (mode) {
      EffortMode.payment => i.copyWith(monthlyPayment: target.roundToDouble()),
      EffortMode.allIn => i.copyWith(
        housingBudget: (target + i.runningCosts).roundToDouble(),
      ),
      EffortMode.debtRatio => i.copyWith(
        debtRatio: income > 0
            ? ((target + i.otherLoans) / income).clamp(
                minDebtRatio,
                maxDebtRatio,
              )
            : Rules.debtRatioLimit,
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = simulate(_input);
    final summary = SummaryCard(input: _input, result: result);
    final inputs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MainParams(
          input: _input,
          result: result,
          onEdit: _edit,
          onChanged: _set,
          onEffortMode: _effortMode,
        ),
        const SizedBox(height: 16),
        BudgetParams(input: _input, onChanged: _set),
        const SizedBox(height: 16),
        AdvancedParams(input: _input, result: result, onChanged: _set),
      ],
    );
    final details = ResultDetails(input: _input, result: result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PropertyCard(input: _input, onChanged: _set, wide: wide),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 440, child: inputs),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [summary, const SizedBox(height: 16), details],
                ),
              ),
            ],
          )
        else ...[
          summary,
          const SizedBox(height: 16),
          inputs,
          const SizedBox(height: 16),
          details,
        ],
      ],
    );
  }
}

/// Where the property is, first thing of a project: the address names the
/// project and gives the zone and the nearby sales, whose price per m² needs
/// the surface.
class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.input,
    required this.onChanged,
    required this.wide,
  });

  final SimulationInput input;
  final ValueChanged<SimulationInput> onChanged;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final address = AddressField(
      address: input.address,
      onChanged: (address, zone) =>
          onChanged(input.copyWith(address: () => address, zone: zone)),
    );
    final surface = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Surface habitable',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          NumberField(
            value: input.surface,
            decimals: 2,
            suffix: 'm²',
            dense: true,
            onChanged: (v) => onChanged(input.copyWith(surface: v)),
          ),
        ],
      ),
    );
    return SectionCard(
      title: 'Le bien',
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: address),
                const SizedBox(width: 24),
                SizedBox(width: 200, child: surface),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [address, surface],
            ),
    );
  }
}
