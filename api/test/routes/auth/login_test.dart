import 'dart:convert';
import 'dart:io';

import 'package:api/models/user.dart';
import 'package:api/repositories/user_repository.dart';
import 'package:api/utils/password_utils.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/login.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _FakeUserRepository implements UserRepository {
  UserAuthenticationData? authentication;

  @override
  Future<User?> findByEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<UserAuthenticationData?> findAuthenticationByEmail(
    String email,
  ) async => authentication;

  @override
  Future<User> createUser({
    required String email,
    required String passwordHash,
    String? name,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('POST /auth/login', () {
    test('returns the user and a temporary token', () async {
      final repository = _FakeUserRepository()
        ..authentication = UserAuthenticationData(
          user: User(
            id: 'user-id',
            email: 'user@example.com',
            name: 'Usuário',
            createdAt: DateTime.utc(2026, 10, 22),
          ),
          passwordHash: hashPassword('senha123'),
        );
      final context = _requestContext(
        repository,
        body: {
          'email': 'user@example.com',
          'password': 'senha123',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data']! as Map<String, dynamic>;
      final user = data['user']! as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(body['success'], isTrue);
      expect(user['email'], 'user@example.com');
      expect(user, isNot(contains('passwordHash')));
      expect(
        data['token'],
        isA<String>().having((value) => value, 'value', isNotEmpty),
      );
    });

    test('returns 401 for an invalid password', () async {
      final repository = _FakeUserRepository()
        ..authentication = UserAuthenticationData(
          user: User(
            id: 'user-id',
            email: 'user@example.com',
            createdAt: DateTime.utc(2026, 10, 22),
          ),
          passwordHash: hashPassword('senha-correta'),
        );
      final context = _requestContext(
        repository,
        body: {
          'email': 'user@example.com',
          'password': 'senha-errada',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final error = body['error']! as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(body['success'], isFalse);
      expect(error, {
        'code': 'invalid_credentials',
        'message': 'E-mail ou senha inválidos.',
      });
    });

    test('returns 401 when the user does not exist', () async {
      final context = _requestContext(
        _FakeUserRepository(),
        body: {
          'email': 'missing@example.com',
          'password': 'senha123',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(body, {
        'success': false,
        'error': {
          'code': 'invalid_credentials',
          'message': 'E-mail ou senha inválidos.',
        },
      });
    });

    test('returns a standardized validation error for missing email', () async {
      final context = _requestContext(
        _FakeUserRepository(),
        body: {'password': 'senha123'},
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      expect(body, {
        'success': false,
        'error': {
          'code': 'validation_error',
          'message': 'Informe o e-mail.',
        },
      });
    });
  });
}

RequestContext _requestContext(
  UserRepository repository, {
  required Map<String, Object?> body,
}) {
  final context = _MockRequestContext();
  final request = Request.post(
    Uri.parse('http://localhost/auth/login'),
    headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
    body: jsonEncode(body),
  );

  when(() => context.request).thenReturn(request);
  when(() => context.read<UserRepository>()).thenReturn(repository);
  return context;
}
