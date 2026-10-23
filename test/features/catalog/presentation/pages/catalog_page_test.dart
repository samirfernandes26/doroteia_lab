import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:doroteia_lab/features/catalog/data/catalog_storage.dart';
import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/pages/catalog_page.dart';
import 'package:doroteia_lab/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCatalogStorage implements CatalogStorage {
  _MemoryCatalogStorage(this.products);

  List<CatalogProduct> products;

  @override
  Future<List<CatalogProduct>> readProducts() async => [...products];

  @override
  Future<void> saveProducts(List<CatalogProduct> products) async {
    this.products = [...products];
  }
}

class _AuthenticatedRepository implements AuthRepository {
  static const user = UserEntity(id: 'user-id', email: 'user@example.com');

  @override
  UserEntity? get currentUser => user;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(user);

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
  }) async => user;

  @override
  Future<void> signOut() async {}
}

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

  Future<void> pumpCatalog(
    WidgetTester tester,
    List<CatalogProduct> products,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthenticatedRepository()),
          catalogStorageProvider.overrideWithValue(
            _MemoryCatalogStorage(products),
          ),
        ],
        child: const MaterialApp(home: CatalogPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('recalcula o lote e mostra o badge de mesa cheia', (
    tester,
  ) async {
    await pumpCatalog(tester, [product]);

    expect(find.text('Vasinho Hexagonal'), findsOneWidget);
    final initialTotal = tester.widget<Text>(
      find.byKey(const ValueKey('total-product-1')),
    );
    expect(initialTotal.data, contains('50,00'));
    expect(find.text('Mesa Cheia!'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('increment-product-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('increment-product-1')));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Mesa Cheia!'), findsOneWidget);
    expect(find.textContaining('90,00'), findsOneWidget);
    expect(find.text('2h 30min'), findsOneWidget);
  });

  testWidgets('abre o formulário de cadastro no catálogo vazio', (
    tester,
  ) async {
    await pumpCatalog(tester, const []);

    expect(find.text('Seu catálogo ainda está vazio'), findsOneWidget);
    await tester.tap(find.text('Cadastrar Produto'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Produto no Catálogo'), findsOneWidget);
    expect(find.text('NOME DO PRODUTO'), findsOneWidget);
    expect(find.text('CAPACIDADE MÁXIMA DA MESA (PEÇAS)'), findsOneWidget);
    expect(find.text('1 UNIDADE (PEÇA ÚNICA)'), findsOneWidget);
    expect(find.text('MESA CHEIA (CAPACIDADE MÁXIMA)'), findsOneWidget);
    expect(find.text('Salvar Produto'), findsOneWidget);
    expect(find.text('Informe o nome do produto.'), findsNothing);
    expect(find.text('Informe um valor maior que zero.'), findsNothing);
    expect(
      find.text('Informe uma capacidade inteira maior que zero.'),
      findsNothing,
    );

    final saveButton = find.text('Salvar Produto');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Informe o nome do produto.'), findsOneWidget);
    expect(find.text('Informe um valor maior que zero.'), findsNWidgets(5));
    expect(
      find.text('Informe uma capacidade inteira maior que zero.'),
      findsOneWidget,
    );
  });

  testWidgets('cadastra um produto pelo formulário completo', (tester) async {
    await pumpCatalog(tester, const []);

    await tester.tap(find.text('Cadastrar Produto'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Suporte de Headset');
    await tester.enterText(fields.at(1), '22');
    await tester.enterText(fields.at(2), '12');
    await tester.enterText(fields.at(3), '15');
    await tester.enterText(fields.at(4), '4');
    await tester.enterText(fields.at(5), '5');
    await tester.enterText(fields.at(6), '0');
    await tester.enterText(fields.at(7), '65');
    await tester.enterText(fields.at(8), '8');
    await tester.enterText(fields.at(9), '30');
    await tester.enterText(fields.at(10), '45');

    final saveButton = find.text('Salvar Produto');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Suporte de Headset'), findsOneWidget);
    expect(find.text('1 / 4 un'), findsOneWidget);
    expect(find.text('5h 00min'), findsOneWidget);
    expect(find.text('Enviar Orçamento WhatsApp'), findsOneWidget);
  });
}
