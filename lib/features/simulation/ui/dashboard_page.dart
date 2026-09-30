import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/simmo_logo.dart';
import '../data/saved_inputs.dart';
import '../domain/rules.dart';
import '../domain/simulation_input.dart';
import '../domain/simulation_result.dart';
import '../domain/simulator.dart';
import 'advanced_params.dart';
import 'main_params.dart';
import 'results.dart';

/// The whole app: inputs and results on one page, recomputed on every change.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.saved});

  /// Values kept on the device; null in tests.
  final SavedInputs? saved;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  var _input = const SimulationInput();

  /// Main parameters in the order the user last typed them (newest last).
  final _edited = <MainField>[];

  /// Which untouched parameters adapt first: the purchase capacity.
  static const _computePreference = [
    MainField.price,
    MainField.loan,
    MainField.payment,
    MainField.duration,
    MainField.downPayment,
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.saved;
    if (saved == null) return;
    _input = saved.restore(_input);
    // A saved price was typed by the user: it stays an input.
    if (saved.hasPrice) {
      _edited.add(MainField.price);
      _input = _input.copyWith(computed: _pickComputed());
    }
  }

  void _set(SimulationInput input, {bool priceTyped = false}) {
    widget.saved?.save(_input, input, priceTyped: priceTyped);
    setState(() => _input = input);
  }

  /// The two parameters to compute: untouched ones first, then the least
  /// recently typed, so the latest entries always stay as typed.
  Set<MainField> _pickComputed() {
    final order = [
      ..._computePreference.where((f) => !_edited.contains(f)),
      ..._edited,
    ];
    for (var j = 1; j < order.length; j++) {
      for (var i = 0; i < j; i++) {
        final pair = {order[i], order[j]};
        if (isSolvable(pair)) return pair;
      }
    }
    return const {MainField.price, MainField.loan};
  }

  void _edit(MainField field, SimulationInput edited) {
    final previous = simulate(_input);
    _edited
      ..remove(field)
      ..add(field);
    final computed = _pickComputed();
    // Parameters that stop being computed keep their last computed value,
    // so nothing jumps.
    var input = edited;
    for (final f in _input.computed.difference(computed)) {
      if (f != field) input = _keep(input, f, previous);
    }
    _set(
      input.copyWith(computed: computed),
      priceTyped: field == MainField.price,
    );
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
    MainField.payment =>
      i.effortMode == EffortMode.payment
          ? i.copyWith(monthlyPayment: r.monthlyPayment)
          : i.copyWith(debtRatio: r.debtRatioAfter),
  };

  /// Converts the effort to the other unit without changing it.
  void _effortMode(EffortMode mode) {
    final i = _input;
    final income = retainedIncome(i);
    _set(
      mode == EffortMode.payment
          ? i.copyWith(
              effortMode: mode,
              monthlyPayment: max(0, targetMonthly(i)).roundToDouble(),
            )
          : i.copyWith(
              effortMode: mode,
              debtRatio: income > 0
                  ? ((i.monthlyPayment + i.otherLoans) / income).clamp(
                      minDebtRatio,
                      maxDebtRatio,
                    )
                  : Rules.debtRatioLimit,
            ),
    );
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
        AdvancedParams(input: _input, result: result, onChanged: _set),
      ],
    );
    final details = ResultDetails(result: result);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      const SizedBox(height: 24),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 440, child: inputs),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  summary,
                                  const SizedBox(height: 16),
                                  details,
                                ],
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const SimmoLogo(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simmo',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text('Simulation de prêt immobilier', style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
