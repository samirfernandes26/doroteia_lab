import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/services/catalog_quote_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = CatalogProduct(
    id: 'product-1',
    name: 'Vasinho Hexagonal',
    projectUrl: 'https://example.com/projeto.stl',
    dimensions: ProductDimensions(height: 10, width: 10, length: 12),
    bedCapacity: 10,
    singleUnitPrice: 50,
    singleUnitTimeMinutes: 60,
    mediumCapacity: 5,
    mediumUnitPrice: 40,
    mediumTotalTimeMinutes: 180,
    fullBedUnitPrice: 30,
    fullBedTotalTimeMinutes: 300,
  );

  test('formata uma proposta limpa com os valores interpolados', () {
    final quote = formatCatalogQuote(product, 7);

    expect(quote, contains('📦 Produto: Vasinho Hexagonal'));
    expect(quote, contains('📏 Dimensões: 10 x 10 x 12 cm'));
    expect(quote, contains('📊 Quantidade Solicitada: 7 unidade(s)'));
    expect(quote, contains('⏳ Tempo Estimado de Produção: 3h 48min'));
    expect(quote, contains('💰 Preço Unitário: R\$ 36,00'));
    expect(quote, contains('💳 Valor Total do Lote: R\$ 252,00'));
    expect(quote, isNot(contains('depreciação')));
    expect(quote, isNot(contains('custo de produção')));
    expect(quote, isNot(contains(product.projectUrl)));
    expect(quote, isNot(contains('preço base')));
    expect(quote, isNot(contains('DOROTEIA LAB')));
    expect(quote, isNot(contains('Aguardamos sua confirmação')));
  });

  test('normaliza a quantidade antes de montar o orçamento', () {
    final quote = formatCatalogQuote(product, 99);

    expect(quote, contains('📊 Quantidade Solicitada: 10 unidade(s)'));
    expect(quote, contains('⏳ Tempo Estimado de Produção: 5h 00min'));
    expect(quote, contains('💰 Preço Unitário: R\$ 30,00'));
    expect(quote, contains('💳 Valor Total do Lote: R\$ 300,00'));
  });

  test('formata duração com horas e minutos', () {
    expect(formatDuration(40), '40min');
    expect(formatDuration(60), '1h 00min');
    expect(formatDuration(100), '1h 40min');
  });
}
