import 'package:shared_preferences/shared_preferences.dart';

import '../domain/simulation_input.dart';

/// Income, reference tax income, rate, typed price, borrower age and typed
/// withholding rate, kept on the device (browser local storage) and restored
/// at the next visit. Stored as text: whole numbers lose their double type
/// in JSON on the web.
class SavedInputs {
  SavedInputs(this._prefs);

  final SharedPreferences _prefs;

  static const _price = 'price';
  static const _income = 'netMonthlyIncome';
  static const _taxIncome = 'referenceTaxIncome';
  static const _rate = 'rate';
  static const _age = 'borrowerAge';
  static const _withholding = 'withholdingRate';

  bool get hasPrice => _get(_price) != null;

  SimulationInput restore(SimulationInput input) {
    final withholding = _get(_withholding);
    return input.copyWith(
      price: _get(_price),
      netMonthlyIncome: _get(_income),
      referenceTaxIncome: _get(_taxIncome),
      rate: _get(_rate),
      borrowerAge: _get(_age)?.round(),
      withholdingRate: withholding == null ? null : () => withholding,
    );
  }

  /// Saves what changed from [before] to [after]; the price only when the
  /// user typed it ([priceTyped]), not when it was computed.
  void save(
    SimulationInput before,
    SimulationInput after, {
    bool priceTyped = false,
  }) {
    void keep(String key, double old, double value) {
      if (old != value) _prefs.setString(key, value.toString());
    }

    if (priceTyped) _prefs.setString(_price, after.price.toString());
    keep(_income, before.netMonthlyIncome, after.netMonthlyIncome);
    keep(_taxIncome, before.referenceTaxIncome, after.referenceTaxIncome);
    keep(_rate, before.rate, after.rate);
    keep(_age, before.borrowerAge.toDouble(), after.borrowerAge.toDouble());
    final withholding = after.withholdingRate;
    if (withholding != before.withholdingRate) {
      // Back to the estimate: forget the typed rate.
      withholding == null
          ? _prefs.remove(_withholding)
          : _prefs.setString(_withholding, withholding.toString());
    }
  }

  /// Forgets every saved value.
  void clear() {
    for (final key in [
      _price,
      _income,
      _taxIncome,
      _rate,
      _age,
      _withholding,
    ]) {
      _prefs.remove(key);
    }
  }

  double? _get(String key) {
    final text = _prefs.getString(key);
    return text == null ? null : double.tryParse(text);
  }
}
