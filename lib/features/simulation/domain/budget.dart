import 'simulation_input.dart';
import 'simulation_result.dart';
import 'simulator.dart';

/// Monthly housing cost before and after the purchase, all included: the
/// buyer's view, where the bank only counts the loan.
class HousingBudget {
  const HousingBudget({
    required this.rent,
    required this.payment,
    required this.condoFees,
    required this.propertyTax,
    required this.currentUtilities,
    required this.utilities,
    required this.worksSaving,
    required this.income,
    required this.incomeTax,
    required this.otherLoans,
  });

  final double rent;
  final double payment;
  final double condoFees;

  /// Property tax, per month.
  final double propertyTax;
  final double currentUtilities;
  final double utilities;

  /// Monthly saving for the co-ownership works to come.
  final double worksSaving;

  /// Income retained by the simulator, as for the bank's residual income.
  final double income;
  final double incomeTax;
  final double otherLoans;

  double get totalBefore => rent + currentUtilities;
  double get totalAfter =>
      payment + condoFees + propertyTax + utilities + worksSaving;

  /// Income left after tax, other loans and all housing costs.
  double get residualBefore => income - incomeTax - otherLoans - totalBefore;
  double get residualAfter => income - incomeTax - otherLoans - totalAfter;
}

HousingBudget housingBudget(SimulationInput input, SimulationResult result) =>
    HousingBudget(
      rent: input.currentRent,
      payment: result.monthlyPayment,
      condoFees: input.condoFees,
      propertyTax: input.monthlyPropertyTax,
      currentUtilities: input.currentUtilities,
      utilities: input.utilities,
      worksSaving: input.worksSaving,
      income: retainedIncome(input),
      incomeTax: result.incomeTax,
      otherLoans: input.otherLoans,
    );

/// The simulation at another [price], down payment and duration unchanged.
SimulationResult atPrice(
  SimulationInput input,
  SimulationResult result,
  double price,
) => simulate(
  input.copyWith(
    computed: {MainField.loan, MainField.payment},
    price: price,
    downPayment: result.downPayment,
    durationMonths: result.durationMonths,
  ),
);

/// Extra monthly payment for each 1,000 € more on the price.
double costPerThousand(SimulationInput input, SimulationResult result) =>
    atPrice(input, result, result.price + 1000).monthlyPayment -
    atPrice(input, result, result.price).monthlyPayment;
