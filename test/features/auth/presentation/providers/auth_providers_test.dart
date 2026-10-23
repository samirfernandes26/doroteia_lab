import 'dart:async';

import 'package:doroteia_lab/shared/data/exceptions/api_auth_exception.dart';
import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:doroteia_lab/features/auth/domain/repositories/auth_repository.dart';
import 'package:doroteia_lab/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthController', () {
    late _MockAuthRepository repository;
    late AuthController controller;

    setUp(() {
      repository = _MockAuthRepository();
      controller = AuthController(repository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('mantém estado loading enquanto o login está em andamento', () async {
      const user = UserEntity(id: 'user-id', email: 'user@example.com');
      final completer = Completer<UserEntity>();
      when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      final operation = controller.signIn(
        email: 'user@example.com',
        password: 'senha123',
      );

      expect(controller.state, const AsyncValue<void>.loading());
      completer.complete(user);
      await operation;
      expect(controller.state, const AsyncValue<void>.data(null));
    });

    test('captura erro de autenticação para a UI', () async {
      const exception = ApiAuthException(
        'E-mail ou senha inválidos.',
        code: 'invalid_credentials',
        statusCode: 401,
      );
      when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(exception);

      await controller.signIn(email: 'user@example.com', password: 'incorreta');

      expect(controller.state.hasError, isTrue);
      expect(controller.state.error, same(exception));
    });
  });
}
