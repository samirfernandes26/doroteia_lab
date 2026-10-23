import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog_storage.dart';
import '../../domain/entities/catalog_product.dart';

final catalogStorageProvider = Provider<CatalogStorage>((ref) {
  return SharedPreferencesCatalogStorage();
});

final catalogProvider = StateNotifierProvider<CatalogController, CatalogState>((
  ref,
) {
  final controller = CatalogController(ref.watch(catalogStorageProvider));
  unawaited(controller.load());
  return controller;
});

class CatalogState {
  const CatalogState({
    this.products = const [],
    this.selectedQuantities = const {},
    this.searchQuery = '',
    this.isLoading = true,
    this.errorMessage,
  });

  final List<CatalogProduct> products;
  final Map<String, int> selectedQuantities;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  List<CatalogProduct> get filteredProducts {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return products;
    return products
        .where(
          (product) => product.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  int quantityFor(CatalogProduct product) {
    return product.normalizeQuantity(selectedQuantities[product.id] ?? 1);
  }

  CatalogState copyWith({
    List<CatalogProduct>? products,
    Map<String, int>? selectedQuantities,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      products: products ?? this.products,
      selectedQuantities: selectedQuantities ?? this.selectedQuantities,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CatalogController extends StateNotifier<CatalogState> {
  CatalogController(this._storage) : super(const CatalogState());

  final CatalogStorage _storage;

  Future<void> load() async {
    try {
      final products = await _storage.readProducts();
      state = state.copyWith(
        products: products,
        selectedQuantities: {for (final product in products) product.id: 1},
        isLoading: false,
        clearError: true,
      );
    } on Object {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar o catálogo salvo.',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void incrementQuantity(String productId) => _changeQuantity(productId, 1);

  void decrementQuantity(String productId) => _changeQuantity(productId, -1);

  void _changeQuantity(String productId, int delta) {
    final product = state.products
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) return;

    final nextQuantity = product.normalizeQuantity(
      state.quantityFor(product) + delta,
    );
    state = state.copyWith(
      selectedQuantities: {
        ...state.selectedQuantities,
        productId: nextQuantity,
      },
    );
  }

  Future<void> saveProduct(CatalogProduct product) async {
    final previousState = state;
    final productIndex = state.products.indexWhere(
      (item) => item.id == product.id,
    );
    final products = [...state.products];

    if (productIndex == -1) {
      products.add(product);
    } else {
      products[productIndex] = product;
    }

    state = state.copyWith(
      products: products,
      selectedQuantities: {
        ...state.selectedQuantities,
        product.id: product.normalizeQuantity(
          state.selectedQuantities[product.id] ?? 1,
        ),
      },
      clearError: true,
    );

    try {
      await _storage.saveProducts(products);
    } on Object {
      state = previousState.copyWith(
        errorMessage: 'Não foi possível salvar o produto.',
      );
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    final previousState = state;
    final products = state.products
        .where((product) => product.id != productId)
        .toList(growable: false);
    final quantities = {...state.selectedQuantities}..remove(productId);

    state = state.copyWith(
      products: products,
      selectedQuantities: quantities,
      clearError: true,
    );

    try {
      await _storage.saveProducts(products);
    } on Object {
      state = previousState.copyWith(
        errorMessage: 'Não foi possível excluir o produto.',
      );
      rethrow;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}
