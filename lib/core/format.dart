/// French number formatting (no intl dependency needed for these few cases).
const _nbsp = ' ';

String groupDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// `295 195 €`, or `1 462,03 €` with [cents].
String euros(double value, {bool cents = false}) {
  final fixed = value.abs().toStringAsFixed(cents ? 2 : 0).split('.');
  final amount = groupDigits(fixed[0]) + (cents ? ',${fixed[1]}' : '');
  return '${value < 0 && value.abs() >= (cents ? 0.005 : 0.5) ? '−' : ''}'
      '$amount$_nbsp€';
}

/// `34,87 %` from 0.3487.
String percent(double fraction, {int decimals = 2}) =>
    '${(fraction * 100).toStringAsFixed(decimals).replaceAll('.', ',')}$_nbsp%';

/// `25 ans`, `24 ans 11 mois`, `8 mois`.
String durationLabel(int months) {
  final years = months ~/ 12;
  final rest = months % 12;
  final y = years == 0 ? '' : '$years${_nbsp}an${years > 1 ? 's' : ''}';
  final m = rest == 0 ? '' : '$rest${_nbsp}mois';
  return [y, m].where((s) => s.isNotEmpty).join(' ');
}
