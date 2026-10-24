import 'dart:async';

import 'package:doroteia_lab/app.dart';
import 'package:doroteia_lab/core/router/app_router.dart';
import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:doroteia_lab/features/catalog/data/catalog_storage.dart';
import 'package:doroteia_lab/features/catalog/domain/entities/catalog_product.dart';
import 'package:doroteia_lab/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAuthRepository implements AuthRepository {
  _TestAuthRepository({this.user});

  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();
  UserEntity? user;

  @override
  UserEntity? get currentUser => user;

  @override
  Stream<UserEntity?> get authStateChanges async* {
    yield user;
    yield* _authStateController.stream;
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _authenticate(email);
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _authenticate(email);
  }

  @override
  Future<void> signOut() async {
    user = null;
    _authStateController.add(null);
  }

  UserEntity _authenticate(String email) {
    final authenticatedUser = UserEntity(id: 'test-user', email: email);
    user = authenticatedUser;
    _authStateController.add(authenticatedUser);
    return authenticatedUser;
  }

  void dispose() {
    _authStateController.close();
  }
}

class _MemoryCatalogStorage implements CatalogStorage {
  _MemoryCatalogStorage([List<CatalogProduct> products = const []])
    : _products = [...products];

  List<CatalogProduct> _products;

  @override
  Future<List<CatalogProduct>> readProducts() async => [..._products];

  @override
  Future<void> saveProducts(List<CatalogProduct> products) async {
    _products = [...products];
  }
}

void main() {
  Widget appFor(_TestAuthRepository repository) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        catalogStorageProvider.overrideWithValue(_MemoryCatalogStorage()),
      ],
      child: const DoroteiaLabApp(),
    );
  }

  testWidgets('exibe a tela de login para usuário não autenticado', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    expect(find.text('Doroteia Lab'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('configura autofill para credenciais de login', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();

    expect(fields, hasLength(2));
    expect(fields.first.autofillHints, const [
      AutofillHints.username,
      AutofillHints.email,
    ]);
    expect(fields.last.autofillHints, const [AutofillHints.password]);
  });

  testWidgets('oculta o painel de marca em telas menores que 800 px', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    expect(find.text('Inovação em 3D', findRichText: true), findsOneWidget);

    tester.view.physicalSize = const Size(799, 800);
    await tester.pump();

    expect(find.text('Inovação em 3D', findRichText: true), findsNothing);
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
  });

  testWidgets('impede acesso à home sem autenticação', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        catalogStorageProvider.overrideWithValue(_MemoryCatalogStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Entrar no Sistema'), findsOneWidget);
    expect(find.text('Módulos do Sistema'), findsNothing);
  });

  testWidgets('redireciona usuário autenticado para o dashboard', (
    WidgetTester tester,
  ) async {
    const user = UserEntity(id: 'user-id', email: 'user@example.com');
    final repository = _TestAuthRepository(user: user);
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    expect(find.text('Módulos do Sistema'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-module-calculadora')),
      findsOneWidget,
    );
  });

  testWidgets('login pelo provider redireciona para a home', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText).first,
      'usuario@example.com',
    );
    await tester.enterText(find.byType(EditableText).last, 'senha123');
    await tester.tap(find.text('Entrar no Sistema'));
    await tester.pumpAndSettle();

    expect(find.text('Módulos do Sistema'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-product-count')),
      findsOneWidget,
    );
  });
}
