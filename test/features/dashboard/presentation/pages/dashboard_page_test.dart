import 'package:doroteia_lab/app.dart';
import 'package:doroteia_lab/core/theme/app_colors.dart';
import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:doroteia_lab/features/catalog/data/catalog_storage.dart';
import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:doroteia_lab/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:doroteia_lab/features/dashboard/domain/dashboard_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCatalogStorage implements CatalogStorage {
  _MemoryCatalogStorage(List<CatalogProduct> products)
    : _products = [...products];

  List<CatalogProduct> _products;

  @override
  Future<List<CatalogProduct>> readProducts() async => [..._products];

  @override
  Future<void> saveProducts(List<CatalogProduct> products) async {
    _products = [...products];
  }
}

class _FailingCatalogStorage implements CatalogStorage {
  @override
  Future<List<CatalogProduct>> readProducts() {
    throw StateError('storage indisponível');
  }

  @override
  Future<void> saveProducts(List<CatalogProduct> products) async {}
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

const _products = <CatalogProduct>[
  CatalogProduct(
    id: 'product-1',
    name: 'Vasinho Hexagonal',
    dimensions: ProductDimensions(height: 10, width: 10, length: 12),
    bedCapacity: 3,
    singleUnitPrice: 50,
    singleUnitTimeMinutes: 60,
    fullBedUnitPrice: 30,
    fullBedTotalTimeMinutes: 150,
  ),
  CatalogProduct(
    id: 'product-2',
    name: 'Suporte de Headset',
    dimensions: ProductDimensions(height: 20, width: 12, length: 14),
    bedCapacity: 4,
    singleUnitPrice: 65,
    singleUnitTimeMinutes: 80,
    fullBedUnitPrice: 42,
    fullBedTotalTimeMinutes: 210,
  ),
];

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    Size size = const Size(1280, 1000),
    List<CatalogProduct> products = _products,
    CatalogStorage? storage,
  }) async {
    setViewport(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogStorageProvider.overrideWithValue(
            storage ?? _MemoryCatalogStorage(products),
          ),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset positionOf(String moduleId, WidgetTester tester) {
    return tester.getTopLeft(
      find.byKey(ValueKey('dashboard-module-$moduleId')),
    );
  }

  testWidgets('mostra o total dinâmico do catálogo nos KPIs', (tester) async {
    await pumpDashboard(tester);

    final productCount = tester.widget<Text>(
      find.byKey(const ValueKey('dashboard-product-count')),
    );

    expect(productCount.data, '2');
    expect(find.text('Produtos no Catálogo'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Pronto para cálculo'), findsOneWidget);
  });

  testWidgets('usa a paleta visual compartilhada do sistema', (tester) async {
    await pumpDashboard(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.background);
    expect(dashboardModules[0].accentColor, AppColors.brand);
    expect(dashboardModules[1].accentColor, AppColors.catalogSuccess);
    expect(dashboardModules[2].accentColor, AppColors.brandLight);
  });

  testWidgets('não informa zero quando o catálogo não pode ser carregado', (
    tester,
  ) async {
    await pumpDashboard(tester, storage: _FailingCatalogStorage());

    final productCount = tester.widget<Text>(
      find.byKey(const ValueKey('dashboard-product-count')),
    );
    expect(productCount.data, '—');
    expect(find.text('Catálogo indisponível'), findsOneWidget);
  });

  testWidgets('exibe o card placeholder como módulo indisponível', (
    tester,
  ) async {
    await pumpDashboard(tester, products: const []);

    final placeholder = find.byKey(
      const ValueKey('dashboard-module-novo-modulo'),
    );
    expect(placeholder, findsOneWidget);
    expect(
      find.descendant(
        of: placeholder,
        matching: find.text('Novo Módulo Em Breve'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: placeholder, matching: find.text('Em preparação')),
      findsOneWidget,
    );
  });

  testWidgets('reorganiza os módulos em uma, duas e três colunas', (
    tester,
  ) async {
    await pumpDashboard(tester, size: const Size(390, 1400));

    final calculatorAtOneColumn = positionOf('calculadora', tester);
    final catalogAtOneColumn = positionOf('catalogo', tester);
    final accountAtOneColumn = positionOf('conta', tester);
    expect(catalogAtOneColumn.dx, closeTo(calculatorAtOneColumn.dx, 1));
    expect(catalogAtOneColumn.dy, greaterThan(calculatorAtOneColumn.dy));
    expect(accountAtOneColumn.dy, greaterThan(catalogAtOneColumn.dy));

    tester.view.physicalSize = const Size(800, 1400);
    await tester.pumpAndSettle();

    final calculatorAtTwoColumns = positionOf('calculadora', tester);
    final catalogAtTwoColumns = positionOf('catalogo', tester);
    final accountAtTwoColumns = positionOf('conta', tester);
    expect(catalogAtTwoColumns.dy, closeTo(calculatorAtTwoColumns.dy, 1));
    expect(catalogAtTwoColumns.dx, greaterThan(calculatorAtTwoColumns.dx));
    expect(accountAtTwoColumns.dx, closeTo(calculatorAtTwoColumns.dx, 1));
    expect(accountAtTwoColumns.dy, greaterThan(calculatorAtTwoColumns.dy));

    tester.view.physicalSize = const Size(1280, 1400);
    await tester.pumpAndSettle();

    final calculatorAtThreeColumns = positionOf('calculadora', tester);
    final catalogAtThreeColumns = positionOf('catalogo', tester);
    final accountAtThreeColumns = positionOf('conta', tester);
    final placeholderAtThreeColumns = positionOf('novo-modulo', tester);
    expect(catalogAtThreeColumns.dy, closeTo(calculatorAtThreeColumns.dy, 1));
    expect(accountAtThreeColumns.dy, closeTo(calculatorAtThreeColumns.dy, 1));
    expect(catalogAtThreeColumns.dx, greaterThan(calculatorAtThreeColumns.dx));
    expect(accountAtThreeColumns.dx, greaterThan(catalogAtThreeColumns.dx));
    expect(
      placeholderAtThreeColumns.dx,
      closeTo(calculatorAtThreeColumns.dx, 1),
    );
    expect(
      placeholderAtThreeColumns.dy,
      greaterThan(calculatorAtThreeColumns.dy),
    );
  });

  testWidgets('mantém o dashboard utilizável em viewport muito estreito', (
    tester,
  ) async {
    await pumpDashboard(tester, size: const Size(280, 1200));

    expect(find.text('Painel de Controle Integrado'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-module-calculadora')),
      findsOneWidget,
    );
  });

  testWidgets('navega do dashboard para a calculadora e retorna', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 1000));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthenticatedRepository()),
          catalogStorageProvider.overrideWithValue(
            _MemoryCatalogStorage(_products),
          ),
        ],
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('dashboard-module-calculadora')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados do Projeto'), findsOneWidget);
    expect(find.text('Voltar ao Dashboard'), findsOneWidget);

    await tester.tap(find.text('Voltar ao Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Módulos do Sistema'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-module-calculadora')),
      findsOneWidget,
    );
  });

  testWidgets('abre catálogo e perfil pelos cards e retorna ao dashboard', (
    tester,
  ) async {
    setViewport(tester, const Size(1280, 1000));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthenticatedRepository()),
          catalogStorageProvider.overrideWithValue(
            _MemoryCatalogStorage(_products),
          ),
        ],
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-module-catalogo')));
    await tester.pumpAndSettle();

    expect(
      find.text('Catálogo & Otimizador de Impressão por Mesa (3 Pontos)'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voltar ao Dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-module-conta')));
    await tester.pumpAndSettle();

    expect(find.text('Acesso & Conta'), findsOneWidget);
    expect(find.text('Sessão ativa e protegida'), findsOneWidget);
    await tester.tap(find.text('Voltar ao Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Módulos do Sistema'), findsOneWidget);
  });
}
