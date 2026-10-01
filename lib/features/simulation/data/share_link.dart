import 'dart:convert';
import 'dart:typed_data';

import '../domain/simulation_input.dart';

const siteUrl = 'https://simmo.centuryspine.org/';

/// Link reproducing [input] exactly: every parameter, the computed pair
/// included, packed into a short code. The code sits in the fragment (after
/// `#`), which browsers never send to the server.
String shareLink(SimulationInput input) => '$siteUrl#${encodeInput(input)}';

/// Format version, first byte of the code. Fields below are read in this
/// exact order: never reorder them; a change of layout gets a new version.
/// Version 2 appends the housing budget and negotiation to version 1.
const _version = 2;

/// Amounts are stored in cents, rates in units of 1e-7.
const _cents = 100;
const _rateUnit = 1e7;

String encodeInput(SimulationInput i) {
  final out = _Writer();
  out.byte(_version);
  final pair = MainField.values.where(i.computed.contains).toList();
  out.byte(pair[0].index * 16 + pair[1].index);
  out.flags([
    i.effortMode == EffortMode.payment,
    i.firstTimeBuyer,
    i.raisedTransferTax,
    i.efficientHome,
    i.bankInsurance,
    i.couple,
    i.ptzEnabled,
    i.smoothing,
  ]);
  out.byte(
    (i.propertyKind == PropertyKind.newBuild ? 1 : 0) +
        (i.dwellingType == DwellingType.house ? 2 : 0) +
        i.zone.index * 4 +
        (i.guaranteeFees != null ? 16 : 0) +
        (i.insuranceRate != null ? 32 : 0) +
        (i.withholdingRate != null ? 64 : 0),
  );
  for (final amount in [
    i.price,
    i.downPayment,
    i.loanAmount,
    i.monthlyPayment,
    i.netMonthlyIncome,
    i.referenceTaxIncome,
    i.works,
    i.agencyFees,
    i.furniture,
    i.notaryMiscFees,
    i.bankFees,
    i.brokerFees,
    i.otherLoans,
    i.currentRent,
    i.rentalIncome,
    i.actionLogement,
    ?i.guaranteeFees,
  ]) {
    out.varint((amount * _cents).round());
  }
  for (final rate in [
    i.debtRatio,
    i.rate,
    i.insuranceCoverage,
    ?i.insuranceRate,
    ?i.withholdingRate,
  ]) {
    out.varint((rate * _rateUnit).round());
  }
  out.varint(i.durationMonths);
  out.varint(i.borrowerAge);
  out.varint(i.children);
  for (final amount in [
    i.condoFees,
    i.propertyTax,
    i.utilities,
    i.currentUtilities,
    i.condoCalls,
    i.condoWorks,
    i.askingPrice,
    i.offerPrice,
    i.maxPrice,
  ]) {
    out.varint((amount * _cents).round());
  }
  out.varint(i.condoWorksYears);
  return base64Url.encode(out.bytes).replaceAll('=', '');
}

