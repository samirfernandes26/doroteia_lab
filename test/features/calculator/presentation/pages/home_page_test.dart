import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:doroteia_lab/features/calculator/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> pumpCalculator(
    WidgetTester tester, {
    Size size = const Size(1200, 900),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthenticatedRepository()),
        ],
        child: const MaterialApp(home: CalculatorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('atualiza o resumo em tempo real ao alterar os campos', (
    tester,
  ) async {
    await pumpCalculator(tester);

    expect(find.textContaining('65,25'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '100');
    await tester.enterText(fields.at(2), '100');
    await tester.enterText(fields.at(3), '2');
    await tester.enterText(fields.at(4), '5');
    await tester.pump();

    // Material: R$ 10,00; máquina: R$ 10,00; margem padrão: 50%.
    expect(find.textContaining('30,00'), findsOneWidget);
  });

  testWidgets('empilha as seções abaixo de 900 px', (tester) async {
    await pumpCalculator(tester);

    final projectTitle = find.text('Dados do Projeto');
    final summaryTitle = find.text('Resumo do Orçamento');
    expect(
      tester.getTopLeft(projectTitle).dy,
      closeTo(tester.getTopLeft(summaryTitle).dy, 1),
    );

    tester.view.physicalSize = const Size(700, 900);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(summaryTitle).dy,
      greaterThan(tester.getTopLeft(projectTitle).dy),
    );
  });

  testWidgets('abre o modal com todas as opções de compartilhamento', (
    tester,
  ) async {
    await pumpCalculator(tester);

    await tester.tap(find.text('Compartilhar Orçamento'));
    await tester.pumpAndSettle();

    expect(find.text('Copiar Resumo Formatado'), findsOneWidget);
    expect(find.text('Enviar Direto pelo WhatsApp'), findsOneWidget);
    expect(find.text('Compartilhar como Imagem'), findsOneWidget);
    expect(find.text('Imprimir / Salvar em PDF'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
