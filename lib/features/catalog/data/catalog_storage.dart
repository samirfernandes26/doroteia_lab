import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/catalog_product.dart';

abstract interface class CatalogStorage {
  Future<List<CatalogProduct>> readProducts();

  Future<void> saveProducts(List<CatalogProduct> products);
}

class SharedPreferencesCatalogStorage implements CatalogStorage {
  SharedPreferencesCatalogStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _productsKey = 'doroteia_lab.catalog.products';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<CatalogProduct>> readProducts() async {
    final serializedProducts = await _preferences.getString(_productsKey);
    if (serializedProducts == null || serializedProducts.isEmpty) {
      return const [];
    }

    try {
      final decodedProducts = jsonDecode(serializedProducts);
      if (decodedProducts is! List<dynamic>) {
        throw const FormatException('Catálogo salvo inválido.');
      }

      return decodedProducts
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Produto salvo inválido.');
            }
            return CatalogProduct.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException {
      await _preferences.remove(_productsKey);
      return const [];
    }
  }

  @override
  Future<void> saveProducts(List<CatalogProduct> products) {
    return _preferences.setString(
      _productsKey,
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
  }
}