/// The simulation in a link fragment, or null when it holds none.
SimulationInput? decodeInput(String fragment) {
  try {
    final padded = fragment.padRight((fragment.length + 3) ~/ 4 * 4, '=');
    final r = _Reader(base64Url.decode(padded));
    final version = r.byte();
    if (version < 1 || version > _version) return null;
    final pairByte = r.byte();
    final computed = {
      MainField.values[pairByte ~/ 16],
      MainField.values[pairByte % 16],
    };
    if (!isSolvable(computed)) return null;
    final f = r.flags();
    final kinds = r.byte();
    double amount() => r.varint() / _cents;
    double rate() => r.varint() / _rateUnit;

    final price = amount();
    final downPayment = amount();
    final loanAmount = amount();
    final monthlyPayment = amount();
    final netMonthlyIncome = amount();
    final referenceTaxIncome = amount();
    final works = amount();
    final agencyFees = amount();
    final furniture = amount();
    final notaryMiscFees = amount();
    final bankFees = amount();
    final brokerFees = amount();
    final otherLoans = amount();
    final currentRent = amount();
    final rentalIncome = amount();
    final actionLogement = amount();
    final guaranteeFees = kinds & 16 != 0 ? amount() : null;
    final debtRatio = rate();
    final interestRate = rate();
    final insuranceCoverage = rate();
    final insuranceRate = kinds & 32 != 0 ? rate() : null;
    final withholdingRate = kinds & 64 != 0 ? rate() : null;
    final durationMonths = r.varint();
    final borrowerAge = r.varint();
    final children = r.varint();
    const none = SimulationInput();
    final v2 = version >= 2;
    final condoFees = v2 ? amount() : none.condoFees;
    final propertyTax = v2 ? amount() : none.propertyTax;
    final utilities = v2 ? amount() : none.utilities;
    final currentUtilities = v2 ? amount() : none.currentUtilities;
    final condoCalls = v2 ? amount() : none.condoCalls;
    final condoWorks = v2 ? amount() : none.condoWorks;
    final askingPrice = v2 ? amount() : none.askingPrice;
    final offerPrice = v2 ? amount() : none.offerPrice;
    final maxPrice = v2 ? amount() : none.maxPrice;
    final condoWorksYears = v2 ? r.varint() : none.condoWorksYears;
    if (!r.done) return null;

    return SimulationInput(
      computed: computed,
      price: price,
      downPayment: downPayment,
      loanAmount: loanAmount,
      durationMonths: durationMonths,
      effortMode: f[0] ? EffortMode.payment : EffortMode.debtRatio,
      debtRatio: debtRatio,
      monthlyPayment: monthlyPayment,
      netMonthlyIncome: netMonthlyIncome,
      referenceTaxIncome: referenceTaxIncome,
      rate: interestRate,
      propertyKind: kinds & 1 != 0
          ? PropertyKind.newBuild
          : PropertyKind.existing,
      dwellingType: kinds & 2 != 0
          ? DwellingType.house
          : DwellingType.apartment,
      zone: PtzZone.values[kinds ~/ 4 % 4],
      firstTimeBuyer: f[1],
      raisedTransferTax: f[2],
      works: works,
      agencyFees: agencyFees,
      furniture: furniture,
      notaryMiscFees: notaryMiscFees,
      bankFees: bankFees,
      brokerFees: brokerFees,
      guaranteeFees: guaranteeFees,
      efficientHome: f[3],
      borrowerAge: borrowerAge,
      bankInsurance: f[4],
      insuranceRate: insuranceRate,
      insuranceCoverage: insuranceCoverage,
      couple: f[5],
      children: children,
      otherLoans: otherLoans,
      currentRent: currentRent,
      rentalIncome: rentalIncome,
      withholdingRate: withholdingRate,
      ptzEnabled: f[6],
      actionLogement: actionLogement,
      smoothing: f[7],
      condoFees: condoFees,
      propertyTax: propertyTax,
      utilities: utilities,
      currentUtilities: currentUtilities,
      condoCalls: condoCalls,
      condoWorks: condoWorks,
      condoWorksYears: condoWorksYears,
      askingPrice: askingPrice,
      offerPrice: offerPrice,
      maxPrice: maxPrice,
    );
  } on Object {
    // Not a code from this app (bad base64, truncated, unknown field).
    return null;
  }
}

/// Bytes, booleans packed by 8, and unsigned variable-length integers
/// (7 bits per byte). Arithmetic rather than bit shifts: on the web,
/// shifts truncate to 32 bits.
class _Writer {
  final _bytes = <int>[];

  Uint8List get bytes => Uint8List.fromList(_bytes);

  void byte(int value) => _bytes.add(value);

  void flags(List<bool> values) {
    var value = 0;
    for (var bit = 0; bit < values.length; bit++) {
      if (values[bit]) value += 1 << bit;
    }
    byte(value);
  }

  void varint(int value) {
    var rest = value;
    while (rest >= 128) {
      byte(rest % 128 + 128);
      rest ~/= 128;
    }
    byte(rest);
  }
}

class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  var _position = 0;

  bool get done => _position == _bytes.length;

  int byte() => _bytes[_position++];

  List<bool> flags() {
    final value = byte();
    return [for (var bit = 0; bit < 8; bit++) value & (1 << bit) != 0];
  }

  int varint() {
    var value = 0;
    var scale = 1;
    while (true) {
      final b = byte();
      value += (b % 128) * scale;
      if (b < 128) return value;
      scale *= 128;
    }
  }
}
