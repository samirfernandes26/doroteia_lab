import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:doroteia_lab/features/catalog/data/catalog_storage.dart';
import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/pages/catalog_page.dart';
import 'package:doroteia_lab/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:doroteia_lab/features/catalog/presentation/widgets/catalog_product_card.dart';
import 'package:doroteia_lab/features/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductFormDialog', () {
    testWidgets('exibe validações cruzadas de capacidade, preço e tempo', (
      tester,
    ) async {
      await _openProductForm(tester);
      await _fillValidProduct(tester);

      await tester.enterText(
        find.byKey(const ValueKey('medium-capacity')),
        '7',
      );
      await _submit(tester);

      expect(find.byKey(const ValueKey('product-form-error')), findsOneWidget);
      expect(
        find.text(
          'A quantidade da mesa média deve estar entre 1 e a capacidade máxima.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('medium-capacity')),
        '3',
      );
      await tester.enterText(find.byKey(const ValueKey('medium-price')), '70');
      await _submit(tester);

      expect(
        find.text(
          'Os preços unitários não podem aumentar da peça única até a mesa cheia.',
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const ValueKey('medium-price')), '50');
      await tester.enterText(find.byKey(const ValueKey('medium-hours')), '0');
      await tester.enterText(
        find.byKey(const ValueKey('medium-minutes')),
        '30',
      );
      await _submit(tester);

      expect(
        find.text(
          'Os tempos totais não podem diminuir da peça única até a mesa cheia.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('exibe erro no campo para URL de projeto inválida', (
      tester,
    ) async {
      await _openProductForm(tester);
      await _fillValidProduct(tester, projectUrl: 'makerworld.com/modelo');

      await _submit(tester);

      expect(
        find.text('Informe uma URL válida iniciada por http:// ou https://.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('product-form-error')), findsNothing);
    });

    for (final mediumCapacity in [1, 6]) {
      testWidgets(
        'aceita fallback com mesa média em $mediumCapacity e ignora seus valores',
        (tester) async {
          CatalogProduct? savedProduct;
          await _openProductForm(
            tester,
            onClosed: (product) => savedProduct = product,
          );
          await _fillValidProduct(tester);
          await tester.enterText(
            find.byKey(const ValueKey('medium-capacity')),
            '$mediumCapacity',
          );
          await tester.enterText(
            find.byKey(const ValueKey('medium-hours')),
            '0',
          );
          await tester.enterText(
            find.byKey(const ValueKey('medium-minutes')),
            '1',
          );
          await tester.enterText(
            find.byKey(const ValueKey('medium-price')),
            '999',
          );

          await _submit(tester);

          expect(savedProduct, isNotNull);
          expect(savedProduct!.mediumCapacity, mediumCapacity);
          expect(savedProduct!.unitPriceFor(3), 52);
          expect(savedProduct!.totalTimeMinutesFor(3), 108);
          expect(
            find.byKey(const ValueKey('product-form-error')),
            findsNothing,
          );
        },
      );
    }

    testWidgets('pré-preenche e devolve todos os pontos ao editar', (
      tester,
    ) async {
      const original = CatalogProduct(
        id: 'product-to-edit',
        name: 'Produto original',
        projectUrl: 'https://makerworld.com/model/123',
        dimensions: ProductDimensions(height: 22, width: 12, length: 15),
        bedCapacity: 6,
        singleUnitPrice: 65,
        singleUnitTimeMinutes: 75,
        mediumCapacity: 3,
        mediumUnitPrice: 50,
        mediumTotalTimeMinutes: 150,
        fullBedUnitPrice: 40,
        fullBedTotalTimeMinutes: 300,
      );
      CatalogProduct? editedProduct;

      await _openProductForm(
        tester,
        product: original,
        onClosed: (product) => editedProduct = product,
      );

      expect(find.text('Editar Produto do Catálogo'), findsOneWidget);
      expect(_fieldText(tester, 'product-name'), 'Produto original');
      expect(
        _fieldText(tester, 'project-url'),
        'https://makerworld.com/model/123',
      );
      expect(_fieldText(tester, 'max-capacity'), '6');
      expect(_fieldText(tester, 'single-hours'), '1');
      expect(_fieldText(tester, 'single-minutes'), '15');
      expect(_fieldText(tester, 'single-price'), '65,00');
      expect(_fieldText(tester, 'medium-capacity'), '3');
      expect(_fieldText(tester, 'medium-hours'), '2');
      expect(_fieldText(tester, 'medium-minutes'), '30');
      expect(_fieldText(tester, 'medium-price'), '50,00');
      expect(_fieldText(tester, 'full-hours'), '5');
      expect(_fieldText(tester, 'full-minutes'), '0');
      expect(_fieldText(tester, 'full-price'), '40,00');

      final updatedValues = <String, String>{
        'product-name': 'Produto atualizado',
        'project-url': 'https://www.printables.com/model/456',
        'max-capacity': '8',
        'single-hours': '1',
        'single-minutes': '30',
        'single-price': '80',
        'medium-capacity': '4',
        'medium-hours': '3',
        'medium-minutes': '30',
        'medium-price': '60',
        'full-hours': '7',
        'full-minutes': '0',
        'full-price': '45',
      };
      for (final entry in updatedValues.entries) {
        await tester.enterText(ValueKey(entry.key).finder, entry.value);
      }

      await _submit(tester);

      expect(editedProduct, isNotNull);
      expect(editedProduct!.id, original.id);
      expect(editedProduct!.name, 'Produto atualizado');
      expect(editedProduct!.projectUrl, 'https://www.printables.com/model/456');
      expect(editedProduct!.bedCapacity, 8);
      expect(editedProduct!.singleUnitTimeMinutes, 90);
      expect(editedProduct!.singleUnitPrice, 80);
      expect(editedProduct!.mediumCapacity, 4);
      expect(editedProduct!.mediumTotalTimeMinutes, 210);
      expect(editedProduct!.mediumUnitPrice, 60);
      expect(editedProduct!.fullBedTotalTimeMinutes, 420);
      expect(editedProduct!.fullBedUnitPrice, 45);
    });

    testWidgets('permanece navegável sem overflow em viewport mobile', (
      tester,
    ) async {
      await _openProductForm(tester, viewport: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('save-product')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('save-product')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('limita a grade visual a 24 slots para capacidade extrema', (
    tester,
  ) async {
    _setViewport(tester, const Size(520, 1000));
    const product = CatalogProduct(
      id: 'extreme-capacity',
      name: 'Lote industrial',
      dimensions: ProductDimensions(height: 1, width: 1, length: 1),
      bedCapacity: 10000,
      singleUnitPrice: 100,
      singleUnitTimeMinutes: 60,
      mediumCapacity: 5000,
      mediumUnitPrice: 70,
      mediumTotalTimeMinutes: 30000,
      fullBedUnitPrice: 40,
      fullBedTotalTimeMinutes: 60000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CatalogProductCard(
              product: product,
              quantity: 1,
              onIncrement: _noop,
              onDecrement: _noop,
              onEdit: _noop,
              onDelete: _noop,
              onWhatsApp: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slots = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('bed-slot-');
    });
    expect(slots, findsNWidgets(24));
    expect(find.byKey(const ValueKey('bed-slot-24')), findsNothing);
    expect(find.text('1 / 10000 un'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CatalogPage não gera overflow no cabeçalho e toolbar mobile', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 568));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthenticatedRepository()),
          catalogStorageProvider.overrideWithValue(
            _MemoryCatalogStorage(const []),
          ),
        ],
        child: const MaterialApp(home: CatalogPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doroteia Lab'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Calculadora'), findsOneWidget);
    expect(find.text('Cadastrar Produto'), findsNWidgets(2));
    expect(find.text('Buscar produto no catálogo...'), findsOneWidget);
    expect(
      find.text(
        'Interpolação de 3 Pontos (1 Unidade → Mesa Média → Mesa Cheia)',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _ProductFormHarness extends StatelessWidget {
  const _ProductFormHarness({required this.onClosed, this.product});

  final ValueChanged<CatalogProduct?> onClosed;
  final CatalogProduct? product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey('open-product-form'),
          onPressed: () async {
            final result = await showProductFormDialog(
              context,
              product: product,
            );
            onClosed(result);
          },
          child: const Text('Abrir formulário'),
        ),
      ),
    );
  }
}

Future<void> _openProductForm(
  WidgetTester tester, {
  Size viewport = const Size(900, 900),
  ValueChanged<CatalogProduct?>? onClosed,
  CatalogProduct? product,
}) async {
  _setViewport(tester, viewport);
  await tester.pumpWidget(
    MaterialApp(
      home: _ProductFormHarness(onClosed: onClosed ?? (_) {}, product: product),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-product-form')));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, String key) {
  return tester
      .widget<TextFormField>(find.byKey(ValueKey(key)))
      .controller!
      .text;
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _fillValidProduct(
  WidgetTester tester, {
  String projectUrl = '',
}) async {
  final values = <String, String>{
    'product-name': 'Produto de teste',
    'project-url': projectUrl,
    'height': '10',
    'width': '10',
    'length': '10',
    'max-capacity': '6',
    'single-hours': '1',
    'single-minutes': '0',
    'single-price': '60',
    'medium-capacity': '3',
    'medium-hours': '2',
    'medium-minutes': '0',
    'medium-price': '50',
    'full-hours': '3',
    'full-minutes': '0',
    'full-price': '40',
  };

  for (final entry in values.entries) {
    await tester.enterText(ValueKey(entry.key).finder, entry.value);
  }
}

Future<void> _submit(WidgetTester tester) async {
  final saveButton = find.byKey(const ValueKey('save-product'));
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void _noop() {}

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

extension on Key {
  Finder get finder => find.byKey(this);
}
