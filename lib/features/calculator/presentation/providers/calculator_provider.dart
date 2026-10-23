import 'package:flutter_riverpod/flutter_riverpod.dart';

final calculatorProvider =
    StateNotifierProvider.autoDispose<CalculatorController, CalculatorState>(
      (ref) => CalculatorController(),
    );

class CalculatorState {
  const CalculatorState({
    this.projectName = 'Suporte de Headset',
    this.filamentPrice = 130,
    this.pieceWeight = 200,
    this.printingHours = 5,
    this.machineCostPerHour = 3.5,
    this.profitMargin = 50,
  });

  final String projectName;
  final double filamentPrice;
  final double pieceWeight;
  final double printingHours;
  final double machineCostPerHour;
  final double profitMargin;

  double get materialCost => (filamentPrice / 1000) * pieceWeight;

  double get machineCost => printingHours * machineCostPerHour;

  double get productionCost => materialCost + machineCost;

  double get profitValue => productionCost * (profitMargin / 100);

  double get finalPrice => productionCost + profitValue;

  CalculatorState copyWith({
    String? projectName,
    double? filamentPrice,
    double? pieceWeight,
    double? printingHours,
    double? machineCostPerHour,
    double? profitMargin,
  }) {
    return CalculatorState(
      projectName: projectName ?? this.projectName,
      filamentPrice: filamentPrice ?? this.filamentPrice,
      pieceWeight: pieceWeight ?? this.pieceWeight,
      printingHours: printingHours ?? this.printingHours,
      machineCostPerHour: machineCostPerHour ?? this.machineCostPerHour,
      profitMargin: profitMargin ?? this.profitMargin,
    );
  }
}

class CalculatorController extends StateNotifier<CalculatorState> {
  CalculatorController() : super(const CalculatorState());

  void setProjectName(String value) {
    state = state.copyWith(projectName: value);
  }

  void setFilamentPrice(String value) {
    state = state.copyWith(filamentPrice: _parsePositiveNumber(value));
  }

  void setPieceWeight(String value) {
    state = state.copyWith(pieceWeight: _parsePositiveNumber(value));
  }

  void setPrintingHours(String value) {
    state = state.copyWith(printingHours: _parsePositiveNumber(value));
  }

  void setMachineCostPerHour(String value) {
    state = state.copyWith(machineCostPerHour: _parsePositiveNumber(value));
  }

  void setProfitMargin(double value) {
    state = state.copyWith(profitMargin: value.clamp(0, 500));
  }

  double _parsePositiveNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite || parsed < 0) return 0;
    return parsed;
  }
}
