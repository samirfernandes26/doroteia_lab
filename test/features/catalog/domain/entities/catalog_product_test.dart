import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const product = CatalogProduct(
    id: 'product-1',
    name: 'Suporte de Headset',
    projectUrl: 'https://makerworld.com/model/123',
    dimensions: ProductDimensions(height: 22, width: 12, length: 15),
    bedCapacity: 10,
    singleUnitPrice: 100,
    singleUnitTimeMinutes: 60,
    mediumCapacity: 4,
    mediumUnitPrice: 70,
    mediumTotalTimeMinutes: 150,
    fullBedUnitPrice: 40,
    fullBedTotalTimeMinutes: 300,
  );

  group('CatalogProduct', () {
    test('mantém os valores base para uma única peça', () {
      expect(product.unitPriceFor(1), 100);
      expect(product.totalPriceFor(1), 100);
      expect(product.totalTimeMinutesFor(1), 60);
    });

    test('interpola preço e tempo entre peça única e mesa média', () {
      expect(product.unitPriceFor(2), 90);
      expect(product.totalPriceFor(2), 180);
      expect(product.totalTimeMinutesFor(2), 90);
      expect(product.discountPercentageFor(2), 10);
    });

    test('atinge exatamente os parâmetros da mesa média', () {
      expect(product.unitPriceFor(4), 70);
      expect(product.totalPriceFor(4), 280);
      expect(product.totalTimeMinutesFor(4), 150);
    });

    test('interpola preço e tempo entre mesa média e mesa cheia', () {
      expect(product.unitPriceFor(7), 55);
      expect(product.totalPriceFor(7), 385);
      expect(product.totalTimeMinutesFor(7), 225);
    });

    test('atinge exatamente os parâmetros de mesa cheia', () {
      expect(product.unitPriceFor(10), 40);
      expect(product.totalPriceFor(10), 400);
      expect(product.totalTimeMinutesFor(10), 300);
    });

    test('arredonda o tempo interpolado para o minuto mais próximo', () {
      const productWithFractionalTime = CatalogProduct(
        id: 'rounded-time',
        name: 'Tempo fracionado',
        dimensions: ProductDimensions(height: 1, width: 1, length: 1),
        bedCapacity: 6,
        singleUnitPrice: 10,
        singleUnitTimeMinutes: 60,
        mediumCapacity: 4,
        mediumUnitPrice: 8,
        mediumTotalTimeMinutes: 101,
        fullBedUnitPrice: 6,
        fullBedTotalTimeMinutes: 180,
      );

      expect(productWithFractionalTime.totalTimeMinutesFor(2), 74);
    });

    test('limita a quantidade entre 1 e a capacidade da mesa', () {
      expect(product.normalizeQuantity(0), 1);
      expect(product.normalizeQuantity(99), 10);
      expect(product.unitPriceFor(99), 40);
    });

    test('usa interpolação direta quando a mesa média é 1', () {
      const fallbackProduct = CatalogProduct(
        id: 'fallback-first',
        name: 'Fallback inicial',
        dimensions: ProductDimensions(height: 1, width: 1, length: 1),
        bedCapacity: 5,
        singleUnitPrice: 100,
        singleUnitTimeMinutes: 60,
        mediumCapacity: 1,
        mediumUnitPrice: 95,
        mediumTotalTimeMinutes: 70,
        fullBedUnitPrice: 60,
        fullBedTotalTimeMinutes: 180,
      );

      expect(fallbackProduct.unitPriceFor(3), 80);
      expect(fallbackProduct.totalTimeMinutesFor(3), 120);
    });

    test('usa interpolação direta quando a mesa média é a mesa cheia', () {
      const fallbackProduct = CatalogProduct(
        id: 'fallback-last',
        name: 'Fallback final',
        dimensions: ProductDimensions(height: 1, width: 1, length: 1),
        bedCapacity: 5,
        singleUnitPrice: 100,
        singleUnitTimeMinutes: 60,
        mediumCapacity: 5,
        mediumUnitPrice: 70,
        mediumTotalTimeMinutes: 150,
        fullBedUnitPrice: 60,
        fullBedTotalTimeMinutes: 180,
      );

      expect(fallbackProduct.unitPriceFor(3), 80);
      expect(fallbackProduct.totalTimeMinutesFor(3), 120);
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

    test('expõe aliases do contrato e serializa o novo formato', () {
      final json = product.toJson();

      expect(product.height, 22);
      expect(product.width, 12);
      expect(product.length, 15);
      expect(product.maxCapacity, 10);
      expect(product.singleTimeMinutes, 60);
      expect(product.fullUnitPrice, 40);
      expect(product.fullTotalTimeMinutes, 300);
      expect(json, {
        'id': 'product-1',
        'name': 'Suporte de Headset',
        'projectUrl': 'https://makerworld.com/model/123',
        'height': 22.0,
        'width': 12.0,
        'length': 15.0,
        'maxCapacity': 10,
        'singleTimeMinutes': 60.0,
        'singleUnitPrice': 100.0,
        'mediumCapacity': 4,
        'mediumTotalTimeMinutes': 150.0,
        'mediumUnitPrice': 70.0,
        'fullTotalTimeMinutes': 300.0,
        'fullUnitPrice': 40.0,
      });
      expect(CatalogProduct.fromJson(json), product);
    });

    test('migra JSON legado mantendo a interpolação de dois pontos', () {
      final legacyProduct = CatalogProduct.fromJson({
        'id': 'legacy',
        'name': 'Produto antigo',
        'dimensions': {'height': 5, 'width': 4, 'length': 3},
        'bedCapacity': 5,
        'singleUnitPrice': 100,
        'singleUnitTimeMinutes': 60,
        'fullBedUnitPrice': 60,
        'fullBedTotalTimeMinutes': 180,
      });

      expect(legacyProduct.projectUrl, isEmpty);
      expect(legacyProduct.mediumCapacity, 5);
      expect(legacyProduct.mediumUnitPrice, 60);
      expect(legacyProduct.mediumTotalTimeMinutes, 180);
      expect(legacyProduct.unitPriceFor(3), 80);
      expect(legacyProduct.totalTimeMinutesFor(3), 120);
    });

    test('rejeita configuração parcial ou capacidade média inválida', () {
      final json = product.toJson();

      expect(
        () => CatalogProduct.fromJson({...json}..remove('mediumUnitPrice')),
        throwsFormatException,
      );
      expect(
        () => CatalogProduct.fromJson({...json, 'mediumCapacity': 11}),
        throwsFormatException,
      );
    });
  });
}
