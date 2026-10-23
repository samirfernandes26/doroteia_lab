import 'package:doroteia_lab/features/calculator/presentation/providers/calculator_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorState', () {
    test('calcula todos os valores conforme as regras do orçamento', () {
      const state = CalculatorState(
        filamentPrice: 130,
        pieceWeight: 200,
        printingHours: 5,
        machineCostPerHour: 3.5,
        profitMargin: 50,
      );

      expect(state.materialCost, closeTo(26, 0.001));
      expect(state.machineCost, closeTo(17.5, 0.001));
      expect(state.productionCost, closeTo(43.5, 0.001));
      expect(state.profitValue, closeTo(21.75, 0.001));
      expect(state.finalPrice, closeTo(65.25, 0.001));
    });
  });

  group('CalculatorController', () {
    test('aceita valores decimais com vírgula e limita a margem', () {
      final controller = CalculatorController();

      controller.setFilamentPrice('89,90');
      controller.setMachineCostPerHour('4,25');
      controller.setProfitMargin(600);

      expect(controller.state.filamentPrice, closeTo(89.90, 0.001));
      expect(controller.state.machineCostPerHour, closeTo(4.25, 0.001));
      expect(controller.state.profitMargin, 500);
    });
  });
}
