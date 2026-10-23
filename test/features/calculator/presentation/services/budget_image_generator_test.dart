import 'dart:ui' as ui;

import 'package:doroteia_lab/features/calculator/presentation/providers/calculator_provider.dart';
import 'package:doroteia_lab/features/calculator/presentation/services/budget_image_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gera um card PNG com as dimensões esperadas', (tester) async {
    const budget = CalculatorState(
      projectName: 'Suporte de Headset',
      filamentPrice: 130,
      pieceWeight: 200,
      printingHours: 5,
      machineCostPerHour: 3.5,
      profitMargin: 50,
    );

    final bytes = (await tester.runAsync(
      () => const BudgetImageGenerator().generate(budget),
    ))!;

    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

    final dimensions = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final result = (width: frame.image.width, height: frame.image.height);
      frame.image.dispose();
      codec.dispose();
      return result;
    });
    expect(dimensions?.width, BudgetImageGenerator.width);
    expect(dimensions?.height, BudgetImageGenerator.height);
  });

  test('gera um nome de arquivo seguro para o download', () {
    expect(
      budgetImageFileName('Suporte de Headset'),
      'orcamento-suporte-de-headset.png',
    );
  });
}
