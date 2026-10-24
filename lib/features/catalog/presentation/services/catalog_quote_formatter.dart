import 'package:intl/intl.dart';

import '../../domain/entities/catalog_product.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
final _dimension = NumberFormat('0.##', 'pt_BR');

String formatCatalogQuote(CatalogProduct product, int quantity) {
  final normalizedQuantity = product.normalizeQuantity(quantity);

  return '''
📦 Produto: ${product.name}
📏 Dimensões: ${formatProductDimensions(product.dimensions)} cm
📊 Quantidade Solicitada: $normalizedQuantity unidade(s)
⏳ Tempo Estimado de Produção: ${formatDuration(product.totalTimeMinutesFor(normalizedQuantity))}

💰 Preço Unitário: ${_currency.format(product.unitPriceFor(normalizedQuantity))}
💳 Valor Total do Lote: ${_currency.format(product.totalPriceFor(normalizedQuantity))}
'''
      .trim();
}

String formatProductDimensions(ProductDimensions dimensions) {
  return '${_dimension.format(dimensions.height)} x '
      '${_dimension.format(dimensions.width)} x '
      '${_dimension.format(dimensions.length)}';
}

String formatDuration(double totalMinutes) {
  final roundedMinutes = totalMinutes.round().clamp(0, 1 << 31);
  final hours = roundedMinutes ~/ 60;
  final minutes = roundedMinutes % 60;

  if (hours == 0) return '${minutes}min';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}
