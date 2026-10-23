import 'dart:async';

import 'package:doroteia_lab/app.dart';
import 'package:doroteia_lab/core/router/app_router.dart';
import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
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

void main() {
  testWidgets('exibe a tela de login para usuário não autenticado', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doroteia Lab'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const DoroteiaLabApp(),
      ),
    );
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
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
    expect(find.text('Dados do Projeto'), findsNothing);
  });

  testWidgets('redireciona usuário autenticado para a home', (
    WidgetTester tester,
  ) async {
    const user = UserEntity(id: 'user-id', email: 'user@example.com');
    final repository = _TestAuthRepository(user: user);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dados do Projeto'), findsOneWidget);
    expect(find.text('Resumo do Orçamento'), findsOneWidget);
  });

  testWidgets('login pelo provider redireciona para a home', (
    WidgetTester tester,
  ) async {
    final repository = _TestAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const DoroteiaLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText).first,
      'usuario@example.com',
    );
    await tester.enterText(find.byType(EditableText).last, 'senha123');
    await tester.tap(find.text('Entrar no Sistema'));
    await tester.pumpAndSettle();

    expect(find.text('Dados do Projeto'), findsOneWidget);
    expect(find.text('Resumo do Orçamento'), findsOneWidget);
  });
}
