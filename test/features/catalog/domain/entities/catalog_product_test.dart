import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = CatalogProduct(
    id: 'product-1',
    name: 'Suporte de Headset',
    dimensions: ProductDimensions(height: 22, width: 12, length: 15),
    bedCapacity: 5,
    singleUnitPrice: 100,
    singleUnitTimeMinutes: 60,
    fullBedUnitPrice: 60,
    fullBedTotalTimeMinutes: 180,
  );

  group('CatalogProduct', () {
    test('mantém os valores base para uma única peça', () {
      expect(product.unitPriceFor(1), 100);
      expect(product.totalPriceFor(1), 100);
      expect(product.totalTimeMinutesFor(1), 60);
    });

    test('interpola preço e tempo no meio da capacidade', () {
      expect(product.unitPriceFor(3), 80);
      expect(product.totalPriceFor(3), 240);
      expect(product.totalTimeMinutesFor(3), 120);
      expect(product.discountPercentageFor(3), 20);
    });

    test('atinge exatamente os parâmetros de mesa cheia', () {
      expect(product.unitPriceFor(5), 60);
      expect(product.totalPriceFor(5), 300);
      expect(product.totalTimeMinutesFor(5), 180);
    });

    test('limita a quantidade entre 1 e a capacidade da mesa', () {
      expect(product.normalizeQuantity(0), 1);
      expect(product.normalizeQuantity(99), 5);
      expect(product.unitPriceFor(99), 60);
    });

    test('usa os valores unitários quando a capacidade é 1', () {
      const singleProduct = CatalogProduct(
        id: 'single',
        name: 'Peça grande',
        dimensions: ProductDimensions(height: 30, width: 30, length: 30),
        bedCapacity: 1,
        singleUnitPrice: 75,
        singleUnitTimeMinutes: 90,
        fullBedUnitPrice: 50,
        fullBedTotalTimeMinutes: 240,
      );

      expect(singleProduct.unitPriceFor(1), 75);
      expect(singleProduct.totalPriceFor(1), 75);
      expect(singleProduct.totalTimeMinutesFor(1), 90);
    });
  });
}
