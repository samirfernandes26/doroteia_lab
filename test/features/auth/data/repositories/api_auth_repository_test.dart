import 'package:doroteia_lab/shared/data/datasources/api_auth_datasource.dart';
import 'package:doroteia_lab/shared/data/datasources/auth_session_storage.dart';
import 'package:doroteia_lab/shared/data/exceptions/api_auth_exception.dart';
import 'package:doroteia_lab/shared/data/repositories/api_auth_repository.dart';
import 'package:doroteia_lab/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiAuthDatasource extends Mock implements ApiAuthDatasource {}

class _MockAuthSessionStorage extends Mock implements AuthSessionStorage {}

void main() {
  const user = UserEntity(
    id: 'user-id',
    email: 'user@example.com',
    name: 'User',
  );

  group('ApiAuthRepository', () {
    late _MockApiAuthDatasource datasource;
    late _MockAuthSessionStorage sessionStorage;
    late ApiAuthRepository repository;

    setUp(() {
      datasource = _MockApiAuthDatasource();
      sessionStorage = _MockAuthSessionStorage();
      when(() => sessionStorage.saveUser(user)).thenAnswer((_) async {});
      when(() => sessionStorage.clearUser()).thenAnswer((_) async {});
      repository = ApiAuthRepository(datasource, sessionStorage);
    });

    tearDown(() {
      repository.dispose();
    });

    test('propaga erros do datasource sem autenticar o usuário', () async {
      const exception = ApiAuthException(
        'E-mail ou senha inválidos.',
        code: 'invalid_credentials',
        statusCode: 401,
      );
      when(
        () => datasource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(exception);

      await expectLater(
        repository.signInWithEmail(
          email: 'user@example.com',
          password: 'incorreta',
        ),
        throwsA(same(exception)),
      );
      expect(repository.currentUser, isNull);
    });

    test('emite o usuário autenticado no stream após o login', () async {
      when(
        () => datasource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);
      final emittedStates = <UserEntity?>[];
      final subscription = repository.authStateChanges.listen(
        emittedStates.add,
      );
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      final authenticatedUser = await repository.signInWithEmail(
        email: 'user@example.com',
        password: 'senha123',
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.currentUser, user);
      expect(authenticatedUser, user);
      expect(emittedStates, [null, user]);
      verify(() => sessionStorage.saveUser(user)).called(1);
    });

    test('limpa o usuário e emite null no signOut', () async {
      when(
        () => datasource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);
      await repository.signInWithEmail(
        email: 'user@example.com',
        password: 'senha123',
      );
      final emittedStates = <UserEntity?>[];
      final subscription = repository.authStateChanges.listen(
        emittedStates.add,
      );
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);

      await repository.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(repository.currentUser, isNull);
      expect(emittedStates, [user, null]);
      verify(() => sessionStorage.clearUser()).called(1);
    });

    test('inicia autenticado quando recebe uma sessão restaurada', () async {
      repository.dispose();
      repository = ApiAuthRepository(
        datasource,
        sessionStorage,
        initialUser: user,
      );

      await expectLater(repository.authStateChanges.first, completion(user));
      expect(repository.currentUser, user);
    });
  });
}
