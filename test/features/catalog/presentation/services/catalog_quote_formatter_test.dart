import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/services/catalog_quote_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = CatalogProduct(
    id: 'product-1',
    name: 'Vasinho Hexagonal',
    dimensions: ProductDimensions(height: 10, width: 10, length: 12),
    bedCapacity: 3,
    singleUnitPrice: 50,
    singleUnitTimeMinutes: 60,
    fullBedUnitPrice: 30,
    fullBedTotalTimeMinutes: 150,
  );

  test('formata uma proposta comercial limpa para mesa cheia', () {
    final quote = formatCatalogQuote(product, 3);

    expect(quote, contains('🧪 DOROTEIA LAB — ORÇAMENTO DE IMPRESSÃO 3D'));
    expect(quote, contains('📦 Produto: Vasinho Hexagonal'));
    expect(quote, contains('📏 Dimensões: 10 x 10 x 12 cm'));
    expect(
      quote,
      contains('📊 Quantidade Solicitada: 3 unidade(s) (Lote com Mesa Cheia)'),
    );
    expect(quote, contains('⏳ Tempo Estimado de Produção: 2h 30min'));
    expect(quote, contains('💰 Preço Unitário: R\$ 30,00'));
    expect(quote, contains('💳 VALOR TOTAL: R\$ 90,00'));
    expect(quote, isNot(contains('depreciação')));
    expect(quote, isNot(contains('custo de produção')));
  });

  test('formata duração com horas e minutos', () {
    expect(formatDuration(40), '40min');
    expect(formatDuration(60), '1h 00min');
    expect(formatDuration(100), '1h 40min');
  });
}
