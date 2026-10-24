import 'package:doroteia_lab/features/catalog/data/catalog_storage.dart';
import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCatalogStorage implements CatalogStorage {
  _MemoryCatalogStorage([List<CatalogProduct> initialProducts = const []])
    : products = [...initialProducts];

  List<CatalogProduct> products;

  @override
  Future<List<CatalogProduct>> readProducts() async => [...products];

  @override
  Future<void> saveProducts(List<CatalogProduct> products) async {
    this.products = [...products];
  }
}

void main() {
  const product = CatalogProduct(
    id: 'product-1',
    name: 'Chaveiro',
    projectUrl: 'https://makerworld.com/model/chaveiro',
    dimensions: ProductDimensions(height: 5, width: 4, length: 2),
    bedCapacity: 6,
    singleUnitPrice: 15,
    singleUnitTimeMinutes: 40,
    mediumCapacity: 3,
    mediumUnitPrice: 12,
    mediumTotalTimeMinutes: 75,
    fullBedUnitPrice: 10,
    fullBedTotalTimeMinutes: 120,
  );

  test('carrega produtos e controla a quantidade dentro dos limites', () async {
    final storage = _MemoryCatalogStorage([product]);
    final controller = CatalogController(storage);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state.products, [product]);
    expect(controller.state.quantityFor(product), 1);

    controller.decrementQuantity(product.id);
    expect(controller.state.quantityFor(product), 1);

    controller.incrementQuantity(product.id);
    controller.incrementQuantity(product.id);
    controller.incrementQuantity(product.id);
    controller.incrementQuantity(product.id);
    controller.incrementQuantity(product.id);
    controller.incrementQuantity(product.id);
    expect(controller.state.quantityFor(product), 6);
  });

  test('persiste inclusão, edição e exclusão', () async {
    final storage = _MemoryCatalogStorage();
    final controller = CatalogController(storage);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.saveProduct(product);
    expect(storage.products, [product]);

    final edited = CatalogProduct(
      id: product.id,
      name: 'Chaveiro atualizado',
      projectUrl: product.projectUrl,
      dimensions: product.dimensions,
      bedCapacity: product.bedCapacity,
      singleUnitPrice: product.singleUnitPrice,
      singleUnitTimeMinutes: product.singleUnitTimeMinutes,
      mediumCapacity: product.mediumCapacity,
      mediumUnitPrice: product.mediumUnitPrice,
      mediumTotalTimeMinutes: product.mediumTotalTimeMinutes,
      fullBedUnitPrice: product.fullBedUnitPrice,
      fullBedTotalTimeMinutes: product.fullBedTotalTimeMinutes,
    );
    await controller.saveProduct(edited);
    expect(storage.products, [edited]);

    await controller.deleteProduct(product.id);
    expect(storage.products, isEmpty);
  });

  test('filtra produtos pelo nome sem diferenciar maiúsculas', () async {
    final storage = _MemoryCatalogStorage([product]);
    final controller = CatalogController(storage);
    addTearDown(controller.dispose);
    await controller.load();

    controller.setSearchQuery('CHAVE');
    expect(controller.state.filteredProducts, [product]);

    controller.setSearchQuery('vasinho');
    expect(controller.state.filteredProducts, isEmpty);
  });
}
