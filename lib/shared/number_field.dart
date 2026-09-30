import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/theme/app_colors.dart';

/// Numeric text field in French format (`250 000`, `3,5`). [value] is
/// multiplied by [scale] for display: 100 shows the fraction 0.035 as 3,5.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.suffix = '€',
    this.decimals = 0,
    this.scale = 1,
    this.hint,
    this.dense = false,
    this.highlight = false,
  });

  final double value;

  /// Must store the value as typed: a clamped or rounded value comes back
  /// as [value] and rewrites the text mid-typing (typing "42" into an age
  /// field clamped at 18 turns "4" into "18").
  final ValueChanged<double> onChanged;
  final String suffix;
  final int decimals;
  final double scale;
  final String? hint;
  final bool dense;

  /// Shows the value in the brand colour (a computed value).
  final bool highlight;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final _controller = TextEditingController(text: _format(widget.value));

  String _format(double value) {
    final shown = value * widget.scale;
    final fixed = shown.toStringAsFixed(widget.decimals).split('.');
    var decimals = fixed.length > 1 ? fixed[1] : '';
    while (decimals.endsWith('0')) {
      decimals = decimals.substring(0, decimals.length - 1);
    }
    return groupDigits(fixed[0]) + (decimals.isEmpty ? '' : ',$decimals');
  }

  double? _parse(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.');
    final number = double.tryParse(clean);
    return number == null ? null : number / widget.scale;
  }

  @override
  void didUpdateWidget(NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rewrite when the shown text no longer rounds to the value, so the
    // field being typed in is never touched.
    final current = _parse(_controller.text) ?? 0;
    final step = 0.5 / pow(10, widget.decimals);
    if ((current - widget.value).abs() * widget.scale >= step) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimals > 0,
      ),
      textAlign: TextAlign.end,
      inputFormatters: [_GroupingFormatter(widget.decimals)],
      style:
          (widget.dense
                  ? Theme.of(context).textTheme.bodyLarge
                  : Theme.of(context).textTheme.titleMedium)
              ?.copyWith(color: widget.highlight ? AppColors.primary : null),
      decoration: InputDecoration(
        isDense: widget.dense,
        hintText: widget.hint,
        suffixText: widget.suffix,
      ),
      onChanged: (text) => widget.onChanged(_parse(text) ?? 0),
    );
  }
}

/// Keeps digits and one decimal comma, groups thousands.
class _GroupingFormatter extends TextInputFormatter {
  _GroupingFormatter(this.decimals);

  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('.', ',');
    text = text.replaceAll(RegExp(r'[^0-9,]'), '');
    final comma = text.indexOf(',');
    var integer = comma < 0 ? text : text.substring(0, comma);
    var fraction = comma < 0 || decimals == 0
        ? null
        : text.substring(comma + 1).replaceAll(',', '');
    if (fraction != null && fraction.length > decimals) {
      fraction = fraction.substring(0, decimals);
    }
    integer = integer.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted =
        groupDigits(integer) + (fraction == null ? '' : ',$fraction');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
